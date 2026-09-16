alter table public.appointments add column duration_minutes integer not null default 30 check(duration_minutes between 5 and 240);
create table clinic_private.schedule_settings (
 clinic_id uuid not null, doctor_id uuid not null, periods jsonb not null,
 primary key(clinic_id,doctor_id), foreign key(clinic_id,doctor_id) references public.clinic_memberships(clinic_id,user_id));
create table clinic_private.scheduling_waitlist (
 id uuid primary key default gen_random_uuid(), clinic_id uuid not null, doctor_id uuid not null,
 patient_id uuid not null, notes text not null default '' check(length(notes)<=500), created_at timestamptz not null default now(),
 unique(clinic_id,doctor_id,patient_id), foreign key(clinic_id,doctor_id) references public.clinic_memberships(clinic_id,user_id),
 foreign key(clinic_id,patient_id) references public.patients(clinic_id,id));
create index scheduling_waitlist_patient_idx on clinic_private.scheduling_waitlist(clinic_id,patient_id);
alter table clinic_private.schedule_settings enable row level security;
alter table clinic_private.scheduling_waitlist enable row level security;
revoke all on clinic_private.schedule_settings,clinic_private.scheduling_waitlist from public,anon,authenticated;
create function clinic_private.validate_booking() returns trigger
language plpgsql security definer set search_path='' as $$
declare v_periods jsonb; v_local timestamp; v_minute integer;
begin
 if new.status in ('cancelled','noShow','completed') then return new; end if;
 if TG_OP='UPDATE' and new.starts_at=old.starts_at and new.duration_minutes=old.duration_minutes and new.doctor_id=old.doctor_id then return new; end if;
 perform pg_advisory_xact_lock(hashtextextended(new.clinic_id::text,2));
 if exists(select 1 from public.appointments a where a.clinic_id=new.clinic_id and a.doctor_id=new.doctor_id
   and a.id<>new.id and a.status not in ('cancelled','noShow','completed')
   and a.starts_at<new.starts_at+make_interval(mins=>new.duration_minutes)
   and a.starts_at+make_interval(mins=>a.duration_minutes)>new.starts_at) then raise exception 'SLOT_UNAVAILABLE'; end if;
 select periods into v_periods from clinic_private.schedule_settings where clinic_id=new.clinic_id and doctor_id=new.doctor_id;
 if v_periods is not null then
   v_local=new.starts_at at time zone 'Africa/Cairo'; v_minute=extract(hour from v_local)::integer*60+extract(minute from v_local)::integer;
   if not exists(select 1 from jsonb_array_elements(v_periods) p where (p->>'weekday')::integer=extract(isodow from v_local)::integer
     and (p->>'start')::integer<=v_minute and (p->>'end')::integer>=v_minute+new.duration_minutes) then raise exception 'OUTSIDE_WORKING_HOURS'; end if;
 end if;
 return new;
end $$;
revoke all on function clinic_private.validate_booking() from public,anon,authenticated;
create trigger validate_booking before insert or update of starts_at,duration_minutes,doctor_id on public.appointments
 for each row execute function clinic_private.validate_booking();
-- Keep the deployed command's authorization, immutable receipts and audit logic.
do $$
declare source text; updated text;
begin
 source=pg_get_functiondef('clinic_private.apply_command(uuid,uuid,text,uuid,text,jsonb,integer)'::regprocedure);
 updated=replace(source,'starts_at,appointment_type,notes,created_by)','starts_at,appointment_type,notes,created_by,duration_minutes)');
 updated=replace(updated,$old$coalesce(p_payload->>'appointment_type','Consultation'),coalesce(p_payload->>'notes',''),auth.uid())$old$,
   $new$coalesce(p_payload->>'appointment_type','Consultation'),coalesce(p_payload->>'notes',''),auth.uid(),coalesce((p_payload->>'duration_minutes')::integer,30))$new$);
 updated=replace(updated,'starts_at=excluded.starts_at,appointment_type=excluded.appointment_type,',
   'starts_at=excluded.starts_at,duration_minutes=excluded.duration_minutes,appointment_type=excluded.appointment_type,');
 if updated=source or position('duration_minutes=excluded.duration_minutes' in updated)=0 then raise exception 'Unexpected appointment command definition'; end if;
 execute updated;
end $$;
create function clinic_private.schedule(p_clinic_id uuid,p_doctor_id uuid,p_action text,p_payload jsonb)
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
   for item in select value from jsonb_array_elements(periods) loop
     if jsonb_typeof(item)<>'object' or not (item ?& array['weekday','start','end']) or
       jsonb_typeof(item->'weekday')<>'number' or jsonb_typeof(item->'start')<>'number' or jsonb_typeof(item->'end')<>'number' or
       (item->>'weekday')::integer not between 1 and 7 or (item->>'start')::integer not between 0 and 1439 or
       (item->>'end')::integer not between 1 and 1440 or (item->>'start')::integer >= (item->>'end')::integer then raise exception 'INVALID_SCHEDULE'; end if;
   end loop;
   if exists(select 1 from jsonb_array_elements(periods) with ordinality a(p,i),jsonb_array_elements(periods) with ordinality b(p,i)
     where a.i<b.i and a.p->>'weekday'=b.p->>'weekday' and (a.p->>'start')::int<(b.p->>'end')::int and (b.p->>'start')::int<(a.p->>'end')::int) then raise exception 'INVALID_SCHEDULE'; end if;
   insert into clinic_private.schedule_settings values(p_clinic_id,p_doctor_id,periods) on conflict(clinic_id,doctor_id) do update set periods=excluded.periods;
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
create function public.clinic_schedule(p_clinic_id uuid,p_doctor_id uuid,p_action text,p_payload jsonb default '{}'::jsonb)
returns jsonb language sql volatile security invoker set search_path='' as $$ select clinic_private.schedule(p_clinic_id,p_doctor_id,p_action,p_payload) $$;
revoke all on function clinic_private.schedule(uuid,uuid,text,jsonb),public.clinic_schedule(uuid,uuid,text,jsonb) from public,anon;
grant execute on function clinic_private.schedule(uuid,uuid,text,jsonb),public.clinic_schedule(uuid,uuid,text,jsonb) to authenticated;
