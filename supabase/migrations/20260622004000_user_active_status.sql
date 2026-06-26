alter table public.users
add column if not exists is_active boolean not null default true;

update public.users
set is_active = true
where is_active is null;

create or replace function public.is_admin(user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users
    where id = user_id
      and role = 'admin'
      and is_active = true
  );
$$;

drop policy if exists "Admins can update user status" on public.users;
create policy "Admins can update user status"
  on public.users
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));
