-- Corrections to deployed behaviour. Deployed migrations stay immutable, so
-- each change is re-declared here.
--
-- 1. Only the visit's own doctor may amend it. The deployed amendment checked
--    the clinic role only, so any active doctor could amend any completed
--    visit while the documentation promised otherwise.
-- 2. A patient sent to the doctor could never leave that state except by
--    completing a visit with a diagnosis, so a mis-sent patient or a walkout
--    blocked that doctor's queue permanently.
-- 3. An accepted 'send' must replay its stored receipt before the freshness
--    and presence checks, otherwise retrying a committed handoff reports a
--    failure for work the server already did.
-- 4. Saving an empty working-period list silently closed the clinic to all
--    booking, and there was no way back to the unconfigured state.
-- 5. Expired presence leases and document access grants accumulated forever.

-- 1 ---------------------------------------------------------------------
-- Re-declare the amendment with an assigned-doctor check. The untouched body
-- is taken from the deployed definition rather than retyped, so only the
-- intended predicate changes.
do $$
declare source text; updated text;
begin
  source = pg_get_functiondef(
    'clinic_private.apply_visit_amendment(uuid,uuid,uuid,jsonb,integer)'::regprocedure);
  if position('AMENDMENT_NOT_ASSIGNED_DOCTOR' in source) > 0 then return; end if;
  updated = replace(
    source,
    'if not v_visit.completed then raise exception ''VISIT_NOT_COMPLETED''; end if;',
    'if not v_visit.completed then raise exception ''VISIT_NOT_COMPLETED''; end if;'
    || E'\n  if v_visit.doctor_id <> auth.uid() then'
    || E'\n    raise exception ''AMENDMENT_NOT_ASSIGNED_DOCTOR'' using errcode=''42501'';'
    || E'\n  end if;');
  if updated = source
     or position('AMENDMENT_NOT_ASSIGNED_DOCTOR' in updated) = 0 then
    raise exception 'Unexpected visit amendment definition';
  end if;
  execute updated;
end $$;

-- 2 ---------------------------------------------------------------------
-- Allow a doctor's active patient to be returned to the queue or cancelled.
-- Completion still runs through the visit command, so this adds no route to
-- a completed appointment without a diagnosis.
do $$
declare source text; updated text;
begin
  source = pg_get_functiondef(
    'clinic_private.apply_command(uuid,uuid,text,uuid,text,jsonb,integer)'::regprocedure);
  if position('withDoctor'' and v_status in (''waiting'',''cancelled'')' in source) > 0 then return; end if;
  updated = replace(
    source,
    'or (v_appointment.status=''waiting'' and v_status=''cancelled'')',
    'or (v_appointment.status=''waiting'' and v_status=''cancelled'')'
    || E'\n        or (v_appointment.status=''withDoctor'' and v_status in (''waiting'',''cancelled'') and p_action=''status'')');
  if updated = source
     or position('withDoctor'' and v_status in (''waiting'',''cancelled'')' in updated) = 0 then
    raise exception 'Unexpected appointment transition definition';
  end if;
  execute updated;
end $$;

-- 3 ---------------------------------------------------------------------
-- operation_receipts is private and unreadable by an invoker wrapper, so the
-- replay probe needs its own definer function.
create function clinic_private.command_receipt_exists(
  p_clinic_id uuid,
  p_operation_id uuid
) returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1 from clinic_private.operation_receipts
    where clinic_id=p_clinic_id and actor_id=auth.uid()
      and operation_id=p_operation_id)
$$;

