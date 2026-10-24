$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    Push-Location frontend
    try {
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'Falló flutter pub get.' }
        & flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'Falló el análisis de Flutter.' }
        & flutter test
        if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas Flutter.' }
        & flutter build web --release --base-href /rastro-rural/ --no-web-resources-cdn
        if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación web.' }
    } finally { Pop-Location }
    & .\mvnw.cmd clean verify
    if ($LASTEXITCODE -ne 0) { throw 'Falló la verificación Java.' }
    Write-Host 'Listo: backend/target/rastro-rural.war'
} finally { Pop-Location }
