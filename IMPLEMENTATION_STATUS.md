# Clinic Apps — Implementation Status

Last updated: 12 September 2026

This is the persistent execution checkpoint. Update it whenever work changes state, verification changes, and before stopping. `CONTINUE-HERE.md` contains the broader architecture and operating context.


## 12 September 2026 correction pass

A review of the local working tree found defects in the 12 September feature work and in earlier deployed behaviour. All are fixed locally; verification is 50/50 Flutter tests, 34/34 backend tests and clean static analysis.

**Arabic completeness.** Every string that reaches `tr()` at runtime now has a translation: 556 keys covering 502 sinks, up from 389 covering ~390. The large gap was the data layer — `safeError()` forwards every `ClinicFailure.message` into `tr()`, and none of those ~110 messages had an Arabic entry, so any error or validation message appeared in English while the app was in Arabic. Also fixed: eight `tr()` call sites that received an already-interpolated string and so could never match a key, runtime values (`actor_role`, `object_type`, outbox `entity_type`/`action`/`state`, membership role, document category and state) that were substituted untranslated, two untranslated `Semantics` labels, and one raw `Text` literal. `test/translation_coverage_test.dart` scans the source for every sink and fails if any string lacks an entry, so this cannot silently regress.

**Rejected requests no longer block the queue.** A `failed` outbox row halted every later operation, document upload and shared action, and nothing could clear it short of wiping app data. `ClinicRepository.discardRejectedOperation` discards a request the server definitively rejected — only the `failed` state, which is reached solely after a non-transient rejection, so the request was never applied — then restores the record from the server so the next save carries the version the server holds. The synchronization screen exposes it with a confirmation.

**Patient reconciliation.** `refresh()` read only the first page of active patients, so records beyond the first 50 were never updated and an archive performed on another device was never observed at all. `reconcilePatients()` now pages through active and archived patients, bounded to 40 pages per state, on startup, on manual refresh and at most every five minutes from the Realtime path.

**Other client fixes.** Assistants bind to a deterministically ordered doctor instead of an arbitrary row; the scheduling waitlist resolves patients from the server when they are not cached; PDF text direction follows the document language so a mixed-script line no longer flips; PDF numerals are normalized to Western digits.

**Deployed migration.** `supabase/migrations/20260916215601_clinic_amendment_queue_and_schedule_fixes.sql` was deployed to clinic-chatgpt-dev on 16 September 2026.

- Only the visit's own doctor may amend it. The deployed function checks the clinic doctor role only, so any active doctor can amend any completed visit — contrary to what this document and `README.md` previously claimed. Regression test included.
- A patient with the doctor can return to the queue or be cancelled. Previously the only exit from `withDoctor` was completing a visit with a diagnosis, so a mis-sent patient or a walkout held the doctor's only active slot indefinitely.
- An accepted `send` replays its stored receipt before the freshness and presence checks. The deployed wrapper checked expiry and presence first, so retrying an already-committed handoff reported a failure.
- An empty working-period list is rejected, and `settings_clear` returns to the unconfigured state. Saving an empty list silently closed the clinic to every booking with no way back.
- Stale presence leases and expired document access grants are pruned on the paths that create them. Leases referenced by an immutable receipt are retained so the receipt's foreign key holds.

**Not addressed.** The server still verifies only the size of an uploaded object, not its SHA-256, which is not computable in SQL. Orphaned Storage bytes from abandoned staging still cannot be removed — adding a delete path to clinical storage was judged too risky to do unprompted. A multi-doctor picker for assistants needs the server to expose doctor display names, which assistants cannot currently read.

## 12 September 2026 feature update

Arabic/English selection with RTL, duration-aware scheduling with weekly working periods/breaks and a cancellation waitlist, and bilingual printable visit documents are implemented locally. See `docs/bilingual-scheduling-printing.md` for usage and boundaries. Local cache schema is now v5; duration defaults to 30 minutes for existing appointments.

