# Rastro Rural

Aplicación comunitaria para reportar animales perdidos y compartir avistamientos en Travesías, Florencia, Caquetá. Frontend **Flutter 3.47.5 / Dart**, backend **Java 17 / Jakarta Servlet / Tomcat 10.1**, base de datos **MySQL 8**. Versión 1.2.0.

## Organización

```text
frontend/        Flutter Material 3: pantallas, tema, cliente API, recursos y pruebas
backend/         Java: API, identidad, JDBC, validación y pruebas HTTP
database/        Esquema actual de cinco tablas y ejemplos históricos en legacy/
tools/auth-local/ Simulador local del login central de la plantilla suministrada
scripts/         Preparación local, compilación y arranque
docs/            Base de datos, desarrollo, identidad, pruebas y futuro Dokploy
Dockerfile       Compila Flutter y Java y produce una imagen Tomcat
docker-compose.yml Futuro servicio Dokploy con MySQL externo ya existente
compose.yaml     Entorno alternativo local con su propio MySQL
```

La aplicación funciona exclusivamente en línea. No guarda reportes ni tokens en localStorage, sessionStorage, IndexedDB o colas offline. No registra Service Workers. Flutter, las fuentes y CanvasKit se sirven desde Tomcat; el backend entrega `Cache-Control: no-store`.

## Pruebas locales en este equipo

La base utilizada es **rastro_rural_local**, en **127.0.0.1:3310**. Es independiente de la base de Dokploy y de las bases anteriores. Los valores privados están en `.local/settings.json`, excluido de Git y de Docker.

En PowerShell, desde esta carpeta:

```powershell
# Configura JAVA_HOME para un JDK 17 o superior antes de compilar.
./scripts/start-mysql-local.ps1
# Solo si hay que iniciar MySQL después de reiniciar Windows.
./scripts/build.ps1
./scripts/run-local.ps1
```

En otra terminal, con Python 3:

```powershell
./scripts/start-auth-local.ps1
```

Abre **http://127.0.0.1:8110/** para probar el login de las cuentas de la plantilla y entrar a Rastro Rural. Las cuentas se configuran en `test_accounts` del archivo privado. También puedes abrir **http://localhost:8080/rastro-rural/**: en desarrollo se conserva el acceso automático de Vecino 1 para probar los formularios. No hay botón ni modal de “Acceso comunitario”.

Para preparar otro MySQL local vacío, ejecuta `python scripts/setup-local.py --port 3310`. Requiere un servidor MySQL ya iniciado y el cliente mysql; usa `MYSQL_PWD` del administrador si tiene contraseña. No descarga ni arranca MySQL. Nunca apunta al servidor remoto. El script evita modificar una base local con esquema incompatible.

## Funciones

- Inicio con instrucciones sencillas y ayuda por pantalla.
- Tablero con búsqueda, especie, sector y paginación.
- Crear/editar reporte, fotografía JPEG/PNG, cancelar o marcar encontrado.
- Registrar avistamientos con sector, fecha y hora de Bogotá.
- Encuesta de cinco preguntas y una respuesta por identidad y versión.
- Autoría a partir de la identidad validada del servidor: cada registro guarda referencia, emisor y nombre; la base del servicio no contiene tablas de usuarios ni login.

## Compilar y comprobar

`scripts/build.ps1` ejecuta análisis, pruebas Flutter, build web y verificación Maven. Resultado: **backend/target/rastro-rural.war**. Para comprobar solo Java: `./mvnw.cmd test`. Para las pruebas web: `cd frontend; flutter test`. El WAR completo necesita primero `flutter build web --release --base-href /rastro-rural/ --no-web-resources-cdn`.

## Docker y Dokploy

El proyecto está preparado para una futura aplicación de tipo Compose conectada al repositorio **MrMichi117/rastro-rural**, rama `main`, ruta `docker-compose.yml`. Esta configuración utiliza la base MySQL existente; no crea otra base ni otro servicio de identidad en el servidor. **No se ha desplegado en Dokploy.** Antes del despliegue deben acordarse la identidad de producción, la red compartida, las variables privadas y la ruta pública.

Para la alternativa local Docker: `Copy-Item .env.example .env`, completar contraseñas y usar siempre `docker compose -f compose.yaml up -d --build`. MySQL local Docker se publica en 127.0.0.1:3309; no confundir con MySQL nativo de este equipo en 3310.

## Documentación

- [Base de datos](docs/01-base-de-datos.md)
- [Desarrollo y diseño Flutter](docs/02-desarrollo.md)
- [GitHub](docs/03-github.md)
- [Futuro Dokploy](docs/04-despliegue.md)
- [Identidad y plantilla de tokens](docs/IDENTIDAD.md)
- [Workbench local](docs/WORKBENCH-LOCAL.md)
- [API](docs/API.md)
- [Verificación](docs/PRUEBAS.md)
