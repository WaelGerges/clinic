-- Private, email-bound invitations. No admin credential is sent to a mobile app.
alter table public.clinic_memberships add column access_changed_at timestamptz not null default clock_timestamp();
create table clinic_private.staff_invitations (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  email text not null,
  token_hash bytea not null unique,
  clinical_read boolean not null default false,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default clock_timestamp(),
  expires_at timestamptz not null default now()+interval '24 hours',
  used_at timestamptz,
  revoked_at timestamptz
);
create index staff_invite_clinic_idx on clinic_private.staff_invitations(clinic_id,created_at);
create index staff_invite_creator_idx on clinic_private.staff_invitations(created_by);
alter table clinic_private.staff_invitations enable row level security;
revoke all on clinic_private.staff_invitations from public,anon,authenticated;

create function clinic_private.invite_assistant(p_clinic_id uuid,p_email text,p_clinical_read boolean)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_code text; v_id uuid; v_expiry timestamptz; v_email text=lower(btrim(p_email));
begin
  if not clinic_private.allowed(p_clinic_id,'admin') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  if v_email is null or length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'INVALID_EMAIL'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text,2));
  if (select count(*) from clinic_private.staff_invitations where clinic_id=p_clinic_id
      and created_at>now()-interval '1 hour')>=20 then raise exception 'INVITATION_LIMIT'; end if;
  update clinic_private.staff_invitations set revoked_at=now() where clinic_id=p_clinic_id
    and email=v_email and used_at is null and revoked_at is null;
  v_code=replace(gen_random_uuid()::text||gen_random_uuid()::text,'-','');
  insert into clinic_private.staff_invitations(clinic_id,email,token_hash,clinical_read,created_by)
    values(p_clinic_id,v_email,sha256(convert_to(v_code,'UTF8')),coalesce(p_clinical_read,false),auth.uid())
    returning id,expires_at into v_id,v_expiry;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,new_value)
    values(p_clinic_id,auth.uid(),'doctor','staff.invited','invitation',v_id,
      jsonb_build_object('email',v_email,'clinical_read',coalesce(p_clinical_read,false)));
  return jsonb_build_object('id',v_id,'code',v_code,'email',v_email,'expires_at',v_expiry);
end $$;

create function clinic_private.join_clinic(p_code text) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_invite clinic_private.staff_invitations%rowtype; v_email text;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  select lower(email) into v_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
  if v_email is null or p_code is null or length(p_code)<>64 then raise exception 'INVITATION_INVALID'; end if;
  -- Discover the clinic without holding a row lock; use the same clinic lock order as admin mutations.
  select * into v_invite from clinic_private.staff_invitations where token_hash=sha256(convert_to(btrim(p_code),'UTF8'));
  if not found then raise exception 'INVITATION_INVALID'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_invite.clinic_id::text,2));
  select * into v_invite from clinic_private.staff_invitations where id=v_invite.id for update;
  if v_invite.email<>v_email or v_invite.used_at is not null or v_invite.revoked_at is not null
    or v_invite.expires_at<=now() or not exists(select 1 from public.clinics where id=v_invite.clinic_id and not archived)
    then raise exception 'INVITATION_INVALID'; end if;
  -- A later access decision supersedes an older invitation, even if the user's
  -- email changed and a pending invitation could not be matched by email.
  if exists(select 1 from public.clinic_memberships m where m.clinic_id=v_invite.clinic_id
      and m.user_id=auth.uid() and v_invite.created_at<=m.access_changed_at) then
    raise exception 'INVITATION_INVALID'; end if;
  if exists(select 1 from public.clinic_memberships where clinic_id=v_invite.clinic_id and user_id=auth.uid()
    and (active or role<>'assistant')) then raise exception 'ALREADY_MEMBER'; end if;
  insert into public.clinic_memberships(clinic_id,user_id,role,clinical_read)
    values(v_invite.clinic_id,auth.uid(),'assistant',v_invite.clinical_read)
    on conflict(clinic_id,user_id) do update set active=true,clinical_read=excluded.clinical_read,access_changed_at=clock_timestamp();
  update clinic_private.staff_invitations set used_at=now() where id=v_invite.id;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id)
    values(v_invite.clinic_id,auth.uid(),'assistant','staff.joined','invitation',v_invite.id);
  return v_invite.clinic_id;