create or replace function public.clinic_apply_command(
  p_clinic_id uuid,p_operation_id uuid,p_entity_type text,p_entity_id uuid,
  p_action text,p_payload jsonb,p_expected_version integer
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
begin
  if p_entity_type='appointment' and p_action='send'
     -- An already-accepted request replays its stored receipt unchanged.
     -- Checking freshness or presence first would reject a retry of a handoff
     -- the server already committed, which is exactly what the receipt model
     -- exists to prevent.
     and not clinic_private.command_receipt_exists(p_clinic_id,p_operation_id) then
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

-- 4 ---------------------------------------------------------------------
-- Reject an empty working-period list and provide the missing way back to the
-- unconfigured state.
create or replace function clinic_private.schedule(
  p_clinic_id uuid,p_doctor_id uuid,p_action text,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare periods jsonb; item jsonb; v_id uuid; result jsonb;
begin
 if auth.uid() is null or not clinic_private.allowed(p_clinic_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if not exists(select 1 from public.clinic_memberships where clinic_id=p_clinic_id and user_id=p_doctor_id and active and role='doctor') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' then raise exception 'INVALID_SCHEDULE'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text,2));
 if p_action='settings' then
   if not clinic_private.allowed(p_clinic_id,'admin') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
   periods=p_payload->'periods';
   if periods is null or jsonb_typeof(periods)<>'array' or jsonb_array_length(periods)>28 then raise exception 'INVALID_SCHEDULE'; end if;
   -- An empty list is configured-but-never-open, which refuses every booking.
   -- Clearing the schedule is 'settings_clear', which is explicit.
   if jsonb_array_length(periods)=0 then raise exception 'EMPTY_SCHEDULE'; end if;
   for item in select value from jsonb_array_elements(periods) loop
     if jsonb_typeof(item)<>'object' or not (item ?& array['weekday','start','end']) or
       jsonb_typeof(item->'weekday')<>'number' or jsonb_typeof(item->'start')<>'number' or jsonb_typeof(item->'end')<>'number' or
       (item->>'weekday')::integer not between 1 and 7 or (item->>'start')::integer not between 0 and 1439 or
       (item->>'end')::integer not between 1 and 1440 or (item->>'start')::integer >= (item->>'end')::integer then raise exception 'INVALID_SCHEDULE'; end if;
   end loop;
   if exists(select 1 from jsonb_array_elements(periods) with ordinality a(p,i),jsonb_array_elements(periods) with ordinality b(p,i)
     where a.i<b.i and a.p->>'weekday'=b.p->>'weekday' and (a.p->>'start')::int<(b.p->>'end')::int and (b.p->>'start')::int<(a.p->>'end')::int) then raise exception 'INVALID_SCHEDULE'; end if;
   insert into clinic_private.schedule_settings values(p_clinic_id,p_doctor_id,periods) on conflict(clinic_id,doctor_id) do update set periods=excluded.periods;
 elsif p_action='settings_clear' then
   if not clinic_private.allowed(p_clinic_id,'admin') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
   delete from clinic_private.schedule_settings where clinic_id=p_clinic_id and doctor_id=p_doctor_id;
 elsif p_action='waitlist_add' then
   v_id=(p_payload->>'patient_id')::uuid;
   if not exists(select 1 from public.patients where clinic_id=p_clinic_id and id=v_id and not archived) then raise exception 'INVALID_PATIENT'; end if;
   insert into clinic_private.scheduling_waitlist(clinic_id,doctor_id,patient_id,notes) values(p_clinic_id,p_doctor_id,v_id,coalesce(p_payload->>'notes',''))
     on conflict(clinic_id,doctor_id,patient_id) do update set notes=excluded.notes;
 elsif p_action='waitlist_remove' then
   delete from clinic_private.scheduling_waitlist where clinic_id=p_clinic_id and doctor_id=p_doctor_id and id=(p_payload->>'id')::uuid;
 elsif p_action<>'read' then raise exception 'INVALID_SCHEDULE'; end if;
 if p_action<>'read' then
   insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id)
     select p_clinic_id,auth.uid(),role,'schedule.'||p_action,'schedule',p_doctor_id from public.clinic_memberships where clinic_id=p_clinic_id and user_id=auth.uid();
 end if;
 select jsonb_build_object('configured',true,'periods',s.periods) into result from clinic_private.schedule_settings s where clinic_id=p_clinic_id and doctor_id=p_doctor_id;
 return jsonb_build_object('settings',coalesce(result,'{"configured":false,"periods":[]}'::jsonb),
   'waitlist',coalesce((select jsonb_agg(to_jsonb(w) order by w.created_at,w.id) from clinic_private.scheduling_waitlist w where w.clinic_id=p_clinic_id and w.doctor_id=p_doctor_id),'[]'::jsonb));
end $$;

-- 5 ---------------------------------------------------------------------
-- Bounded housekeeping on the paths that create these rows, so no scheduler is
-- required. Presence rows an immutable receipt still references are retained,
-- otherwise the receipt's foreign key would break.
create function clinic_private.prune_delivery_presence() returns void
language sql security definer set search_path='' as $$
  delete from clinic_private.doctor_device_presence p
  where p.expires_at < clock_timestamp() - interval '7 days'
    and not exists(
      select 1 from clinic_private.appointment_receipts r
      where (r.clinic_id,r.doctor_id,r.device_id)=(p.clinic_id,p.doctor_id,p.device_id))
$$;

create function clinic_private.prune_attachment_grants() returns void
language sql security definer set search_path='' as $$
  delete from clinic_private.attachment_access_grants
  where expires_at < clock_timestamp() - interval '1 day'
$$;

do $$
declare source text; updated text;
begin
  source = pg_get_functiondef('clinic_private.clinic_doctor_heartbeat(uuid,uuid)'::regprocedure);
  if position('prune_delivery_presence' in source) > 0 then return; end if;
  updated = replace(
    source,
    '  v_expires=v_now+interval ''60 seconds'';',
    '  perform clinic_private.prune_delivery_presence();'
    || E'\n  v_expires=v_now+interval ''60 seconds'';');
  if updated = source then raise exception 'Unexpected heartbeat definition'; end if;
  execute updated;
end $$;

do $$
declare source text; updated text;
begin
  source = pg_get_functiondef('clinic_private.authorize_attachment_access(uuid,text)'::regprocedure);
  if position('prune_attachment_grants' in source) > 0 then return; end if;
  updated = replace(
    source,
    '  v_expiry=clock_timestamp()+interval ''90 seconds'';',
    '  perform clinic_private.prune_attachment_grants();'
    || E'\n  v_expiry=clock_timestamp()+interval ''90 seconds'';');
  if updated = source then raise exception 'Unexpected attachment authorization definition'; end if;
  execute updated;
end $$;

-- Privileges -------------------------------------------------------------
revoke all on function
  clinic_private.command_receipt_exists(uuid,uuid),
  clinic_private.prune_delivery_presence(),
  clinic_private.prune_attachment_grants()
  from public,anon,authenticated;
grant execute on function clinic_private.command_receipt_exists(uuid,uuid)
  to authenticated;

revoke all on function clinic_private.schedule(uuid,uuid,text,jsonb),
  public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer) from public,anon;
grant execute on function clinic_private.schedule(uuid,uuid,text,jsonb),
  public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer) to authenticated;
