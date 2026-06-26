insert into storage.buckets (id, name, public)
values ('sponsorship-product-images', 'sponsorship-product-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Admins upload sponsorship product images" on storage.objects;
create policy "Admins upload sponsorship product images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'sponsorship-product-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Admins update sponsorship product images" on storage.objects;
create policy "Admins update sponsorship product images"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'sponsorship-product-images'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'sponsorship-product-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Admins delete sponsorship product images" on storage.objects;
create policy "Admins delete sponsorship product images"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'sponsorship-product-images'
    and public.is_admin(auth.uid())
  );

drop policy if exists "Public view sponsorship product images" on storage.objects;
create policy "Public view sponsorship product images"
  on storage.objects
  for select
  to public
  using (bucket_id = 'sponsorship-product-images');
