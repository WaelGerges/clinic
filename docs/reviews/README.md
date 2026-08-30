# Historical review evidence

This directory preserves security-review records from the foundation and staff migrations. SQL copies inside review snapshots are evidence, not additional migrations and must not be applied.

- `clinic-foundation-security-review.md`: rejected historical foundation candidate; both findings were fixed before hosted deployment.
- `clinic-foundation-deployment-report.md`: successful foundation deployment/verification, hosted version `20260828185721`, immutable hash `8FD7A2FF398E9E2570BA05AED81E4668621A6F2C550790EF5FDD20DCC59E106D`.
- `clinic-staff-security-review.md`: rejected historical staff candidate whose invitations could outlive revocation.
- `staff-revised-snapshot`: independent review inputs/tests for corrected staff hash `DBF2B47C30CBCB13098E2DE42F2BB572CE243ACB5F5216029EA1B567EB6B808B`.

The corrected staff/realtime migration was subsequently deployed as hosted version `20260828194057`, followed by the policy optimization, document pipeline/indexes, visit indexes, and completed-visit amendment migrations listed in the root handoff. The historical reports have not been rewritten; their statements about the earlier pause describe that point in time only.

Current deployment and verification status is maintained in `../../CONTINUE-HERE.md`. Local or PGlite review evidence is not hosted Auth, Storage, Realtime, two-device, or production verification.
