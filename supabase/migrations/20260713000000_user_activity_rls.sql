drop policy if exists "Users view active community activities" on public.activities;
create policy "Users view active community activities"
  on public.activities
  for select
  to authenticated
  using (
    coalesce(is_deleted, false) = false
    and coalesce(is_archived, false) = false
  );

drop policy if exists "Users view active activity registrations" on public.activity_registrations;
create policy "Users view active activity registrations"
  on public.activity_registrations
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.activities a
      where a.id = activity_registrations.activity_id
        and coalesce(a.is_deleted, false) = false
        and coalesce(a.is_archived, false) = false
    )
  );