Verification: 48/48 Flutter tests and 28/28 backend tests passed. Workspace static analysis and the final document-file analysis passed; `git diff --check` passed. Both Android development debug APKs built successfully and were staged in `dist/android-dev/clinic-assistant-dev.apk` and `dist/android-dev/clinic-doctor-dev.apk`. Six fictional PDF samples were generated in both languages and visually inspected; mixed-direction Arabic text and page grouping were corrected.

**Deployment completed:** The user explicitly approved the development migration on 12 September 2026. `clinic_smart_scheduling` was applied to `clinic-chatgpt-dev` (`geikkygtnsgbtajyqdvc`) as version `20260912110955`. The local migration filename was aligned with the hosted version without changing the SQL. SHA-256: `226ACD93CDDFE9E4761E55E6ECF9595DE74DD4CC9C23CE7407250DC275FEBB4E`.

Hosted verification confirmed `appointments.duration_minutes` is a non-null integer defaulting to 30, the booking-validation trigger is enabled, the command persists durations, both new private tables have RLS and deny direct authenticated SELECT/INSERT, and the scheduling RPC permits authenticated calls while denying anonymous execution. Ten migrations are now deployed. Physical two-device scheduling acceptance remains outstanding.

Advisors: no security ERROR findings or performance WARN/ERROR findings. Private tables have intentional default-deny RLS INFO notices; unused-index INFO notices are expected. A separate Auth WARN reports disabled leaked-password protection; it was not changed by this migration. Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

Final APK SHA-256: Assistant `30151A2179972AF4EAD42BA696BBF2306E937A8DC9E05967D0EA54C8955DED42` (221,887,396 bytes); Doctor `418951F3B259EA81050C19F8A46C1CA9CB21D97A85DDCF10EB699757867C18F2` (254,489,608 bytes). These supersede the older artifact records below. No installation into existing devices was performed in this update.

The previously documented Auth, offline-delta and production-readiness limitations still apply. No production release or physical printer/iOS acceptance is claimed.

## Safety and target

- Use fictional development/test data only. This is not a production or compliance-approved clinical system.
- The only permitted hosted target is Supabase project **clinic-chatgpt-dev** (`geikkygtnsgbtajyqdvc`) in organization `wjekiplqybrqdvuxleub`, region `eu-west-1`.
- Never access or modify `clinicdb` (`zqzehmidtbqtxiudkbrg`) and never create another hosted project.
- Flutter receives only the ignored public URL and publishable key from `config/development.json`; privileged keys must never ship in a client.
- Deployed migrations are immutable. Every later database change requires a new timestamped migration.

## Completed

### Architecture and hosted database

- Separate Clinic Assistant and Clinic Doctor Flutter applications share `packages/clinic_core` and one clinic-isolated Supabase backend.
- Ten local migrations are deployed to the approved hosted project under matching versions:

| Version | Migration | SHA-256 |
|---|---|---|
| `20260828185721` | `clinic_foundation` | `8FD7A2FF398E9E2570BA05AED81E4668621A6F2C550790EF5FDD20DCC59E106D` |
| `20260828194057` | `clinic_staff_and_realtime` | `DBF2B47C30CBCB13098E2DE42F2BB572CE243ACB5F5216029EA1B567EB6B808B` |
| `20260828195423` | `clinic_membership_policy_initplan` | `F31C6120F0212963F8BC8D2D27EBAC5D31FAC42DD579500CBCFBA6BB74FB0E88` |
| `20260829014008` | `clinic_documents` | `875F41B25D933E3CEB917A915AF5EACA2F631C2758B5B1CC1D95753A557F7647` |
| `20260829014205` | `clinic_document_indexes` | `4C54B1C0EA6CB0642C9ABD8C547DFFD9CC729489ED0A99437FE65E46C49DFA5E` |
| `20260829023224` | `clinic_visit_indexes` | `D5A5305407442A83225DAF7B198C3F6F0CAA3FB0CE7F828A618F63A81D3A2C91` |
| `20260829093430` | `clinic_visit_amendments` | `4C988C91B0636D564E9CAC9E601B4D36F14A78E1B44554113A29461C277ABD31` |
| `20260829160124` | `clinic_doctor_delivery_receipts` | `807887A7C3850AA25BEDFB8061F1F06EC9CE10EB3D91DF533D9283ADF7BDC9F4` |
| `20260829160304` | `clinic_delivery_receipt_hardening` | `66CF9155A70D42590592EA36BE0A002541B9A2B71C6CA017D13A0A9A9CA509E1` |
| `20260912110955` | `clinic_smart_scheduling` | `226ACD93CDDFE9E4761E55E6ECF9595DE74DD4CC9C23CE7407250DC275FEBB4E` |

