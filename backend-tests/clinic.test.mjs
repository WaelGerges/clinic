import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

let db;
const doctorA = randomUUID(), doctorB = randomUUID(), assistantA = randomUUID(), invitee = randomUUID();
const deliveryAssistant = randomUUID();
const doctorDeviceA = randomUUID(), doctorDeviceB = randomUUID();
let clinicA, clinicB;

async function asUser(id, role = 'authenticated') {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id ?? '']);
  await db.exec(`set role ${role}`);
}
async function command(clinic, type, id, action, payload, version, op = randomUUID()) {
  if ((type==='appointment' && ['status','send'].includes(action)) || (type==='visit' && ['complete','amend'].includes(action))) {
    payload = { _expires_at:new Date(Date.now()+60_000).toISOString(), ...payload };
  }
  const { rows } = await db.query(
    'select public.clinic_apply_command($1,$2,$3,$4,$5,$6::jsonb,$7) as receipt',
    [clinic, op, type, id, action, JSON.stringify(payload), version]);
  return rows[0].receipt;
}
const patientInput = (name = 'Fictional patient') => ({full_name:name, gender:'Female',
  birth_date:'1990-04-12', mobile:'01000000000', notes:'Test data only', alerts:''});
async function newPatient(clinic = clinicA) {
  const id = randomUUID();
  return (await command(clinic,'patient',id,'save',patientInput(),0)).entity;
}
async function appointmentFor(patient, doctor = doctorA) {
  return (await command(patient.clinic_id,'appointment',randomUUID(),'save',{
    patient_id:patient.id, doctor_id:doctor, starts_at:new Date().toISOString(),
    appointment_type:'Consultation',notes:''},0)).entity;
}
async function waiting(appointment) {
  let a = (await command(appointment.clinic_id,'appointment',appointment.id,'status',{status:'arrived'},appointment.version)).entity;
  a = (await command(a.clinic_id,'appointment',a.id,'status',{status:'waiting'},a.version)).entity;
  return a;
}
async function heartbeat(clinic, device) {
  return (await db.query(
    'select public.clinic_doctor_heartbeat($1,$2) as value',
    [clinic,device],
  )).rows[0].value;
}
const attachmentHash = 'ab'.repeat(32);
async function beginAttachment({
  id=randomUUID(), clinic=clinicA, patient, visit=null,
  fileName='fictional-report.pdf', contentType='application/pdf',
  category='Other', notes='Test data only', bytes=321,
  clinical=false, sha256=attachmentHash,
}={}) {
  const {rows}=await db.query(`select public.clinic_begin_attachment(
    $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) as value`,
    [id,clinic,patient,visit,fileName,contentType,category,notes,bytes,clinical,sha256]);
  return rows[0].value;
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
  // Model hosted Supabase defaults, including implicit privileges on new views/sequences.
  await db.exec(`alter default privileges in schema public grant all on tables to anon,authenticated;
    alter default privileges in schema public grant all on sequences to anon,authenticated;
    alter default privileges in schema public grant all on functions to anon,authenticated;`);
  for (const id of [doctorA,doctorB,assistantA,invitee,deliveryAssistant]) {
    await db.query('insert into auth.users values($1,now(),$2)',[id,`${id}@example.test`]);
  }
  const directory = new URL('../supabase/migrations/',import.meta.url);
  for (const name of (await readdir(directory)).filter(n=>n.endsWith('.sql')).sort()) {
    try { await db.exec(await readFile(new URL(name,directory),'utf8')); }
    catch (error) { throw new Error(`Migration ${name}: ${error.message} [${error.code}]`); }
  }
  await asUser(doctorA);
  clinicA=(await db.query("select public.clinic_create('Fictional clinic A') as id")).rows[0].id;
  await heartbeat(clinicA,doctorDeviceA);
  await asUser(doctorB);
  clinicB=(await db.query("select public.clinic_create('Fictional clinic B') as id")).rows[0].id;
  await heartbeat(clinicB,doctorDeviceB);
  await db.exec('reset role');
  await db.query("insert into public.clinic_memberships(clinic_id,user_id,role) values($1,$2,'assistant')",[clinicA,assistantA]);
});
after(async () => { await db?.close(); });

test('anonymous access and direct authenticated writes are denied',async()=>{
  await asUser(null,'anon');
  await assert.rejects(db.query('select * from public.patients'),e=>e.code==='42501');
  await assert.rejects(db.query("select public.clinic_create('Bad clinic')"),e=>e.code==='42501');
  await asUser(assistantA);
  await assert.rejects(db.query('delete from public.patients'),e=>e.code==='42501');
});

test('clinic ownership, RLS and cross-clinic identifiers stay isolated',async()=>{
  await asUser(doctorA);
  const a=await newPatient();
  await asUser(doctorB);
  assert.equal((await db.query('select * from public.patients where id=$1',[a.id])).rows.length,0);
  await assert.rejects(command(clinicA,'patient',randomUUID(),'save',patientInput(),0),/FORBIDDEN/);
  await assert.rejects(command(clinicB,'patient',a.id,'save',patientInput(),0),/CROSS_CLINIC_ID/);
  const b=await newPatient(clinicB);
  assert.equal(b.patient_number,1,'number allocation is clinic-scoped');
  await assert.rejects(command(clinicB,'appointment',randomUUID(),'save',{
    patient_id:a.id,doctor_id:doctorB,starts_at:new Date().toISOString()},0),/INVALID_PATIENT/);
});

