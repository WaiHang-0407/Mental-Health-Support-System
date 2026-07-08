create table if not exists public.activity_sponsorships (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  sponsorship_id uuid not null references public.sponsorships(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (activity_id, sponsorship_id)
);

insert into public.activity_sponsorships (activity_id, sponsorship_id)
select activity_id, id
from public.sponsorships
where activity_id is not null
on conflict (activity_id, sponsorship_id) do nothing;

alter table public.activity_sponsorships enable row level security;


drop policy if exists "Anyone can view activity sponsorships" on public.activity_sponsorships;
create policy "Anyone can view activity sponsorships"
  on public.activity_sponsorships
  for select
  using (true);

drop policy if exists "Admins create activity sponsorships" on public.activity_sponsorships;
create policy "Admins create activity sponsorships"
  on public.activity_sponsorships
  for insert
  to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists "Admins delete activity sponsorships" on public.activity_sponsorships;
create policy "Admins delete activity sponsorships"
  on public.activity_sponsorships
  for delete
  to authenticated
  using (public.is_admin(auth.uid()));
