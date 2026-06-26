drop policy if exists "Admins can update affirmations" on public.affirmations;
create policy "Admins can update affirmations"
  on public.affirmations
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));
