-- Private clinical documents. Metadata is application-owned; object bytes stay in
-- a private Supabase Storage bucket and can only be read through a short lease.
alter table public.attachments
  add column sha256 bytea not null check (octet_length(sha256)=32);

create table clinic_private.attachment_access_grants (
  user_id uuid not null references auth.users(id),
  attachment_id uuid not null references public.attachments(id),
  object_path text not null,
  purpose text not null check (purpose in ('preview','download','share')),
  created_at timestamptz not null default clock_timestamp(),
  expires_at timestamptz not null,
  primary key (user_id,object_path)
);
create index attachment_grant_expiry_idx
  on clinic_private.attachment_access_grants(expires_at);
alter table clinic_private.attachment_access_grants enable row level security;
revoke all on clinic_private.attachment_access_grants from public,anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('clinic-documents','clinic-documents',false,20971520,
  array['image/jpeg','image/png','image/webp','application/pdf']::text[])
on conflict (id) do update set
  public=false,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

create function clinic_private.attachment_object_allowed(p_path text,p_write boolean)
returns boolean language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists(
    select 1
    from public.attachments a
    where a.object_path=p_path
      and clinic_private.allowed(a.clinic_id,
        case when a.clinical then 'clinical_read' else 'read' end)
      and case when p_write then
        a.state='pending' and a.uploaded_by=auth.uid()
      else
        a.state='ready' and exists(
          select 1 from clinic_private.attachment_access_grants g
          where g.user_id=auth.uid() and g.attachment_id=a.id
            and g.object_path=a.object_path
            and g.expires_at>clock_timestamp())
      end)
$$;

drop policy if exists clinic_document_insert on storage.objects;
create policy clinic_document_insert on storage.objects
  for insert to authenticated
  with check (bucket_id='clinic-documents'
    and clinic_private.attachment_object_allowed(name,true));

drop policy if exists clinic_document_read on storage.objects;
create policy clinic_document_read on storage.objects
  for select to authenticated
  using (bucket_id='clinic-documents'
    and clinic_private.attachment_object_allowed(name,false));