test('membership visibility remains own/admin/doctor scoped after policy optimization',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional membership policy clinic') as id")).rows[0].id;
  const invite=(await db.query('select public.clinic_invite_assistant($1,$2,false) as value',
    [clinic,`${assistantA}@example.test`])).rows[0].value;
  await asUser(assistantA);
  await db.query('select public.clinic_join($1)',[invite.code]);
  await asUser(doctorA);
  const other=(await db.query('select public.clinic_invite_assistant($1,$2,false) as value',
    [clinic,`${invitee}@example.test`])).rows[0].value;
  await asUser(invitee);
  await db.query('select public.clinic_join($1)',[other.code]);
  const visible=async()=>new Set((await db.query('select user_id from public.clinic_memberships where clinic_id=$1',[clinic])).rows.map(r=>r.user_id));
  await asUser(assistantA);
  assert.deepEqual(await visible(),new Set([assistantA,doctorA]));
  await asUser(doctorA);
  assert.deepEqual(await visible(),new Set([assistantA,doctorA,invitee]));
  await asUser(doctorB);
  assert.deepEqual(await visible(),new Set());
});

test('operation replay is idempotent and rejects payload reuse',async()=>{
  await asUser(assistantA);
  const id=randomUUID(), op=randomUUID(), input=patientInput('Replay test');
  const first=await command(clinicA,'patient',id,'save',input,0,op);
  assert.deepEqual(await command(clinicA,'patient',id,'save',input,0,op),first);
  await assert.rejects(command(clinicA,'patient',id,'save',patientInput('Changed payload'),0,op),/OPERATION_ID_REUSED/);
  assert.equal((await db.query('select version from public.patients where id=$1',[id])).rows[0].version,1);
});

test('stale patient edits preserve server data and assistants cannot set alerts',async()=>{
  await asUser(assistantA);
  const p=await newPatient();
  const update=await command(clinicA,'patient',p.id,'save',{...patientInput(),notes:'First update'},1);
  assert.equal(update.version,2);
  await assert.rejects(command(clinicA,'patient',p.id,'save',{...patientInput(),notes:'Stale update'},1),/VERSION_CONFLICT/);
  await assert.rejects(command(clinicA,'patient',p.id,'save',{...patientInput(),alerts:'Unauthorized'},2),/FORBIDDEN_ALERT_EDIT/);
  assert.equal((await db.query('select notes from public.patients where id=$1',[p.id])).rows[0].notes,'First update');
});

test('queue protects the active slot, preserves clinical revisions and completes atomically',async()=>{
  await asUser(assistantA);
  const p=await newPatient(), p2=await newPatient();
  let a=await waiting(await appointmentFor(p));
  const b=await waiting(await appointmentFor(p2));
  a=(await command(clinicA,'appointment',a.id,'send',{},a.version)).entity;
  await assert.rejects(command(clinicA,'appointment',b.id,'send',{},b.version),/DOCTOR_BUSY/);
  await assert.rejects(command(clinicA,'patient',p.id,'save',{...patientInput(),archived:true},p.version),/PATIENT_ACTIVE/);
  const visitId=randomUUID();
  const visit={appointment_id:a.id,patient_id:p.id,diagnoses:['Fictional diagnosis'],
    medications:[{id:randomUUID(),name:'Fictional medication',dose:'Test only'}],notes:'Draft one'};
  await assert.rejects(command(clinicA,'visit',visitId,'save',visit,0),/FORBIDDEN/);
  await asUser(doctorA);
  const first=await command(clinicA,'visit',visitId,'save',visit,0);
  assert.equal(first.entity.medications.length,1);
  const second=await command(clinicA,'visit',visitId,'save',{...visit,notes:'Draft two'},1);
  assert.equal(second.entity.notes,'Draft two');
  assert.equal((await db.query('select count(*)::int as n from public.visit_revisions where visit_id=$1',[visitId])).rows[0].n,2);
  const completed=await command(clinicA,'visit',visitId,'complete',{},2);
  assert.equal(completed.entity.completed,true);
  assert.equal(completed.appointment.status,'completed');
  assert.equal((await db.query('select status from public.appointments where id=$1',[a.id])).rows[0].status,'completed');
  await assert.rejects(command(clinicA,'visit',visitId,'save',visit,3),/COMPLETED_VISIT_IMMUTABLE/);

  const amendment={...visit,notes:'Corrected fictional clinical note',
    diagnoses:['Corrected fictional diagnosis'],amendment_reason:'Correct a fictional transcription error.',
    _expires_at:new Date(Date.now()+60_000).toISOString()};
  await asUser(assistantA);
  await assert.rejects(command(clinicA,'visit',visitId,'amend',amendment,3),/FORBIDDEN/);
  await asUser(doctorA);
  await assert.rejects(command(clinicA,'visit',visitId,'amend',{...amendment,amendment_reason:'short'},3),/AMENDMENT_REASON_REQUIRED/);
  await assert.rejects(command(clinicA,'visit',visitId,'amend',{
    ...amendment,medications:[{id:randomUUID(),name:'x'.repeat(301)}]},3),/INVALID_AMENDMENT/);
  await assert.rejects(command(clinicA,'visit',visitId,'amend',{
    ...amendment,_expires_at:new Date(Date.now()-1000).toISOString()},3),/COMMAND_EXPIRED/);
  const amendOp=randomUUID();
  const amended=await command(clinicA,'visit',visitId,'amend',amendment,3,amendOp);
  assert.equal(amended.entity.completed,true);
  assert.equal(amended.entity.version,4);
  assert.equal(amended.entity.current_revision,3);
  assert.equal(amended.entity.notes,'Corrected fictional clinical note');
  assert.equal(amended.entity.amendment_reason,'Correct a fictional transcription error.');
  assert.deepEqual(await command(clinicA,'visit',visitId,'amend',amendment,3,amendOp),amended);
  await assert.rejects(command(clinicA,'visit',visitId,'amend',amendment,3),/VERSION_CONFLICT/);
  assert.deepEqual((await db.query(
    'select revision,notes,amendment_reason from public.visit_revisions where visit_id=$1 order by revision',
    [visitId])).rows,[
      {revision:1,notes:'Draft one',amendment_reason:''},
      {revision:2,notes:'Draft two',amendment_reason:''},
      {revision:3,notes:'Corrected fictional clinical note',amendment_reason:'Correct a fictional transcription error.'},
    ]);
  assert.equal((await db.query(
    "select count(*)::int as n from public.audit_events where object_id=$1 and action='visit.amend'",
    [visitId])).rows[0].n,1);
  await assert.rejects(command(clinicA,'visit',visitId,'save',visit,4),/COMPLETED_VISIT_IMMUTABLE/);
  await asUser(assistantA);
  assert.equal((await db.query('select * from public.visit_details where id=$1',[visitId])).rows.length,0);
  assert.equal((await command(clinicA,'appointment',b.id,'send',{},b.version)).entity.status,'withDoctor');
  // End this fixture's active appointment through a complete clinical visit.
  await asUser(doctorA);
  const nextVisit=randomUUID();
  await command(clinicA,'visit',nextVisit,'save',{...visit,appointment_id:b.id,patient_id:p2.id},0);
  await command(clinicA,'visit',nextVisit,'complete',{},1);
});

