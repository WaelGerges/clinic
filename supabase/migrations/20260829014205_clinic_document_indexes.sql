-- Cover foreign-key checks and visit-scoped document retrieval without changing
-- the least-privilege policies established by clinic_documents.
create index attachment_grant_attachment_idx
  on clinic_private.attachment_access_grants(attachment_id);
create index attachment_visit_patient_fk_idx
  on public.attachments(clinic_id,visit_id,patient_id)
  where visit_id is not null;

create function clinic_private.revoke_attachment_grants() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if old.state='ready' and new.state<>'ready' then
    delete from clinic_private.attachment_access_grants where attachment_id=new.id;
  end if;
  return new;
end $$;
create trigger revoke_attachment_grants_on_state
  after update of state on public.attachments
  for each row execute function clinic_private.revoke_attachment_grants();
revoke all on function clinic_private.revoke_attachment_grants() from public,anon,authenticated;
