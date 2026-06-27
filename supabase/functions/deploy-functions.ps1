param(
  [string]$ProjectRef = ''
)

$ErrorActionPreference = 'Stop'

$functionsRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent (Split-Path -Parent $functionsRoot)
$envPath = Join-Path $functionsRoot '.env'
$functionNames = @('task-automation', 'task-suggestions')

if (!(Get-Command supabase -ErrorAction SilentlyContinue)) {
  Write-Host 'No se encontro Supabase CLI en PATH.'
  Write-Host 'Instala la CLI o abre una terminal donde el comando supabase este disponible.'
  exit 1
}

if (!(Test-Path $envPath)) {
  Write-Host 'Falta supabase/functions/.env.'
  Write-Host 'Copia .env.example, completa SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY y AUTOMATION_SECRET, y vuelve a ejecutar.'
  exit 1
}

$envContent = Get-Content $envPath -Raw
$hasPlaceholder = $envContent -match 'TU-PROYECTO|TU_SERVICE_ROLE_O_SECRET_KEY|CAMBIA_ESTE_VALOR_LARGO'

if ($hasPlaceholder) {
  Write-Host 'Edita supabase/functions/.env antes de desplegar.'
  Write-Host 'No despliego porque aun hay placeholders.'
  exit 1
}

Push-Location $repoRoot
try {
  $projectArgs = @()
  if ($ProjectRef.Trim()) {
    $projectArgs = @('--project-ref', $ProjectRef.Trim())
  }

  Write-Host 'Subiendo secretos desde supabase/functions/.env...'
  & supabase secrets set --env-file $envPath @projectArgs
  if ($LASTEXITCODE -ne 0) {
    throw 'Fallo supabase secrets set.'
  }

  foreach ($functionName in $functionNames) {
    Write-Host "Desplegando Edge Function: $functionName..."
    & supabase functions deploy $functionName --no-verify-jwt --use-api @projectArgs
    if ($LASTEXITCODE -ne 0) {
      throw "Fallo supabase functions deploy para $functionName."
    }
  }

  Write-Host 'Deploy de Functions terminado.'
} finally {
  Pop-Location
}
