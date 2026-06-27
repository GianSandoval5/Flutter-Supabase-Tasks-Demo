$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root 'supabase\functions\.env'
$examplePath = Join-Path $root 'supabase\functions\.env.example'

if (!(Test-Path $envPath)) {
  Copy-Item $examplePath $envPath
  Write-Host 'Se creo supabase/functions/.env.'
  Write-Host 'Completa SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY antes de ejecutar otra vez.'
  exit 1
}

$envContent = Get-Content $envPath -Raw
$hasPlaceholder = $envContent -match 'TU-PROYECTO|TU_SERVICE_ROLE_O_SECRET_KEY|CAMBIA_ESTE_VALOR_LARGO'

if ($hasPlaceholder) {
  Write-Host 'Edita supabase/functions/.env antes de ejecutar.'
  Write-Host 'SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY deben tener valores reales de tu proyecto.'
  Write-Host 'AUTOMATION_SECRET ya puede ser cualquier secreto largo; puedes usar el generado en ese archivo.'
  exit 1
}

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Host 'Docker Desktop es requerido para ejecutar Supabase Functions localmente.'
  Write-Host 'Instalalo desde https://docs.docker.com/desktop o usa deploy remoto con --use-api.'
  exit 1
}

try {
  docker info *> $null
} catch {
  Write-Host 'Docker Desktop no esta corriendo.'
  Write-Host 'Abre Docker Desktop, espera a que termine de iniciar y vuelve a presionar Ctrl+F5.'
  Write-Host 'La conexion remota a Supabase puede estar bien aunque el runtime local no arranque.'
  exit 1
}

try {
  & supabase functions serve --no-verify-jwt --env-file $envPath
} catch {
  throw
}

if ($LASTEXITCODE -ne 0) {
  Write-Host ''
  Write-Host 'No se pudo iniciar Supabase Functions localmente.'
  Write-Host 'Si el mensaje dice "supabase start is not running", ejecuta primero:'
  Write-Host ''
  Write-Host '  supabase start'
  Write-Host ''
  Write-Host 'Luego vuelve a presionar Ctrl+F5.'
  Write-Host ''
  Write-Host 'Alternativa sin runtime local: desplegar remoto con:'
  Write-Host ''
  Write-Host '  .\supabase\functions\deploy-task-automation.ps1'
  Write-Host ''
  exit $LASTEXITCODE
}
