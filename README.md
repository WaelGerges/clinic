# Clinic Assistant and Clinic Doctor

Two Flutter Android/iOS applications share a clinic domain package, encrypted relational cache, durable outbox, and Supabase adapters.

**Development system only. It is not production-ready and must contain fictional data only.** Passing local tests, a healthy Supabase project, and debug APKs do not establish clinical or regulatory readiness.

## Cloud target

The only permitted backend is **clinic-chatgpt-dev**, project `geikkygtnsgbtajyqdvc`, in Homeversion (`wjekiplqybrqdvuxleub`), `eu-west-1`. Never use or reset `clinicdb` (`zqzehmidtbqtxiudkbrg`) and do not create another project.

`config/development.json` contains the ignored public project URL and publishable key. No service-role, database, or administrator secret belongs in Flutter or a build argument.

Nine migrations are deployed: the foundation; staff invitations and Realtime publication; membership-policy query optimization; private document storage and indexes; visit indexes; immutable completed-visit amendments; and hardened Doctor presence/explicit appointment receipts. See [CONTINUE-HERE.md](CONTINUE-HERE.md) for versions, hashes, hosted checks, and remaining gates.

## Toolchain and commands

Use Flutter 3.47.2 stable / Dart 3.13.2 from the isolated SDK recorded in `CONTINUE-HERE.md`. The user's shared Flutter installation is incomplete and must not be reset or upgraded for this project.

```text
# repository root
flutter pub get
flutter analyze
npm test

# packages/clinic_core
flutter test
dart run build_runner build   # after Drift schema edits

# either app directory
flutter run --dart-define-from-file=../../config/development.json
flutter build apk --debug --dart-define-from-file=../../config/development.json
```

Debug builds without Supabase configuration expose a clearly labeled fictional local preview. Preview changes never reach Supabase. Release builds do not expose preview entry.

Android compiles against API 37.0 and supports API 24 or newer. Release signing is intentionally absent. iOS build, signing, and runtime validation require macOS/Xcode and the user's Apple credentials.

## Layout

- `apps/assistant` and `apps/doctor`: separate platform identities and entry points.
- `packages/clinic_core/lib/src/domain`: immutable entities and validation.
- `packages/clinic_core/lib/src/data`: encrypted Drift cache, outbox, repository, and Supabase gateway.
- `packages/clinic_core/lib/src/features`: Auth, patients, appointments, queue, visits, documents, staff, privacy-safe audit review, and sync/conflict UI.
- `supabase/migrations`: the exact versioned SQL deployed to the approved project.
- `backend-tests`: PGlite authorization/integrity tests with test-only Auth stubs.
- `docs`: architecture, API contract, designs, and historical review evidence.

## Implemented

- Email/password entry, registration, clinic creation/selection, verified-email invitation join, staff access controls, secure session storage, and per-app password-recovery callback handling.
- Patient create/edit/search/archive/restore, appointment workflow, atomic queue handoff, doctor workspace, consultations, diagnoses, prescriptions, and retained visit revisions.
- Doctor-only, append-only amendments of completed visits with mandatory reason, version checks, exact idempotent replay, and retained prior clinical rows.
- Clinic/account-specific encrypted cache, transactional outbox, bounded retry, visible conflict recovery, and periodic plus Realtime refresh.
- Private `clinic-documents` Storage pipeline for PDF/JPEG/PNG/WebP up to 20 MiB: encrypted local staging, exact upload/finalize replay, SHA-256 and magic-byte validation, 90-second audited access leases, preview/share, archive/restore, and retry.
- Doctor-admin-only paginated audit/access review that fetches actor/action/object/time fields without clinical before/after payloads.
- Foreground Doctor-device presence leases and explicit, immutable appointment receipt acknowledgement; Assistant handoff requires fresh presence and displays assignment separately from receipt.
- Android backup/cleartext disabled and sensitive-screen screenshot protection. Camera and photo-library usage descriptions are present on iOS.

The latest local result is 45/45 Flutter tests, 27/27 backend tests, clean static analysis, two successful clean development debug APK builds, and native Android cold-start/routing checks.

## Required before any real use

The two callback URLs still need to be added to Supabase Auth **Additional Redirect URLs**:

```text
dev.homeversion.clinic.assistant://auth-callback/
dev.homeversion.clinic.doctor://auth-callback/
```

Then SMTP/email delivery, recovery, invitations, RLS, Storage, Realtime, presence-gated queue handoff, explicit Doctor receipt, and completion must be tested with owned verified fictional accounts on separate devices. Other release blockers include real-device failure/rollback validation of the bounded offline lease and a durable delta/tombstone protocol; fuller read/login/session logging and operational audit coverage; MFA/device controls; load/failure testing; backup/restore and retention drills; signed Android/iOS releases; accessibility and real-device coverage; and Egyptian privacy/cross-border hosting review.

No real patient data should be entered.
