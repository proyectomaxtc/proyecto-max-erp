# Publicacion alternativa en GitHub Pages

Usar GitHub Pages evita depender de los creditos de Netlify para publicar la app.

## Link esperado

Cuando GitHub Pages quede activo, la app quedara en:

https://proyectomaxtc.github.io/proyecto-max-erp/

## Configuracion necesaria en GitHub

En el repositorio `proyecto-max-erp`:

1. Entrar a `Settings`.
2. Entrar a `Secrets and variables`.
3. Entrar a `Actions`.
4. Crear estos `Repository secrets`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
5. Entrar a `Settings`.
6. Entrar a `Pages`.
7. En `Build and deployment`, elegir `GitHub Actions`.

Cada vez que se suba un cambio a `main`, GitHub va a publicar una version nueva.

## Importante

La base de datos sigue siendo Supabase. Este cambio solo reemplaza a Netlify como lugar donde se publica la web.
