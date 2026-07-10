-- Ejecutar en Supabase SQL Editor si el propietario no puede borrar ventas.
-- Borra la venta y el movimiento de caja asociado en una sola operacion.

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
      and lower(trim(rol)) in ('propietario', 'administrador', 'owner')
  )
$$;

create or replace function public.delete_venta_owner(venta_id text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer := 0;
begin
  if not public.is_owner() then
    raise exception 'Solo el propietario puede eliminar ventas';
  end if;

  delete from public.caja
  where id = venta_id || '-caja';

  delete from public.ventas
  where id = venta_id;

  get diagnostics deleted_count = row_count;

  if deleted_count = 0 then
    raise exception 'No se encontro la venta para eliminar';
  end if;

  return deleted_count;
end;
$$;

grant execute on function public.delete_venta_owner(text) to authenticated;
