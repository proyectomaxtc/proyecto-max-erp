-- Perfiles iniciales de propietarios.
-- Ejecutar en Supabase SQL Editor despues de crear los usuarios en Authentication.

insert into public.user_profiles (
  auth_id,
  app_user_id,
  nombre,
  rol,
  sucursal,
  activo
) values
(
  'dc31d4c1-491f-45ba-a748-ac8fe3526536',
  'owner',
  'Propietario 1',
  'Propietario',
  'Casa Central Santa Fe',
  true
),
(
  '761118f3-da5e-4854-aec9-2a591ba4976b',
  'owner-2',
  'Propietario 2',
  'Propietario',
  'Casa Central Santa Fe',
  true
) on conflict (auth_id) do update set
  app_user_id = excluded.app_user_id,
  nombre = excluded.nombre,
  rol = excluded.rol,
  sucursal = excluded.sucursal,
  activo = excluded.activo;