end $$;

create function clinic_private.staff_list(p_clinic_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
  if not clinic_private.allowed(p_clinic_id,'admin') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('user_id',m.user_id,'email',u.email,
    'role',m.role,'active',m.active,'clinical_read',m.clinical_read) order by m.created_at)
    from public.clinic_memberships m join auth.users u on u.id=m.user_id where m.clinic_id=p_clinic_id),'[]'::jsonb);
end $$;

create function clinic_private.set_staff_access(p_clinic_id uuid,p_user_id uuid,p_active boolean,p_clinical_read boolean)
returns void language plpgsql security definer set search_path='' as $$
declare v_previous jsonb; v_next jsonb;
begin
  if not clinic_private.allowed(p_clinic_id,'admin') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  if p_active is null or p_clinical_read is null then raise exception 'INVALID_COMMAND'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_clinic_id::text,2));
  select to_jsonb(m) into v_previous from public.clinic_memberships m
    where m.clinic_id=p_clinic_id and m.user_id=p_user_id and m.role='assistant' for update;
  if not found then raise exception 'ASSISTANT_NOT_FOUND'; end if;
  update clinic_private.staff_invitations set revoked_at=clock_timestamp()
    where clinic_id=p_clinic_id and used_at is null and revoked_at is null
      and email=(select lower(email) from auth.users where id=p_user_id);
  update public.clinic_memberships set active=p_active,clinical_read=p_clinical_read,access_changed_at=clock_timestamp()
    where clinic_id=p_clinic_id and user_id=p_user_id returning to_jsonb(clinic_memberships.*) into v_next;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,previous_value,new_value)
    values(p_clinic_id,auth.uid(),'doctor','staff.access_changed','membership',p_user_id,v_previous,v_next);
end $$;

create function public.clinic_invite_assistant(p_clinic_id uuid,p_email text,p_clinical_read boolean default false)
returns jsonb language sql security invoker set search_path='' as $$select clinic_private.invite_assistant(p_clinic_id,p_email,p_clinical_read)$$;
create function public.clinic_join(p_code text) returns uuid language sql security invoker set search_path='' as $$select clinic_private.join_clinic(p_code)$$;
create function public.clinic_staff(p_clinic_id uuid) returns jsonb language sql security invoker set search_path='' as $$select clinic_private.staff_list(p_clinic_id)$$;
create function public.clinic_set_staff_access(p_clinic_id uuid,p_user_id uuid,p_active boolean,p_clinical_read boolean)
returns void language sql security invoker set search_path='' as $$select clinic_private.set_staff_access(p_clinic_id,p_user_id,p_active,p_clinical_read)$$;

revoke all on function clinic_private.invite_assistant(uuid,text,boolean),clinic_private.join_clinic(text),
  clinic_private.staff_list(uuid),clinic_private.set_staff_access(uuid,uuid,boolean,boolean),
  public.clinic_invite_assistant(uuid,text,boolean),public.clinic_join(text),public.clinic_staff(uuid),
  public.clinic_set_staff_access(uuid,uuid,boolean,boolean) from public,anon;
grant execute on function clinic_private.invite_assistant(uuid,text,boolean),clinic_private.join_clinic(text),
  clinic_private.staff_list(uuid),clinic_private.set_staff_access(uuid,uuid,boolean,boolean),
  public.clinic_invite_assistant(uuid,text,boolean),public.clinic_join(text),public.clinic_staff(uuid),
  public.clinic_set_staff_access(uuid,uuid,boolean,boolean) to authenticated;

-- Only publish application-owned tables. Supabase-managed schemas are unchanged.
-- Local test databases need not define the hosted publication.
do $$
declare v_table text;
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach v_table in array array['patients','appointments','visits'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=v_table) then
        execute format('alter publication supabase_realtime add table public.%I',v_table);
      end if;
    end loop;
  end if;
end $$;
