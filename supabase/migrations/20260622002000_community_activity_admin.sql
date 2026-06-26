alter table public.activities
add column if not exists registration_deadline timestamptz;

drop policy if exists "Admins view activity registrations" on public.activity_registrations;
create policy "Admins view activity registrations"
  on public.activity_registrations
  for select
  to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists "Admins create activities" on public.activities;
create policy "Admins create activities"
  on public.activities
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins update activities" on public.activities;
create policy "Admins update activities"
  on public.activities
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins create sponsorships" on public.sponsorships;
create policy "Admins create sponsorships"
  on public.sponsorships
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins update sponsorships" on public.sponsorships;
create policy "Admins update sponsorships"
  on public.sponsorships
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins create sponsorship products" on public.sponsorship_products;
create policy "Admins create sponsorship products"
  on public.sponsorship_products
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins update sponsorship products" on public.sponsorship_products;
create policy "Admins update sponsorship products"
  on public.sponsorship_products
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));
