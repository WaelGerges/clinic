-- Completed clinical visits remain immutable. Amendments append a new revision,
-- retain every earlier revision, and use the same exact-operation receipt model
-- as other shared commands.
create function clinic_private.apply_visit_amendment(
  p_clinic_id uuid,
  p_operation_id uuid,
  p_entity_id uuid,
  p_payload jsonb,
  p_expected_version integer
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_request jsonb;
  v_response jsonb;
  v_previous jsonb;
  v_entity jsonb;
  v_saved clinic_private.operation_receipts%rowtype;
  v_visit public.visits%rowtype;
  v_role text;
  v_revision integer;
  v_reason text;
  v_rx uuid;
  v_item jsonb;
  v_position integer;
begin
  if auth.uid() is null or not clinic_private.allowed(p_clinic_id, 'clinical_write') then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  if p_operation_id is null or p_entity_id is null or p_expected_version is null
     or p_expected_version < 1 or p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'INVALID_AMENDMENT';
  end if;
  if pg_column_size(p_payload) > 1048576 then raise exception 'INVALID_AMENDMENT'; end if;

  select role into v_role
  from public.clinic_memberships
  where clinic_id=p_clinic_id and user_id=auth.uid() and active;
  if v_role <> 'doctor' then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;

  v_request=jsonb_build_object(
    'type','visit','id',p_entity_id,'action','amend',
    'payload',p_payload,'version',p_expected_version
  );
  perform pg_advisory_xact_lock(
    hashtextextended(p_clinic_id::text||auth.uid()::text||p_operation_id::text,0)
  );
  perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text,2));

  select * into v_saved
  from clinic_private.operation_receipts
  where (clinic_id,actor_id,operation_id)=(p_clinic_id,auth.uid(),p_operation_id);
  if found then
    if v_saved.request <> v_request then raise exception 'OPERATION_ID_REUSED'; end if;
    return v_saved.response;
  end if;

  if p_payload->>'_expires_at' is null
     or (p_payload->>'_expires_at')::timestamptz <= clock_timestamp()
     or (p_payload->>'_expires_at')::timestamptz > clock_timestamp()+interval '2 minutes' then
    raise exception 'COMMAND_EXPIRED';
  end if;

  select * into v_visit
  from public.visits
  where clinic_id=p_clinic_id and id=p_entity_id
  for update;
  if v_visit.id is null then raise exception 'NOT_FOUND'; end if;
  if v_visit.version <> p_expected_version then
    raise exception 'VERSION_CONFLICT' using detail=coalesce(
      (select to_jsonb(d) from public.visit_details d
       where d.clinic_id=p_clinic_id and d.id=p_entity_id),
      '{}'::jsonb
    )::text;
  end if;
  if not v_visit.completed then raise exception 'VISIT_NOT_COMPLETED'; end if;
  if p_payload->>'patient_id' is not null
     and (p_payload->>'patient_id')::uuid <> v_visit.patient_id then
    raise exception 'VISIT_IDENTITY_CHANGED';
  end if;
  if p_payload->>'appointment_id' is not null
     and (p_payload->>'appointment_id')::uuid <> v_visit.appointment_id then
    raise exception 'VISIT_IDENTITY_CHANGED';
  end if;

  v_reason=btrim(coalesce(p_payload->>'amendment_reason',''));
  if length(v_reason) not between 10 and 1000 then
    raise exception 'AMENDMENT_REASON_REQUIRED';
  end if;
  if length(coalesce(p_payload->>'notes','')) > 20000
     or length(coalesce(p_payload->>'follow_up','')) > 5000
     or jsonb_typeof(p_payload->'diagnoses') <> 'array'
     or jsonb_array_length(p_payload->'diagnoses') > 50
     or jsonb_typeof(p_payload->'medications') <> 'array'
     or jsonb_array_length(p_payload->'medications') > 100 then
    raise exception 'INVALID_AMENDMENT';
  end if;

  select to_jsonb(d) into v_previous
  from public.visit_details d
  where d.clinic_id=p_clinic_id and d.id=p_entity_id;
  v_revision=v_visit.current_revision+1;
  insert into public.visit_revisions(
    clinic_id,visit_id,revision,notes,follow_up,amendment_reason,authored_by
  ) values(
    p_clinic_id,p_entity_id,v_revision,
    coalesce(p_payload->>'notes',''),coalesce(p_payload->>'follow_up',''),
    v_reason,auth.uid()
  );

  v_position=0;
  for v_item in select value from jsonb_array_elements(p_payload->'diagnoses') loop
    if jsonb_typeof(v_item) <> 'string'
       or length(btrim(v_item#>>'{}')) not between 1 and 1000 then
      raise exception 'INVALID_AMENDMENT';
    end if;
    insert into public.diagnoses(
      clinic_id,visit_id,revision,position,description,code_system,code
    ) values(
      p_clinic_id,p_entity_id,v_revision,v_position,btrim(v_item#>>'{}'),null,null
    );
    v_position=v_position+1;
  end loop;
  if v_position=0 then raise exception 'DIAGNOSIS_REQUIRED'; end if;

  insert into public.prescriptions(clinic_id,visit_id,revision)
  values(p_clinic_id,p_entity_id,v_revision)
  returning id into v_rx;
  v_position=0;
  for v_item in select value from jsonb_array_elements(p_payload->'medications') loop
    if jsonb_typeof(v_item) <> 'object'
       or v_item->>'id' is null
       or length(btrim(coalesce(v_item->>'name',''))) not between 1 and 300
       or length(coalesce(v_item->>'strength','')) > 200
       or length(coalesce(v_item->>'dose','')) > 200
       or length(coalesce(v_item->>'frequency','')) > 200
       or length(coalesce(v_item->>'duration','')) > 200
       or length(coalesce(v_item->>'instructions','')) > 5000
       or length(coalesce(v_item->>'notes','')) > 5000 then
      raise exception 'INVALID_AMENDMENT';
    end if;
    insert into public.prescription_items(
      clinic_id,prescription_id,id,position,name,strength,dose,frequency,
      duration,instructions,notes
    ) values(
      p_clinic_id,v_rx,(v_item->>'id')::uuid,v_position,
      btrim(v_item->>'name'),coalesce(v_item->>'strength',''),
      coalesce(v_item->>'dose',''),coalesce(v_item->>'frequency',''),
      coalesce(v_item->>'duration',''),coalesce(v_item->>'instructions',''),
      coalesce(v_item->>'notes','')
    );
    v_position=v_position+1;
  end loop;

  update public.visits
  set current_revision=v_revision,version=version+1,updated_at=now()
  where clinic_id=p_clinic_id and id=p_entity_id;
  select to_jsonb(d) into v_entity
  from public.visit_details d
  where d.clinic_id=p_clinic_id and d.id=p_entity_id;
  v_response=jsonb_build_object(
    'entity',v_entity,'version',(v_entity->>'version')::integer
  );

  insert into public.audit_events(
    clinic_id,actor_id,actor_role,action,object_type,object_id,
    previous_value,new_value
  ) values(
    p_clinic_id,auth.uid(),v_role,'visit.amend','visit',p_entity_id,
    v_previous,v_entity
  );
  insert into clinic_private.operation_receipts(
    clinic_id,actor_id,operation_id,request,response
  ) values(
    p_clinic_id,auth.uid(),p_operation_id,v_request,v_response
  );
  return v_response;
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
  if p_entity_type='visit' and p_action='amend' then
    return clinic_private.apply_visit_amendment(
      p_clinic_id,p_operation_id,p_entity_id,p_payload,p_expected_version
    );
  end if;
  return clinic_private.apply_command(
    p_clinic_id,p_operation_id,p_entity_type,p_entity_id,p_action,p_payload,p_expected_version
  );
end $$;

revoke all on function clinic_private.apply_visit_amendment(uuid,uuid,uuid,jsonb,integer)
  from public,anon;
grant execute on function clinic_private.apply_visit_amendment(uuid,uuid,uuid,jsonb,integer)
  to authenticated;
revoke all on function public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer)
  from public,anon;
grant execute on function public.clinic_apply_command(uuid,uuid,text,uuid,text,jsonb,integer)
  to authenticated;