- Clinic membership IDs, RLS, restrictive grants, validated RPCs, idempotent operation receipts, private Storage policies, private security-definer implementations, public security-invoker wrappers, and Realtime invalidation enforce the current backend boundary.
- The latest hosted review found both new private delivery tables empty, RLS enabled, and no direct authenticated SELECT/INSERT privileges. Security advisors have no ERROR/WARN findings. Performance advisors have no unindexed foreign keys; unused-index INFO notices are expected in the empty development database.

### Application workflows

- Authentication entry, signup/verification messaging, app-specific signup and recovery redirects, secure session storage, clinic creation/selection, staff invitation/join, and doctor staff/access management.
- Patient create/edit/search/archive/restore, paginated local/hosted search, appointment scheduling, queue, current-patient handoff, clinical drafts, visit completion, and immutable visit history.
- Doctor-only, online, append-only completed-visit amendments with mandatory reason, bounded first-submission expiry, versioning, and exact idempotent replay.
- Private JPEG/PNG/WebP/PDF document pipeline with validation, SHA-256, encrypted staging, exact object paths, retry, audited read leases, preview/share, archive, and restore.
- Encrypted relational cache schema v4, account/clinic partitioning, durable outbox, exact replay, conflict review/recovery history, and authoritative shared-state confirmation.
- Eight-hour app-specific offline clinic-access lease in secure storage with project/app/user/clinic/role/capability binding, rollback checks, renewal after membership verification, and in-memory expiry locking.
- Distinct Assistant/Doctor recovery deep links, Android intent filters, iOS URL schemes, cold-start recovery-event binding, replacement-password validation, and requested global signout.
- Privacy-safe Doctor-admin audit/access review with safe columns, compact identifiers, Cairo timestamps, pagination, retry, and no clinical before/after payloads.
- Doctor device identity is generated as a protected persistent UUID. The Doctor app publishes a server-timestamped 60-second presence lease immediately and every 20 seconds while foregrounded, stopping when backgrounded.
- Assistant handoff now requires fresh presence. Server assignment and device receipt remain separate visible states. The assigned Doctor device must explicitly acknowledge the exact appointment/version before consultation opens; acknowledgement is authorized, idempotent, audited, immutable, and retained after completion.
- Android `FLAG_SECURE`, disabled backup and cleartext traffic, separate application IDs, and iOS project/privacy declarations.

### Verification completed

- The approved `clinic-chatgpt-dev` project now has a complete fictional test sequence named `Patient 01` through `Patient 100` in `Clinic-Test1`. On 2 September 2026, 98 missing rows (`Patient 03` through `Patient 100`) were inserted with synthetic demographics, digit-only non-routable test mobile values, a fictional address, and the marker `FICTIONAL-SEED-2026-09-02`. Verification found no missing name in the 1-100 sequence, and the seed marker identifies exactly 98 inserted rows. Existing records were preserved. Subsequent concurrent app activity advanced the live clinic total and its synchronized patient counter to `103`; this does not alter the 98-row seed set.

