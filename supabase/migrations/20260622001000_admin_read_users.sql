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
  );
$$;

drop policy if exists "Admins can view all users" on public.users;
create policy "Admins can view all users"
  on public.users
  for select
  to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists "Admins can view all patients" on public.patients;
create policy "Admins can view all patients"
  on public.patients
  for select
  to authenticated
  using (public.is_admin(auth.uid()));
