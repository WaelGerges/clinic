-- Development foundation. Apply only to geikkygtnsgbtajyqdvc after review.
-- The mobile apps receive a publishable key, never privileged database credentials.
create schema if not exists clinic_private;
revoke all on schema clinic_private from public;
grant usage on schema clinic_private to authenticated;

create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 2 and 160),
  time_zone text not null default 'Africa/Cairo' check (time_zone = 'Africa/Cairo'),
  created_at timestamptz not null default now(),
  archived boolean not null default false
);
create table public.clinic_memberships (
  clinic_id uuid not null references public.clinics(id),
  user_id uuid not null references auth.users(id),
  role text not null check (role in ('doctor','assistant')),
  is_admin boolean not null default false,
  clinical_read boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key(clinic_id,user_id),
  check (not is_admin or role='doctor')
);
create index memberships_user_idx on public.clinic_memberships(user_id,active,clinic_id);

create function clinic_private.allowed(p_clinic uuid, p_capability text default 'read')
returns boolean language plpgsql stable security definer set search_path='' as $$
begin
  if auth.uid() is null then return false; end if;
  return exists(select 1 from public.clinic_memberships m
    join public.clinics c on c.id=m.clinic_id
    where m.clinic_id=p_clinic and m.user_id=auth.uid() and m.active and not c.archived
    and case p_capability when 'read' then true
      when 'clinical_read' then m.role='doctor' or m.clinical_read
      when 'clinical_write' then m.role='doctor'
      when 'admin' then m.is_admin else false end);
end $$;

create table public.patients (
  id uuid primary key,
  clinic_id uuid not null references public.clinics(id),
  patient_number bigint not null,
  full_name text not null check(length(btrim(full_name)) between 2 and 300),
  gender text not null check(gender in ('Female','Male','Other','Not specified')),
  birth_date date not null check(birth_date between date '1800-01-01' and current_date),
  mobile text not null check(length(regexp_replace(mobile,'[^0-9]','','g')) between 7 and 20),
  secondary_mobile text not null default '',
  address text not null default '',
  notes text not null default '',
  alerts text not null default '',
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1 check(version>0),
  unique(clinic_id,id), unique(clinic_id,patient_number)
);
create index patient_clinic_name_idx on public.patients(clinic_id,archived,lower(full_name),id);
create index patient_change_idx on public.patients(clinic_id,updated_at,id);
create index patient_phone_idx on public.patients(clinic_id,(regexp_replace(mobile,'[^0-9]','','g')));

create table clinic_private.patient_counters (
  clinic_id uuid primary key references public.clinics(id),
  last_number bigint not null check(last_number>0)
);
alter table clinic_private.patient_counters enable row level security;

create table public.appointments (
  id uuid primary key,
  clinic_id uuid not null references public.clinics(id),
  patient_id uuid not null,
  doctor_id uuid not null,
  starts_at timestamptz not null,
  status text not null default 'scheduled' check(status in
    ('scheduled','confirmed','arrived','waiting','withDoctor','completed','cancelled','noShow')),
  appointment_type text not null default 'Consultation',
  notes text not null default '',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1 check(version>0),
  unique(clinic_id,id), unique(clinic_id,id,patient_id,doctor_id),
  foreign key(clinic_id,patient_id) references public.patients(clinic_id,id),
  foreign key(clinic_id,doctor_id) references public.clinic_memberships(clinic_id,user_id)
);
create unique index one_active_patient_per_doctor on public.appointments(clinic_id,doctor_id)
  where status='withDoctor';
create unique index no_duplicate_waiting_patient on public.appointments(clinic_id,doctor_id,patient_id)
  where status in ('waiting','withDoctor');
create index appointment_day_idx on public.appointments(clinic_id,starts_at,id);
create index appointment_patient_idx on public.appointments(clinic_id,patient_id,starts_at desc);
create index appointment_doctor_idx on public.appointments(clinic_id,doctor_id,status);
create index appointment_creator_idx on public.appointments(created_by);