- Flutter: **45/45 tests pass** across domain, authorization lease, encrypted cache/repository, delivery presence/receipt, recovery, amendment, audit, accessibility/layout, and UI flows.
- Backend: **27/27 PGlite tests pass**, including presence-gated handoff, device binding, exact acknowledgement replay, immutable receipt retention, authorization, and audit behavior.
- Flutter static analysis: **clean**, no issues.
- Both development debug APKs were clean-built, installed on the emulator, and cold-started. Dart VM and Supabase initialization were observed without kernel/isolate errors. Each recovery scheme resolves only to its matching app.
- `ClinicAssistantDevice` emulator connectivity was repaired and reverified after a cold boot: ADB is online, `eth0` has `10.0.2.15/24` with gateway `10.0.2.2`, Android reports the network as `VALIDATED`, DNS resolves the configured Supabase host, and TCP 443 connects successfully. ICMP echo to public addresses is blocked upstream and is not used as the HTTPS health criterion. The existing Assistant debug APK was reinstalled and launched successfully on this AVD (PID observed).
- `ClinicDoctorDevice` received the same repair as a concurrent second emulator on `emulator-5556`: it was cold-booted without a snapshot using explicit DNS/network settings, its emulated data interface was reset until `eth0` acquired `10.0.2.15/24` and gateway `10.0.2.2`, Android reports the network as `VALIDATED`, DNS resolves the configured Supabase host, and TCP 443 connects successfully. Its AVD now persistently forces cold boot and disables fast snapshot boot, matching the repaired Assistant AVD. The updated Doctor debug APK was rebuilt, installed, launched, and observed foregrounded with PID `4529`; `ClinicAssistantDevice` remained online on `emulator-5554`.
- Hosted signup/email confirmation is now partially accepted: Auth logs show a successful signup request and confirmation email delivery, and `auth.users` contains one confirmed user with no unconfirmed users. The browser's later `localhost:3000` failure occurred only after successful confirmation because signup had omitted `emailRedirectTo`; signup now supplies the correct Assistant/Doctor mobile callback. The isolated auth callback test passes and Flutter analysis is clean. The broader screen-test file was also attempted, but its SQLite-dependent tests were blocked by a host native-asset loading failure unrelated to the auth change.

### GitHub source control

