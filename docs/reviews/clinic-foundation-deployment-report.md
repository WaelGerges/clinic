# Clinic foundation deployment

**Status: deployed and verified for development.** The two findings from the previous review are corrected. This is not an end-to-end application or production-readiness approval.

## Exact deployment

| Item | Verified value |
|---|---|
| Organization | Homeversion |
| Project | clinic-chatgpt-dev |
| Project reference | geikkygtnsgbtajyqdvc |
| Reviewed source file | 20260828180143_clinic_foundation.sql |
| Source SHA-256 | 8FD7A2FF398E9E2570BA05AED81E4668621A6F2C550790EF5FDD20DCC59E106D |
| Hosted migration name | clinic_foundation |
| Hosted migration version | 20260828185721 |
| Migration tool result | success: true |

The source hash was checked again immediately before applying its exact contents. Hosted migration history contains this one migration. No staff/realtime or other migration was applied. The existing clinicdb project was not changed.

**Migration tracking:** the MCP tool assigned the hosted version above, which differs from the source filename timestamp. Reconcile local filename/history tracking with the hosted version before a later CLI push; do not reapply the foundation. No remote history repair was performed here.

## Local verification

- Twelve foundation tests passed against an isolated copy containing only this migration. The staff invitation test was explicitly skipped because it belongs to the separate, undeployed migration.
- Three independent regression tests passed: new-visit patient mismatch rejection, existing-visit appointment/patient mismatch rejection, and denial of audit-sequence reset by both client database roles.
- Tests reproduced the target's actual default privileges for public tables/views, functions and sequences.
- Missing, null and mismatched visit identities are rejected without changing visits, revisions, audit events or operation receipts. Both setval and nextval are denied for anon/authenticated in the updated foundation suite.

## Hosted verification

| Check | Result |
|---|---|
| Application tables | 11 public and 2 clinic_private tables; RLS enabled on all 13 |
| Public table policies | 11 SELECT policies for authenticated, scoped by clinic membership and relevant clinical/admin permissions |
| Anonymous table/view access | No privileges on the application tables or visit_details |
| Authenticated direct access | SELECT only on public application tables/view; no direct writes |
| Private table access | Neither anon nor authenticated has direct read/write privileges |
| Audit identity sequence | Neither client role has SELECT, UPDATE or USAGE |
| visit_details | security_invoker=true; authenticated SELECT only |
| Database functions | Privileged implementations in clinic_private; public wrappers/search use invoker rights; empty search_path; no anonymous EXECUTE |
| Hosted role smoke test | Anonymous reads/create and nonmember commands denied; nonmember application reads return no records |
| REST patient read with publishable key and no user session | HTTP 401, SQLSTATE 42501, permission denied |
| REST request targeting clinic_private | HTTP 406, PGRST106, invalid schema |
| Clinical records | No clinic or patient records created; exact clinic/patient/audit counts remain zero |

Role smoke checks used transaction-scoped simulated claims and rolled back. They did not create application users or patient data. The REST checks used only the public client key; no privileged credentials were shared.

## Security advisors

**0 ERROR, 0 WARN, 2 INFO notices.** Both are `rls_enabled_no_policy`:

- clinic_private.operation_receipts
- clinic_private.patient_counters

These tables intentionally have no client policies or grants and are accessed by the checked private command functions. REST confirms that clinic_private is not an exposed schema. No permissive policies were added merely to silence the notices. [Supabase notice and remediation guidance](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## Remaining work

- Reconcile the local migration timestamp with the actual hosted version before future CLI deployments.
- The separate staff invitation/realtime migration remains undeployed and unreviewed here.
- Storage workflows, authenticated mobile-app integration, real-session authorization tests, offline synchronization and end-to-end clinic workflows are not established by this deployment.
- Continue using fictional data until the separate production security and privacy requirements are satisfied.
