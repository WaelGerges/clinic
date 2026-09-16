// Regression tests for the corrections in
// supabase/migrations/20260916215601_clinic_amendment_queue_and_schedule_fixes.sql
//
// Each test fails against the previously deployed behaviour.
import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { setTimeout } from 'node:timers/promises';
import { PGlite } from '@electric-sql/pglite';

let db;
const doctorA = randomUUID(), doctorB = randomUUID(), assistantA = randomUUID();
const deviceA = randomUUID(), deviceB = randomUUID();
let slot = 0;

function fixtureTime() {
  const day = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Africa/Cairo', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(new Date());
  return new Date(Date.parse(`${day}T00:00:00+03:00`) + (slot++) * 30 * 60 * 1000).toISOString();
}

async function asUser(id, role = 'authenticated') {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id ?? '']);
  await db.exec(`set role ${role}`);
}

async function command(clinic, type, id, action, payload, version, op = randomUUID()) {
  if ((type === 'appointment' && ['status', 'send'].includes(action)) ||
      (type === 'visit' && ['complete', 'amend'].includes(action))) {
    payload = { _expires_at: new Date(Date.now() + 60_000).toISOString(), ...payload };
  }
  const { rows } = await db.query(
    'select public.clinic_apply_command($1,$2,$3,$4,$5,$6::jsonb,$7) as receipt',
    [clinic, op, type, id, action, JSON.stringify(payload), version]);
  return rows[0].receipt;
}

const heartbeat = (clinic, device) =>
  db.query('select public.clinic_doctor_heartbeat($1,$2) as value', [clinic, device]);

async function newPatient(clinic) {
  return (await command(clinic, 'patient', randomUUID(), 'save', {
    full_name: 'Fictional patient', gender: 'Female', birth_date: '1990-04-12',
    mobile: '01000000000', notes: 'Test data only', alerts: '',
  }, 0)).entity;
}

async function appointmentFor(clinic, patient, doctor) {
  return (await command(clinic, 'appointment', randomUUID(), 'save', {
    patient_id: patient.id, doctor_id: doctor, starts_at: fixtureTime(),
    appointment_type: 'Consultation', notes: '',
  }, 0)).entity;
}

async function waiting(clinic, appointment) {
  let a = (await command(clinic, 'appointment', appointment.id, 'status',
    { status: 'arrived' }, appointment.version)).entity;
  return (await command(clinic, 'appointment', a.id, 'status',
    { status: 'waiting' }, a.version)).entity;
}

/** Sends the patient to the doctor, with a fresh presence lease. */
async function sendToDoctor(clinic, patient, doctor, device) {
  const ready = await waiting(clinic, await appointmentFor(clinic, patient, doctor));
  await heartbeat(clinic, device);
  return (await command(clinic, 'appointment', ready.id, 'send', {}, ready.version)).entity;
}

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
  for (const id of [doctorA, doctorB, assistantA]) {
    await db.query('insert into auth.users values($1,now(),$2)', [id, `${id}@example.test`]);
  }
  const directory = new URL('../supabase/migrations/', import.meta.url);
  for (const name of (await readdir(directory)).filter(n => n.endsWith('.sql')).sort()) {
    try { await db.exec(await readFile(new URL(name, directory), 'utf8')); }
    catch (error) { throw new Error(`Migration ${name}: ${error.message} [${error.code}]`); }
  }
});
after(async () => { await db?.close(); });

test('only the visit doctor may amend it; another clinic doctor may not', async () => {
  await asUser(doctorA);
  const clinic = (await db.query("select public.clinic_create('Fictional amendment clinic') as id")).rows[0].id;
  await db.exec('reset role');
  await db.query(
    "insert into public.clinic_memberships(clinic_id,user_id,role,is_admin,clinical_read) values($1,$2,'doctor',true,true)",
    [clinic, doctorB]);

  await asUser(doctorA);
  const patient = await newPatient(clinic);
  const sent = await sendToDoctor(clinic, patient, doctorA, deviceA);
  const visitId = randomUUID();
  const visit = {
    patient_id: patient.id, appointment_id: sent.id, notes: 'Fictional note',
    diagnoses: ['Fictional diagnosis'], medications: [],
  };
  const saved = await command(clinic, 'visit', visitId, 'save', visit, 0);
  const done = await command(clinic, 'visit', visitId, 'complete', {}, saved.entity.version);
  const amendment = {
    ...visit, notes: 'Corrected fictional note',
    amendment_reason: 'Correct a fictional transcription error.',
  };

  // doctorB is an active admin doctor of the same clinic, but not this
  // visit's doctor. The deployed function allowed this.
  await asUser(doctorB);
  await assert.rejects(
    command(clinic, 'visit', visitId, 'amend', amendment, done.entity.version),
    /AMENDMENT_NOT_ASSIGNED_DOCTOR/);
  assert.equal(
    (await db.query('select current_revision from public.visits where id=$1', [visitId])).rows[0].current_revision,
    1);

  await asUser(doctorA);
  const amended = await command(clinic, 'visit', visitId, 'amend', amendment, done.entity.version);
  assert.equal(amended.entity.notes, 'Corrected fictional note');
  assert.equal(amended.entity.current_revision, 2);
});

