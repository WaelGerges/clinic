# Clinic apps — continuation checkpoint

Updated 29 August 2026 after direct implementation, hosted migrations, Android runtime checks, and documentation reconciliation. Continue in `C:\waelg\projects\clinic-chatgpt`; this directory is the source of truth. Do not republish an older staging copy over it.

## Non-negotiable guardrails

- Development and tests use fictional data only. This is not a production or compliance-approved clinical system.
- The only permitted Supabase target is **clinic-chatgpt-dev** (`geikkygtnsgbtajyqdvc`), Homeversion (`wjekiplqybrqdvuxleub`), `eu-west-1`.
- Never touch `clinicdb` (`zqzehmidtbqtxiudkbrg`) and never create another project.
- The mobile apps use only the ignored public URL/publishable key from `config/development.json`. Never add a service-role or database secret.
- Preserve versioned migrations and lockfiles. A deployed migration is immutable; further SQL changes require a new timestamped migration.

## Product and architecture

There are separate Clinic Assistant and Clinic Doctor apps with one shared Flutter package and one centralized, clinic-isolated backend. Doctors administer a clinic and author clinical records. Assistants manage demographics, scheduling, queue, and permitted documents; clinical read is explicit. Clinic membership UUIDs, RLS, validated RPCs, and Storage policies enforce isolation. Egypt scheduling uses `Africa/Cairo` independently of the device time zone.

The cache is encrypted and separated by account/clinic. Supabase Realtime is an invalidation signal; it is not treated as an offline database. Shared queue/visit actions require authoritative confirmation and exact operation IDs.

## Hosted database state

All local migrations below are deployed to the approved project under the matching hosted version. Do not reapply them.

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

The last hosted verification found no Auth users or application records; the new presence and receipt tables are empty, RLS-enabled, and have no direct authenticated read/write privileges. Security advisors have no ERROR/WARN findings. The remaining INFO notices are intentional default-deny private tables with no client policies. Performance advisors have no unindexed foreign keys; remaining INFO findings are unused indexes on the empty development database.

Private document bytes use the non-public `clinic-documents` bucket. Storage writes require exact pending metadata/path/actor checks. Reads require current authorization plus a 90-second audited lease. Metadata, digest, size, clinic/patient/visit identity, and object existence are rechecked around upload/download/finalization.

Completed visit amendments route through `public.clinic_apply_command` to a search-path-locked private security-definer function. Only the assigned doctor can amend a completed visit. The request is online-only, versioned, expires if first submitted after one minute, requires a 10–1000 character reason and a diagnosis, returns exact idempotent replay, appends a new revision, and retains old revisions/diagnoses/prescriptions/items.

Doctor devices use a protected persistent UUID and publish a server-timestamped 60-second presence lease immediately and every 20 seconds while foregrounded. Assistant handoff requires a fresh lease. Assignment and explicit receipt are separate server states: the assigned Doctor device must acknowledge the exact appointment/version before consultation opens. Receipts are clinic/doctor/device-bound, idempotent, immutable, retained, and audited. Privileged implementations live in `clinic_private`; exposed public RPCs are security-invoker wrappers.

## Implemented client behavior

- Auth entry, signup/verification message, secure session storage, clinic creation/selection, invitation join, and doctor staff/access management.
- Password reset requests include distinct Assistant/Doctor callback URLs. Android intent filters and iOS URL schemes are registered. A controller binds during Supabase initialization so cold-start `passwordRecovery` events cannot be missed. The replacement password is confirmed and validated at 12–72 characters, then the app requests global sign-out and requires a fresh login.
- Patient create/edit/search/archive/restore; paginated local and hosted search; appointments, queue, current-patient workspace, clinical drafts/completion, immutable history, and doctor-only amendment UI.
- Encrypted relational cache schema v4, durable outbox, exact replay, visible patient conflict review/recovery history, and no optimistic shared-state success.
- Documents from camera/gallery/files with metadata, magic-byte/type/size validation, encrypted durable staging, upload retry, safe local/remote preview, guarded share, archive/restore, and pending/failed status.
- Doctor-admin-only paginated audit/access review with explicit safe columns, compact identifiers, Cairo timestamps, and no raw clinical before/after payloads.
- Foreground Doctor-device presence, presence-gated handoff, explicit immutable receipt acknowledgement, and distinct Assistant assignment/receipt states.
- Android `FLAG_SECURE`, disabled backups and cleartext, and separate application IDs. iOS projects and privacy strings exist but have not been built on macOS.

