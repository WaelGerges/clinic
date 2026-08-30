-- Preserve membership visibility while evaluating the caller ID once per query.
-- The deployed foundation and staff migrations remain immutable.
alter policy membership_read on public.clinic_memberships
  using (
    clinic_private.allowed(clinic_id)
    and (
      user_id = (select auth.uid())
      or clinic_private.allowed(clinic_id, 'admin')
      or role = 'doctor'
    )
  );