test('doctor presence gates handoff and an immutable explicit device receipt confirms delivery',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional delivery clinic') as id")).rows[0].id;
  await db.exec('reset role');
  await db.query("insert into public.clinic_memberships(clinic_id,user_id,role) values($1,$2,'assistant')",[clinic,deliveryAssistant]);
  await asUser(deliveryAssistant);
  const patient=await newPatient(clinic);
  const waitingAppointment=await waiting(await appointmentFor(patient,doctorA));
  await assert.rejects(
    command(clinic,'appointment',waitingAppointment.id,'send',{},waitingAppointment.version),
    /DOCTOR_OFFLINE/,
  );
  await asUser(doctorA);
  const device=randomUUID();
  const presence=await heartbeat(clinic,device);
  assert.equal(presence.doctor_online,true);
  await asUser(deliveryAssistant);
  const sent=(await command(
    clinic,'appointment',waitingAppointment.id,'send',{},waitingAppointment.version,
  )).entity;
  let state=(await db.query(
    'select public.clinic_doctor_delivery_state($1,$2,$3) as value',
    [clinic,doctorA,sent.id],
  )).rows[0].value;
  assert.equal(state.doctor_online,true);
  assert.equal(state.acknowledged_at,null);
  await assert.rejects(
    db.query('select public.clinic_acknowledge_appointment($1,$2,$3,$4,$5)',
      [clinic,sent.id,device,randomUUID(),sent.version]),
    e=>e.code==='42501',
  );
  await asUser(doctorA);
  await assert.rejects(
    db.query('select public.clinic_acknowledge_appointment($1,$2,$3,$4,$5)',
      [clinic,sent.id,randomUUID(),randomUUID(),sent.version]),
    /DOCTOR_DEVICE_OFFLINE/,
  );
  const operation=randomUUID();
  const acknowledged=(await db.query(
    'select public.clinic_acknowledge_appointment($1,$2,$3,$4,$5) as value',
    [clinic,sent.id,device,operation,sent.version],
  )).rows[0].value;
  assert.ok(acknowledged.acknowledged_at);
  const replay=(await db.query(
    'select public.clinic_acknowledge_appointment($1,$2,$3,$4,$5) as value',
    [clinic,sent.id,device,operation,sent.version],
  )).rows[0].value;
  assert.equal(replay.acknowledged_at,acknowledged.acknowledged_at);
  assert.equal(replay.appointment_version,acknowledged.appointment_version);
  await assert.rejects(
    db.query('select public.clinic_acknowledge_appointment($1,$2,$3,$4,$5)',
      [clinic,randomUUID(),device,operation,sent.version]),
    /OPERATION_ID_REUSED/,
  );
  await asUser(deliveryAssistant);
  state=(await db.query(
    'select public.clinic_doctor_delivery_state($1,$2,$3) as value',
    [clinic,doctorA,sent.id],
  )).rows[0].value;
  assert.equal(state.acknowledged_at,acknowledged.acknowledged_at);
  await db.exec('reset role');
  await assert.rejects(
    db.query('update clinic_private.appointment_receipts set acknowledged_at=now()'),
    /IMMUTABLE_HISTORY/,
  );
  assert.equal((await db.query(
    "select count(*)::int as n from public.audit_events where object_id=$1 and action='appointment.received'",
    [sent.id],
  )).rows[0].n,1);
  await asUser(assistantA);
});

