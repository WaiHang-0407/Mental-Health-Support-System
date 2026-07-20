create table if not exists public.admin_activity_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.users(id) on delete set null,
  action text not null,
  target_type text,
  target_id uuid,
  created_at timestamptz not null default now()
);

alter table public.admin_activity_logs enable row level security;

drop policy if exists "Admins insert admin activity logs" on public.admin_activity_logs;
create policy "Admins insert admin activity logs"
  on public.admin_activity_logs
  for insert
  to authenticated
  with check (
    admin_id = auth.uid()
    and exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );

drop policy if exists "Admins view admin activity logs" on public.admin_activity_logs;
create policy "Admins view admin activity logs"
  on public.admin_activity_logs
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );
