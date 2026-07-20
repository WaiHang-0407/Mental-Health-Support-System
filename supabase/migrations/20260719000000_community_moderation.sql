alter table public.comments
add column if not exists is_archived boolean not null default false;

alter table public.posts
add column if not exists archived_by uuid references public.users(id) on delete set null,
add column if not exists archived_reason text,
add column if not exists archived_at timestamptz;

alter table public.comments
add column if not exists archived_by uuid references public.users(id) on delete set null,
add column if not exists archived_reason text,
add column if not exists archived_at timestamptz;

alter table public.reports
add column if not exists resolution_action text,
add column if not exists resolution_note text,
add column if not exists resolved_at timestamptz;

create table if not exists public.user_warnings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  admin_id uuid references public.users(id) on delete set null,
  target_type text not null check (target_type in ('post', 'comment')),
  target_id uuid not null,
  reason text not null,
  description text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.user_warnings enable row level security;

drop policy if exists "Admins insert user warnings" on public.user_warnings;
create policy "Admins insert user warnings"
  on public.user_warnings
  for insert
  to authenticated
  with check (
    admin_id = auth.uid()
    and
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );

drop policy if exists "Admins view user warnings" on public.user_warnings;
create policy "Admins view user warnings"
  on public.user_warnings
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

drop policy if exists "Users view own warnings" on public.user_warnings;
create policy "Users view own warnings"
  on public.user_warnings
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Patients can soft delete own posts" on public.posts;
drop policy if exists "Patients and admins can update posts" on public.posts;
create policy "Patients and admins can update posts"
  on public.posts
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
    or (
      auth.uid() = patient_id
      and (
        archived_by is null
        or archived_by = auth.uid()
      )
    )
  )
  with check (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
    or (
      auth.uid() = patient_id
      and (
        archived_by is null
        or archived_by = auth.uid()
      )
    )
  );

drop policy if exists "Patients can soft delete own comments" on public.comments;
drop policy if exists "Patients and admins can update comments" on public.comments;
create policy "Patients and admins can update comments"
  on public.comments
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
    or (
      auth.uid() = patient_id
      and (
        archived_by is null
        or archived_by = auth.uid()
      )
    )
  )
  with check (
    exists (
      select 1
      from public.users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
    or (
      auth.uid() = patient_id
      and (
        archived_by is null
        or archived_by = auth.uid()
      )
    )
  );
