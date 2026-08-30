# Staff and realtime migration security review

**Decision: do not deploy this candidate.** A reproducible authorization issue allows an older invitation to undo staff revocation. No hosted changes were made during this review.

## Scope

- Candidate: `20260828190427_clinic_staff_and_realtime.sql`.
- SHA-256: `61458061A90A2C0AB416B52ACE550DC16914A037D534AB8EE2EB4265A97958AB`.
- Intended target: `clinic-chatgpt-dev` / `geikkygtnsgbtajyqdvc` only.
- Foundation prerequisite matches deployed SHA-256 `8FD7A2FF398E9E2570BA05AED81E4668621A6F2C550790EF5FDD20DCC59E106D`.
- Hosted preflight: ACTIVE_HEALTHY with only `20260828185721 clinic_foundation` in migration history.
- The frozen source was not edited. Local tests used an isolated copy of precisely these two migrations.

## P1 — An older invitation can restore revoked staff access

**Relevant candidate lines: 26–38, 53–61, and 80–89.**

`invite_assistant` permits an unused invitation to be issued to an existing active assistant. `set_staff_access` changes the membership but does not invalidate outstanding invitations. `join_clinic` then permits an inactive assistant membership to be reactivated using any otherwise valid invitation and copies its earlier clinical-read permission.

The independent local test performs this sequence through the application RPCs:

1. An assistant joins a fictional clinic normally.
2. The administrator issues another invitation to the same verified email and leaves it unused.
3. The administrator disables the assistant and removes clinical-read access. The membership is verified as `active=false, clinical_read=false`.
4. The disabled assistant redeems the older unused invitation.
5. The call succeeds, and the membership becomes `active=true, clinical_read=true`.

This bypasses the administrator's later revocation without a new invitation or access approval after the revocation. Email binding, expiry and single-use checks do not prevent this sequence.

### Required correction

Invalidate outstanding invitations affected by access revocation in the same clinic-locked transaction, or bind invitation validity to a membership revocation/version boundary. Rejecting invitations for already-active members can reduce the problem but should not be the only revocation safeguard. An explicitly issued fresh invitation after revocation may remain supported; an older token must not silently restore access or superseded clinical permissions.

Extend tests to verify the old token is rejected, membership remains disabled, and no successful-join audit entry is added. Also test an explicitly authorized fresh re-invitation and stale invitation permissions after staff access changes.

## Evidence

Command: `node --test backend-tests/clinic.test.mjs` from `C:/Users/WaelAmin/Documents/Codex/2026-08-28/supabase-plugin-supabase-openai-curated-remote/work/clinic-staff-review`.

Reproduction file: `backend-tests/clinic.test.mjs`, test beginning at line 268.

**Result: 14 tests, 13 passed, 1 failed.** The original combined suite passed. The additional assertion failed with:

```text
Pre-revocation invitation restored revoked access: {"active":true,"clinical_read":true}
```

All users and clinic fixtures were local and fictional. No application users, clinical records or invitations were created in the hosted project. No privileged credentials were shared.

## Pending

The candidate has not been applied, so no hosted version was assigned. Hosted grants, RPC behavior, realtime publication and post-deployment advisors for this migration remain unverified. The previously verified foundation remains deployed. `clinicdb`, paid services and private-table policies were not changed. No two-device integration is claimed.