test('duplicate waiting entry and canceled appointment handoff are rejected',async()=>{
  await asUser(assistantA);
  const p=await newPatient();
  await waiting(await appointmentFor(p));
  let duplicate=await appointmentFor(p);
  duplicate=(await command(clinicA,'appointment',duplicate.id,'status',{status:'arrived'},1)).entity;
  await assert.rejects(command(clinicA,'appointment',duplicate.id,'status',{status:'waiting'},2),e=>e.code==='23505');
  duplicate=(await command(clinicA,'appointment',duplicate.id,'status',{status:'cancelled'},2)).entity;
  await assert.rejects(command(clinicA,'appointment',duplicate.id,'send',{},duplicate.version),/INVALID_TRANSITION/);
});

test('revoked membership cannot replay a previously successful operation',async()=>{
  await asUser(assistantA);
  const op=randomUUID(), id=randomUUID(), payload=patientInput();
  await command(clinicA,'patient',id,'save',payload,0,op);
  await db.exec('reset role');
  await db.query('update public.clinic_memberships set active=false where clinic_id=$1 and user_id=$2',[clinicA,assistantA]);
  await asUser(assistantA);
  await assert.rejects(command(clinicA,'patient',id,'save',payload,0,op),/FORBIDDEN/);
  assert.equal((await db.query('select * from public.patients')).rows.length,0);
  await db.exec('reset role');
  await db.query('update public.clinic_memberships set active=true where clinic_id=$1 and user_id=$2',[clinicA,assistantA]);
});

test('audit and revision records reject overwrite even through privileged SQL',async()=>{
  await db.exec('reset role');
  await assert.rejects(db.query("update public.audit_events set action='changed'"),/IMMUTABLE_HISTORY/);
  await assert.rejects(db.query("update public.visit_revisions set notes='changed'"),/IMMUTABLE_HISTORY/);
  const {rows}=await db.query(`select c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind='r' and not c.relrowsecurity`);
  assert.deepEqual(rows,[],'all exposed tables have RLS');
});

test('expired queue intent cannot execute and an inactive doctor cannot receive a patient',async()=>{
  await asUser(assistantA);
  const p=await newPatient(), a=await waiting(await appointmentFor(p));
  await assert.rejects(command(clinicA,'appointment',a.id,'send',{
    _expires_at:new Date(Date.now()-60_000).toISOString()},a.version),/COMMAND_EXPIRED/);
  assert.equal((await db.query('select status from public.appointments where id=$1',[a.id])).rows[0].status,'waiting');
  await db.exec('reset role');
  await db.query('update public.clinic_memberships set active=false where clinic_id=$1 and user_id=$2',[clinicA,doctorA]);
  await asUser(assistantA);
  await assert.rejects(command(clinicA,'appointment',a.id,'send',{},a.version),/INVALID_DOCTOR/);
  await db.exec('reset role');
  await db.query('update public.clinic_memberships set active=true where clinic_id=$1 and user_id=$2',[clinicA,doctorA]);
});

test('patient search uses literal matching, secondary numbers and separate archives',async()=>{
  await asUser(assistantA);
  const id=randomUUID();
  await command(clinicA,'patient',id,'save',{...patientInput('Unique search fixture'),secondary_mobile:'01123456789'},0);
  const search=async(term,archived=false)=>(await db.query(
    'select id from public.clinic_search_patients($1,$2,0,50,$3)',[clinicA,term,archived])).rows;
  assert.deepEqual(await search('e search fi'),[{id}]);
  assert.deepEqual(await search('123456789'),[{id}]);
  assert.deepEqual(await search('%'),[]);
  await command(clinicA,'patient',id,'save',{...patientInput('Unique search fixture'),archived:true},1);
  assert.deepEqual(await search('Unique search fixture'),[]);
  assert.deepEqual(await search('Unique search fixture',true),[{id}]);
  await asUser(doctorB);
  assert.deepEqual(await search('Unique search fixture',true),[]);
});

test('assistant invitations bind to verified email, are single use and cannot grant admin',async()=>{
  await asUser(assistantA);
  await assert.rejects(db.query('select public.clinic_invite_assistant($1,$2,false)',[clinicA,`${invitee}@example.test`]),e=>e.code==='42501');
  await asUser(doctorA);
  const invitation=(await db.query('select public.clinic_invite_assistant($1,$2,true) as value',[clinicA,`${invitee}@example.test`])).rows[0].value;
  assert.equal(invitation.code.length,64);
  await asUser(doctorB);
  await assert.rejects(db.query('select public.clinic_join($1)',[invitation.code]),/INVITATION_INVALID/);
  await asUser(invitee);
  assert.equal((await db.query('select public.clinic_join($1) as id',[invitation.code])).rows[0].id,clinicA);
  await assert.rejects(db.query('select public.clinic_join($1)',[invitation.code]),/INVITATION_INVALID/);
  const membership=(await db.query('select role,is_admin,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',[clinicA,invitee])).rows[0];
  assert.deepEqual(membership,{role:'assistant',is_admin:false,clinical_read:true});
  await assert.rejects(db.query('select public.clinic_staff($1)',[clinicA]),e=>e.code==='42501');
  await asUser(doctorA);
  await db.query('select public.clinic_set_staff_access($1,$2,false,false)',[clinicA,invitee]);
  await asUser(invitee);
  assert.equal((await db.query('select * from public.patients')).rows.length,0);
});