test('a patient with the doctor can return to the queue or be cancelled', async () => {
  await asUser(doctorA);
  const clinic = (await db.query("select public.clinic_create('Fictional handoff clinic') as id")).rows[0].id;
  const patient = await newPatient(clinic);

  let active = await sendToDoctor(clinic, patient, doctorA, deviceA);
  assert.equal(active.status, 'withDoctor');

  // Returned to the queue rather than stranded with the doctor.
  active = (await command(clinic, 'appointment', active.id, 'status',
    { status: 'waiting' }, active.version)).entity;
  assert.equal(active.status, 'waiting');

  // The released slot lets the doctor take the next patient.
  const second = await sendToDoctor(clinic, await newPatient(clinic), doctorA, deviceA);
  assert.equal(second.status, 'withDoctor');

  // A walkout can be cancelled straight from the doctor.
  const cancelled = (await command(clinic, 'appointment', second.id, 'status',
    { status: 'cancelled' }, second.version)).entity;
  assert.equal(cancelled.status, 'cancelled');

  // Completion is still reachable only through the visit command.
  const third = await sendToDoctor(clinic, await newPatient(clinic), doctorA, deviceA);
  await assert.rejects(
    command(clinic, 'appointment', third.id, 'status', { status: 'completed' }, third.version),
    /INVALID_TRANSITION/);
});

test('an accepted handoff replays its receipt after expiry and after presence lapses', async () => {
  await asUser(doctorA);
  const clinic = (await db.query("select public.clinic_create('Fictional replay clinic') as id")).rows[0].id;
  const patient = await newPatient(clinic);
  const ready = await waiting(clinic, await appointmentFor(clinic, patient, doctorA));
  await heartbeat(clinic, deviceA);

  // The receipt is keyed on the exact request, so a retry must resend the
  // byte-identical payload. That is what the client's outbox replays: the
  // stored payload, including its now-elapsed _expires_at.
  const op = randomUUID();
  const payload = { _expires_at: new Date(Date.now() + 1000).toISOString() };
  const send = () => db.query(
    'select public.clinic_apply_command($1,$2,$3,$4,$5,$6::jsonb,$7) as receipt',
    [clinic, op, 'appointment', ready.id, 'send', JSON.stringify(payload), ready.version]);

  const accepted = (await send()).rows[0].receipt;
  assert.equal(accepted.entity.status, 'withDoctor');

  // Let the freshness window close, and lapse the doctor's presence.
  await setTimeout(1300);
  await db.exec('reset role');
  // Both timestamps move; the table checks expires_at > last_seen_at.
  await db.query(`update clinic_private.doctor_device_presence
    set last_seen_at=clock_timestamp()-interval '5 minutes',
        expires_at=clock_timestamp()-interval '1 minute'`);
  await asUser(doctorA);

  // The deployed wrapper raised COMMAND_EXPIRED / DOCTOR_OFFLINE here, for
  // work the server had already committed.
  assert.deepEqual((await send()).rows[0].receipt, accepted);

  // A genuinely new handoff while the doctor is offline is still refused.
  const other = await waiting(clinic, await appointmentFor(clinic, await newPatient(clinic), doctorA));
  await assert.rejects(
    command(clinic, 'appointment', other.id, 'send', {}, other.version),
    /DOCTOR_OFFLINE/);
});