## Password recovery configuration still required

The code and native routes are implemented, but Supabase Auth must allow these exact URLs under **Authentication → URL Configuration → Additional Redirect URLs**:

```text
dev.homeversion.clinic.assistant://auth-callback/
dev.homeversion.clinic.doctor://auth-callback/
```

This environment exposed database/Storage migration tools but no Auth-settings mutation API or usable dashboard-control runtime, so the allowlist was not changed. Do not call recovery end to end complete until the allowlist, SMTP delivery, an owned verified account, link expiry, password update, and cross-device session revocation have been tested.

## Latest verification

| Check | Result |
|---|---|
| Flutter tests | 45/45 pass across domain, secure access-lease, encrypted-cache/repository, recovery, amendment, audit, presence/receipt, accessibility/layout, and screen flows |
| Backend tests | 27/27 PGlite tests pass across default ACLs, isolation, staff revocation, commands, documents, amendments, and Doctor presence/receipt |
| Static analysis | Clean after the presence/receipt implementation |
| Hosted schema | Nine matching migrations deployed; no hosted application data created |
| Advisors | No security ERROR/WARN; no unindexed foreign keys |
| Android builds | Assistant and Doctor debug APKs built with `config/development.json` |
| Android runtime | Both clean-rebuilt APKs freshly installed and cold-started; Dart VM/Supabase initialization confirmed without kernel/isolate errors; both custom callback schemes routed to their own activity; Assistant document selection/staging/PDF preview was previously exercised with a fictional file |
| Authenticated cloud workflow | Not tested; no owned verified test accounts were created |
| iOS | Not built or run; macOS/Xcode/signing required |

Current debug APKs:

| App | Path | Bytes | SHA-256 |
|---|---|---:|---|
| Assistant | `apps/assistant/build/app/outputs/flutter-apk/app-debug.apk` | 205,384,648 | `1446C6E236524D31E2B1AB61B9304522FBA004FD587DC2D3F370686928171A99` |
| Doctor | `apps/doctor/build/app/outputs/flutter-apk/app-debug.apk` | 205,384,999 | `D574D4C4D6C89AB9831A4A397B166A8765AAAC34076597DE2E13B9F552B11CD1` |

These are development debug binaries, not release artifacts.

## Toolchain

- Flutter bat: `C:\Users\WaelAmin\Documents\Codex\2026-08-28\act-as-a-senior-software-architect\work\flutter-stable\bin\flutter.bat`
- Dart exe: `C:\Users\WaelAmin\Documents\Codex\2026-08-28\act-as-a-senior-software-architect\work\flutter-stable\bin\cache\dart-sdk\bin\dart.exe`
- Flutter 3.47.2 stable / Dart 3.13.2.
- Android SDK: `C:\Users\WaelAmin\AppData\Local\Android\Sdk`; API 37.0, minSdk 24; Android Studio JDK.
- The isolated SDK and its caches live outside this workspace, so format/analyze/test/build commands may need sandbox approval. Direct `dart.exe` is more reliable than its batch wrapper here.
- Do not reset, upgrade, or repair the user's shared `C:\flutter\flutter` installation.

## Remaining release blockers

1. Configure the two hosted Auth redirect URLs and validate signup/verification/recovery/invitation using owned verified fictional accounts.
2. Run two-device hosted acceptance for RLS, invitations/revocation, Realtime, queue handoff/completion, amendments, document upload/read/share/archive, and session revocation.
3. Validate the eight-hour cold-start authorization lease under real-device clock changes, process death, key loss, and revocation, and complete paginated delta/tombstone synchronization. Current outbox/conflict recovery is useful but not a complete offline protocol.
4. Extend the implemented administrator audit review with fuller read/login/session logging, MFA/device controls, and operational alerting.
5. Complete load, failure, crash-recovery, accessibility, backgrounding, low-storage, and real-device tests.
6. Perform backup/restore and retention drills; privacy/security review for Egypt and cross-border hosting; production monitoring and incident procedures.
7. Configure signed Android releases and build/sign/test iOS on macOS. Release encryption and privacy controls must fail closed.

Do not claim the whole project complete based on the implemented UI, deployed migrations, local emulator checks, or current test counts.
