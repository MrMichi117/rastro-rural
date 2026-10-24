$ErrorActionPreference = 'Stop'
$settingsFile = Join-Path $PSScriptRoot '../.local/settings.json'
if (Test-Path $settingsFile) {
    $localSettings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    foreach ($name in @('DB_URL','DB_USER','DB_PASSWORD','LOCAL_JWT_SECRET','LOCAL_AUTH_ISSUER','CENTRAL_LOGIN_URL','CENTRAL_DASHBOARD_URL','PORT')) {
        $property = $localSettings.PSObject.Properties[$name]
        if ($property) { [Environment]::SetEnvironmentVariable($name, [string]$property.Value, 'Process') }
    }
}
Push-Location (Join-Path $PSScriptRoot '../backend')
try {
    foreach ($name in @('JAVA_HOME','DB_URL','DB_USER','DB_PASSWORD')) {
        if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Configura $name antes de ejecutar." }
    }
    if (-not $env:APP_ENV) { $env:APP_ENV='development' }
    & ..\mvnw.cmd test-compile dependency:build-classpath '-Dmdep.outputFile=target/classpath.txt' '-Dmdep.includeScope=test' -q
    if ($LASTEXITCODE -ne 0) { throw 'No fue posible compilar.' }
    $classpath='target/test-classes;target/classes;' + (Get-Content target/classpath.txt -Raw).Trim()
    & (Join-Path $env:JAVA_HOME 'bin/java.exe') -cp $classpath co.edu.travesias.rastro.LocalPreview
} finally { Pop-Location }
