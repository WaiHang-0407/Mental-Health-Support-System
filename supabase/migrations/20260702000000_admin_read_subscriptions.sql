drop policy if exists "Admins can view all subscriptions" on public.subscriptions;
create policy "Admins can view all subscriptions"
  on public.subscriptions
  for select
  to authenticated
  using (public.is_admin(auth.uid()));
