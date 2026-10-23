# Fase 4 — Despliegue en producción

Se entrega un WAR y configuración reproducible; el servidor público requiere dominio, TLS, credenciales y el contrato de identidad central aprobado. No expongas a Internet el Compose de desarrollo.

## 1. Preparar la entrega

Si actualizas desde la primera versión, respalda la base y aplica `database/002_login_unico.sql` con una cuenta administrativa **antes** de desplegar el nuevo WAR. El SQL crea la tabla login y conserva los reportes. En Compose con volumen existente, el script no se ejecuta automáticamente: abre `docker compose exec db mysql -uroot -p rastro_rural` y aplica el contenido de esa migración. No elimines el volumen.

En el equipo de desarrollo, con Java 17+:

```powershell
.\mvnw.cmd clean verify
Get-FileHash target/rastro-rural.war -Algorithm SHA256
```

Conserva el hash, tag Git y WAR. Tomcat 10.1 implementa Jakarta Servlet 6; Tomcat 9 no sirve para este WAR. Actualiza periódicamente las versiones de parche y dependencias y vuelve a ejecutar las pruebas. Las etiquetas Docker de Tomcat/MySQL reciben actualizaciones: para una entrega totalmente reproducible fija sus digest después de validar la imagen en el entorno real.

## 2. Opción A — Servidor Linux con Compose

Instala Docker Engine y Compose siguiendo su documentación para la distribución del servidor. Copia o clona el repositorio en `/opt/rastro-rural`, con acceso de escritura solo para el equipo autorizado. En esa carpeta:

```bash
cp .env.example .env
chmod 600 .env
mkdir -p secrets
nano .env
```

Configura dos contraseñas distintas, JWT_ISSUER y PLATFORM_ORIGIN. Recibe la clave **pública** del equipo de plataforma y colócala en `secrets/platform-public.pem`, formato SPKI `BEGIN PUBLIC KEY`. No copies su clave privada. La clave pública puede ser legible por el usuario del contenedor; los secretos de `.env` no deben estar en Git.

```bash
docker compose -f compose.yaml -f compose.production.yaml config --quiet
docker compose -f compose.yaml -f compose.production.yaml up -d --build
docker compose ps
docker compose logs --tail=100 web
curl --fail http://127.0.0.1:8080/rastro-rural/api/health
```

La base queda en una red Docker interna, sin puerto publicado. El puerto web está enlazado a localhost para un proxy instalado en el mismo servidor. El enlace MySQL sin TLS se limita a esa red privada; para una base externa usa `sslMode=VERIFY_IDENTITY` y certificados confiables, quitando `allowPublicKeyRetrieval`.

Reduce los privilegios del usuario de aplicación después de inicializar:

```bash
docker compose exec db mysql -uroot -p
```

```sql
REVOKE ALL PRIVILEGES ON rastro_rural.* FROM 'rastro'@'%';
GRANT SELECT, INSERT, UPDATE ON rastro_rural.* TO 'rastro'@'%';
```

El esquema inicial solo se aplica en un volumen nuevo. Nunca borres el volumen para actualizar el código.

## 3. Publicar con HTTPS mediante Nginx

Configura DNS del dominio al servidor y obtén un certificado TLS mediante el procedimiento de tu proveedor (por ejemplo ACME/Certbot). Ejemplo de bloque, reemplazando dominio y rutas por los certificados reales:

```nginx
server {
    listen 80;
    server_name rastro.example.org;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    server_name rastro.example.org;
    ssl_certificate /etc/letsencrypt/live/rastro.example.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rastro.example.org/privkey.pem;
    client_max_body_size 5m;
    add_header Strict-Transport-Security "max-age=31536000" always;
    location = / { return 302 /rastro-rural/; }
    location /rastro-rural/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
        proxy_no_cache 1;
        proxy_cache_bypass 1;
    }
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
curl --fail https://rastro.example.org/rastro-rural/api/health
```

Mantén el firewall con HTTPS, HTTP para redirección/ACME y administración restringida. No publiques 3306 ni el Tomcat Manager. Ajusta límites de peticiones en el proxy según la carga real y conserva logs sin cuerpos ni tokens.

## 4. Opción B — Tomcat instalado en servidor compartido

