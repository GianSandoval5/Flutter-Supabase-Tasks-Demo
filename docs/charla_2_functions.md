# Charla 2: Supabase Functions y procesos automaticos

Esta segunda parte extiende la demo de tareas con una automatizacion real:
contar tareas, registrar el resultado y ejecutar el proceso desde una Edge
Function. La misma funcion se puede llamar manualmente, desde otra funcion o
desde un job programado con `pg_cron`.

## Objetivo de la demo

- Mostrar por que una tarea automatica no debe vivir en Flutter.
- Mover el proceso a Supabase Edge Functions.
- Registrar cada ejecucion en Postgres.
- Programar una ejecucion diaria a una hora concreta.
- Explicar como otra funcion puede disparar el mismo proceso.

## Archivos agregados

```text
supabase/
  03_task_automation.sql
  04_schedule_task_automation.sql
  functions/
    .env.example
    task-automation/index.ts
docs/
  charla_2_functions.md
```

## Paso 1: preparar la base de datos

Ejecuta primero el SQL principal de la charla 1:

```sql
supabase/01_schema_tasks.sql
```

Despues ejecuta:

```sql
supabase/03_task_automation.sql
```

Ese archivo crea:

- `public.task_automation_runs`: historial de ejecuciones.
- `public.register_task_automation_run(...)`: funcion SQL que cuenta tareas y
  registra el resultado.

Consulta de verificacion:

```sql
select * from public.task_automation_runs order by created_at desc;
```

## Paso 2: configurar secretos de la Edge Function

La Edge Function usa un secreto propio para que no quede publica. Genera un
valor largo y guardalo como `AUTOMATION_SECRET`.

En local puedes copiar la plantilla:

```powershell
Copy-Item supabase/functions/.env.example supabase/functions/.env
```

Edita `supabase/functions/.env` con tus valores reales:

```text
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_O_SECRET_KEY
AUTOMATION_SECRET=CAMBIA_ESTE_VALOR_LARGO
```

En produccion no subas ese archivo. Guarda el secreto con la CLI o desde el
Dashboard:

```bash
supabase secrets set AUTOMATION_SECRET=CAMBIA_ESTE_VALOR_LARGO
```

La `service_role` o secret key solo vive en el backend. Nunca va en Flutter.

Nota: no ejecutes `npm install` dentro de `supabase/functions`. Supabase Edge
Functions usa Deno; no necesita `package.json`, `package-lock.json` ni
`node_modules`.

El `AUTOMATION_SECRET` puede ser cualquier valor largo y dificil de adivinar.
Para esta demo se genero uno local en `supabase/functions/.env`; usa ese mismo
valor cuando ejecutes `supabase secrets set AUTOMATION_SECRET=...` y cuando
guardes `task_automation_secret` en Vault.

## Paso 3: probar la funcion manualmente

Desde el emulador:

La pantalla `Mis tareas` tiene un boton con icono de rayo. Ese boton llama a
`task-automation` usando la sesion autenticada de Supabase, por eso no se mete
`AUTOMATION_SECRET` dentro de Flutter.

Para correr la app en Android con `Ctrl+F5`, completa `.env` en la raiz:

```text
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

Luego selecciona `Flutter Android: emulador (.env)` y presiona `Ctrl+F5`.

Prueba local opcional de la Function, si quieres usar Docker:

```bash
supabase start
supabase functions serve --no-verify-jwt --env-file supabase/functions/.env
```

En otra terminal, para el modo local:

```powershell
Invoke-RestMethod `
  -Uri "http://127.0.0.1:54321/functions/v1/task-automation" `
  -Method POST `
  -Headers @{
    "Content-Type" = "application/json"
    "x-automation-secret" = "CAMBIA_ESTE_VALOR_LARGO"
  } `
  -Body '{"run_type":"test","source":"local-demo","notes":"Prueba local para charla 2"}'
```

Produccion:

```powershell
.\supabase\functions\deploy-task-automation.ps1
```

Si el proyecto no esta linkeado:

```powershell
.\supabase\functions\deploy-task-automation.ps1 -ProjectRef TU_PROJECT_REF
```

Comandos equivalentes:

```powershell
supabase secrets set --env-file supabase/functions/.env
supabase functions deploy task-automation --no-verify-jwt --use-api
```

Con project ref explicito:

```powershell
supabase secrets set --env-file supabase/functions/.env --project-ref TU_PROJECT_REF
supabase functions deploy task-automation --no-verify-jwt --use-api --project-ref TU_PROJECT_REF
```

Llamada de prueba en PowerShell:

```powershell
Invoke-RestMethod `
  -Uri "https://TU-PROYECTO.supabase.co/functions/v1/task-automation" `
  -Method POST `
  -Headers @{
    "Content-Type" = "application/json"
    "x-automation-secret" = "CAMBIA_ESTE_VALOR_LARGO"
  } `
  -Body '{"run_type":"manual","source":"dashboard","notes":"Ejecucion manual para charla 2"}'
```

## Paso 4: programar una hora concreta

Para programar el proceso se usa `pg_cron` y `pg_net`. Antes de ejecutar el
archivo de programacion, guarda los valores que el job usara:

```sql
select vault.create_secret('https://TU-PROYECTO.supabase.co', 'project_url');
select vault.create_secret('MISMO_VALOR_DE_AUTOMATION_SECRET', 'task_automation_secret');
```

Si tu proyecto no permite crear extensiones desde SQL, habilita `pg_cron`,
`pg_net` y Vault desde `Database > Extensions` en el Dashboard.

Luego ejecuta:

```sql
supabase/04_schedule_task_automation.sql
```

El ejemplo crea el job `daily-task-automation-edge` con esta expresion:

```cron
0 13 * * *
```

`pg_cron` usa UTC. Esa hora equivale a las 08:00 en Peru cuando Peru esta en
UTC-5.

Para revisar el job:

```sql
select * from cron.job where jobname = 'daily-task-automation-edge';
```

Para pausarlo o reemplazarlo:

```sql
select cron.unschedule('daily-task-automation-edge');
```

## Paso 5: llamarla desde otra funcion

Otra Edge Function puede reutilizar el mismo proceso con un `fetch` interno:

```ts
await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/task-automation`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "x-automation-secret": Deno.env.get("AUTOMATION_SECRET") ?? "",
  },
  body: JSON.stringify({
    run_type: "trigger",
    source: "otra-edge-function",
    notes: "Proceso disparado desde otra funcion",
  }),
});
```

La idea para explicar en la charla: Flutter solo consume datos; la logica
programada, sensible o con claves secretas vive en Supabase.

## Guion rapido para mostrarlo

1. Mostrar `03_task_automation.sql` y explicar que la base registra ejecuciones.
2. Mostrar `task-automation/index.ts` y explicar el secreto `x-automation-secret`.
3. Invocar la Edge Function manualmente.
4. Consultar `task_automation_runs` y ver el nuevo registro.
5. Mostrar `04_schedule_task_automation.sql` y explicar `pg_cron` + `pg_net`.
6. Cerrar con el caso de "otra funcion" usando el snippet de `fetch`.
