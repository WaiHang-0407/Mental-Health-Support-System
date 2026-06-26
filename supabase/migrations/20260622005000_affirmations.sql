create table if not exists public.affirmations (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  created_by uuid references public.users(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.affirmations enable row level security;

drop policy if exists "Admins can view affirmations" on public.affirmations;
create policy "Admins can view affirmations"
  on public.affirmations
  for select
  to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists "Admins can create affirmations" on public.affirmations;
create policy "Admins can create affirmations"
  on public.affirmations
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins can update affirmations" on public.affirmations;
create policy "Admins can update affirmations"
  on public.affirmations
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "Authenticated users can view active affirmations" on public.affirmations;
create policy "Authenticated users can view active affirmations"
  on public.affirmations
  for select
  to authenticated
  using (is_active = true);
