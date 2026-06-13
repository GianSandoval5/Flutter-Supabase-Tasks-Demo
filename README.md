# Flutter + Supabase Tasks Demo

Proyecto de ejemplo para una charla práctica de Flutter + Supabase. La demo muestra un flujo completo con autenticación, PostgreSQL, Row Level Security, CRUD de tareas y Realtime.

## Qué incluye

- Login con email/contraseña.
- Registro de usuarios.
- Magic Link opcional.
- Tabla `tasks` en Supabase Postgres.
- Policies RLS para que cada usuario vea solo sus tareas.
- Crear, completar y eliminar tareas desde Flutter.
- Actualización en vivo usando Realtime.
- Soporte web listo para correr en Chrome.

## Requisitos

- Flutter 3.44.1 o compatible con Dart 3.12.
- Un proyecto de Supabase.
- Chrome si vas a hacer la demo en web.

Verifica tu entorno:

```bash
flutter --version
flutter doctor
```

## Configurar Supabase

1. Crea un proyecto en Supabase.
2. Entra a `Project Settings > API`.
3. Copia:
   - `Project URL`
   - `Publishable key`
4. Abre `SQL Editor`.
5. Ejecuta el archivo:

```sql
supabase/01_schema_tasks.sql
```

Ese script crea la tabla `public.tasks`, habilita RLS, agrega policies por usuario y activa la tabla para Realtime.

Para una demo en vivo, puedes desactivar temporalmente la confirmación de email en `Authentication > Sign In / Providers > Email`. Así el registro entra directo sin esperar el correo.

## Ejecutar en Chrome

Usa tus valores reales de Supabase:

```bash
flutter pub get
flutter run -d chrome --web-port 5000 \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

En PowerShell puedes usar una sola línea:

```powershell
flutter run -d chrome --web-port 5000 --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

También puedes copiar `scripts/run_web.example.sh` y reemplazar los placeholders.

## Ejecutar en móvil

```bash
flutter run -d android \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

Para Magic Link en Android/iOS, agrega el redirect `io.supabase.flutter://login-callback/` en la configuración de URLs de Supabase Auth.

## Validar antes de la charla

```bash
flutter pub get
flutter analyze
flutter test
flutter build web \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

El build confirma compilación. La prueba de integración real requiere credenciales válidas y el SQL ejecutado en Supabase.

## Flujo sugerido para la demo

1. Mostrar `lib/main.dart` y explicar `Supabase.initialize`.
2. Mostrar `lib/core/supabase_config.dart` y por qué se usan `--dart-define`.
3. Ejecutar el SQL de `supabase/01_schema_tasks.sql`.
4. Crear una cuenta o iniciar sesión.
5. Crear una tarea.
6. Abrir la app en dos ventanas y mostrar Realtime.
7. Marcar una tarea como completada.
8. Eliminar una tarea.
9. Explicar que Flutter no envía `user_id`; lo llena Supabase con `auth.uid()`.
10. Mostrar las policies RLS para cerrar con seguridad.

Hay un guion más detallado en `docs/demo_script_45min.md`.

## Estructura principal

```text
lib/
  core/
    app_theme.dart
    supabase_config.dart
  features/
    auth/presentation/
      auth_gate.dart
      login_page.dart
    tasks/
      data/tasks_repository.dart
      domain/task.dart
      presentation/tasks_page.dart
supabase/
  01_schema_tasks.sql
  02_seed_optional.sql
docs/
  demo_script_45min.md
```

## Problemas comunes

Si aparece `Faltan variables de entorno`, faltan los `--dart-define`.

Si aparece `relation "tasks" does not exist`, ejecuta `supabase/01_schema_tasks.sql`.

Si el registro queda esperando correo, confirma el email o desactiva temporalmente la confirmación para la demo.

Si Realtime no actualiza en vivo, confirma que el script SQL se ejecutó completo y que la tabla `public.tasks` está en la publicación `supabase_realtime`.

## Seguridad

La `Publishable key` se puede usar en el cliente. No pongas nunca la `service_role key` en Flutter, GitHub, slides públicas ni capturas de pantalla.