create function clinic_private.begin_attachment(
  p_id uuid,p_clinic_id uuid,p_patient_id uuid,p_visit_id uuid,
  p_file_name text,p_content_type text,p_category text,p_notes text,
  p_bytes bigint,p_clinical boolean,p_sha256_hex text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_attachment public.attachments%rowtype;
  v_role text;
  v_path text;
  v_hash bytea;
begin
  if auth.uid() is null or not clinic_private.allowed(p_clinic_id) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  if p_id is null or p_patient_id is null or p_bytes is null
      or p_bytes<1 or p_bytes>20971520
      or p_file_name is null or length(btrim(p_file_name)) not between 1 and 180
      or p_file_name ~ '[[:cntrl:]/\\]'
      or p_content_type is null
      or p_content_type not in ('image/jpeg','image/png','image/webp','application/pdf')
      or p_category is null
      or p_category not in ('Lab','Radiology','Referral','Consent','Other')
      or p_clinical is null or p_sha256_hex is null
      or p_sha256_hex !~ '^[0-9a-f]{64}$' then
    raise exception 'INVALID_ATTACHMENT';
  end if;
  if not exists(select 1 from public.patients p where p.clinic_id=p_clinic_id
      and p.id=p_patient_id and not p.archived) then
    raise exception 'INVALID_PATIENT';
  end if;
  if p_visit_id is not null then
    if not coalesce(p_clinical,false) or
       not clinic_private.allowed(p_clinic_id,'clinical_read') or
       not exists(select 1 from public.visits v where v.clinic_id=p_clinic_id
         and v.id=p_visit_id and v.patient_id=p_patient_id) then
      raise exception 'INVALID_VISIT' using errcode='42501';
    end if;
  elsif p_clinical and not clinic_private.allowed(p_clinic_id,'clinical_read') then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  select role into v_role from public.clinic_memberships
    where clinic_id=p_clinic_id and user_id=auth.uid() and active;
  v_path=p_clinic_id::text||'/'||p_patient_id::text||'/'||p_id::text;
  v_hash=decode(p_sha256_hex,'hex');
  perform pg_advisory_xact_lock(hashtextextended(p_id::text,3));
  select * into v_attachment from public.attachments where id=p_id for update;
  if found then
    if v_attachment.clinic_id<>p_clinic_id or v_attachment.patient_id<>p_patient_id
       or v_attachment.visit_id is distinct from p_visit_id
       or v_attachment.file_name<>btrim(p_file_name)
       or v_attachment.content_type<>p_content_type
       or v_attachment.category<>p_category
       or v_attachment.notes<>coalesce(p_notes,'')
       or v_attachment.object_path<>v_path or v_attachment.bytes<>p_bytes
       or v_attachment.clinical<>p_clinical or v_attachment.sha256<>v_hash
       or v_attachment.uploaded_by<>auth.uid() then
      raise exception 'ATTACHMENT_ID_REUSED' using errcode='42501';
    end if;
    if v_attachment.state='failed' and not exists(select 1 from storage.objects o
        where o.bucket_id='clinic-documents' and o.name=v_path) then
      update public.attachments set state='pending',updated_at=clock_timestamp(),version=version+1
        where id=p_id returning * into v_attachment;
    end if;
    return (to_jsonb(v_attachment)-'sha256')||
      jsonb_build_object('sha256_hex',encode(v_attachment.sha256,'hex'));
  end if;
  insert into public.attachments(id,clinic_id,patient_id,visit_id,file_name,content_type,
    category,notes,object_path,bytes,clinical,state,uploaded_by,sha256)
  values(p_id,p_clinic_id,p_patient_id,p_visit_id,btrim(p_file_name),p_content_type,
    p_category,coalesce(p_notes,''),v_path,p_bytes,p_clinical,'pending',auth.uid(),v_hash)
  returning * into v_attachment;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,new_value)
  values(p_clinic_id,auth.uid(),v_role,'attachment.staged','attachment',p_id,
    jsonb_build_object('patient_id',p_patient_id,'visit_id',p_visit_id,
      'file_name',btrim(p_file_name),'content_type',p_content_type,
      'category',p_category,'bytes',p_bytes,'clinical',p_clinical));
  return (to_jsonb(v_attachment)-'sha256')||
    jsonb_build_object('sha256_hex',encode(v_attachment.sha256,'hex'));
end $$;

create function clinic_private.finalize_attachment(p_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_attachment public.attachments%rowtype;
  v_role text;
  v_stored_bytes bigint;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_id::text,3));
  select * into v_attachment from public.attachments where id=p_id for update;
  if v_attachment.id is null or not clinic_private.allowed(v_attachment.clinic_id,
       case when v_attachment.clinical then 'clinical_read' else 'read' end)
     or (v_attachment.uploaded_by<>auth.uid()
       and not clinic_private.allowed(v_attachment.clinic_id,'admin')) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  if v_attachment.state='ready' then
    return (to_jsonb(v_attachment)-'sha256')||
      jsonb_build_object('sha256_hex',encode(v_attachment.sha256,'hex'));
  end if;
  if v_attachment.state not in ('pending','failed') then raise exception 'INVALID_ATTACHMENT_STATE'; end if;
  select case when o.metadata->>'size' ~ '^[0-9]+$'
    then (o.metadata->>'size')::bigint end into v_stored_bytes
  from storage.objects o
  where o.bucket_id='clinic-documents' and o.name=v_attachment.object_path;
  if v_stored_bytes is null then raise exception 'ATTACHMENT_OBJECT_MISSING'; end if;
  if v_stored_bytes<>v_attachment.bytes then raise exception 'ATTACHMENT_SIZE_MISMATCH'; end if;
  update public.attachments set state='ready',updated_at=clock_timestamp(),version=version+1
    where id=p_id returning * into v_attachment;
  select role into v_role from public.clinic_memberships
    where clinic_id=v_attachment.clinic_id and user_id=auth.uid() and active;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,new_value)
  values(v_attachment.clinic_id,auth.uid(),v_role,'attachment.finalized','attachment',p_id,
    jsonb_build_object('bytes',v_attachment.bytes,'content_type',v_attachment.content_type,
      'sha256_hex',encode(v_attachment.sha256,'hex')));
  return (to_jsonb(v_attachment)-'sha256')||
    jsonb_build_object('sha256_hex',encode(v_attachment.sha256,'hex'));
end $$;

create function clinic_private.fail_attachment(p_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_attachment public.attachments%rowtype; v_role text;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_id::text,3));
  select * into v_attachment from public.attachments where id=p_id for update;
  if not found or v_attachment.uploaded_by<>auth.uid()
     or not clinic_private.allowed(v_attachment.clinic_id,
       case when v_attachment.clinical then 'clinical_read' else 'read' end) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  if v_attachment.state='pending' and not exists(select 1 from storage.objects o
      where o.bucket_id='clinic-documents' and o.name=v_attachment.object_path) then
    update public.attachments set state='failed',updated_at=clock_timestamp(),version=version+1
      where id=p_id;
    select role into v_role from public.clinic_memberships
      where clinic_id=v_attachment.clinic_id and user_id=auth.uid() and active;
    insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id)
    values(v_attachment.clinic_id,auth.uid(),v_role,'attachment.failed','attachment',p_id);
  end if;
end $$;

create function clinic_private.authorize_attachment_access(p_id uuid,p_purpose text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_attachment public.attachments%rowtype; v_role text; v_expiry timestamptz;
begin
  if auth.uid() is null or p_purpose is null
     or p_purpose not in ('preview','download','share') then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  select * into v_attachment from public.attachments where id=p_id and state='ready';
  if v_attachment.id is null or not clinic_private.allowed(v_attachment.clinic_id,
       case when v_attachment.clinical then 'clinical_read' else 'read' end) then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  v_expiry=clock_timestamp()+interval '90 seconds';
  insert into clinic_private.attachment_access_grants(user_id,attachment_id,object_path,purpose,expires_at)
    values(auth.uid(),p_id,v_attachment.object_path,p_purpose,v_expiry)
  on conflict(user_id,object_path) do update set attachment_id=excluded.attachment_id,
    purpose=excluded.purpose,created_at=clock_timestamp(),expires_at=excluded.expires_at;
  select role into v_role from public.clinic_memberships
    where clinic_id=v_attachment.clinic_id and user_id=auth.uid() and active;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id,new_value)
  values(v_attachment.clinic_id,auth.uid(),v_role,'attachment.accessed','attachment',p_id,
    jsonb_build_object('purpose',p_purpose));
  return jsonb_build_object('attachment_id',p_id,'object_path',v_attachment.object_path,
    'expires_at',v_expiry,'bytes',v_attachment.bytes,
    'sha256_hex',encode(v_attachment.sha256,'hex'));
end $$;

