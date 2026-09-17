// Regression tests for supabase/migrations/20260917090000_clinic_input_bounds.sql
// (security review 2026-09-17, SEC-001). Each rejection below was accepted by
// the previously deployed schema.
import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

let db;
const doctor = randomUUID(), assistant = randomUUID(), device = randomUUID();
let clinic;
let slot = 0;

function fixtureTime(offsetMs = 0) {
  const day = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Africa/Cairo', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(new Date());
  return new Date(Date.parse(`${day}T00:00:00+03:00`) + (slot++) * 30 * 60 * 1000 + offsetMs).toISOString();
}

async function asUser(id, role = 'authenticated') {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id ?? '']);
  await db.exec(`set role ${role}`);
}

async function command(type, id, action, payload, version, op = randomUUID()) {
  if ((type === 'appointment' && ['status', 'send'].includes(action)) ||
      (type === 'visit' && ['complete', 'amend'].includes(action))) {
    payload = { _expires_at: new Date(Date.now() + 60_000).toISOString(), ...payload };
  }
  const { rows } = await db.query(
    'select public.clinic_apply_command($1,$2,$3,$4,$5,$6::jsonb,$7) as receipt',
    [clinic, op, type, id, action, JSON.stringify(payload), version]);
  return rows[0].receipt;
}

const patientInput = (extra = {}) => ({
  full_name: 'Fictional patient', gender: 'Female', birth_date: '1990-04-12',
  mobile: '01000000000', notes: 'Test data only', alerts: '', ...extra,
});

async function newPatient(extra = {}) {
  return (await command('patient', randomUUID(), 'save', patientInput(extra), 0)).entity;
}

async function withDoctor(patient) {
  await asUser(assistant);
  let a = (await command('appointment', randomUUID(), 'save', {
    patient_id: patient.id, doctor_id: doctor, starts_at: fixtureTime(),
    appointment_type: 'Consultation', notes: '',
  }, 0)).entity;
  a = (await command('appointment', a.id, 'status', { status: 'arrived' }, a.version)).entity;
  a = (await command('appointment', a.id, 'status', { status: 'waiting' }, a.version)).entity;
  await asUser(doctor);
  await db.query('select public.clinic_doctor_heartbeat($1,$2)', [clinic, device]);
  await asUser(assistant);
  a = (await command('appointment', a.id, 'send', {}, a.version)).entity;
  await asUser(doctor);
  return a;
}

/** Releases the doctor's slot so the next fixture can use it. */
async function release(appointment) {
  await asUser(assistant);
  const { rows } = await db.query('select version from public.appointments where id=$1', [appointment.id]);
  await command('appointment', appointment.id, 'status', { status: 'cancelled' }, rows[0].version);
}

const checkViolation = (e) => e.code === '23514';

before(async () => {
  db = new PGlite();
  await db.exec(`create role anon; create role authenticated;
    create schema auth; grant usage on schema auth to anon,authenticated;
    create table auth.users(id uuid primary key,email_confirmed_at timestamptz,email text);
    create function auth.uid() returns uuid language sql stable as
      $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;`);
  await db.exec(`create schema storage; grant usage on schema storage to anon,authenticated;
    create table storage.buckets(
      id text primary key,name text not null,public boolean not null default false,
      file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(
      id uuid primary key default gen_random_uuid(),bucket_id text not null references storage.buckets(id),
      name text not null,owner_id uuid,metadata jsonb not null default '{}'::jsonb,
      created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
      unique(bucket_id,name));
    alter table storage.buckets enable row level security;
    alter table storage.objects enable row level security;
    grant all on storage.buckets,storage.objects to anon,authenticated;`);
  await db.exec(`alter default privileges in schema public grant all on tables to anon,authenticated;
    alter default privileges in schema public grant all on sequences to anon,authenticated;
    alter default privileges in schema public grant all on functions to anon,authenticated;`);
  for (const id of [doctor, assistant]) {
    await db.query('insert into auth.users values($1,now(),$2)', [id, `${id}@example.test`]);
  }
  const directory = new URL('../supabase/migrations/', import.meta.url);
  for (const name of (await readdir(directory)).filter(n => n.endsWith('.sql')).sort()) {
    try { await db.exec(await readFile(new URL(name, directory), 'utf8')); }
    catch (error) { throw new Error(`Migration ${name}: ${error.message} [${error.code}]`); }
  }
  await asUser(doctor);
  clinic = (await db.query("select public.clinic_create('Fictional bounds clinic') as id")).rows[0].id;
  await db.exec('reset role');
  await db.query("insert into public.clinic_memberships(clinic_id,user_id,role) values($1,$2,'assistant')", [clinic, assistant]);
});
after(async () => { await db?.close(); });

