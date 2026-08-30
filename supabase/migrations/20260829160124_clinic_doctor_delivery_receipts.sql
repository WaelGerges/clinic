-- A server-confirmed queue assignment is not proof that a Doctor device saw it.
-- Doctor devices publish short presence leases and explicitly acknowledge the
-- assigned appointment. Receipts are immutable and retained after completion.
create table clinic_private.doctor_device_presence (
  clinic_id uuid not null,
  doctor_id uuid not null,
  device_id uuid not null,
  last_seen_at timestamptz not null,
  expires_at timestamptz not null,
  primary key(clinic_id,doctor_id,device_id),
  foreign key(clinic_id,doctor_id)
    references public.clinic_memberships(clinic_id,user_id),
  check(expires_at>last_seen_at)
);
create index doctor_presence_expiry_idx
  on clinic_private.doctor_device_presence(clinic_id,doctor_id,expires_at desc);

create table clinic_private.appointment_receipts (
  clinic_id uuid not null,
  appointment_id uuid not null,
  doctor_id uuid not null,
  device_id uuid not null,
  operation_id uuid not null,
  appointment_version integer not null check(appointment_version>0),
  acknowledged_at timestamptz not null,
  primary key(clinic_id,appointment_id),
  unique(clinic_id,doctor_id,operation_id),
  foreign key(clinic_id,appointment_id)
    references public.appointments(clinic_id,id),
  foreign key(clinic_id,doctor_id,device_id)
    references clinic_private.doctor_device_presence(clinic_id,doctor_id,device_id)
);
create index appointment_receipt_doctor_time_idx
  on clinic_private.appointment_receipts(clinic_id,doctor_id,acknowledged_at desc);
create trigger immutable_appointment_receipts
  before update or delete on clinic_private.appointment_receipts
  for each row execute function clinic_private.immutable();

alter table clinic_private.doctor_device_presence enable row level security;
alter table clinic_private.appointment_receipts enable row level security;

