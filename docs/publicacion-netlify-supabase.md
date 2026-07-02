# Publicacion de Tucuman Cerraduras

Esta app queda pensada para funcionar como PWA web con Netlify y Supabase.

## 1. Supabase

En Supabase debe estar ejecutado el archivo:

`supabase/schema.sql`

Despues de crear usuarios en Authentication, asociar cada usuario con:

- `supabase/owner_profiles.sql` para propietarios
- `supabase/profile_template.sql` para empleados nuevos

## 2. Variables en Netlify

En Netlify ir a:

`Site configuration > Environment variables`

Crear estas variables:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

No pegarlas en el codigo fuente. Netlify las usa al compilar.

## 3. Build

El archivo `netlify.toml` ya deja configurado:

- Carpeta publicada: `build/web`
- Build Flutter web
- Conexion con Supabase por variables
- Redireccion para que la PWA no falle al recargar

## 4. Uso

Cuando Netlify publique la app, el link sera fijo y se podra abrir desde:

- Windows
- iPhone
- Android
- Casa Central Santa Fe
- Sucursal Alberdi
- Datos moviles

Los cambios de productos, stock, ventas, caja y usuarios se sincronizan por Supabase si el usuario entra con email y contrasena de Supabase.