create table public.visits (
  id uuid primary key,
  clinic_id uuid not null references public.clinics(id),
  patient_id uuid not null,
  appointment_id uuid not null,
  doctor_id uuid not null,
  current_revision integer not null default 1,
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1 check(version>0),
  unique(clinic_id,id), unique(clinic_id,id,patient_id), unique(clinic_id,appointment_id),
  foreign key(clinic_id,patient_id) references public.patients(clinic_id,id),
  foreign key(clinic_id,appointment_id,patient_id,doctor_id)
    references public.appointments(clinic_id,id,patient_id,doctor_id)
);
create index visit_timeline_idx on public.visits(clinic_id,patient_id,created_at desc,id);
create index visit_doctor_idx on public.visits(clinic_id,doctor_id);

create table public.visit_revisions (
  clinic_id uuid not null,
  visit_id uuid not null,
  revision integer not null check(revision>0),
  notes text not null default '',
  follow_up text not null default '',
  amendment_reason text not null default '',
  authored_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  primary key(clinic_id,visit_id,revision),
  foreign key(clinic_id,visit_id) references public.visits(clinic_id,id)
);
alter table public.visits add constraint current_revision_exists
  foreign key(clinic_id,id,current_revision) references public.visit_revisions(clinic_id,visit_id,revision)
  deferrable initially deferred;
create index revision_author_idx on public.visit_revisions(authored_by);

create table public.diagnoses (
  clinic_id uuid not null,
  visit_id uuid not null,
  revision integer not null,
  position integer not null check(position>=0),
  description text not null check(length(btrim(description))>0),
  code_system text,
  code text,
  primary key(clinic_id,visit_id,revision,position),
  foreign key(clinic_id,visit_id,revision) references public.visit_revisions(clinic_id,visit_id,revision)
);
create table public.prescriptions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null,
  visit_id uuid not null,
  revision integer not null,
  created_at timestamptz not null default now(),
  unique(clinic_id,id), unique(clinic_id,visit_id,revision),
  foreign key(clinic_id,visit_id,revision) references public.visit_revisions(clinic_id,visit_id,revision)
);
create table public.prescription_items (
  clinic_id uuid not null,
  prescription_id uuid not null,
  id uuid not null,
  position integer not null check(position>=0),
  name text not null check(length(btrim(name))>0),
  strength text not null default '', dose text not null default '',
  frequency text not null default '', duration text not null default '',
  instructions text not null default '', notes text not null default '',
  primary key(clinic_id,prescription_id,id),
  unique(clinic_id,prescription_id,position),
  foreign key(clinic_id,prescription_id) references public.prescriptions(clinic_id,id)
);

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null,
  patient_id uuid not null,
  visit_id uuid,
  file_name text not null,
  content_type text not null,
  category text not null default 'Other',
  notes text not null default '',
  object_path text not null unique,
  bytes bigint not null check(bytes>0),
  clinical boolean not null default true,
  state text not null default 'pending' check(state in ('pending','ready','failed','archived')),
  uploaded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  unique(clinic_id,id),
  foreign key(clinic_id,patient_id) references public.patients(clinic_id,id),
  foreign key(clinic_id,visit_id,patient_id) references public.visits(clinic_id,id,patient_id)
);
create index attachment_patient_idx on public.attachments(clinic_id,patient_id,created_at desc,id);
create index attachment_visit_idx on public.attachments(clinic_id,visit_id);
create index attachment_uploader_idx on public.attachments(uploaded_by);

create table clinic_private.operation_receipts (
  clinic_id uuid not null references public.clinics(id),
  actor_id uuid not null references auth.users(id),
  operation_id uuid not null,
  request jsonb not null,
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key(clinic_id,actor_id,operation_id)
);
create index receipt_actor_idx on clinic_private.operation_receipts(actor_id);
create table public.audit_events (
  id bigint generated always as identity primary key,
  clinic_id uuid not null references public.clinics(id),
  actor_id uuid not null references auth.users(id),
  actor_role text not null,
  action text not null,
  object_type text not null,
  object_id uuid not null,
  previous_value jsonb,
  new_value jsonb,
  occurred_at timestamptz not null default now()
);
create index audit_clinic_time_idx on public.audit_events(clinic_id,occurred_at desc,id);
create index audit_actor_idx on public.audit_events(actor_id);

create function clinic_private.immutable() returns trigger
language plpgsql set search_path='' as $$
begin raise exception 'IMMUTABLE_HISTORY' using errcode='42501'; end $$;
create trigger immutable_revisions before update or delete on public.visit_revisions
  for each row execute function clinic_private.immutable();
