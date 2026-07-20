create table if not exists public.daily_activities (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  duration_minutes integer,
  is_active boolean not null default true,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.daily_activities enable row level security;

drop policy if exists "Admins manage daily activities" on public.daily_activities;
create policy "Admins manage daily activities"
  on public.daily_activities
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );

drop policy if exists "Patients view active daily activities" on public.daily_activities;
create policy "Patients view active daily activities"
  on public.daily_activities
  for select
  to authenticated
  using (is_active = true);
