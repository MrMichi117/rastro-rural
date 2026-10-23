$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    foreach ($name in @('JAVA_HOME','DB_URL','DB_USER','DB_PASSWORD')) {
        if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Configura $name antes de ejecutar." }
    }
    if (-not $env:APP_ENV) { $env:APP_ENV='development' }
    & .\mvnw.cmd test-compile dependency:build-classpath '-Dmdep.outputFile=target/classpath.txt' '-Dmdep.includeScope=test' -q
    if ($LASTEXITCODE -ne 0) { throw 'No fue posible compilar.' }
    $classpath='target/test-classes;target/classes;' + (Get-Content target/classpath.txt -Raw).Trim()
    & (Join-Path $env:JAVA_HOME 'bin/java.exe') -cp $classpath co.edu.travesias.rastro.LocalPreview
} finally { Pop-Location }
