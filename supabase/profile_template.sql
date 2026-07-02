-- Reemplazar los valores antes de ejecutar.
-- El auth_id se copia desde Supabase > Authentication > Users > User UID.

insert into public.user_profiles (
  auth_id,
  app_user_id,
  nombre,
  rol,
  sucursal,
  activo
) values (
  '00000000-0000-0000-0000-000000000000',
  'owner',
  'Propietario',
  'Propietario',
  'Casa Central Santa Fe',
  true
) on conflict (auth_id) do update set
  app_user_id = excluded.app_user_id,
  nombre = excluded.nombre,
  rol = excluded.rol,
  sucursal = excluded.sucursal,
  activo = excluded.activo;
