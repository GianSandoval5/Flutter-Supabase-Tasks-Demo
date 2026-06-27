# Supabase Edge Functions

Esta carpeta no usa `npm install`, `node_modules` ni `package.json`.

Las Edge Functions de Supabase corren sobre Deno. Por eso el import:

```ts
import { createClient } from "npm:@supabase/supabase-js@2";
```

lo resuelve el runtime de Supabase/Deno, no npm.

Para la charla no necesitas ejecutar Functions localmente. Despliega la Function
remota y usa el emulador Flutter con `Ctrl+F5`.

El emulador llama a `task-suggestions` con la sesion autenticada del usuario. No
usa `AUTOMATION_SECRET`; ese secreto queda solo para cron, terminal u otra
funcion backend.

Si quieres probar Functions localmente con Docker, desde la raiz ejecuta:

```powershell
supabase start
supabase functions serve --no-verify-jwt --env-file supabase/functions/.env
```

Para correr la app en el emulador con `Ctrl+F5`, completa `.env` en la raiz:

```text
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_PUBLISHABLE_KEY=TU_PUBLISHABLE_KEY
```

Para desplegar:

```powershell
.\supabase\functions\deploy-functions.ps1
```

Si el proyecto no esta linkeado localmente:

```powershell
.\supabase\functions\deploy-functions.ps1 -ProjectRef TU_PROJECT_REF
```

Comandos equivalentes sin script:

```powershell
supabase secrets set --env-file supabase/functions/.env
supabase functions deploy task-automation --no-verify-jwt --use-api
supabase functions deploy task-suggestions --no-verify-jwt --use-api
```

Con project ref explicito:

```powershell
supabase secrets set --env-file supabase/functions/.env --project-ref TU_PROJECT_REF
supabase functions deploy task-automation --no-verify-jwt --use-api --project-ref TU_PROJECT_REF
supabase functions deploy task-suggestions --no-verify-jwt --use-api --project-ref TU_PROJECT_REF
```

Para probar la funcion remota despues del deploy:

```powershell
$vars = @{}
Get-Content supabase/functions/.env | ForEach-Object {
  if ($_ -match '^\s*([^#=]+)=(.*)$') { $vars[$matches[1].Trim()] = $matches[2].Trim() }
}

Invoke-RestMethod `
  -Uri "$($vars.SUPABASE_URL.TrimEnd('/'))/functions/v1/task-automation" `
  -Method POST `
  -Headers @{
    "Content-Type" = "application/json"
    "x-automation-secret" = $vars.AUTOMATION_SECRET
  } `
  -Body '{"run_type":"manual","source":"terminal","notes":"Prueba remota desde PowerShell"}'
```

Para probar sugerencias por terminal usando el secreto backend:

```powershell
Invoke-RestMethod `
  -Uri "$($vars.SUPABASE_URL.TrimEnd('/'))/functions/v1/task-suggestions" `
  -Method POST `
  -Headers @{
    "Content-Type" = "application/json"
    "x-automation-secret" = $vars.AUTOMATION_SECRET
  } `
  -Body '{"limit":4}'
```

Si prefieres copiar y pegar en el Dashboard de Supabase, crea una Edge Function
llamada `task-suggestions` y pega el contenido completo de:

```text
supabase/functions/task-suggestions/index.ts
```

Despues despliegala con `Verify JWT` desactivado, igual que el comando
`--no-verify-jwt`.

Si corriste `npm install` por error y se creo `package-lock.json`, puedes
eliminarlo. No forma parte de esta demo.