test('visit identity rejects absent, null and mismatched patient/appointment without side effects',async()=>{
  await asUser(doctorB);
  const clinic=(await db.query("select public.clinic_create('Fictional identity clinic') as id")).rows[0].id;
  await heartbeat(clinic,doctorDeviceB);
  const p=await newPatient(clinic), other=await newPatient(clinic);
  let a=await waiting(await appointmentFor(p,doctorB));
  const b=await appointmentFor(other,doctorB);
  a=(await command(clinic,'appointment',a.id,'send',{},a.version)).entity;
  const visitId=randomUUID(), valid={patient_id:p.id,appointment_id:a.id,diagnoses:['Fictional original'],notes:'Original draft'};
  const snapshot=async()=>{
    await db.exec('reset role');
    const value=(await db.query(`select
      (select coalesce(jsonb_agg(v order by id),'[]'::jsonb) from public.visits v where clinic_id=$1) as visits,
      (select count(*)::int from public.visit_revisions where clinic_id=$1) as revisions,
      (select count(*)::int from public.audit_events where clinic_id=$1) as audit,
      (select count(*)::int from clinic_private.operation_receipts where clinic_id=$1) as receipts`,[clinic])).rows[0];
    await asUser(doctorB);
    return value;
  };
  for (const version of [0,1]) {
    if (version===1) await command(clinic,'visit',visitId,'save',valid,0);
    const before=await snapshot();
    const {patient_id:ignoredPatient,...withoutPatient}=valid;
    const {appointment_id:ignoredAppointment,...withoutAppointment}=valid;
    for (const bad of [withoutPatient,withoutAppointment,{...valid,patient_id:null},
      {...valid,appointment_id:null},{...valid,patient_id:other.id},
      {...valid,appointment_id:b.id,patient_id:other.id}]) {
      await assert.rejects(command(clinic,'visit',visitId,'save',bad,version),/IDENTITY|ASSIGNMENT_CHANGED/);
      assert.deepEqual(await snapshot(),before);
    }
  }
});

test('default privileges cannot expose audit sequences or anonymous clinical views',async()=>{
  for (const [user,role] of [[null,'anon'],[assistantA,'authenticated']]) {
    await asUser(user,role);
    await assert.rejects(db.query("select setval('public.audit_events_id_seq',1,false)"),e=>e.code==='42501');
    await assert.rejects(db.query("select nextval('public.audit_events_id_seq')"),e=>e.code==='42501');
  }
  await asUser(null,'anon');
  await assert.rejects(db.query('select * from public.visit_details'),e=>e.code==='42501');
});

