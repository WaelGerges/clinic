# Clinic foundation migration review

**Decision: do not deploy this candidate.** Two issues require correction. No hosted writes were performed.

## Reviewed scope

- Migration: `20260828180143_clinic_foundation.sql`, 498 lines.
- SHA-256: `E96038C7F3F8281FFE47E751B1AF11A6552345CBBAA66867B1629B6849997E00`.
- Source: `C:/Users/WaelAmin/Documents/Codex/2026-08-28/act-as-a-senior-software-architect/work/clinic-project/supabase/migrations/20260828180143_clinic_foundation.sql`.
- Intended target only: `clinic-chatgpt-dev` / `geikkygtnsgbtajyqdvc` / Homeversion.
- Hosted preflight: ACTIVE_HEALTHY, empty migration history and no application tables. Read-only default-privilege inspection succeeded.
- The frozen source file was not edited. No other migration was included in the review snapshot. The separate staff/realtime work was excluded.

## Findings

### P1 — Reject mismatched visit identities before saving clinical content

**Source lines 403–422.** For a new visit, the function takes the patient from the appointment without comparing it with the submitted `patient_id`. For an existing visit, `coalesce(v_visit.appointment_id, payload.appointment_id)` ignores a different submitted appointment. Neither path rejects a mismatched patient identity.

Two local reproductions were accepted when they should fail: creating a visit with an assigned appointment for patient A but a payload naming patient B; and updating an existing visit while the payload names a different appointment and patient. Content is written against the original/assigned record. This is a clinical data-integrity risk for stale or incorrectly associated drafts, not a demonstrated cross-clinic authorization bypass.

**Required correction:** validate the save command's patient and appointment IDs against the assignment and existing visit before writing any clinical revision. Reject missing, null, or mismatched required identities. Add tests confirming rejection leaves the record, revisions, audit entries, and operation receipts unchanged.

### P2 — Remove client privileges on the audit identity sequence

**Source lines 201 and 485–497.** The target project's actual default ACL grants sequence SELECT, UPDATE and USAGE to `anon` and `authenticated`. The migration revokes table permissions but leaves `public.audit_events_id_seq` at those defaults.

With those hosted defaults reproduced in local PGlite, both roles successfully executed `setval` on the audit sequence. Resetting it can cause duplicate audit IDs and fail later audited commands. RLS and UPDATE/DELETE triggers on the audit table do not protect the sequence. This is a database-role privilege finding; direct sequence access through the current REST API was not demonstrated.

**Required correction:** explicitly revoke all privileges on this sequence from PUBLIC, anon and authenticated. The privileged command function can continue to generate audit IDs. Include the target's default ACLs in the security test setup and test both client roles. Explicitly removing unnecessary anonymous view grants is also advisable.

## Verification

An isolated copy of the exact migration was tested with the existing PGlite dependency, without network access or hosted test data. The original ten foundation tests passed. Three added review tests failed: two identity checks and one check covering sequence modification by both client roles.

Reproduction suite: `C:/Users/WaelAmin/Documents/Codex/2026-08-28/supabase-plugin-supabase-openai-curated-remote/work/clinic-foundation-review/backend-tests/clinic.test.mjs`.

Run from that snapshot's root: `node --test backend-tests/clinic.test.mjs`.

**Result: 13 tests, 10 passed, 3 failed.** The failures are missing expected rejections, not migration syntax or setup failures.

Post-deployment migration-history, exposed-table/RLS/grant, and advisor verification remain pending because deployment was stopped. No real patient records were created, no credentials were shared, and `clinicdb` was not changed. No end-to-end app integration is claimed.