create trigger immutable_diagnoses before update or delete on public.diagnoses
  for each row execute function clinic_private.immutable();
create trigger immutable_prescriptions before update or delete on public.prescriptions
  for each row execute function clinic_private.immutable();
create trigger immutable_items before update or delete on public.prescription_items
  for each row execute function clinic_private.immutable();
create trigger immutable_audit before update or delete on public.audit_events
  for each row execute function clinic_private.immutable();

alter table public.clinics enable row level security;
alter table public.clinic_memberships enable row level security;
alter table public.patients enable row level security;
alter table public.appointments enable row level security;
alter table public.visits enable row level security;
alter table public.visit_revisions enable row level security;
alter table public.diagnoses enable row level security;
alter table public.prescriptions enable row level security;
alter table public.prescription_items enable row level security;
alter table public.attachments enable row level security;
alter table public.audit_events enable row level security;
alter table clinic_private.operation_receipts enable row level security;

create policy clinic_read on public.clinics for select to authenticated
  using(clinic_private.allowed(id));
create policy membership_read on public.clinic_memberships for select to authenticated
  using(clinic_private.allowed(clinic_id) and (user_id=auth.uid() or clinic_private.allowed(clinic_id,'admin') or role='doctor'));
create policy patient_read on public.patients for select to authenticated using(clinic_private.allowed(clinic_id));
create policy appointment_read on public.appointments for select to authenticated using(clinic_private.allowed(clinic_id));
create policy visit_read on public.visits for select to authenticated using(clinic_private.allowed(clinic_id,'clinical_read'));
create policy revision_read on public.visit_revisions for select to authenticated using(clinic_private.allowed(clinic_id,'clinical_read'));
create policy diagnosis_read on public.diagnoses for select to authenticated using(clinic_private.allowed(clinic_id,'clinical_read'));
create policy prescription_read on public.prescriptions for select to authenticated using(clinic_private.allowed(clinic_id,'clinical_read'));
create policy medication_read on public.prescription_items for select to authenticated using(clinic_private.allowed(clinic_id,'clinical_read'));
create policy attachment_read on public.attachments for select to authenticated
  using(clinic_private.allowed(clinic_id) and (not clinical or clinic_private.allowed(clinic_id,'clinical_read')));
create policy audit_read on public.audit_events for select to authenticated using(clinic_private.allowed(clinic_id,'admin'));

create view public.visit_details with (security_invoker=true) as
  select v.*,r.notes,r.follow_up,r.amendment_reason,
    coalesce((select jsonb_agg(d.description order by d.position) from public.diagnoses d
      where (d.clinic_id,d.visit_id,d.revision)=(v.clinic_id,v.id,v.current_revision)),'[]'::jsonb) diagnoses,
    coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'name',i.name,'strength',i.strength,
      'dose',i.dose,'frequency',i.frequency,'duration',i.duration,'instructions',i.instructions,'notes',i.notes)
      order by i.position) from public.prescriptions p join public.prescription_items i
      on (i.clinic_id,i.prescription_id)=(p.clinic_id,p.id)
      where (p.clinic_id,p.visit_id,p.revision)=(v.clinic_id,v.id,v.current_revision)),'[]'::jsonb) medications
  from public.visits v join public.visit_revisions r
    on (r.clinic_id,r.visit_id,r.revision)=(v.clinic_id,v.id,v.current_revision);

create function clinic_private.create_clinic(p_name text) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  if not exists(select 1 from auth.users where id=auth.uid() and email_confirmed_at is not null) then
    raise exception 'EMAIL_VERIFICATION_REQUIRED' using errcode='42501'; end if;
  insert into public.clinics(name) values(btrim(p_name)) returning id into v_id;
  insert into public.clinic_memberships(clinic_id,user_id,role,is_admin,clinical_read)
    values(v_id,auth.uid(),'doctor',true,true);
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id)
    values(v_id,auth.uid(),'doctor','clinic.created','clinic',v_id);
  return v_id;
end $$;
create function public.clinic_create(p_name text) returns uuid
language sql security invoker set search_path='' as $$select clinic_private.create_clinic(p_name)$$;

