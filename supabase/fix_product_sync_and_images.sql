-- Reparacion de sincronizacion para productos e imagenes.
-- Ejecutar en Supabase SQL Editor con rol postgres.
--
-- Objetivo:
-- 1. Los empleados autenticados pueden leer el catalogo en cualquier equipo.
-- 2. Las ventas de empleados pueden actualizar stock en productos.
-- 3. Solo propietario crea o elimina productos desde la app.
-- 4. Las fotos del bucket product-images se pueden ver en todos los equipos.

alter table public.productos enable row level security;

drop policy if exists "productos authenticated read" on public.productos;
drop policy if exists "productos owner write" on public.productos;
drop policy if exists "productos owner update" on public.productos;
drop policy if exists "productos owner delete" on public.productos;
drop policy if exists "productos authenticated update" on public.productos;

create policy "productos authenticated read"
on public.productos for select to authenticated
using (true);

create policy "productos owner write"
on public.productos for insert to authenticated
with check (public.is_owner());

create policy "productos authenticated update"
on public.productos for update to authenticated
using (true)
with check (true);

create policy "productos owner delete"
on public.productos for delete to authenticated
using (public.is_owner());

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "product images authenticated read" on storage.objects;
drop policy if exists "product images authenticated insert" on storage.objects;
drop policy if exists "product images authenticated update" on storage.objects;
drop policy if exists "product images authenticated delete" on storage.objects;

create policy "product images authenticated read"
on storage.objects for select to authenticated
using (bucket_id = 'product-images');

create policy "product images authenticated insert"
on storage.objects for insert to authenticated
with check (bucket_id = 'product-images');

create policy "product images authenticated update"
on storage.objects for update to authenticated
using (bucket_id = 'product-images')
with check (bucket_id = 'product-images');

create policy "product images authenticated delete"
on storage.objects for delete to authenticated
using (bucket_id = 'product-images');