test('working hours reject an empty period list and can be cleared explicitly', async () => {
  await asUser(doctorA);
  const clinic = (await db.query("select public.clinic_create('Fictional hours clinic') as id")).rows[0].id;
  const patient = await newPatient(clinic);
  const schedule = async (action, payload = {}) => (await db.query(
    'select public.clinic_schedule($1,$2,$3,$4::jsonb) as data',
    [clinic, doctorA, action, JSON.stringify(payload)])).rows[0].data;
  const book = time => command(clinic, 'appointment', randomUUID(), 'save', {
    patient_id: patient.id, doctor_id: doctorA,
    starts_at: `2026-09-14T${time}:00+03:00`, duration_minutes: 30,
  }, 0);

  await schedule('settings', { periods: [{ weekday: 1, start: 540, end: 720 }] });
  await book('09:00');
  await assert.rejects(book('13:00'), /OUTSIDE_WORKING_HOURS/);

  // An empty list was accepted and silently closed the clinic to all booking.
  await assert.rejects(schedule('settings', { periods: [] }), /EMPTY_SCHEDULE/);
  assert.equal((await schedule('read')).settings.periods.length, 1);

  // Clearing is explicit and returns to the unconfigured state.
  assert.equal((await schedule('settings_clear')).settings.configured, false);
  await book('13:00');
});

test('stale presence is pruned but leases cited by a receipt are retained', async () => {
  await asUser(doctorA);
  const clinic = (await db.query("select public.clinic_create('Fictional pruning clinic') as id")).rows[0].id;
  const sent = await sendToDoctor(clinic, await newPatient(clinic), doctorA, deviceA);
  await db.query('select public.clinic_acknowledge_appointment($1,$2,$3,$4,$5)',
    [clinic, sent.id, deviceA, randomUUID(), sent.version]);

  // A long-dead lease from a device that never acknowledged anything.
  await db.exec('reset role');
  await db.query(
    `insert into clinic_private.doctor_device_presence values(
       $1,$2,$3,clock_timestamp()-interval '30 days',
       clock_timestamp()-interval '30 days'+interval '1 minute')`,
    [clinic, doctorA, deviceB]);

  await asUser(doctorA);
  await heartbeat(clinic, deviceA);

  await db.exec('reset role');
  const devices = (await db.query(
    'select device_id from clinic_private.doctor_device_presence where clinic_id=$1', [clinic])).rows;
  assert.deepEqual(devices.map(r => r.device_id), [deviceA]);
  // The acknowledging device's lease survives because a receipt references it.
  assert.equal(
    (await db.query('select count(*)::int as n from clinic_private.appointment_receipts where clinic_id=$1', [clinic])).rows[0].n,
    1);
});

test('expired document access grants are pruned on the next authorization', async () => {
  await asUser(doctorA);
  const clinic = (await db.query("select public.clinic_create('Fictional grant clinic') as id")).rows[0].id;
  const patient = await newPatient(clinic);
  const id = randomUUID();
  const digest = 'ab'.repeat(32);
  await db.query(
    'select public.clinic_begin_attachment($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) as value',
    [id, clinic, patient.id, null, 'fictional.pdf', 'application/pdf', 'Other',
      'Test data only', 321, false, digest]);
  await db.exec('reset role');
  await db.query(
    `insert into storage.objects(bucket_id,name,metadata)
     values('clinic-documents',$1,jsonb_build_object('size',321))`,
    [`${clinic}/${patient.id}/${id}`]);
  await asUser(doctorA);
  await db.query('select public.clinic_finalize_attachment($1)', [id]);
  await db.query("select public.clinic_authorize_attachment_access($1,'preview')", [id]);

  // Age the grant well past its lease, then authorize again.
  await db.exec('reset role');
  await db.query("update clinic_private.attachment_access_grants set expires_at=clock_timestamp()-interval '2 days'");
  const stale = randomUUID();
  await db.query(
    `insert into clinic_private.attachment_access_grants(user_id,attachment_id,object_path,purpose,expires_at)
     values($1,$2,$3,'preview',clock_timestamp()-interval '3 days')`,
    [doctorB, id, `stale/${stale}`]);
  await asUser(doctorA);
  await db.query("select public.clinic_authorize_attachment_access($1,'preview')", [id]);

  await db.exec('reset role');
  const grants = (await db.query('select user_id,expires_at from clinic_private.attachment_access_grants')).rows;
  assert.equal(grants.length, 1);
  assert.equal(grants[0].user_id, doctorA);
  assert.ok(new Date(grants[0].expires_at) > new Date());
});
