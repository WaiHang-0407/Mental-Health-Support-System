alter table public.activities
add column if not exists image_url text;

alter table public.activity_paths
add column if not exists cover_image_url text;

insert into storage.buckets (id, name, public)
values ('activity-images', 'activity-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Admins upload activity images" on storage.objects;
create policy "Admins upload activity images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'activity-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Admins update activity images" on storage.objects;
create policy "Admins update activity images"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'activity-images'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'activity-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Admins delete activity images" on storage.objects;
create policy "Admins delete activity images"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'activity-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Public view activity images" on storage.objects;
create policy "Public view activity images"
  on storage.objects
  for select
  to public
  using (bucket_id = 'activity-images');