Instala JDK 17 y Tomcat 10.1 con un usuario de servicio dedicado. Inicializa MySQL con la fase 1. En Linux, define las variables con un archivo protegido del gestor de servicios, o en `CATALINA_BASE/bin/setenv.sh`:

```bash
export APP_ENV=production
export DB_URL='jdbc:mysql://127.0.0.1:3306/rastro_rural?connectionTimeZone=-05:00&forceConnectionTimeZoneToSession=true&sslMode=VERIFY_IDENTITY'
export DB_USER=rastro
export DB_PASSWORD='OBTENER_DEL_GESTOR_DE_SECRETOS'
export JWT_ISSUER='https://plataforma.example.org'
export JWT_PUBLIC_KEY_FILE='/etc/rastro/platform-public.pem'
export PLATFORM_ORIGIN='https://plataforma.example.org'
```

Configura los certificados/truststore JDBC para VERIFY_IDENTITY. En una base estrictamente local puedes usar socket/red privada y la configuración local documentada si la política del servidor lo permite. No copies literalmente el valor ilustrativo de contraseña.

Copia el WAR a `CATALINA_BASE/webapps/rastro-rural.war` y reinicia el servicio Tomcat según su nombre real. En Windows configura estas variables para la cuenta del servicio o usa propiedades JVM en el administrador del servicio Tomcat; un servicio de Windows no hereda el PowerShell abierto y puede no leer `setenv.bat`. Para ejecución mediante `catalina.bat run`, exportarlas en esa terminal sí funciona.

Usa `/rastro-rural/` para convivir con los demás proyectos; evita sustituir ROOT.war. El frontend y la API comparten el mismo contexto. El pool de Rastro Rural está limitado a diez conexiones: coordina la capacidad total de MySQL con los otros equipos.

## 5. Verificación de aceptación

1. `/api/health` responde `{"status":"ok"}`; tablero y catálogos cargan.
2. El modal no ofrece vecinos de desarrollo. Un token `dev-vecino-1` recibe 401.
3. La plataforma entrega identidad real; token vencido, emisor erróneo o audiencia distinta reciben 401.
4. Crea un reporte con foto y confirma en MySQL y tablero; entra desde un segundo usuario y registra avistamiento.
5. El segundo usuario no puede editar ni cerrar el reporte ajeno (403).
6. El autor cierra el reporte: desaparece del tablero activo y permanece en Mis reportes.
7. Encuesta: valores fuera de 1–5 se rechazan; el segundo envío de la misma versión recibe 409.
8. Desconecta la red: no hay mensaje de éxito ni reenvío al reconectar. Consulta el estado antes de repetir una escritura.
9. Comprueba el diseño en móvil y escritorio y las cabeceras `Cache-Control: no-store`.

## 6. Copias y restauración

El respaldo incluye fotografías porque están en MySQL. En Linux:

```bash
mkdir -p backups
chmod 700 backups
docker compose exec -T db sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqldump -uroot --single-transaction --hex-blob --no-tablespaces rastro_rural' > "backups/rastro-$(date +%F-%H%M).sql"
```

La variable se expande dentro del contenedor y no se imprime. Programa respaldos según el volumen de cambios, cifra las copias externas y restringe su acceso. Una política de retención debe acordarse con el equipo; prueba restauraciones en una base aislada antes de necesitar una recuperación real.

Para restaurar **sobre un destino preparado y con la aplicación detenida**, el archivo contiene las tablas y puede reemplazar datos existentes:

```bash
docker compose stop web
docker compose exec -T db sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot rastro_rural' < backups/ARCHIVO_VERIFICADO.sql
docker compose -f compose.yaml -f compose.production.yaml up -d web
```

Verifica primero que el destino y la copia sean los correctos. Tras restaurar, prueba health, catálogos, un detalle y su fotografía.

## 7. Actualizar y volver atrás

Respalda, descarga el tag aprobado y ejecuta las migraciones nuevas con una cuenta administrativa. Construye la imagen y recrea web; no es un procedimiento de cero interrupciones. Conserva el WAR/imagen anterior para revertir la aplicación. Una migración incompatible puede exigir restaurar también la base: ensaya el rollback sobre una copia.

Supervisa errores HTTP, salud de MySQL, espacio del volumen, logs, duración de consultas y expiración TLS. La disponibilidad de 95 % y los 2,5 s bajo 3G son objetivos de los sprints, no garantías comprobadas en este despliegue.
