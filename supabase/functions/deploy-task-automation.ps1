param(
  [string]$ProjectRef = ''
)

$scriptPath = Join-Path $PSScriptRoot 'deploy-functions.ps1'

if ($ProjectRef.Trim()) {
  & $scriptPath -ProjectRef $ProjectRef
} else {
  & $scriptPath
}

exit $LASTEXITCODE
