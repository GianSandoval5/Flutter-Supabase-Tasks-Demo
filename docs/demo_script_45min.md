# Guion sugerido para demo de 45 minutos

## 0 - 5 min: Contexto
- Qué problema resuelve Flutter + Supabase.
- Diferencia entre frontend rápido y backend listo para usar.
- Qué incluye la demo: Auth, PostgreSQL, RLS, CRUD y Realtime.

## 5 - 12 min: Setup de Supabase
- Crear proyecto.
- Obtener Project URL y Publishable Key.
- Ejecutar `supabase/01_schema_tasks.sql`.
- Revisar tabla `tasks` y policies.

## 12 - 20 min: Inicialización en Flutter
- Revisar `lib/main.dart`.
- Explicar `Supabase.initialize`.
- Ejecutar con `--dart-define`.

## 20 - 28 min: Auth
- Revisar `LoginPage`.
- Crear usuario o iniciar sesión.
- Explicar sesión actual y `AuthGate`.

## 28 - 38 min: CRUD + RLS
- Crear una tarea.
- Marcar como completada.
- Eliminar.
- Mostrar que no enviamos `user_id` desde Flutter porque Supabase lo llena con `auth.uid()`.

## 38 - 43 min: Realtime
- Abrir la app en dos ventanas o dispositivos.
- Crear o actualizar una tarea y mostrar actualización en vivo.
- Explicar `stream(primaryKey: ['id'])`.

## 43 - 45 min: Cierre
- Siguiente parte: `docs/charla_2_functions.md` muestra una Edge Function programada con `pg_cron`.
- Buenas prácticas: RLS, separar repositorios, no exponer claves secretas, mover lógica sensible a Edge Functions.