test('later staff revocation invalidates unused invitations and permits only a fresh authorized invite',async()=>{
  await asUser(doctorA);
  await db.query('select public.clinic_set_staff_access($1,$2,true,false)',[clinicA,invitee]);
  const old=(await db.query('select public.clinic_invite_assistant($1,$2,true) as v',[clinicA,`${invitee}@example.test`])).rows[0].v;
  await db.query('select public.clinic_set_staff_access($1,$2,false,false)',[clinicA,invitee]);
  const before=(await db.query("select count(*)::int as n from public.audit_events where clinic_id=$1 and action='staff.joined'",[clinicA])).rows[0].n;
  await asUser(invitee);
  await assert.rejects(db.query('select public.clinic_join($1)',[old.code]),/INVITATION_INVALID/);
  await asUser(doctorA);
  assert.deepEqual((await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',[clinicA,invitee])).rows[0],{active:false,clinical_read:false});
  assert.equal((await db.query("select count(*)::int as n from public.audit_events where clinic_id=$1 and action='staff.joined'",[clinicA])).rows[0].n,before);
  const fresh=(await db.query('select public.clinic_invite_assistant($1,$2,false) as v',[clinicA,`${invitee}@example.test`])).rows[0].v;
  await asUser(invitee);
  await db.query('select public.clinic_join($1)',[fresh.code]);
  assert.deepEqual((await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',[clinicA,invitee])).rows[0],{active:true,clinical_read:false});
});

// Retained review regressions, promoted into the regular suite.
test('review: disabling an assistant invalidates all invitations issued before revocation',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional invitation revocation review') as id")).rows[0].id;
  const issue=async()=> (await db.query('select public.clinic_invite_assistant($1,$2,true) as invitation',
    [clinic,`${assistantA}@example.test`])).rows[0].invitation;
  const first=await issue();
  await asUser(assistantA);
  await db.query('select public.clinic_join($1)',[first.code]);
  await asUser(doctorA);
  // The current RPC allows another unused invitation for an active member.
  const pending=await issue();
  await db.query('select public.clinic_set_staff_access($1,$2,false,false)',[clinic,assistantA]);
  const revoked=(await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',
    [clinic,assistantA])).rows[0];
  assert.deepEqual(revoked,{active:false,clinical_read:false});
  await asUser(assistantA);
  let rejection;
  try { await db.query('select public.clinic_join($1)',[pending.code]); }
  catch (error) { rejection=error; }
  if (!rejection) {
    const restored=(await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',
      [clinic,assistantA])).rows[0];
    assert.fail(`Pre-revocation invitation restored revoked access: ${JSON.stringify(restored)}`);
  }
  assert.match(rejection.message,/INVITATION_INVALID/);
});

test('review: membership cutoff rejects an old invitation missed after an email change',async()=>{
  const originalEmail=`${assistantA}@example.test`, changedEmail=`changed-${assistantA}@example.test`;
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional email cutoff review') as id")).rows[0].id;
  const issue=async(read)=>(await db.query('select public.clinic_invite_assistant($1,$2,$3) as value',
    [clinic,originalEmail,read])).rows[0].value;
  const first=await issue(false);
  await asUser(assistantA);
  await db.query('select public.clinic_join($1)',[first.code]);
  await asUser(doctorA);
  const old=await issue(true);
  await db.exec('reset role');
  await db.query('update auth.users set email=$1 where id=$2',[changedEmail,assistantA]);
  try {
    await asUser(doctorA);
    await db.query('select public.clinic_set_staff_access($1,$2,false,false)',[clinic,assistantA]);
  } finally {
    await db.exec('reset role');
    await db.query('update auth.users set email=$1 where id=$2',[originalEmail,assistantA]);
  }
  const pending=(await db.query('select revoked_at,used_at from clinic_private.staff_invitations where id=$1',[old.id])).rows[0];
  assert.deepEqual(pending,{revoked_at:null,used_at:null},'this token must exercise the membership cutoff, not email invalidation');
  const before=(await db.query("select count(*)::int as n from public.audit_events where clinic_id=$1 and action='staff.joined'",[clinic])).rows[0].n;
  await asUser(assistantA);
  await assert.rejects(db.query('select public.clinic_join($1)',[old.code]),/INVITATION_INVALID/);
  await asUser(doctorA);
  assert.deepEqual((await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',
    [clinic,assistantA])).rows[0],{active:false,clinical_read:false});
  assert.equal((await db.query("select count(*)::int as n from public.audit_events where clinic_id=$1 and action='staff.joined'",[clinic])).rows[0].n,before);
  const fresh=await issue(false);
  await asUser(assistantA);
  await db.query('select public.clinic_join($1)',[fresh.code]);
  assert.deepEqual((await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',
    [clinic,assistantA])).rows[0],{active:true,clinical_read:false});
});

test('review: clinical access reduction invalidates an older higher-privilege invitation',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional access reduction review') as id")).rows[0].id;
  const issue=async()=>(await db.query('select public.clinic_invite_assistant($1,$2,true) as value',
    [clinic,`${assistantA}@example.test`])).rows[0].value;
  const first=await issue();
  await asUser(assistantA);
  await db.query('select public.clinic_join($1)',[first.code]);
  await asUser(doctorA);
  const pending=await issue();
  await db.query('select public.clinic_set_staff_access($1,$2,true,false)',[clinic,assistantA]);
  await asUser(assistantA);
  await assert.rejects(db.query('select public.clinic_join($1)',[pending.code]),/INVITATION_INVALID/);
  assert.deepEqual((await db.query('select active,clinical_read from public.clinic_memberships where clinic_id=$1 and user_id=$2',
    [clinic,assistantA])).rows[0],{active:true,clinical_read:false});
});

test('review: expired invitations cannot be consumed or create a membership',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional expiry review') as id")).rows[0].id;
  const invite=(await db.query('select public.clinic_invite_assistant($1,$2,false) as value',
    [clinic,`${invitee}@example.test`])).rows[0].value;
  await db.exec('reset role');
  const stored=(await db.query("select encode(token_hash,'hex') as hash,extract(epoch from (expires_at-created_at)) as ttl from clinic_private.staff_invitations where id=$1",[invite.id])).rows[0];
  assert.match(stored.hash,/^[a-f0-9]{64}$/);
  assert.notEqual(stored.hash,invite.code);
  assert.ok(Number(stored.ttl)>86300 && Number(stored.ttl)<=86400);
  assert.equal((await db.query('select to_jsonb(a)::text as value from public.audit_events a where object_id=$1',[invite.id])).rows.some(r=>r.value.includes(invite.code)),false);
  await db.query("update clinic_private.staff_invitations set expires_at=now()-interval '1 second' where id=$1",[invite.id]);
  await asUser(invitee);
  await assert.rejects(db.query('select public.clinic_join($1)',[invite.code]),/INVITATION_INVALID/);
  await db.exec('reset role');
  assert.equal((await db.query('select count(*)::int as n from public.clinic_memberships where clinic_id=$1 and user_id=$2',[clinic,invitee])).rows[0].n,0);
  assert.equal((await db.query('select used_at from clinic_private.staff_invitations where id=$1',[invite.id])).rows[0].used_at,null);
});

