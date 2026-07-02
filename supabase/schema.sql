create table if not exists public.usuarios (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.clientes (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.productos (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.ventas (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.compras (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.servicios (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.caja (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.caja_turnos (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.configuracion (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.notificaciones (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_profiles (
  auth_id uuid primary key references auth.users(id) on delete cascade,
  app_user_id text unique not null,
  nombre text not null,
  rol text not null check (rol in ('Propietario', 'Empleado')),
  sucursal text not null,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.usuarios enable row level security;
alter table public.clientes enable row level security;
alter table public.productos enable row level security;
alter table public.ventas enable row level security;
alter table public.compras enable row level security;
alter table public.servicios enable row level security;
alter table public.caja enable row level security;
alter table public.caja_turnos enable row level security;
alter table public.configuracion enable row level security;
alter table public.notificaciones enable row level security;
alter table public.user_profiles enable row level security;

create or replace function public.current_user_profile()
returns public.user_profiles
language sql
stable
security definer
set search_path = public
as $$
  select *
  from public.user_profiles
  where auth_id = auth.uid()
    and activo = true
  limit 1
$$;

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
      and rol = 'Propietario'
  )
$$;

create or replace function public.current_branch()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select sucursal
  from public.user_profiles
  where auth_id = auth.uid()
    and activo = true
  limit 1
$$;

create policy "profile owner or self read"
on public.user_profiles for select to authenticated
using (public.is_owner() or auth_id = auth.uid());

create policy "profile owner insert"
on public.user_profiles for insert to authenticated
with check (public.is_owner());

create policy "profile owner update"
on public.user_profiles for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "profile owner delete"
on public.user_profiles for delete to authenticated
using (public.is_owner());

create policy "usuarios owner or self read"
on public.usuarios for select to authenticated
using (public.is_owner() or data->>'authId' = auth.uid()::text);

create policy "usuarios owner insert"
on public.usuarios for insert to authenticated
with check (public.is_owner());

create policy "usuarios owner update"
on public.usuarios for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "usuarios owner delete"
on public.usuarios for delete to authenticated
using (public.is_owner());

create policy "clientes authenticated read"
on public.clientes for select to authenticated
using (true);

create policy "clientes authenticated insert"
on public.clientes for insert to authenticated
with check (true);

create policy "clientes authenticated update"
on public.clientes for update to authenticated
using (true)
with check (true);

create policy "clientes owner delete"
on public.clientes for delete to authenticated
using (public.is_owner());

create policy "productos authenticated read"
on public.productos for select to authenticated
using (true);

create policy "productos owner write"
on public.productos for insert to authenticated
with check (public.is_owner());

create policy "productos owner update"
on public.productos for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "productos owner delete"
on public.productos for delete to authenticated
using (public.is_owner());

create policy "ventas branch read"
on public.ventas for select to authenticated
using (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "ventas branch insert"
on public.ventas for insert to authenticated
with check (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "ventas owner update"
on public.ventas for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "ventas owner delete"
on public.ventas for delete to authenticated
using (public.is_owner());

create policy "servicios branch read"
on public.servicios for select to authenticated
using (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "servicios branch insert"
on public.servicios for insert to authenticated
with check (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "servicios branch update"
on public.servicios for update to authenticated
using (public.is_owner() or data->>'sucursal' = public.current_branch())
with check (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "servicios owner delete"
on public.servicios for delete to authenticated
using (public.is_owner());

create policy "caja_turnos branch read"
on public.caja_turnos for select to authenticated
using (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "caja_turnos branch insert"
on public.caja_turnos for insert to authenticated
with check (public.is_owner() or data->>'sucursal' = public.current_branch());

create policy "caja_turnos owner update"
on public.caja_turnos for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "caja_turnos owner delete"
on public.caja_turnos for delete to authenticated
using (public.is_owner());

create policy "caja movement branch read"
on public.caja for select to authenticated
using (
  public.is_owner()
  or exists (
    select 1
    from public.caja_turnos t
    where t.id = data->>'turnoId'
      and t.data->>'sucursal' = public.current_branch()
  )
);

create policy "caja movement branch insert"
on public.caja for insert to authenticated
with check (
  public.is_owner()
  or exists (
    select 1
    from public.caja_turnos t
    where t.id = data->>'turnoId'
      and t.data->>'sucursal' = public.current_branch()
  )
);

create policy "caja owner update"
on public.caja for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "caja owner delete"
on public.caja for delete to authenticated
using (public.is_owner());

create policy "compras owner all read"
on public.compras for select to authenticated
using (public.is_owner());

create policy "compras owner insert"
on public.compras for insert to authenticated
with check (public.is_owner());

create policy "compras owner update"
on public.compras for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "compras owner delete"
on public.compras for delete to authenticated
using (public.is_owner());

create policy "configuracion owner read"
on public.configuracion for select to authenticated
using (public.is_owner());

create policy "configuracion owner insert"
on public.configuracion for insert to authenticated
with check (public.is_owner());

create policy "configuracion owner update"
on public.configuracion for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "configuracion owner delete"
on public.configuracion for delete to authenticated
using (public.is_owner());

create policy "notificaciones owner read"
on public.notificaciones for select to authenticated
using (public.is_owner());

create policy "notificaciones authenticated insert"
on public.notificaciones for insert to authenticated
with check (true);

create policy "notificaciones owner update"
on public.notificaciones for update to authenticated
using (public.is_owner())
with check (public.is_owner());

create policy "notificaciones owner delete"
on public.notificaciones for delete to authenticated
using (public.is_owner());