- The source is stored in the private repository [WaelGerges/clinic](https://github.com/WaelGerges/clinic), with local `main` tracking `origin/main`.
- The initial audited source upload excluded the development Supabase config, APK/AAB/ZIP artifacts, builds, IDE files, local databases, Android local properties, and signing credentials. No candidate file exceeded 25 MB; secret-pattern matches were documentation warnings only.
- The private [Clinic GitHub Project](https://github.com/users/WaelGerges/projects/1) is linked to the repository and contains five open issues matching the remaining implementation and validation workstreams.
- Final verification confirmed private repository/project visibility, remote `main` at the local commit, five Project items, and HTTP 404 for ignored remote paths `config/development.json` and `dist/`.
- Android Studio is configured to recognize the workspace root as Git through .idea/vcs.xml. GitHub CLI is registered as the secure Git credential helper for github.com; authenticated fetch and dry-run push both succeed for origin/main as WaelGerges.
Current debug artifacts:

| App | Bytes | APK SHA-256 | Generated/packaged kernel SHA-256 |
|---|---:|---|---|
| Assistant | 245,481,442 | `4946E6C59E0249239DCD7AB8D30911640908FB19B892AF0B212F74ECC9B91E64` | `267F461E04AE04629B89583DFE5765B7974202807200BF6D9E4BC3CAF1E56AEE` |
| Doctor | 205,384,461 | `2919019E76A133C39E9466D02222E95D53304B3E645CAC402FF879F1F3AB292D` | `9BD95C7B891992A974A252DE152BAB05F4D2341F0748DD5C73BF56B9813EFC0C` |

- Physical-device test packages are staged in `dist/android-dev/` as `clinic-assistant-dev.apk` and `clinic-doctor-dev.apk`. Both are development debug builds against the approved `clinic-chatgpt-dev` Supabase project. ADB currently sees only the two emulators; a physical phone has not yet been connected or authorized.
- Smaller ARM64 physical-device builds are staged for WhatsApp transfer in `dist/whatsapp/`. Assistant: APK 111.4 MB, SHA-256 `1DD78F21148089572C1561C913815A6729E7B49C7763297992D5632A533BA786`; ZIP 82.6 MB, SHA-256 `07EDC598DE6185A8BAECE7F8618DE41663EDA1E1876EC4DCA642AF23C96E0AF7`. Doctor: APK 111.4 MB, SHA-256 `CCC997F9DB866376AA092D4C0D62D91E624398C5925D78BB0760CEE2D7E7BE61`; ZIP 82.6 MB, SHA-256 `3FAC905C29E081B54B979746EF76D409FFA42A7D0E2934598EDA79EB1534719A`. These are debug-only ARM64 packages and are not signed production releases.

## Partially completed or requiring external validation
### Password recovery and hosted Auth

- Client and native routing code is complete.
- Supabase Auth Additional Redirect URLs still need the exact Assistant and Doctor callback URLs. Available database/Storage tooling exposes no Auth-settings mutation API, and the in-app browser had no signed-in Supabase dashboard session.
- The hosted default email sender delivered one confirmation email and the account confirmation succeeded. Custom SMTP, confirmation deep-link return into Android, a second owned test account, link expiry, password replacement, invitation acceptance, and cross-device session revocation remain unverified.

### Offline synchronization and authorization

- Encrypted cache, outbox, conflict recovery, bounded Realtime refresh, and the eight-hour authorization lease are implemented.
- A paginated durable delta feed/cursor and explicit tombstone coverage are not complete.
- Real-device process death, clock changes, secure-key loss, offline expiry, and post-revocation behavior are not fully tested.

### Audit and operations

- Mutation audit writes, document-read leases, appointment receipt audit, and Doctor-admin review exist.
- General record reads, login/session events, export/share events beyond document leases, and operational alerting are not fully logged or reviewable.
- MFA, broader device/session controls, monitoring, incident response, backup/restore, retention, privacy, and jurisdiction reviews remain release blockers.

### Release validation

- Android remains development-debug only; signing, distribution controls, and fail-closed release checks are incomplete.
- iOS has not been built, signed, or run because macOS/Xcode/signing are required.
- Load, failure, crash recovery, accessibility, backgrounding, low storage, real-device, and backup/restore testing remain incomplete.

## Remaining work, in priority order

1. Through an authorized signed-in Auth-settings interface, configure the two redirect URLs, then run same-device Android confirmation deep-link acceptance plus second-account invitation, recovery, expiry, and session-revocation acceptance.
2. Run two-device hosted acceptance for RLS isolation, staff invitation/revocation, Realtime invalidation, presence-gated queue handoff, explicit Doctor receipt/completion, amendments, documents, and revocation.
3. Implement paginated durable delta synchronization and explicit tombstones with cursor, authorization, crash/replay, and recovery tests.
4. Extend read/login/session/export audit coverage, operational alerting, MFA, and device/session controls.
5. Complete reliability, accessibility, real-device, release signing, iOS, backup/restore, retention, privacy/security, monitoring, and incident-response work.

## Exact next task

Configure these exact hosted Auth Additional Redirect URLs through a signed-in dashboard session: `dev.homeversion.clinic.assistant://auth-callback/` and `dev.homeversion.clinic.doctor://auth-callback/`. Then rebuild/relaunch both apps, open a fresh confirmation link on the same Android device that initiated signup, verify that the matching app receives the callback, and continue with two-account clinic creation/invitation acceptance. After hosted Auth acceptance, the next codebase task is the durable paginated delta/tombstone protocol described above.
