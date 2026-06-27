$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root '.env'
$examplePath = Join-Path $root '.env.example'

if (!(Test-Path $envPath)) {
  if (Test-Path $examplePath) {
    Copy-Item $examplePath $envPath
  }

  Write-Host 'Falta .env en la raiz del proyecto.'
  Write-Host 'Crea .env con SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY antes de usar Ctrl+F5.'
  exit 1
}

$values = @{}
Get-Content $envPath | ForEach-Object {
  if ($_ -match '^\s*([^#=]+)=(.*)$') {
    $values[$matches[1].Trim()] = $matches[2].Trim()
  }
}

$supabaseUrl = $values['SUPABASE_URL']
$publishableKey = $values['SUPABASE_PUBLISHABLE_KEY']
if (!$publishableKey) {
  $publishableKey = $values['SUPABASE_ANON_KEY']
}

if (!$supabaseUrl -or $supabaseUrl -match 'TU-PROYECTO|example') {
  Write-Host 'Falta SUPABASE_URL real en .env.'
  exit 1
}

if (!$publishableKey -or $publishableKey -match 'TU_PUBLISHABLE_KEY|TU_ANON_KEY|example') {
  Write-Host 'Falta SUPABASE_PUBLISHABLE_KEY real en .env.'
  Write-Host 'Copiala desde Supabase Dashboard > Project Settings > API > Publishable key.'
  exit 1
}

if ($values['SUPABASE_SERVICE_ROLE_KEY'] -and $publishableKey -eq $values['SUPABASE_SERVICE_ROLE_KEY']) {
  Write-Host 'No uses SUPABASE_SERVICE_ROLE_KEY como SUPABASE_PUBLISHABLE_KEY.'
  Write-Host 'La service_role es admin y no debe entrar al APK.'
  exit 1
}

Write-Host 'Ejecutando Flutter en emulador Android con Supabase remoto...'
& flutter run -d android `
  --dart-define=SUPABASE_URL=$supabaseUrl `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$publishableKey
