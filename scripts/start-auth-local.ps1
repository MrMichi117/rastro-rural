param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
& $Python (Join-Path $PSScriptRoot '../tools/auth-local/server.py')
if ($LASTEXITCODE -ne 0) { throw 'No fue posible iniciar el login local.' }