create function public.clinic_doctor_heartbeat(
  p_clinic_id uuid,
  p_device_id uuid
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_now timestamptz:=clock_timestamp();
  v_expires timestamptz;
begin
  if auth.uid() is null or p_clinic_id is null or p_device_id is null or not exists(
    select 1 from public.clinic_memberships m
    join public.clinics c on c.id=m.clinic_id
    where m.clinic_id=p_clinic_id and m.user_id=auth.uid()
      and m.active and m.role='doctor' and not c.archived
  ) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  v_expires=v_now+interval '60 seconds';
  insert into clinic_private.doctor_device_presence(
    clinic_id,doctor_id,device_id,last_seen_at,expires_at
  ) values(p_clinic_id,auth.uid(),p_device_id,v_now,v_expires)
  on conflict(clinic_id,doctor_id,device_id) do update
    set last_seen_at=excluded.last_seen_at,expires_at=excluded.expires_at;
  return jsonb_build_object(
    'server_now',v_now,
    'doctor_online',true,
    'presence_expires_at',v_expires,
    'acknowledged_at',null,
    'appointment_version',null
  );
end $$;

create function clinic_private.require_doctor_presence(
  p_clinic_id uuid,
  p_appointment_id uuid
) returns void
language plpgsql
security definer
set search_path=''
as $$
declare
  v_doctor uuid;
  v_status text;
begin
  if auth.uid() is null or not clinic_private.allowed(p_clinic_id) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  select doctor_id,status into v_doctor,v_status
  from public.appointments
  where clinic_id=p_clinic_id and id=p_appointment_id;
  if v_doctor is null then return; end if;
  if v_status<>'waiting' then return; end if;
  if not exists(
    select 1 from public.clinic_memberships
    where clinic_id=p_clinic_id and user_id=v_doctor
      and active and role='doctor'
  ) then raise exception 'INVALID_DOCTOR'; end if;
  if not exists(
    select 1 from clinic_private.doctor_device_presence p
    where p.clinic_id=p_clinic_id and p.doctor_id=v_doctor
      and p.expires_at>clock_timestamp()
  ) then
    raise exception 'DOCTOR_OFFLINE';
  end if;
end $$;

create function public.clinic_doctor_delivery_state(
  p_clinic_id uuid,
  p_doctor_id uuid,
  p_appointment_id uuid default null
) returns jsonb
language plpgsql
volatile
security definer
set search_path=''
as $$
declare
  v_now timestamptz:=clock_timestamp();
  v_expires timestamptz;
  v_receipt clinic_private.appointment_receipts%rowtype;
begin
  if auth.uid() is null or not clinic_private.allowed(p_clinic_id) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  if not exists(
    select 1 from public.clinic_memberships
    where clinic_id=p_clinic_id and user_id=p_doctor_id
      and active and role='doctor'
  ) then raise exception 'INVALID_DOCTOR'; end if;
  if p_appointment_id is not null and not exists(
    select 1 from public.appointments
    where clinic_id=p_clinic_id and id=p_appointment_id
      and doctor_id=p_doctor_id
  ) then raise exception 'NOT_FOUND'; end if;
  select max(expires_at) into v_expires
  from clinic_private.doctor_device_presence
  where clinic_id=p_clinic_id and doctor_id=p_doctor_id;
  if p_appointment_id is not null then
    select * into v_receipt
    from clinic_private.appointment_receipts
    where clinic_id=p_clinic_id and appointment_id=p_appointment_id;
  end if;
  return jsonb_build_object(
    'server_now',v_now,
    'doctor_online',coalesce(v_expires>v_now,false),
    'presence_expires_at',v_expires,
    'acknowledged_at',v_receipt.acknowledged_at,
    'appointment_version',v_receipt.appointment_version
  );
end $$;

create function public.clinic_acknowledge_appointment(
  p_clinic_id uuid,
  p_appointment_id uuid,
  p_device_id uuid,
  p_operation_id uuid,
  p_expected_version integer
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_now timestamptz:=clock_timestamp();
  v_appointment public.appointments%rowtype;
  v_receipt clinic_private.appointment_receipts%rowtype;
  v_expires timestamptz;
begin
  if auth.uid() is null or p_device_id is null or p_operation_id is null
     or p_expected_version is null or p_expected_version<1 or not exists(
    select 1 from public.clinic_memberships m
    join public.clinics c on c.id=m.clinic_id
    where m.clinic_id=p_clinic_id and m.user_id=auth.uid()
      and m.active and m.role='doctor' and not c.archived
  ) then raise exception 'FORBIDDEN' using errcode='42501'; end if;

  perform pg_advisory_xact_lock(
    hashtextextended(p_clinic_id::text||auth.uid()::text||p_operation_id::text,3)
  );
  select * into v_receipt
  from clinic_private.appointment_receipts
  where clinic_id=p_clinic_id and doctor_id=auth.uid()
    and operation_id=p_operation_id;
  if found then
    if v_receipt.appointment_id<>p_appointment_id then
      raise exception 'OPERATION_ID_REUSED';
    end if;
    select expires_at into v_expires
    from clinic_private.doctor_device_presence
    where (clinic_id,doctor_id,device_id)=(p_clinic_id,auth.uid(),v_receipt.device_id);
    return jsonb_build_object(
      'server_now',v_now,'doctor_online',coalesce(v_expires>v_now,false),
      'presence_expires_at',v_expires,
      'acknowledged_at',v_receipt.acknowledged_at,
      'appointment_version',v_receipt.appointment_version
    );
  end if;

  select * into v_appointment
  from public.appointments
  where clinic_id=p_clinic_id and id=p_appointment_id
  for update;
  if v_appointment.id is null or v_appointment.doctor_id<>auth.uid() then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  select * into v_receipt
  from clinic_private.appointment_receipts
  where clinic_id=p_clinic_id and appointment_id=p_appointment_id;
  if found then
    select expires_at into v_expires
    from clinic_private.doctor_device_presence
    where (clinic_id,doctor_id,device_id)=(p_clinic_id,auth.uid(),v_receipt.device_id);
    return jsonb_build_object(
      'server_now',v_now,'doctor_online',coalesce(v_expires>v_now,false),
      'presence_expires_at',v_expires,
      'acknowledged_at',v_receipt.acknowledged_at,
      'appointment_version',v_receipt.appointment_version
    );
  end if;
  if v_appointment.status<>'withDoctor' then raise exception 'ASSIGNMENT_CHANGED'; end if;
  if v_appointment.version<>p_expected_version then
    raise exception 'VERSION_CONFLICT' using detail=to_jsonb(v_appointment)::text;
  end if;
  select expires_at into v_expires
  from clinic_private.doctor_device_presence
  where (clinic_id,doctor_id,device_id)=(p_clinic_id,auth.uid(),p_device_id)
    and expires_at>v_now;
  if v_expires is null then raise exception 'DOCTOR_DEVICE_OFFLINE'; end if;

  insert into clinic_private.appointment_receipts(
    clinic_id,appointment_id,doctor_id,device_id,operation_id,
    appointment_version,acknowledged_at
  ) values(
    p_clinic_id,p_appointment_id,auth.uid(),p_device_id,p_operation_id,
    v_appointment.version,v_now
  ) returning * into v_receipt;
  insert into public.audit_events(
    clinic_id,actor_id,actor_role,action,object_type,object_id,new_value
  ) values(
    p_clinic_id,auth.uid(),'doctor','appointment.received','appointment',
    p_appointment_id,jsonb_build_object(
      'appointment_version',v_receipt.appointment_version,
      'acknowledged_at',v_receipt.acknowledged_at
    )
  );
  return jsonb_build_object(
    'server_now',v_now,'doctor_online',true,
    'presence_expires_at',v_expires,
    'acknowledged_at',v_receipt.acknowledged_at,
    'appointment_version',v_receipt.appointment_version
  );
end $$;

create or replace function public.clinic_apply_command(
  p_clinic_id uuid,p_operation_id uuid,p_entity_type text,p_entity_id uuid,
  p_action text,p_payload jsonb,p_expected_version integer
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
begin
  if p_entity_type='appointment' and p_action='send' then
    if p_payload->>'_expires_at' is null
       or (p_payload->>'_expires_at')::timestamptz<=clock_timestamp()
       or (p_payload->>'_expires_at')::timestamptz>clock_timestamp()+interval '2 minutes' then
      raise exception 'COMMAND_EXPIRED';
    end if;
    perform clinic_private.require_doctor_presence(p_clinic_id,p_entity_id);
  end if;
  if p_entity_type='visit' and p_action='amend' then
    return clinic_private.apply_visit_amendment(
      p_clinic_id,p_operation_id,p_entity_id,p_payload,p_expected_version
    );
  end if;
  return clinic_private.apply_command(
    p_clinic_id,p_operation_id,p_entity_type,p_entity_id,p_action,p_payload,p_expected_version
  );
end $$;

revoke all on clinic_private.doctor_device_presence,
  clinic_private.appointment_receipts from public,anon,authenticated;
revoke all on function clinic_private.require_doctor_presence(uuid,uuid),
  public.clinic_doctor_heartbeat(uuid,uuid),
  public.clinic_doctor_delivery_state(uuid,uuid,uuid),
  public.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer),
  public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer)
  from public,anon;
grant execute on function clinic_private.require_doctor_presence(uuid,uuid),
  public.clinic_doctor_heartbeat(uuid,uuid),
  public.clinic_doctor_delivery_state(uuid,uuid,uuid),
  public.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer),
  public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer)
  to authenticated;