test('patient demographics reject oversized text', async () => {
  await asUser(assistant);
  await assert.rejects(newPatient({ notes: 'n'.repeat(5001) }), checkViolation);
  await assert.rejects(newPatient({ address: 'a'.repeat(501) }), checkViolation);
  await assert.rejects(newPatient({ secondary_mobile: '1'.repeat(41) }), checkViolation);
  await asUser(doctor);
  await assert.rejects(newPatient({ alerts: 'x'.repeat(2001) }), checkViolation);
  const ok = await newPatient({ notes: 'n'.repeat(5000), address: 'a'.repeat(500) });
  assert.equal(ok.notes.length, 5000);
  assert.equal((await db.query('select count(*)::int as n from public.patients where clinic_id=$1', [clinic])).rows[0].n, 1);
});

test('appointments reject oversized notes, blank types, distant past and distant future', async () => {
  await asUser(assistant);
  const p = await newPatient();
  const booking = (extra) => command('appointment', randomUUID(), 'save', {
    patient_id: p.id, doctor_id: doctor, starts_at: fixtureTime(),
    appointment_type: 'Consultation', notes: '', ...extra,
  }, 0);
  await assert.rejects(booking({ notes: 'n'.repeat(2001) }), checkViolation);
  await assert.rejects(booking({ appointment_type: '   ' }), checkViolation);
  await assert.rejects(booking({ appointment_type: 't'.repeat(81) }), checkViolation);
  await assert.rejects(booking({ starts_at: new Date(Date.now() - 2 * 365 * 24 * 3600_000).toISOString() }), /PAST_APPOINTMENT/);
  await assert.rejects(booking({ starts_at: new Date(Date.now() + 3 * 365 * 24 * 3600_000).toISOString() }), /INVALID_COMMAND/);
  await assert.rejects(booking({ starts_at: null }), /INVALID_COMMAND/);
  const ok = await booking({ notes: 'n'.repeat(2000) });
  assert.equal(ok.entity.notes.length, 2000);
});

test('visit drafts reject oversized notes and too many diagnoses or medications atomically', async () => {
  await asUser(assistant);
  const p = await newPatient();
  const a = await withDoctor(p);
  const base = { appointment_id: a.id, patient_id: p.id, diagnoses: ['Fictional diagnosis'], medications: [], notes: 'ok' };
  const save = (extra, id = randomUUID()) => command('visit', id, 'save', { ...base, ...extra }, 0);
  await assert.rejects(save({ notes: 'n'.repeat(20001) }), checkViolation);
  await assert.rejects(save({ follow_up: 'f'.repeat(5001) }), checkViolation);
  await assert.rejects(save({ diagnoses: ['d'.repeat(1001)] }), checkViolation);
  await assert.rejects(save({ diagnoses: Array.from({ length: 51 }, (_, i) => `Fictional diagnosis ${i}`) }), checkViolation);
  const medication = (i) => ({ id: randomUUID(), name: `Fictional medication ${i}` });
  await assert.rejects(save({ medications: Array.from({ length: 101 }, (_, i) => medication(i)) }), checkViolation);
  await assert.rejects(save({ medications: [{ id: randomUUID(), name: 'm'.repeat(301) }] }), checkViolation);
  await assert.rejects(save({ medications: [{ ...medication(0), instructions: 'i'.repeat(5001) }] }), checkViolation);
  // Nothing from the rejected saves survived.
  assert.equal((await db.query('select count(*)::int as n from public.visits where appointment_id=$1', [a.id])).rows[0].n, 0);
  assert.equal((await db.query('select count(*)::int as n from public.audit_events where clinic_id=$1 and action=$2', [clinic, 'visit.save'])).rows[0].n, 0);
  const ok = await save({
    diagnoses: Array.from({ length: 50 }, (_, i) => `Fictional diagnosis ${i}`),
    medications: Array.from({ length: 100 }, (_, i) => medication(i)),
    notes: 'n'.repeat(20000),
  });
  assert.equal(ok.entity.diagnoses.length, 50);
  assert.equal(ok.entity.medications.length, 100);
  await release(a);
});

test('a command payload over one mebibyte is rejected before parsing', async () => {
  await asUser(assistant);
  await assert.rejects(
    command('patient', randomUUID(), 'save', patientInput({ padding: 'p'.repeat(1_100_000) }), 0),
    /INVALID_COMMAND/,
  );
});

test('document staging rejects oversized notes and file names', async () => {
  await asUser(assistant);
  const p = await newPatient();
  const begin = (fileName, notes) => db.query(
    'select public.clinic_begin_attachment($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)',
    [randomUUID(), clinic, p.id, null, fileName, 'application/pdf', 'Other', notes, 321, false, 'ab'.repeat(32)]);
  await assert.rejects(begin('fictional-report.pdf', 'n'.repeat(2001)), checkViolation);
  await assert.rejects(begin('f'.repeat(181), 'ok'), /INVALID_ATTACHMENT/);
  await begin('fictional-report.pdf', 'n'.repeat(2000));
});
