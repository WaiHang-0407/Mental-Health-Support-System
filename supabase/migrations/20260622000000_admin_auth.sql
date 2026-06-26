create table if not exists public.admin_login_logs (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users(id) on delete set null,
  email text not null,
  event text not null,
  created_at timestamptz not null default now()
);

alter table public.admin_login_logs enable row level security;

drop policy if exists "Admins can add their own login logs" on public.admin_login_logs;
create policy "Admins can add their own login logs"
  on public.admin_login_logs
  for insert
  to authenticated
  with check (admin_id = auth.uid());

drop policy if exists "Admins can read their own login logs" on public.admin_login_logs;
create policy "Admins can read their own login logs"
  on public.admin_login_logs
  for select
  to authenticated
  using (admin_id = auth.uid());
