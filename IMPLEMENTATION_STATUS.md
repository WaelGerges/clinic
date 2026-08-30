# Clinic Apps — Implementation Status

Last updated: 30 August 2026

This is the persistent execution checkpoint. Update it whenever work changes state, verification changes, and before stopping. `CONTINUE-HERE.md` contains the broader architecture and operating context.

## Safety and target

- Use fictional development/test data only. This is not a production or compliance-approved clinical system.
- The only permitted hosted target is Supabase project **clinic-chatgpt-dev** (`geikkygtnsgbtajyqdvc`) in organization `wjekiplqybrqdvuxleub`, region `eu-west-1`.
- Never access or modify `clinicdb` (`zqzehmidtbqtxiudkbrg`) and never create another hosted project.
- Flutter receives only the ignored public URL and publishable key from `config/development.json`; privileged keys must never ship in a client.
- Deployed migrations are immutable. Every later database change requires a new timestamped migration.

## Completed

### Architecture and hosted database

- Separate Clinic Assistant and Clinic Doctor Flutter applications share `packages/clinic_core` and one clinic-isolated Supabase backend.
- Nine local migrations are deployed to the approved hosted project under matching versions:

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

- Flutter: **45/45 tests pass** across domain, authorization lease, encrypted cache/repository, delivery presence/receipt, recovery, amendment, audit, accessibility/layout, and UI flows.
- Backend: **27/27 PGlite tests pass**, including presence-gated handoff, device binding, exact acknowledgement replay, immutable receipt retention, authorization, and audit behavior.
- Flutter static analysis: **clean**, no issues.
- Both development debug APKs were clean-built, installed on the emulator, and cold-started. Dart VM and Supabase initialization were observed without kernel/isolate errors. Each recovery scheme resolves only to its matching app.
- `ClinicAssistantDevice` emulator connectivity was repaired and reverified after a cold boot: ADB is online, `eth0` has `10.0.2.15/24` with gateway `10.0.2.2`, Android reports the network as `VALIDATED`, DNS resolves the configured Supabase host, and TCP 443 connects successfully. ICMP echo to public addresses is blocked upstream and is not used as the HTTPS health criterion. The existing Assistant debug APK was reinstalled and launched successfully on this AVD (PID observed).
- `ClinicDoctorDevice` received the same repair as a concurrent second emulator on `emulator-5556`: it was cold-booted without a snapshot using explicit DNS/network settings, its emulated data interface was reset until `eth0` acquired `10.0.2.15/24` and gateway `10.0.2.2`, Android reports the network as `VALIDATED`, DNS resolves the configured Supabase host, and TCP 443 connects successfully. Its AVD now persistently forces cold boot and disables fast snapshot boot, matching the repaired Assistant AVD. The updated Doctor debug APK was rebuilt, installed, launched, and observed foregrounded with PID `4529`; `ClinicAssistantDevice` remained online on `emulator-5554`.
- Hosted signup/email confirmation is now partially accepted: Auth logs show a successful signup request and confirmation email delivery, and `auth.users` contains one confirmed user with no unconfirmed users. The browser's later `localhost:3000` failure occurred only after successful confirmation because signup had omitted `emailRedirectTo`; signup now supplies the correct Assistant/Doctor mobile callback. The isolated auth callback test passes and Flutter analysis is clean. The broader screen-test file was also attempted, but its SQLite-dependent tests were blocked by a host native-asset loading failure unrelated to the auth change.

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

