-- Keep privileged presence/receipt implementations outside the exposed API
-- schema. Public RPCs are narrow invoker wrappers and the private tables stay
-- inaccessible to signed-in clients.
alter function public.clinic_doctor_heartbeat(uuid,uuid)
  set schema clinic_private;
alter function public.clinic_doctor_delivery_state(uuid,uuid,uuid)
  set schema clinic_private;
alter function public.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer)
  set schema clinic_private;

create function public.clinic_doctor_heartbeat(
  p_clinic_id uuid,
  p_device_id uuid
) returns jsonb
language sql
volatile
security invoker
set search_path=''
as $$
  select clinic_private.clinic_doctor_heartbeat(p_clinic_id,p_device_id)
$$;

create function public.clinic_doctor_delivery_state(
  p_clinic_id uuid,
  p_doctor_id uuid,
  p_appointment_id uuid default null
) returns jsonb
language sql
volatile
security invoker
set search_path=''
as $$
  select clinic_private.clinic_doctor_delivery_state(
    p_clinic_id,p_doctor_id,p_appointment_id
  )
$$;

create function public.clinic_acknowledge_appointment(
  p_clinic_id uuid,
  p_appointment_id uuid,
  p_device_id uuid,
  p_operation_id uuid,
  p_expected_version integer
) returns jsonb
language sql
volatile
security invoker
set search_path=''
as $$
  select clinic_private.clinic_acknowledge_appointment(
    p_clinic_id,p_appointment_id,p_device_id,p_operation_id,p_expected_version
  )
$$;

create index appointment_receipt_presence_fk_idx
  on clinic_private.appointment_receipts(clinic_id,doctor_id,device_id);

revoke all on function
  clinic_private.clinic_doctor_heartbeat(uuid,uuid),
  clinic_private.clinic_doctor_delivery_state(uuid,uuid,uuid),
  clinic_private.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer),
  public.clinic_doctor_heartbeat(uuid,uuid),
  public.clinic_doctor_delivery_state(uuid,uuid,uuid),
  public.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer)
  from public,anon;

grant execute on function
  clinic_private.clinic_doctor_heartbeat(uuid,uuid),
  clinic_private.clinic_doctor_delivery_state(uuid,uuid,uuid),
  clinic_private.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer),
  public.clinic_doctor_heartbeat(uuid,uuid),
  public.clinic_doctor_delivery_state(uuid,uuid,uuid),
  public.clinic_acknowledge_appointment(uuid,uuid,uuid,uuid,integer)
  to authenticated;
