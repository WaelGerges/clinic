-- Server-side input bounds (security review 2026-09-17, finding SEC-001).
--
-- The visit `save`, patient `save`, appointment `save` and attachment staging
-- paths accepted unbounded text. Only the amendment path capped its payload.
-- A signed-in member could therefore store multi-megabyte notes, thousands of
-- diagnoses or prescription items, and every save also copied the full
-- visit_details document twice into audit_events. Bounds now live on the
-- tables themselves, so no command path - present or future - can exceed them.
-- The limits match the validation the Flutter clients already apply.
--
-- Deployed migrations stay immutable, so the command function is re-declared
-- from its live definition with the same guarded string patch as before.

-- Patient demographics ---------------------------------------------------------
alter table public.patients
  add constraint patients_secondary_mobile_bound check (length(secondary_mobile) <= 40),
  add constraint patients_address_bound check (length(address) <= 500),
  add constraint patients_notes_bound check (length(notes) <= 5000),
  add constraint patients_alerts_bound check (length(alerts) <= 2000);

-- Appointments ------------------------------------------------------------------
alter table public.appointments
  add constraint appointments_type_bound check (length(btrim(appointment_type)) between 1 and 80),
  add constraint appointments_notes_bound check (length(notes) <= 2000);

-- Clinical revisions --------------------------------------------------------------
alter table public.visit_revisions
  add constraint visit_revisions_notes_bound check (length(notes) <= 20000),
  add constraint visit_revisions_follow_up_bound check (length(follow_up) <= 5000),
  add constraint visit_revisions_reason_bound check (length(amendment_reason) <= 1000);

-- At most 50 diagnoses and 100 prescription items per revision. Positions are
-- allocated 0..n-1 by the command, so a bound on position is a bound on count.
alter table public.diagnoses
  add constraint diagnoses_description_bound check (length(description) <= 1000),
  add constraint diagnoses_position_bound check (position < 50);

alter table public.prescription_items
  add constraint prescription_items_name_bound check (length(name) <= 300),
  add constraint prescription_items_fields_bound check (
    length(strength) <= 200 and length(dose) <= 200 and length(frequency) <= 200
    and length(duration) <= 200 and length(instructions) <= 5000 and length(notes) <= 5000),
  add constraint prescription_items_position_bound check (position < 100);

-- Documents -----------------------------------------------------------------------
alter table public.attachments
  add constraint attachments_file_name_bound check (length(file_name) between 1 and 180),
  add constraint attachments_notes_bound check (length(notes) <= 2000);

-- Command envelope ------------------------------------------------------------------
-- 1. Reject any command payload over 1 MiB before it is parsed further; the
--    amendment path already did this.
-- 2. A new or rescheduled appointment must carry a start time no more than one
--    year in the past and no more than two years ahead. The client already
--    refuses past slots; the server accepted null and any date at all. The
--    wide past window leaves room for back-filling recent history.
do $$
declare source text; updated text;
begin
  source = pg_get_functiondef(
    'clinic_private.apply_command(uuid,uuid,text,uuid,text,jsonb,integer)'::regprocedure);
  if position('pg_column_size(p_payload)' in source) > 0 then return; end if;
  updated = replace(
    source,
    'jsonb_typeof(p_payload)<>''object'' then raise exception ''INVALID_COMMAND''; end if;',
    'jsonb_typeof(p_payload)<>''object'' then raise exception ''INVALID_COMMAND''; end if;'
    || E'\n  if pg_column_size(p_payload)>1048576 then raise exception ''INVALID_COMMAND''; end if;');
  updated = replace(
    updated,
    'raise exception ''APPOINTMENT_PROTECTED''; end if;',
    'raise exception ''APPOINTMENT_PROTECTED''; end if;'
    || E'\n      if (p_payload->>''starts_at'')::timestamptz is null then raise exception ''INVALID_COMMAND''; end if;'
    || E'\n      if (p_payload->>''starts_at'')::timestamptz<clock_timestamp()-interval ''1 year'' then raise exception ''PAST_APPOINTMENT''; end if;'
    || E'\n      if (p_payload->>''starts_at'')::timestamptz>clock_timestamp()+interval ''2 years'' then raise exception ''INVALID_COMMAND''; end if;');
  if updated = source
     or position('pg_column_size(p_payload)' in updated) = 0
     or position('PAST_APPOINTMENT' in updated) = 0 then
    raise exception 'Unexpected command definition';
  end if;
  execute updated;
end $$;
