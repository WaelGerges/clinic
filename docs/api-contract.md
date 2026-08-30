# Clinic API contract

Status: seven SQL migrations through hosted version `20260829093430` are deployed to `clinic-chatgpt-dev` (`geikkygtnsgbtajyqdvc`). Flutter adapters exist for the contracts below. Local and PGlite tests pass, but authenticated two-device hosted acceptance has not been run.

All routes are relative to the approved Supabase URL. The publishable `apikey` is not a user identity; protected requests also require the authenticated user's Bearer token. Missing Auth, inactive membership, role/capability failure, or cross-clinic identity is rejected in the backend. Clients cannot grant their own role or write application tables directly.

## Authentication

Flutter uses the official Supabase SDK for email/password signup, sign-in, secure persisted sessions, recovery requests, password update, and sign-out. Recovery requests select one app-specific callback:

```text
dev.homeversion.clinic.assistant://auth-callback/
dev.homeversion.clinic.doctor://auth-callback/
```

Android/iOS registration and the recovery UI are implemented. The SDK PKCE callback must emit `AuthChangeEvent.passwordRecovery`; the replacement is 12–72 characters with confirmation. After update, the app requests global sign-out and requires a fresh login. The two URLs are not yet in the hosted Auth redirect allowlist, and SMTP/email/recovery/session-revocation acceptance is unverified.

## Read contracts

| Method / path | Purpose | Authorization and bounds |
|---|---|---|
| GET `/rest/v1/clinic_memberships` | Clinic selection and permitted staff/doctor lookup | Current member; own/admin/doctor visibility policies |
| POST `/rest/v1/rpc/clinic_search_patients` | Name, phone, number, or exact internal-ID search | Active member; explicit clinic; offset and limit 1–100 |
| GET `/rest/v1/patients` | Patient rows | Active member; explicit clinic and bounded filters |
| GET `/rest/v1/appointments` | Schedule, queue, and assignment rows | Active member; clinic/date/doctor filters; bounded page |
| GET `/rest/v1/visit_details` | Current visit revision with diagnosis/medication aggregates | Doctor or `clinical_read`; clinic/patient and bounded date page |
| GET `/rest/v1/visit_revisions` | Immutable revision headers and amendment reasons | Doctor or `clinical_read`; clinic/visit/revision filters |
| GET `/rest/v1/prescriptions` and `/prescription_items` | Revision-specific prescriptions | Doctor or `clinical_read` |
| GET `/rest/v1/attachments` | Document metadata, never byte authorization | Member; clinical rows require `clinical_read`; page capped in the client |
| GET `/rest/v1/audit_events` | Clinic audit history | Doctor administrator; client pages 25 rows and explicitly selects only ID/actor/role/action/object/time columns, excluding `previous_value` and `new_value` |

The aggregate visit view is security invoker. Private tables are outside the exposed schema or have no client policies/grants.

## Versioned command envelope

`POST /rest/v1/rpc/clinic_apply_command` accepts:

- `p_clinic_id`, `p_operation_id`, `p_entity_id`: UUIDs.
- `p_entity_type`: `patient`, `appointment`, or `visit`.
- `p_action`, `p_payload`: the action and bounded JSON object.
- `p_expected_version`: nonnegative integer; use 0 for a new entity.

An operation ID identifies one immutable request. Authorization is checked before receipt replay. Exact retries return the recorded result; the same ID with a different request is rejected. Critical client actions add a one-minute `_expires_at`; an unaccepted request first received after expiry is rejected, while an already committed receipt remains replayable.

| Entity/action | Payload | Result and invariants |
|---|---|---|
| `patient/save` | Demographics, phones, address, notes, alerts, archived flag | Server allocates clinic patient number. Only doctors change alerts. Active queue records prevent archive. |
| `appointment/save` | Patient, doctor, UTC start, type, notes | Active same-clinic identities. Existing patient/doctor identity cannot change during reschedule. |
| `appointment/status` | `status` | Enforces scheduled/confirmed/arrived/waiting terminal transition graph. |
| `appointment/send` | One-minute `_expires_at` command timestamp | Today's Waiting appointment → With Doctor only while the assigned Doctor has a fresh device-presence lease. Serializes the doctor slot; never replaces an active patient. |
| `visit/save` | Matching patient/appointment, diagnosis list, medication list, notes, follow-up | Assigned doctor appends a draft revision. Completed visits reject overwrite. |
| `visit/complete` | Empty object | Requires diagnosis, current assignment, and version. Visit, appointment, audit, and receipt commit atomically. |
| `visit/amend` | Full replacement clinical revision plus `amendment_reason` | Assigned doctor only; completed visit only; reason 10–1000; diagnosis required; online-confirmed; appends revision and retains all older rows. |

The backend caps object size, strings, diagnosis/medication counts, and medication fields. A successful amendment advances `current_revision` and visit version and records `visit.amend`. Old revision, diagnosis, prescription, and item rows are immutable.

## Doctor presence and explicit delivery receipt RPCs

Server assignment confirms queue state; it does not confirm that a Doctor device saw the patient. These public endpoints are security-invoker wrappers around search-path-locked private implementations:

| RPC | Authorization | Contract |
|---|---|---|
| `clinic_doctor_heartbeat` | Active, non-archived Doctor membership for the explicit clinic | Upserts the authenticated Doctor's protected device UUID with server `last_seen_at` and a 60-second expiry. The foreground client renews every 20 seconds. |
| `clinic_doctor_delivery_state` | Active clinic member; requested Doctor must be active in that clinic; optional appointment must be assigned to that Doctor | Returns server time, bounded presence expiry/online state, and any explicit appointment acknowledgement/version. It never infers receipt from Realtime or assignment. |
| `clinic_acknowledge_appointment` | Active assigned Doctor, exact active device UUID, `withDoctor` appointment, expected version | Stores one immutable clinic/appointment receipt with a unique operation ID, returns exact replay, rejects operation reuse, and records `appointment.received` audit data without clinical payloads. |

The private presence and receipt tables have RLS enabled and no direct authenticated table privileges. Receipt update/delete is rejected. Presence expiry prevents a backgrounded or disconnected Doctor app from accepting a new handoff.

## Staff and invitation RPCs

| RPC | Authorization | Behavior |
|---|---|---|
| `clinic_create` | Authenticated, email-confirmed user | Creates clinic and doctor-owner membership together; name 2–160 trimmed characters |
| `clinic_invite_assistant` | Doctor administrator | Email-bound, 24-hour, single-use invitation; hash only; optional clinical read; 20/clinic/hour issue cap |
| `clinic_join` | Verified account whose email matches | Consumes one current code; cannot grant admin; honors membership access cutoff |
| `clinic_staff` | Doctor administrator | Returns managed staff projection |
| `clinic_set_staff_access` | Doctor administrator | Changes assistant active/clinical-read state and invalidates older affected invitations |

The product does not email invitation codes; the doctor shares the code privately with the intended address owner.

## Private document lifecycle

The non-public `clinic-documents` bucket accepts JPEG, PNG, WebP, and PDF up to 20 MiB. Client code also verifies magic bytes and SHA-256 and encrypts staged/cached bytes locally.

| RPC / Storage action | Contract |
|---|---|
| `clinic_begin_attachment` | Exact UUID/clinic/patient/optional visit, safe filename, allowed MIME/category, byte count, clinical flag, SHA-256. Creates or exactly replays pending metadata and deterministic path `clinic/patient/attachment`. |
| Storage INSERT | Only the same authenticated uploader may write the exact path while metadata is pending and authorized. |
| `clinic_finalize_attachment` | Requires the exact object, byte size, actor, state, and path before marking ready. |
| `clinic_fail_attachment` | Marks an interrupted pending attempt without losing client staging; retry reuses the same attachment ID/path. |
| `clinic_authorize_attachment_access` | Purpose `preview`, `download`, or `share`; current permission required; creates an audited 90-second object-read lease and returns path/size/digest. |
| Storage SELECT | Requires ready metadata plus an unexpired lease for the current user/path. |
| `clinic_set_attachment_archived` | Uploader or doctor with current read capability; archive immediately prevents read leases; restore requires the retained object. |

Visit-linked documents must be clinical and match the visit patient/clinic. Assistants need explicit clinical read for clinical documents. Metadata visibility never by itself grants byte access.

## Failure mapping

SQL `42501` is forbidden. `VERSION_CONFLICT` includes the authoritative version for conflict review. Other domain failures include `DOCTOR_BUSY`, `PATIENT_ACTIVE`, `PATIENT_ARCHIVED`, `ASSIGNMENT_CHANGED`, `NOT_TODAYS_APPOINTMENT`, `INVALID_TRANSITION`, `COMPLETED_VISIT_IMMUTABLE`, `VISIT_NOT_COMPLETED`, `AMENDMENT_REASON_REQUIRED`, `INVALID_AMENDMENT`, and document identity/state/integrity errors. The Flutter gateway maps these to patient-safe messages without raw SQL, provider traces, object URLs, or record payloads.

Missing schema/function (`PGRST205`/`PGRST202`) is treated as an incompatible clinic service rather than an empty workspace.

## Realtime, offline, and performance limits

The client subscribes to authorized patient, appointment, and visit changes and performs bounded refresh on resume/reconnect. The deployed publication contains application-owned tables only. A selected clinic receives an app-specific eight-hour lease in OS secure storage; offline cold start checks project/user/clinic/role/capabilities, expiry, maximum lifetime, and wall-clock rollback before offering the encrypted cache, and a running app locks at expiry. Real-device process-death/clock/key-loss/revocation acceptance is still required. Document events and a durable delta cursor/tombstone feed remain incomplete.

Local drafts/outbox rows commit together. Conflicts preserve local and server values and block dependent work until reviewed; patient conflict recovery UI exists. Document bytes have a separate encrypted staging queue and exact retry. An uploaded filename or a sent HTTP request is not treated as confirmation.

Clinic command writes currently serialize conservatively with advisory/row locks and active-slot uniqueness. Search/history are bounded and indexed, but representative-volume, multi-connection concurrency, load, and latency benchmarks are still required. PGlite tests do not replace hosted concurrent connection tests.
