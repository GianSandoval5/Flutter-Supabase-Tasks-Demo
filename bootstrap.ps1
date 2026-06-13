# Genera carpetas nativas con tu versión instalada de Flutter
# y luego restaura el código de la demo para evitar sobrescrituras.

$ErrorActionPreference = "Stop"
$backupDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $backupDir | Out-Null

Copy-Item -Recurse lib (Join-Path $backupDir "lib")
Copy-Item pubspec.yaml (Join-Path $backupDir "pubspec.yaml")
Copy-Item analysis_options.yaml (Join-Path $backupDir "analysis_options.yaml")
Copy-Item README.md (Join-Path $backupDir "README.md")
Copy-Item -Recurse supabase (Join-Path $backupDir "supabase")
Copy-Item -Recurse docs (Join-Path $backupDir "docs")
Copy-Item -Recurse scripts (Join-Path $backupDir "scripts")
Copy-Item -Recurse test (Join-Path $backupDir "test")
if (Test-Path web) {
  Copy-Item -Recurse web (Join-Path $backupDir "web")
}
if (Test-Path .vscode) {
  Copy-Item -Recurse .vscode (Join-Path $backupDir ".vscode")
}

flutter create --platforms=android,ios,web .

Remove-Item -Recurse -Force lib,supabase,docs,scripts,test
if (Test-Path .vscode) {
  Remove-Item -Recurse -Force .vscode
}
if (Test-Path (Join-Path $backupDir "web")) {
  Remove-Item -Recurse -Force web
}
Copy-Item -Recurse (Join-Path $backupDir "lib") ./lib
Copy-Item (Join-Path $backupDir "pubspec.yaml") ./pubspec.yaml
Copy-Item (Join-Path $backupDir "analysis_options.yaml") ./analysis_options.yaml
Copy-Item (Join-Path $backupDir "README.md") ./README.md
Copy-Item -Recurse (Join-Path $backupDir "supabase") ./supabase
Copy-Item -Recurse (Join-Path $backupDir "docs") ./docs
Copy-Item -Recurse (Join-Path $backupDir "scripts") ./scripts
Copy-Item -Recurse (Join-Path $backupDir "test") ./test
if (Test-Path (Join-Path $backupDir "web")) {
  Copy-Item -Recurse (Join-Path $backupDir "web") ./web
}
if (Test-Path (Join-Path $backupDir ".vscode")) {
  Copy-Item -Recurse (Join-Path $backupDir ".vscode") ./.vscode
}

flutter pub get

Write-Host "Proyecto listo. Revisa README.md para ejecutar con tus dart-defines de Supabase."
