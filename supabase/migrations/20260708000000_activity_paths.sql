create table if not exists public.activity_paths (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  is_archived boolean not null default false,
  is_deleted boolean not null default false,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.activity_path_pages (
  id uuid primary key default gen_random_uuid(),
  activity_path_id uuid not null references public.activity_paths(id) on delete cascade,
  page_number integer not null,
  title text,
  body text not null default '',
  created_at timestamptz not null default now(),
  unique (activity_path_id, page_number)
);

create table if not exists public.activity_path_page_images (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.activity_path_pages(id) on delete cascade,
  image_url text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.user_activity_paths (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  activity_path_id uuid not null references public.activity_paths(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, activity_path_id)
);

alter table public.activity_paths enable row level security;
alter table public.activity_path_pages enable row level security;
alter table public.activity_path_page_images enable row level security;
alter table public.user_activity_paths enable row level security;

drop policy if exists "Admins manage activity paths" on public.activity_paths;
create policy "Admins manage activity paths"
  on public.activity_paths
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "Users view active activity paths" on public.activity_paths;
create policy "Users view active activity paths"
  on public.activity_paths
  for select
  to authenticated
  using (not is_deleted and not is_archived);

drop policy if exists "Admins manage activity path pages" on public.activity_path_pages;
create policy "Admins manage activity path pages"
  on public.activity_path_pages
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "Users view active activity path pages" on public.activity_path_pages;
create policy "Users view active activity path pages"
  on public.activity_path_pages
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.activity_paths
      where activity_paths.id = activity_path_pages.activity_path_id
        and not activity_paths.is_deleted
        and not activity_paths.is_archived
    )
  );

drop policy if exists "Admins manage activity path page images" on public.activity_path_page_images;
create policy "Admins manage activity path page images"
  on public.activity_path_page_images
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists "Users view active activity path page images" on public.activity_path_page_images;
create policy "Users view active activity path page images"
  on public.activity_path_page_images
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.activity_path_pages
      join public.activity_paths
        on activity_paths.id = activity_path_pages.activity_path_id
      where activity_path_pages.id = activity_path_page_images.page_id
        and not activity_paths.is_deleted
        and not activity_paths.is_archived
    )
  );

drop policy if exists "Admins view user activity paths" on public.user_activity_paths;
create policy "Admins view user activity paths"
  on public.user_activity_paths
  for select
  to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists "Users manage own activity path selections" on public.user_activity_paths;
create policy "Users manage own activity path selections"
  on public.user_activity_paths
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('activity-path-images', 'activity-path-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Admins upload activity path images" on storage.objects;
create policy "Admins upload activity path images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'activity-path-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Admins update activity path images" on storage.objects;
create policy "Admins update activity path images"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'activity-path-images'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'activity-path-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Admins delete activity path images" on storage.objects;
create policy "Admins delete activity path images"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'activity-path-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Public view activity path images" on storage.objects;
create policy "Public view activity path images"
  on storage.objects
  for select
  to public
  using (bucket_id = 'activity-path-images');
