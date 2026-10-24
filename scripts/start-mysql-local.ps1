param(
    [string]$MySqlBase = 'C:/Program Files/MySQL/MySQL Server 8.0',
    [int]$Port = 3310
)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runtimeDir = Join-Path $workspace '.tools'
$dataDir = Join-Path $runtimeDir 'mysql-v12'
$mysql = Join-Path $MySqlBase 'bin/mysql.exe'
$mysqld = Join-Path $MySqlBase 'bin/mysqld.exe'
if (-not (Test-Path $mysqld)) { throw 'Instala MySQL Server o indica -MySqlBase.' }
$probe = New-Object System.Net.Sockets.TcpClient
try {
    if ($probe.ConnectAsync('127.0.0.1',$Port).Wait(1000)) {
        Write-Host "El puerto local 127.0.0.1:$Port ya responde. Verifica MySQL con setup-local.py."
        exit 0
    }
} catch { } finally { $probe.Dispose() }
New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
if (-not (Test-Path (Join-Path $dataDir 'auto.cnf'))) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    & $mysqld --no-defaults --initialize-insecure --datadir="$dataDir" --console 2> (Join-Path $runtimeDir 'mysql-v12-init.log')
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo inicializar MySQL local. Consulta .tools/mysql-v12-init.log.' }
}
Start-Process -FilePath $mysqld -ArgumentList @('--no-defaults', ('--datadir="'+$dataDir+'"'), "--port=$Port", '--bind-address=127.0.0.1','--mysqlx=OFF','--console') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $runtimeDir 'mysql-v12.log') -RedirectStandardError (Join-Path $runtimeDir 'mysql-v12-error.log')
Write-Host "MySQL local iniciándose en 127.0.0.1:$Port. Luego ejecuta scripts/setup-local.py."