create function clinic_private.set_attachment_archived(p_id uuid,p_archived boolean)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_attachment public.attachments%rowtype; v_role text; v_target text;
begin
  if auth.uid() is null or p_archived is null then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_id::text,3));
  select * into v_attachment from public.attachments where id=p_id for update;
  select role into v_role from public.clinic_memberships
    where clinic_id=v_attachment.clinic_id and user_id=auth.uid() and active;
  if v_attachment.id is null or v_role is null
     or not clinic_private.allowed(v_attachment.clinic_id,
       case when v_attachment.clinical then 'clinical_read' else 'read' end)
     or (v_attachment.uploaded_by<>auth.uid() and v_role<>'doctor') then
    raise exception 'FORBIDDEN' using errcode='42501';
  end if;
  v_target=case when p_archived then 'archived' else 'ready' end;
  if v_attachment.state=v_target then
    return (to_jsonb(v_attachment)-'sha256')||
      jsonb_build_object('sha256_hex',encode(v_attachment.sha256,'hex'));
  end if;
  if (p_archived and v_attachment.state<>'ready') or
     (not p_archived and (v_attachment.state<>'archived' or not exists(
       select 1 from storage.objects o where o.bucket_id='clinic-documents'
         and o.name=v_attachment.object_path))) then
    raise exception 'INVALID_ATTACHMENT_STATE';
  end if;
  update public.attachments set state=v_target,updated_at=clock_timestamp(),version=version+1
    where id=p_id returning * into v_attachment;
  insert into public.audit_events(clinic_id,actor_id,actor_role,action,object_type,object_id)
  values(v_attachment.clinic_id,auth.uid(),v_role,
    case when p_archived then 'attachment.archived' else 'attachment.restored' end,
    'attachment',p_id);
  return (to_jsonb(v_attachment)-'sha256')||
    jsonb_build_object('sha256_hex',encode(v_attachment.sha256,'hex'));
end $$;

create function public.clinic_begin_attachment(
  p_id uuid,p_clinic_id uuid,p_patient_id uuid,p_visit_id uuid,
  p_file_name text,p_content_type text,p_category text,p_notes text,
  p_bytes bigint,p_clinical boolean,p_sha256_hex text)
returns jsonb language sql security invoker set search_path='' as $$
  select clinic_private.begin_attachment(p_id,p_clinic_id,p_patient_id,p_visit_id,
    p_file_name,p_content_type,p_category,p_notes,p_bytes,p_clinical,p_sha256_hex)
$$;
create function public.clinic_finalize_attachment(p_id uuid)
returns jsonb language sql security invoker set search_path='' as $$
  select clinic_private.finalize_attachment(p_id)
$$;
create function public.clinic_fail_attachment(p_id uuid)
returns void language sql security invoker set search_path='' as $$
  select clinic_private.fail_attachment(p_id)
$$;
create function public.clinic_authorize_attachment_access(p_id uuid,p_purpose text)
returns jsonb language sql security invoker set search_path='' as $$
  select clinic_private.authorize_attachment_access(p_id,p_purpose)
$$;
create function public.clinic_set_attachment_archived(p_id uuid,p_archived boolean)
returns jsonb language sql security invoker set search_path='' as $$
  select clinic_private.set_attachment_archived(p_id,p_archived)
$$;

revoke all on function clinic_private.attachment_object_allowed(text,boolean),
  clinic_private.begin_attachment(uuid,uuid,uuid,uuid,text,text,text,text,bigint,boolean,text),
  clinic_private.finalize_attachment(uuid),clinic_private.fail_attachment(uuid),
  clinic_private.authorize_attachment_access(uuid,text),
  clinic_private.set_attachment_archived(uuid,boolean),
  public.clinic_begin_attachment(uuid,uuid,uuid,uuid,text,text,text,text,bigint,boolean,text),
  public.clinic_finalize_attachment(uuid),public.clinic_fail_attachment(uuid),
  public.clinic_authorize_attachment_access(uuid,text),
  public.clinic_set_attachment_archived(uuid,boolean) from public,anon;
grant execute on function clinic_private.attachment_object_allowed(text,boolean),
  clinic_private.begin_attachment(uuid,uuid,uuid,uuid,text,text,text,text,bigint,boolean,text),
  clinic_private.finalize_attachment(uuid),clinic_private.fail_attachment(uuid),
  clinic_private.authorize_attachment_access(uuid,text),
  clinic_private.set_attachment_archived(uuid,boolean),
  public.clinic_begin_attachment(uuid,uuid,uuid,uuid,text,text,text,text,bigint,boolean,text),
  public.clinic_finalize_attachment(uuid),public.clinic_fail_attachment(uuid),
  public.clinic_authorize_attachment_access(uuid,text),
  public.clinic_set_attachment_archived(uuid,boolean) to authenticated;
