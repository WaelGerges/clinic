# Phase 2 — Backend Evaluation and Private Clinic Ownership

**Date:** 28 August 2026  
**Status:** Prototype approval received. Backend evaluation complete. Database engine selected: PostgreSQL. Initial cloud host recommended: Supabase Free for fictional-data testing. Clinic isolation approach requires the user's confirmation before schema or app implementation.  
**Requested project root:** C:\waelg\projects\clinic-chatgpt

No cloud resources, database objects, or application code were created during this evaluation.

## 1. Confirmed requirements

- Two separate Flutter apps: Clinic Assistant and Doctor.
- English initially, light and dark themes, phones first; preserve the original responsive/tablet direction for later expansion.
- Clinics operate in Egypt.
- Each doctor/clinic must have a private working environment shared only with authorized staff.
- Doctor is the clinic administrator and has access to every patient in that clinic, not only the currently assigned patient.
- Assistant is a power user for clinic operations.
- Initial scale is unknown. No arbitrary clinic/patient/visit count is assumed as a product restriction.
- Initial testing should use a free or open-source database; changing hosting later must remain practical.
- The user explicitly requested backend evaluation before implementation.

## 2. Decision: distinguish the database from the hosting service

**Select PostgreSQL as the database engine.** It is available under the PostgreSQL License. Its relational model fits patients, encounters, medication items, appointments, clinic memberships, and document metadata. This is an engineering fit assessment, not a measured performance claim. [PostgreSQL license](https://www.postgresql.org/about/licence/)

**Recommend Supabase Free as the initial cloud test host.** Supabase provides PostgreSQL with supporting application services and a Flutter integration. Selecting it for the test environment does not mean the clinical business model must become inseparable from Supabase. [Supabase database](https://supabase.com/docs/guides/database/overview), [Flutter integration](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)

The alternative is PostgreSQL with an independently hosted backend. This gives more infrastructure control but requires more work to provide authentication, authorization, file access, real-time delivery, and operations.

A free database license does not make servers, backups, storage, email delivery, or maintenance permanently free.

## 3. Options evaluated

The ranking below is an architectural judgment for this project, not a benchmark.

| Option | Fit for the clinic system | Test cost and operational tradeoff | Decision |
|---|---|---|---|
| PostgreSQL with Supabase | Relational data plus integrated client-facing services; practical route to a two-phone cloud test | Hosted Free has quotas and pauses; production controls still require design and verification | Recommended initial test stack |
| PostgreSQL with a custom backend | Strong control over hosting, domain API, and isolation | Database software has no license fee; cloud backend and operations are separate responsibilities | Preferred fallback if hosting/privacy requirements rule out Supabase |
| Appwrite | Provides database relationships and an integrated backend platform | Free hosted tier exists; migration to a separately designed PostgreSQL backend would involve application/API mapping | Viable, but less aligned with the selected PostgreSQL-centered portability approach |
| PocketBase | Compact open-source backend using SQLite, with authentication and realtime | Easy experimentation, but its maintainers warn against production-critical use before 1.0 without accepting compatibility/migration work | Not selected as the foundation for long-term clinical records |

Appwrite currently lists 2 GB storage, 5 GB bandwidth, one database and one bucket per free project, with inactivity pausing and two free projects. Its relationship support includes one-to-one, one-to-many, many-to-one, and many-to-many; it should not be dismissed as lacking relationships. [Appwrite pricing](https://appwrite.io/pricing), [Appwrite relationships](https://appwrite.io/docs/products/databases/relationships)

PocketBase's own documentation supplies the maturity warning and describes its SQLite-based architecture. [PocketBase documentation](https://pocketbase.io/docs/)

## 4. Free test environment boundaries

Supabase Free currently lists:

| Resource | Free allowance or restriction |
|---|---|
| Monthly plan | USD 0 |
| Database | 500 MB |
| File storage | 1 GB |
| Egress | 5 GB, with a separate cached-egress allowance |
| Realtime | 200 peak connections; 2 million messages/month |
| Individual file upload | 50 MB maximum |
| Inactivity | Paused after one inactive week |
| Active projects | Two |
| Managed automatic backups and platform audit logs | Not included |

These are provider limits, not permanent product limits. Large radiology files can exceed this test tier. Platform logs are not a substitute for the application's clinical audit history. Some managed advanced authentication/session controls also differ by plan and must not be assumed available. [Supabase pricing](https://supabase.com/pricing)

Use fictional patients and small sample files. Do not treat the free environment as an approved production medical-record service. No paid service has been purchased or provisioned.

Self-hosting remains an option, but the operator becomes responsible for maintenance, hardening, availability, monitoring, and recovery. A local development stack is not a hardened public deployment. [Supabase self-hosting responsibilities](https://supabase.com/docs/guides/self-hosting)

## 5. Private clinic workspace versus physical database

The user said the database should be created according to the clinic or doctor name. There are two meanings to distinguish.

### Recommended starting approach: a private logical workspace

One shared application backend/database serves multiple separately authorized clinic workspaces. Each clinic receives a stable, non-public internal identifier. The displayed clinic name is editable; it is not the security boundary.

- Doctor creates the clinic account/setup, named in the clinic name by default.
- Doctor and actual staff within that clinic use the same clinical data within their final permissions.
- The two apps use the same clinic context.
- Reinstalling a phone does not create another clinic or another database.
- Another doctor with the same name does not gain access to this clinic.
- The same patient name or mobile in two different clinics does not cause automatic cross-clinic merging.
- A clinic rename does not change its identity or require a new database.

This is a **shared physical database with enforced clinic isolation**, not a separate physical database for every doctor and not a privacy guarantee produced by a UI filter.

### Alternative: physical database per clinic

A provisioning service creates and maintains a separate database or backend instance for each clinic. This can offer a stronger separation boundary, but adds per-clinic provisioning, migrations, backup/restore, connection routing, monitoring, and cost.

Physical separation still requires correct application authorization and does not remove privileged infrastructure access.

### Decision required

**Does a private clinic workspace in a shared database match the user's intended privacy model, or is a physically separate database an explicit requirement?**

Do not finalize the tenant schema or build onboarding until this distinction is resolved.

## 6. Proposed first-use workflow

1. Doctor installs Doctor App and creates/verifies their own account.
2. Doctor selects Create clinic and enters the clinic display name and essential settings.
3. The service creates the clinic workspace and doctor-owner membership together. The doctor receives administrator rights only in that clinic.
4. Doctor sends a single-use, expiring invitation to an assistant. Invitation acceptance requires authentication and the intended membership checks.
5. Assistant installs Clinic Assistant App, signs in with a separate account, and accepts the invitation.
6. Both apps display the same clinic context and access the same authorized records.
7. A second clinic has its own membership and records. Its staff cannot discover the first clinic's patients, attachments, queue, or events.
8. Reinstallation or a new phone uses the existing account and membership; it does not recreate the clinic.

Clinic name, a guessed identifier, or knowing a doctor's name must never be sufficient to join.

The product owner manages the initial hosting project. Individual doctors and assistants use application accounts; they do not need hosting-provider accounts or database passwords.

Initial registration/joining requires connectivity. Useful offline work begins only after authorized setup and permitted data download.

## 7. Revised role interpretation

Every right below is limited to the selected clinic and remains subject to record-level rules.

| Capability | Doctor / Clinic Administrator | Assistant / Power User |
|---|---|---|
| View all clinic patients | Yes, including when no patient is currently assigned | Yes, for clinic operations |
| Create/edit demographics | Yes | Yes |
| Manage appointments and queue | Yes; primary operational UI remains in Assistant App | Yes |
| Upload/manage permitted patient documents | Yes | Yes |
| Read clinical visits and prescriptions | Yes | Only if explicitly granted by doctor; proposed least-privilege default |
| Create/sign clinical visits and prescriptions | Yes, as an authorized clinician | No |
| Amend completed clinical visits | Authorized clinical amendment workflow | No |
| Archive patients/documents | With safeguards and retained history | Granted operational archival permission, with the same safeguards |
| Invite/disable staff and change permissions | Yes | No |
| Change clinic ownership or sensitive security settings | Yes, with additional confirmation | No |
| View authorized clinic audit history | Yes | Own relevant activity or granted operational scope |
| Erase or silently overwrite clinical/audit history | No | No |

“Doctor administrator” is an application role, not a PostgreSQL superuser, Supabase service role, or access to all clinics on the platform.

“Power user” is interpreted as broad operational authority, not permission to sign a medical prescription or rewrite a completed visit. Clinical-read access is still a policy choice, not inferred from the label.

Doctor App therefore needs clinic creation, staff invitations/permissions, and clinic settings in its secondary navigation. Authorized Records must remain available for all of the doctor's clinic patients, independently of the Current Patient workspace.

## 8. Isolation requirements to verify later

These are acceptance requirements, not implemented controls.

- Every clinic-owned business record carries a stable clinic association.
- Relationships between patient, appointment, visit, prescription, medication item, and attachment must reject cross-clinic linkage.
- Authorization is enforced in the backend/database, not just hidden buttons or client filters.
- PostgreSQL row-security policies can contribute to row isolation; privileged roles can bypass such policies, so credentials and execution privileges require separate controls. [PostgreSQL row security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- No privileged provider/database credentials in either mobile app.
- Files remain private; knowing an object path does not grant access.
- Live subscriptions are authorized per clinic and doctor.
- The active consultation belongs to a clinic and doctor; it is not one global application-wide patient slot.
- Offline caches and pending work are separated by user/clinic, protected locally, and not exposed on account switching.
- Revocation while offline cannot be instantaneous; an approved offline access window and reconnect checks are necessary.
- Audit events preserve actor, role, clinic, object, time, and appropriate changes. Application users cannot erase audit history.
- Support or infrastructure operators need separate restricted and audited access; the proposed system is not represented as end-to-end encrypted against all operators.

## 9. Portability approach

Changing hosting later is possible, but it will not be a one-setting switch.

1. Keep the clinical domain in relational PostgreSQL tables with explicit relationships.
2. Keep Flutter screens independent of provider-specific client calls through defined data/service boundaries.
3. Isolate authentication, object storage, realtime, and privileged operations behind replaceable components.
4. Keep stable application identities separate from assumptions about a provider's account identifiers.
5. Store file metadata and object references without depending on permanent public provider URLs.
6. Keep versioned schema changes and an explicit data export/import procedure.
7. Migrate and verify database records, files, identities/session behavior, security policies, and live-event behavior separately.
8. Rehearse restoration and tenant-isolation tests before any migration.

Even Supabase-to-Supabase migration documents separate work for storage objects and customized authentication/storage policies. Moving to an independent backend will also require API and authentication work. [Supabase backup/restore guide](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)

Remaining on PostgreSQL while changing host is a smaller change than replacing PostgreSQL with a different database engine.

## 10. Offline and consultation requirements remain unchanged

A cloud connection is not a complete offline synchronization implementation.

- Each app needs protected local records and a durable pending-operation queue.
- Temporary offline patient creation must reconcile to a stable clinic-scoped identity without automatic medical-record merging.
- Connection restoration retries eligible operations; conflicts preserve both versions for authorized review.
- Realtime messages prompt synchronization; the confirmed record state remains authoritative.
- Send to Doctor requires a confirmed shared operation. It cannot report remote delivery while disconnected.
- Completion saved offline is not shared completion; the active slot stays protected until confirmation.
- Clinical amendments preserve history. Failed file transfer does not imply the file is uploaded.
- Repeated requests and simultaneous assistants must not produce duplicate active assignments or clinical completions.

The exact local database, encryption integration, sync protocol, and implementation packages belong in the subsequent detailed architecture.

## 11. Egypt production-readiness gate

The Egyptian PDPC identifies Law No. 151 of 2020 and Executive Regulations No. 816 of 2025 as the applicable personal-data framework. Real medical data requires a qualified review of sensitive-data handling, permitted hosting/transfers, organizational responsibilities, and retention. This evaluation is not legal advice or a compliance certification. Do not assume either that all foreign hosting is allowed or that every record must automatically be hosted in Egypt. [Egyptian Personal Data Protection Center](https://www.pdpc.gov.eg/)

Until that review is complete, use fictional clinic and patient data. Selecting a nearby region does not itself establish compliance.

## 12. Local environment inspection

Read-only inspection found:

| Item | Observation |
|---|---|
| Requested folder | C:\waelg\projects\clinic-chatgpt exists and was empty at inspection |
| Applicable AGENTS.md in inspected parent chain | None found |
| Flutter and Dart | Present on PATH under C:\flutter\flutter\bin |
| Flutter cache metadata | 3.48.0-0.3.pre, main channel; Dart 3.14.0 development build |
| Android SDK default folder | Exists |
| Java | JDK 25 executable found on PATH |
| Git and Node | Found on PATH |
| Docker, .NET, PostgreSQL client, Supabase CLI, adb | Not found on PATH; this alone does not prove they are not installed elsewhere |

No SDK commands were run, no installations were changed, and Android build compatibility has not been verified. Before implementation, verify and pin a supported stable Flutter/Android toolchain. Do not silently switch the user's existing global SDK channel.

macOS/Xcode availability for eventual iOS builds remains a separate requirement.

## 13. Work sequence after the isolation decision

1. Confirm whether clinic privacy means logical isolation or a physical database per clinic.
2. Finalize detailed architecture and the updated doctor-admin/assistant onboarding flows.
3. Arrange authorized access to one development backend project, or choose the independent PostgreSQL hosting path.
4. Verify the development toolchain and create the two-app project in the requested directory.
5. Build and test a first end-to-end slice: doctor creates clinic, invites assistant, assistant registers a fictional patient, queues the patient, doctor receives the patient, completes a visit, and both apps reconcile.
6. Add remaining modules and failure cases, including offline recovery and protected documents.
7. Verify cross-clinic isolation using at least two independent fictional clinics and deliberately unauthorized access attempts.
8. Complete production security, restoration, privacy, device, and usability validation before any live clinical use.

This evaluation is complete. The apps, backend, database schema, and automated tests are not implemented.

