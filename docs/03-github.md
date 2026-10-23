# Fase 3 — Control de versiones con GitHub

Los comandos se ejecutan **dentro de `rastro-rural`**, no en la carpeta superior con documentos, mockups y archivos temporales. No se ha creado un remoto ni publicado código en tu cuenta.

## Crear el repositorio local

```powershell
cd 'C:\Users\brall\Downloads\SEMESTRE 7\REDEII\rastro rural proyecto\rastro-rural'
git init -b main
git config user.name 'TU NOMBRE'
git config user.email 'TU CORREO DE GITHUB'
git status --short
git add .
git diff --cached --stat
git diff --cached --check
git commit -m 'feat: implementar Rastro Rural online con Java y MySQL'
```

La configuración de nombre y correo queda limitada a este repositorio. `.gitignore` excluye `.env`, WAR, compilados, secretos PEM/KEY, logs, IDE y respaldos; conserva `.env.example`, código y wrapper Maven. Antes del commit revisa el diff y comprueba que no hay contraseñas reales. No incluyas `target/` ni la carpeta superior `.tools/`.

## Publicar

En GitHub crea un repositorio personal llamado `rastro-rural`. Elige la visibilidad apropiada y créalo vacío, sin README, licencia ni .gitignore iniciales, porque ya existen archivos locales. Luego:

```powershell
git remote add origin https://github.com/TU_USUARIO/rastro-rural.git
git remote -v
git push -u origin main
```

Autentícate con Git Credential Manager cuando se abra el navegador. No escribas tokens de acceso en la URL, archivos o historial de comandos. Si prefieres GitHub CLI ya autenticado, en vez de crear el repositorio por web:

```powershell
gh auth login
gh repo create rastro-rural --private --source=. --remote=origin --push
```

No ejecutes ambas alternativas para crear el mismo remoto. Si `origin` ya existe, verifica su dirección antes de usar `git remote set-url origin ...`.

## Trabajo en equipo

```powershell
git switch main
git pull --ff-only
git switch -c feat/mejorar-filtros
# Realiza cambios y verifica:
.\mvnw.cmd clean verify
git status
git add src docs
git diff --cached
git commit -m 'feat: ampliar filtros del tablero comunitario'
git push -u origin feat/mejorar-filtros
```

Abre un pull request hacia main, describe comportamiento y pruebas, pide revisión y combina cuando CI pase. Haz commits pequeños por cambio funcional; usa `feat:`, `fix:`, `docs:` o `test:`. Evita `git push --force` en main. Activa protección de rama y revisión obligatoria si el plan de tu cuenta lo permite.

`.github/workflows/verify.yml` compila Java 17, ejecuta pruebas HTTP con Tomcat y MySQL 8.4 y guarda el WAR como artefacto del workflow. No despliega automáticamente ni necesita secretos de producción.

Para una entrega versionada:

```powershell
git switch main
git pull --ff-only
git tag -a v1.0.0 -m 'MVP online de Rastro Rural'
git push origin v1.0.0
```

Si alguna credencial se publica accidentalmente, revócala o rótala: borrarla en el último commit no la elimina del historial.
