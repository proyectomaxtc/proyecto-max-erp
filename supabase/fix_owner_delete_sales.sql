-- Ejecutar en Supabase SQL Editor si el propietario no puede borrar ventas.
-- Hace que el rol propietario funcione aunque este guardado como "propietario",
-- "Propietario " u otra variante con espacios/mayusculas.

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_profiles
    where auth_id = auth.uid()
      and activo = true
      and lower(trim(rol)) = 'propietario'
  )
$$;

update public.user_profiles
set rol = 'Propietario'
where lower(trim(rol)) = 'propietario';
