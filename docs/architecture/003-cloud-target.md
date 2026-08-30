# Development cloud target

Approved target as of 29 August 2026:

- Project: `clinic-chatgpt-dev`
- Organization: Homeversion (`wjekiplqybrqdvuxleub`)
- Project reference: `geikkygtnsgbtajyqdvc`
- Region: `eu-west-1`
- URL: `https://geikkygtnsgbtajyqdvc.supabase.co`
- Provisioned cost: USD 0/month
- Dashboard: <https://supabase.com/dashboard/project/geikkygtnsgbtajyqdvc>

The ignored development configuration contains only the publishable client key. No privileged key is embedded in either app.

## Deployed migrations

The project has nine matching hosted/local versions:

1. `20260828185721_clinic_foundation.sql`
2. `20260828194057_clinic_staff_and_realtime.sql`
3. `20260828195423_clinic_membership_policy_initplan.sql`
4. `20260829014008_clinic_documents.sql`
5. `20260829014205_clinic_document_indexes.sql`
6. `20260829023224_clinic_visit_indexes.sql`
7. `20260829093430_clinic_visit_amendments.sql`
8. `20260829160124_clinic_doctor_delivery_receipts.sql`
9. `20260829160304_clinic_delivery_receipt_hardening.sql`

They provide clinic/RLS foundations, invitation and staff controls, application-owned Realtime publication, query/index improvements, private Storage authorization with audited access leases, append-only completed-visit amendments, and hardened Doctor-device presence/explicit appointment receipts. Exact hashes and verification results are in `../../CONTINUE-HERE.md`.

The last read-only check found no Auth users or application records. The presence and receipt tables are empty, RLS-enabled, and deny direct authenticated reads/writes. Security advisors reported no ERROR/WARN findings; remaining INFO findings are intentional default-deny private tables with RLS and no client policies. Performance advisors reported no unindexed foreign keys. Unused-index INFO findings are expected on the empty database and must be reassessed with representative fictional volume rather than removed blindly.

## Hosted configuration and acceptance gaps

The private `clinic-documents` bucket and policies are deployed, but no authenticated hosted file upload/download has been run. Realtime publication and presence/receipt RPCs are deployed, but no authenticated two-device handoff/acknowledgement has been verified. No hosted Auth account was created by this work.

Password-recovery code expects these Additional Redirect URLs, which are not yet configured:

```text
dev.homeversion.clinic.assistant://auth-callback/
dev.homeversion.clinic.doctor://auth-callback/
```

SMTP/email delivery, invitation flow, recovery, RLS/Storage/Realtime behavior, queue concurrency, and revocation must be validated with owned verified fictional accounts. Project health, local PGlite tests, and successful migrations do not establish those outcomes.

The existing `clinicdb` (`zqzehmidtbqtxiudkbrg`) is excluded. Never link, migrate, query, or reset it, and do not create a duplicate project.
