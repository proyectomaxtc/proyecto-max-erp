# Supabase + Netlify

## Estado Actual

La app puede funcionar de dos maneras:

- Sin claves de Supabase: usa datos locales con Hive.
- Con claves de Supabase y usuario autenticado: sincroniza datos online.

Variables de compilacion:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Crear Tablas

En Supabase abrir `SQL Editor` y ejecutar:

`supabase/schema.sql`

Ese script crea:

- tablas de datos de la app;
- tabla `user_profiles`;
- funciones de rol/sucursal;
- politicas RLS para usuarios autenticados.

## Crear Usuarios Online

En Supabase abrir `Authentication > Users` y crear un usuario por persona:

- Propietario
- Empleado Alberdi
- Empleado Santa Fe

Usar emails reales o internos, por ejemplo:

- `cristian@tucumancerraduras.com`
- `alberdi@tucumancerraduras.com`
- `santafe@tucumancerraduras.com`

Usar contrasenas fuertes. No usar codigos cortos como contrasena online.

## Crear Perfil De Seguridad

Por cada usuario creado en Supabase, copiar el `User UID`.

Luego ejecutar una copia de:

`supabase/profile_template.sql`

Cambiando:

- `auth_id`: User UID de Supabase
- `app_user_id`: id del usuario dentro de la app
- `nombre`
- `rol`: `Propietario` o `Empleado`
- `sucursal`: `Casa Central Santa Fe` o `Sucursal Alberdi`

## Vincular Usuario Dentro De La App

En la app, entrar como propietario a `Configuracion > Usuarios`.

Editar cada usuario y completar:

- Email Supabase
- Auth ID Supabase

Eso permite que al iniciar sesion con email/contrasena la app encuentre su rol y
sucursal.

## Compilar Web Con Claves

```powershell
flutter build web --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
```

Para el proyecto real, no escribir los valores en archivos del repositorio.
Usar variables de entorno en Netlify.

## Netlify

En Netlify:

- Build command: `bash scripts/netlify_build.sh`
- Publish directory: `build/web`

Agregar `SUPABASE_URL` y `SUPABASE_ANON_KEY` en las variables de entorno del
sitio.

## Seguridad

No abrir permisos anonimos para leer, modificar o borrar la base.

El SQL incluido habilita operaciones solo para usuarios autenticados y filtra
ventas, servicios y caja por sucursal. El propietario puede ver todo.