create function clinic_private.apply_command(p_clinic_id uuid,p_operation_id uuid,
  p_entity_type text,p_entity_id uuid,p_action text,p_payload jsonb,p_expected_version integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_request jsonb; v_response jsonb; v_previous jsonb; v_entity jsonb;
  v_saved clinic_private.operation_receipts%rowtype;
  v_patient public.patients%rowtype; v_appointment public.appointments%rowtype;
  v_visit public.visits%rowtype; v_role text; v_revision integer;
  v_rx uuid; v_item jsonb; v_position integer; v_status text; v_doctor uuid; v_number bigint;
begin
  if auth.uid() is null or not clinic_private.allowed(p_clinic_id) then
    raise exception 'FORBIDDEN' using errcode='42501'; end if;
  if p_operation_id is null or p_entity_id is null or p_expected_version is null or p_expected_version<0 or
    p_payload is null or jsonb_typeof(p_payload)<>'object' then raise exception 'INVALID_COMMAND'; end if;
  select role into v_role from public.clinic_memberships where clinic_id=p_clinic_id and user_id=auth.uid();
  if p_entity_type='visit' and v_role<>'doctor' then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  v_request=jsonb_build_object('type',p_entity_type,'id',p_entity_id,'action',p_action,
    'payload',p_payload,'version',p_expected_version);
  perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text||auth.uid()::text||p_operation_id::text,0));
  -- Serialize short clinic mutations in the first release. This also closes
  -- create/update and archive/queue races. Clinics remain independent.
  perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text,2));
  select * into v_saved from clinic_private.operation_receipts
    where (clinic_id,actor_id,operation_id)=(p_clinic_id,auth.uid(),p_operation_id);
  if found then
    if v_saved.request<>v_request then raise exception 'OPERATION_ID_REUSED'; end if;
    return v_saved.response;
  end if;

  -- Critical intent must be fresh. Receipt replay above remains valid after expiry,
  -- so a lost response never causes a second handoff or completion.
  if (p_entity_type='appointment' and p_action in ('status','send')) or
     (p_entity_type='visit' and p_action='complete') then
    if p_payload->>'_expires_at' is null or
       (p_payload->>'_expires_at')::timestamptz <= clock_timestamp() or
       (p_payload->>'_expires_at')::timestamptz > clock_timestamp()+interval '2 minutes' then
      raise exception 'COMMAND_EXPIRED';
    end if;
  end if;

  if p_entity_type='patient' and p_action='save' then
    select * into v_patient from public.patients where clinic_id=p_clinic_id and id=p_entity_id for update;
    if coalesce(v_patient.version,0)<>p_expected_version then
      raise exception 'VERSION_CONFLICT' using detail=coalesce(to_jsonb(v_patient),'{}'::jsonb)::text; end if;
    v_previous=to_jsonb(v_patient);
    if v_role<>'doctor' and coalesce(p_payload->>'alerts','')<>coalesce(v_patient.alerts,'') then
      raise exception 'FORBIDDEN_ALERT_EDIT' using errcode='42501'; end if;
    if coalesce((p_payload->>'archived')::boolean,false) and exists(
      select 1 from public.appointments where clinic_id=p_clinic_id and patient_id=p_entity_id
      and status in ('waiting','withDoctor')) then raise exception 'PATIENT_ACTIVE'; end if;
    if v_patient.id is null then
      insert into clinic_private.patient_counters(clinic_id,last_number) values(p_clinic_id,1)
        on conflict(clinic_id) do update set last_number=clinic_private.patient_counters.last_number+1
        returning last_number into v_number;
    else v_number=v_patient.patient_number; end if;
    insert into public.patients(id,clinic_id,patient_number,full_name,gender,birth_date,mobile,secondary_mobile,
      address,notes,alerts,archived) values(p_entity_id,p_clinic_id,v_number,btrim(p_payload->>'full_name'),
      p_payload->>'gender',(p_payload->>'birth_date')::date,p_payload->>'mobile',
      coalesce(p_payload->>'secondary_mobile',''),coalesce(p_payload->>'address',''),
      coalesce(p_payload->>'notes',''),coalesce(p_payload->>'alerts',''),coalesce((p_payload->>'archived')::boolean,false))
    on conflict(id) do update set full_name=excluded.full_name,gender=excluded.gender,birth_date=excluded.birth_date,
      mobile=excluded.mobile,secondary_mobile=excluded.secondary_mobile,address=excluded.address,notes=excluded.notes,
      alerts=excluded.alerts,archived=excluded.archived,updated_at=now(),version=public.patients.version+1
      where public.patients.clinic_id=p_clinic_id
    returning * into v_patient;
    if not found then raise exception 'CROSS_CLINIC_ID' using errcode='42501'; end if;
    v_entity=to_jsonb(v_patient);
  elsif p_entity_type='appointment' then
    select * into v_appointment from public.appointments where clinic_id=p_clinic_id and id=p_entity_id for update;
    if coalesce(v_appointment.version,0)<>p_expected_version then
      raise exception 'VERSION_CONFLICT' using detail=coalesce(to_jsonb(v_appointment),'{}'::jsonb)::text; end if;
    v_previous=to_jsonb(v_appointment);
    if p_action='save' then
      if v_appointment.status in ('waiting','withDoctor','completed','cancelled','noShow') then
        raise exception 'APPOINTMENT_PROTECTED'; end if;
      v_doctor=(p_payload->>'doctor_id')::uuid;
      if not exists(select 1 from public.clinic_memberships where clinic_id=p_clinic_id and user_id=v_doctor
        and active and role='doctor') then raise exception 'INVALID_DOCTOR'; end if;
      if not exists(select 1 from public.patients where clinic_id=p_clinic_id and id=(p_payload->>'patient_id')::uuid
        and not archived) then raise exception 'INVALID_PATIENT'; end if;
      insert into public.appointments(id,clinic_id,patient_id,doctor_id,starts_at,appointment_type,notes,created_by)
      values(p_entity_id,p_clinic_id,(p_payload->>'patient_id')::uuid,v_doctor,(p_payload->>'starts_at')::timestamptz,
        coalesce(p_payload->>'appointment_type','Consultation'),coalesce(p_payload->>'notes',''),auth.uid())
      on conflict(id) do update set starts_at=excluded.starts_at,appointment_type=excluded.appointment_type,
        notes=excluded.notes,updated_at=now(),version=public.appointments.version+1
        where public.appointments.clinic_id=p_clinic_id
          and public.appointments.patient_id=excluded.patient_id and public.appointments.doctor_id=excluded.doctor_id
      returning * into v_appointment;
      if not found then raise exception 'APPOINTMENT_IDENTITY_CHANGED'; end if;
    elsif p_action in ('status','send') then
      if v_appointment.id is null then raise exception 'NOT_FOUND'; end if;
      v_status=case when p_action='send' then 'withDoctor' else p_payload->>'status' end;
      if not ((v_appointment.status='scheduled' and v_status in ('confirmed','arrived','cancelled','noShow'))
        or (v_appointment.status='confirmed' and v_status in ('arrived','cancelled','noShow'))
        or (v_appointment.status='arrived' and v_status in ('waiting','cancelled'))
        or (v_appointment.status='waiting' and v_status='cancelled')
        or (v_appointment.status='waiting' and v_status='withDoctor' and p_action='send')) then
        raise exception 'INVALID_TRANSITION'; end if;
      if v_status in ('waiting','withDoctor') then
        if not exists(select 1 from public.clinic_memberships where clinic_id=p_clinic_id
          and user_id=v_appointment.doctor_id and active and role='doctor') then
          raise exception 'INVALID_DOCTOR'; end if;
        if not exists(select 1 from public.patients where clinic_id=p_clinic_id and id=v_appointment.patient_id and not archived)
          then raise exception 'PATIENT_ARCHIVED'; end if;
        if (v_appointment.starts_at at time zone 'Africa/Cairo')::date<>(now() at time zone 'Africa/Cairo')::date
          then raise exception 'NOT_TODAYS_APPOINTMENT'; end if;
      end if;
      if v_status='withDoctor' then
        perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text||v_appointment.doctor_id::text,1));
        if exists(select 1 from public.appointments where clinic_id=p_clinic_id
          and doctor_id=v_appointment.doctor_id and status='withDoctor') then raise exception 'DOCTOR_BUSY'; end if;
      end if;
      update public.appointments set status=v_status,updated_at=now(),version=version+1
        where clinic_id=p_clinic_id and id=p_entity_id returning * into v_appointment;
    else raise exception 'INVALID_ACTION'; end if;
    v_entity=to_jsonb(v_appointment);
  elsif p_entity_type='visit' then
    select * into v_visit from public.visits where clinic_id=p_clinic_id and id=p_entity_id for update;
    if coalesce(v_visit.version,0)<>p_expected_version then raise exception 'VERSION_CONFLICT'
      using detail=coalesce((select to_jsonb(d) from public.visit_details d where d.clinic_id=p_clinic_id and d.id=p_entity_id),'{}'::jsonb)::text; end if;
    v_previous=(select to_jsonb(d) from public.visit_details d where d.clinic_id=p_clinic_id and d.id=p_entity_id);
    if v_visit.completed then raise exception 'COMPLETED_VISIT_IMMUTABLE'; end if;
    if p_action='save' then
      if p_payload->>'patient_id' is null or p_payload->>'appointment_id' is null then
        raise exception 'VISIT_IDENTITY_REQUIRED'; end if;
      if v_visit.id is not null and ((p_payload->>'patient_id')::uuid<>v_visit.patient_id
        or (p_payload->>'appointment_id')::uuid<>v_visit.appointment_id) then
        raise exception 'VISIT_IDENTITY_CHANGED'; end if;
    end if;
    select * into v_appointment from public.appointments where clinic_id=p_clinic_id
      and id=coalesce(v_visit.appointment_id,(p_payload->>'appointment_id')::uuid) for update;
    if v_appointment.id is null or v_appointment.doctor_id<>auth.uid() or v_appointment.status<>'withDoctor' then
      raise exception 'ASSIGNMENT_CHANGED'; end if;
    if p_action='save' and (p_payload->>'patient_id')::uuid<>v_appointment.patient_id then
      raise exception 'VISIT_IDENTITY_CHANGED'; end if;
    if p_action='save' then
      v_revision=coalesce(v_visit.current_revision,0)+1;
      if v_visit.id is null then
        insert into public.visits(id,clinic_id,patient_id,appointment_id,doctor_id)
          values(p_entity_id,p_clinic_id,v_appointment.patient_id,v_appointment.id,auth.uid());
      else
        update public.visits set current_revision=v_revision,version=version+1,updated_at=now()
          where clinic_id=p_clinic_id and id=p_entity_id;
      end if;
      insert into public.visit_revisions(clinic_id,visit_id,revision,notes,follow_up,authored_by)
        values(p_clinic_id,p_entity_id,v_revision,coalesce(p_payload->>'notes',''),coalesce(p_payload->>'follow_up',''),auth.uid());
      v_position=0;
      for v_item in select value from jsonb_array_elements(coalesce(p_payload->'diagnoses','[]'::jsonb)) loop
        if length(btrim(v_item#>>'{}'))>0 then
          insert into public.diagnoses values(p_clinic_id,p_entity_id,v_revision,v_position,btrim(v_item#>>'{}'),null,null);
          v_position=v_position+1;
        end if;
      end loop;
      insert into public.prescriptions(clinic_id,visit_id,revision) values(p_clinic_id,p_entity_id,v_revision) returning id into v_rx;
      v_position=0;
      for v_item in select value from jsonb_array_elements(coalesce(p_payload->'medications','[]'::jsonb)) loop
        insert into public.prescription_items(clinic_id,prescription_id,id,position,name,strength,dose,frequency,duration,instructions,notes)
          values(p_clinic_id,v_rx,(v_item->>'id')::uuid,v_position,btrim(v_item->>'name'),coalesce(v_item->>'strength',''),
            coalesce(v_item->>'dose',''),coalesce(v_item->>'frequency',''),coalesce(v_item->>'duration',''),
            coalesce(v_item->>'instructions',''),coalesce(v_item->>'notes',''));
        v_position=v_position+1;
      end loop;
    elsif p_action='complete' then
      if v_visit.id is null or not exists(select 1 from public.diagnoses where clinic_id=p_clinic_id
        and visit_id=p_entity_id and revision=v_visit.current_revision) then raise exception 'DIAGNOSIS_REQUIRED'; end if;
      update public.visits set completed=true,version=version+1,updated_at=now()
        where clinic_id=p_clinic_id and id=p_entity_id;
      update public.appointments set status='completed',version=version+1,updated_at=now()
        where clinic_id=p_clinic_id and id=v_appointment.id;
      insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,previous_value,new_value)
        values(p_clinic_id,auth.uid(),v_role,'appointment.completed','appointment',v_appointment.id,
          to_jsonb(v_appointment),(select to_jsonb(a) from public.appointments a where a.id=v_appointment.id));
    else raise exception 'INVALID_ACTION'; end if;
    select to_jsonb(d) into v_entity from public.visit_details d where d.clinic_id=p_clinic_id and d.id=p_entity_id;
  else raise exception 'INVALID_ENTITY_OR_ACTION'; end if;
  v_response=jsonb_build_object('entity',v_entity,'version',(v_entity->>'version')::integer);
  if p_entity_type='visit' and p_action='complete' then
    v_response=v_response||jsonb_build_object('appointment',
      (select to_jsonb(a) from public.appointments a where a.clinic_id=p_clinic_id and a.id=v_appointment.id));
  end if;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,previous_value,new_value)
    values(p_clinic_id,auth.uid(),v_role,p_entity_type||'.'||p_action,p_entity_type,p_entity_id,v_previous,v_entity);
  insert into clinic_private.operation_receipts(clinic_id,actor_id,operation_id,request,response)
    values(p_clinic_id,auth.uid(),p_operation_id,v_request,v_response);
  return v_response;
end $$;

create function public.clinic_search_patients(p_clinic_id uuid,p_search text default '',p_offset integer default 0,p_limit integer default 50,p_archived boolean default false)
returns setof public.patients language sql stable security invoker set search_path='' as $$
  select p.* from public.patients p
  where p.clinic_id=p_clinic_id and p.archived=coalesce(p_archived,false) and (
    position(lower(btrim(coalesce(p_search,''))) in lower(p.full_name))>0
    or position(btrim(coalesce(p_search,'')) in p.patient_number::text)>0
    or p.id::text=btrim(p_search)
    or (regexp_replace(coalesce(p_search,''),'[^0-9]','','g')<>'' and
      (position(regexp_replace(p_search,'[^0-9]','','g') in regexp_replace(p.mobile,'[^0-9]','','g'))>0
       or position(regexp_replace(p_search,'[^0-9]','','g') in regexp_replace(p.secondary_mobile,'[^0-9]','','g'))>0)))
  order by lower(p.full_name),p.id limit greatest(1,least(coalesce(p_limit,50),100)) offset greatest(coalesce(p_offset,0),0)
$$;
revoke all on function public.clinic_search_patients(uuid,text,integer,integer,boolean) from public,anon;
grant execute on function public.clinic_search_patients(uuid,text,integer,integer,boolean) to authenticated;

create function public.clinic_apply_command(p_clinic_id uuid,p_operation_id uuid,
  p_entity_type text,p_entity_id uuid,p_action text,p_payload jsonb,p_expected_version integer)
returns jsonb language sql security invoker set search_path='' as $$
  select clinic_private.apply_command(p_clinic_id,p_operation_id,p_entity_type,p_entity_id,p_action,p_payload,p_expected_version)
$$;

revoke all on all tables in schema clinic_private from public,anon,authenticated;
revoke all on sequence public.audit_events_id_seq from public,anon,authenticated;
revoke all on public.clinics,public.clinic_memberships,public.patients,public.appointments,
  public.visits,public.visit_revisions,public.diagnoses,public.prescriptions,public.prescription_items,
  public.attachments,public.audit_events,public.visit_details from public,anon,authenticated;
grant select on public.clinics,public.clinic_memberships,public.patients,public.appointments,
  public.visits,public.visit_revisions,public.diagnoses,public.prescriptions,public.prescription_items,
  public.attachments,public.audit_events,public.visit_details to authenticated;
revoke all on function clinic_private.allowed(uuid,text),clinic_private.create_clinic(text),
  clinic_private.immutable(),clinic_private.apply_command(uuid,uuid,text,uuid,text,jsonb,integer),
  public.clinic_create(text),public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer) from public,anon;
grant execute on function clinic_private.allowed(uuid,text),clinic_private.create_clinic(text),
  clinic_private.apply_command(uuid,uuid,text,uuid,text,jsonb,integer),
  public.clinic_create(text),public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer) to authenticated;