test('review: matching but unverified email cannot consume an invitation',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional email verification review') as id")).rows[0].id;
  const invite=(await db.query('select public.clinic_invite_assistant($1,$2,false) as value',
    [clinic,`${invitee}@example.test`])).rows[0].value;
  await db.exec('reset role');
  await db.query('update auth.users set email_confirmed_at=null where id=$1',[invitee]);
  try {
    await asUser(invitee);
    await assert.rejects(db.query('select public.clinic_join($1)',[invite.code]),/INVITATION_INVALID/);
  } finally {
    await db.exec('reset role');
    await db.query('update auth.users set email_confirmed_at=now() where id=$1',[invitee]);
  }
  assert.equal((await db.query('select used_at from clinic_private.staff_invitations where id=$1',[invite.id])).rows[0].used_at,null);
});

test('review: staff controls deny nonadmins and private invitation reads/writes',async()=>{
  for (const user of [assistantA,doctorB]) {
    await asUser(user);
    await assert.rejects(db.query('select public.clinic_staff($1)',[clinicA]),e=>e.code==='42501');
    await assert.rejects(db.query('select public.clinic_set_staff_access($1,$2,true,true)',[clinicA,assistantA]),e=>e.code==='42501');
    await assert.rejects(db.query('select public.clinic_invite_assistant($1,$2,false)',[clinicA,`${invitee}@example.test`]),e=>e.code==='42501');
  }
  for (const [user,role] of [[null,'anon'],[doctorA,'authenticated']]) {
    await asUser(user,role);
    await assert.rejects(db.query('select * from clinic_private.staff_invitations'),e=>e.code==='42501');
    await assert.rejects(db.query('delete from clinic_private.staff_invitations'),e=>e.code==='42501');
  }
  await asUser(null,'anon');
  await assert.rejects(db.query('select public.clinic_join($1)',['a'.repeat(64)]),e=>e.code==='42501');
  await asUser(doctorA);
  await assert.rejects(db.query('select public.clinic_set_staff_access($1,$2,false,false)',[clinicA,doctorA]),/ASSISTANT_NOT_FOUND/);
});

test('review: per-clinic hourly invitation issue limit rejects the twenty-first issue',async()=>{
  await asUser(doctorA);
  const clinic=(await db.query("select public.clinic_create('Fictional invitation limit review') as id")).rows[0].id;
  for (let i=0;i<20;i++) await db.query('select public.clinic_invite_assistant($1,$2,false)',[clinic,`limit-${i}@example.test`]);
  await assert.rejects(db.query('select public.clinic_invite_assistant($1,$2,false)',[clinic,'limit-overflow@example.test']),/INVITATION_LIMIT/);
  await db.exec('reset role');
  assert.equal((await db.query('select count(*)::int as n from clinic_private.staff_invitations where clinic_id=$1',[clinic])).rows[0].n,20);
  assert.equal((await db.query("select count(*)::int as n from public.audit_events where clinic_id=$1 and action='staff.invited'",[clinic])).rows[0].n,20);
});

test('private document lifecycle requires an exact upload path and a short audited read lease',async()=>{
  await asUser(doctorA);
  const patient=await newPatient();
  const id=randomUUID();
  const attachment=await beginAttachment({id,patient:patient.id,clinical:true,bytes:321});
  assert.equal(attachment.object_path,`${clinicA}/${patient.id}/${id}`);
  assert.equal(attachment.sha256_hex,attachmentHash);
  await assert.rejects(db.query(`insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('clinic-documents',$1,$2,$3::jsonb)`,
    [`${clinicA}/${patient.id}/${randomUUID()}`,doctorA,JSON.stringify({size:321})]),e=>e.code==='42501');
  await db.query(`insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('clinic-documents',$1,$2,$3::jsonb)`,
    [attachment.object_path,doctorA,JSON.stringify({size:321,mimetype:'application/pdf'})]);
  const ready=(await db.query('select public.clinic_finalize_attachment($1) as value',[id])).rows[0].value;
  assert.equal(ready.state,'ready');
  assert.deepEqual((await db.query('select name from storage.objects where name=$1',[attachment.object_path])).rows,[]);
  const lease=(await db.query("select public.clinic_authorize_attachment_access($1,'preview') as value",[id])).rows[0].value;
  assert.equal(lease.object_path,attachment.object_path);
  assert.deepEqual((await db.query('select name from storage.objects where name=$1',[attachment.object_path])).rows,
    [{name:attachment.object_path}]);
  await db.query("update storage.objects set metadata='{}' where name=$1",[attachment.object_path]);
  await db.query('delete from storage.objects where name=$1',[attachment.object_path]);
  await db.exec('reset role');
  assert.deepEqual((await db.query('select metadata from storage.objects where name=$1',[attachment.object_path])).rows,
    [{metadata:{size:321,mimetype:'application/pdf'}}],
    'absence of update/delete policies must make both mutations no-ops');
  await db.query("update clinic_private.attachment_access_grants set expires_at=now()-interval '1 second' where attachment_id=$1",[id]);
  await asUser(doctorA);
  assert.deepEqual((await db.query('select name from storage.objects where name=$1',[attachment.object_path])).rows,[]);
  await db.exec('reset role');
  assert.equal((await db.query("select count(*)::int as n from public.audit_events where object_id=$1 and action='attachment.accessed'",[id])).rows[0].n,1);
});

