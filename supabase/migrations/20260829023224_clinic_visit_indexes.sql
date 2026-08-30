-- Cover composite foreign keys used when visits are revised and synchronized.
-- Column order matches each foreign key so PostgreSQL can validate parent
-- updates/deletes without scanning the visits table.
create index if not exists visit_current_revision_fk_idx
  on public.visits(clinic_id, id, current_revision);

create index if not exists visit_appointment_patient_doctor_fk_idx
  on public.visits(clinic_id, appointment_id, patient_id, doctor_id);