test('document authorization isolates clinics and clinical capability',async()=>{
  await asUser(doctorA);
  const patient=await newPatient();
  const clinicalId=randomUUID();
  await beginAttachment({id:clinicalId,patient:patient.id,clinical:true});
  await asUser(assistantA);
  await assert.rejects(beginAttachment({patient:patient.id,clinical:true}),e=>e.code==='42501');
  const nonClinical=await beginAttachment({patient:patient.id,clinical:false,fileName:'fictional-consent.pdf',category:'Consent'});
  assert.equal(nonClinical.clinical,false);
  await assert.rejects(db.query(`insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('clinic-documents',$1,$2,$3::jsonb)`,
    [`${clinicB}/${patient.id}/${nonClinical.id}`,assistantA,JSON.stringify({size:321})]),e=>e.code==='42501');
  await asUser(doctorB);
  await assert.rejects(beginAttachment({clinic:clinicA,patient:patient.id}),e=>e.code==='42501');
  await assert.rejects(db.query("select public.clinic_authorize_attachment_access($1,'download')",[clinicalId]),e=>e.code==='42501');
  await asUser(null,'anon');
  await assert.rejects(db.query(`select public.clinic_begin_attachment(
    $1,$2,$3,null,'x.pdf','application/pdf','Other','',1,false,$4)`,
    [randomUUID(),clinicA,patient.id,attachmentHash]),e=>e.code==='42501');
  await assert.rejects(db.query("select public.clinic_authorize_attachment_access($1,'preview')",[clinicalId]),e=>e.code==='42501');
});

test('document staging is idempotent and validates identity, type, size, name and digest',async()=>{
  await asUser(doctorA);
  const patient=await newPatient();
  const id=randomUUID();
  const first=await beginAttachment({id,patient:patient.id,clinical:true});
  assert.deepEqual(await beginAttachment({id,patient:patient.id,clinical:true}),first);
  await assert.rejects(beginAttachment({id,patient:patient.id,clinical:true,fileName:'changed.pdf'}),/ATTACHMENT_ID_REUSED/);
  for (const invalid of [
    {fileName:'../escape.pdf'},
    {contentType:'text/html'},
    {category:'Executable'},
    {bytes:0},
    {bytes:20971521},
    {sha256:'00'},
  ]) await assert.rejects(beginAttachment({patient:patient.id,clinical:true,...invalid}),/INVALID_ATTACHMENT/);
  await assert.rejects(beginAttachment({patient:patient.id,visit:randomUUID(),clinical:true}),e=>e.code==='42501');
  await assert.rejects(db.query('select public.clinic_finalize_attachment($1)',[id]),/ATTACHMENT_OBJECT_MISSING/);
  await db.query('select public.clinic_fail_attachment($1)',[id]);
  assert.equal((await db.query('select state from public.attachments where id=$1',[id])).rows[0].state,'failed');
  const retried=await beginAttachment({id,patient:patient.id,clinical:true});
  assert.equal(retried.state,'pending');
  await db.query(`insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('clinic-documents',$1,$2,$3::jsonb)`,
    [first.object_path,doctorA,JSON.stringify({size:999})]);
  await assert.rejects(db.query('select public.clinic_finalize_attachment($1)',[id]),/ATTACHMENT_SIZE_MISMATCH/);
  await assert.rejects(db.query("update public.attachments set object_path='tampered' where id=$1",[id]),e=>e.code==='42501');
});

test('archiving immediately revokes document reads and restoration requires the retained object',async()=>{
  await asUser(assistantA);
  const patient=await newPatient();
  const attachment=await beginAttachment({patient:patient.id,clinical:false,bytes:77});
  await db.query(`insert into storage.objects(bucket_id,name,owner_id,metadata)
    values('clinic-documents',$1,$2,$3::jsonb)`,
    [attachment.object_path,assistantA,JSON.stringify({size:77})]);
  await db.query('select public.clinic_finalize_attachment($1)',[attachment.id]);
  await db.query("select public.clinic_authorize_attachment_access($1,'preview')",[attachment.id]);
  assert.equal((await db.query('select count(*)::int as n from storage.objects where name=$1',[attachment.object_path])).rows[0].n,1);
  const archived=(await db.query('select public.clinic_set_attachment_archived($1,true) as value',[attachment.id])).rows[0].value;
  assert.equal(archived.state,'archived');
  assert.equal((await db.query('select count(*)::int as n from storage.objects where name=$1',[attachment.object_path])).rows[0].n,0);
  await assert.rejects(db.query("select public.clinic_authorize_attachment_access($1,'preview')",[attachment.id]),e=>e.code==='42501');
  await db.exec('reset role');
  assert.equal((await db.query('select count(*)::int as n from clinic_private.attachment_access_grants where attachment_id=$1',[attachment.id])).rows[0].n,0);
  await asUser(assistantA);
  const restored=(await db.query('select public.clinic_set_attachment_archived($1,false) as value',[attachment.id])).rows[0].value;
  assert.equal(restored.state,'ready');
  await db.exec('reset role');
  assert.equal((await db.query('select count(*)::int as n from storage.objects where name=$1',[attachment.object_path])).rows[0].n,1,
    'the application has no object delete policy');
});

