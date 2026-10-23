# Fase 2 — Backend y frontend

## Organización

```text
src/main/java/co/edu/travesias/rastro/
  Config.java           Variables de entorno o propiedades JVM
  Database.java         Pool JDBC HikariCP y ciclo de vida
  Identity.java         Identidad JWT RS256 y modo local explícito
  LoginService.java     Carga y actualización del perfil local de login único
  SecurityFilter.java   Identidad y cabeceras de seguridad/no-store
  ApiServlet.java       Rutas HTTP y respuestas JSON
  ReportService.java    Reglas del dominio y transacciones
  Repository.java       Ejecución parametrizada JDBC
  Validation.java       Campos, fechas y fotografías
  Json.java             Serialización y límites de solicitudes
src/main/webapp/
  index.html            Estructura accesible y navegación
  assets/js/api.js      HTTP, mensajes y bloqueo de doble clic
  assets/js/app.js      Vistas y formularios
  assets/js/guidance.js Bienvenida, ayudas por módulo y confirmaciones grandes
  assets/css/app.css    Paleta, tipografías y adaptación móvil
  assets/css/mobile-friendly.css Controles táctiles amplios y lectura en celular
  assets/vendor/        Bootstrap distribuido con la aplicación
  assets/logos/         Logos suministrados por el equipo
  assets/fonts/         Montserrat y Roboto
  WEB-INF/web.xml       Registro de servlet, filtro y listener
```

HTML se sirve desde Tomcat y consulta la API del mismo origen. Las rutas relativas también funcionan bajo `/rastro-rural/`. Los textos aportados por usuarios se escapan antes de renderizar. No se usa un CDN durante la ejecución.

La entrada sin ruta abre `#inicio`: una bienvenida con cuatro acciones y explicación sencilla del servicio. `#tablero` mantiene el acceso directo a los animales perdidos. Cada módulo contiene una guía visible y un enlace para regresar a la ayuda. En celular los botones miden al menos 60 px de alto, las opciones de encuesta 64 px y los campos usan letra de 18 px. Las confirmaciones de cierre tienen botones grandes y una opción para volver sin cambiar nada.

El filtro valida el token en cada petición autenticada y llama LoginService antes de atenderla. El servicio crea o actualiza el perfil de `login` en una transacción; `ultimo_acceso` refleja la última petición autenticada, no una sesión persistente. No se consulta la tabla para aceptar una contraseña ni para omitir la validación de la sesión central.

## Variables

| Variable | Valor / finalidad |
|---|---|
| APP_ENV | `development` habilita los dos vecinos de prueba; cualquier otro valor aplica validación de producción. |
| DB_URL | JDBC MySQL con base y configuración de zona horaria. |
| DB_USER, DB_PASSWORD | Usuario de aplicación, nunca root en producción. |
| JWT_PUBLIC_KEY_FILE | Ruta de clave pública RSA PEM/SPKI. Solo producción. |
| JWT_ISSUER | Emisor exacto aprobado por la plataforma. Solo producción. |
| PLATFORM_ORIGIN | Origen HTTPS de la plataforma para `postMessage`, sin ruta ni barra final. |
| PORT | Puerto del lanzador local (8080 por defecto). |

`.env` se utiliza mediante Docker Compose. Java ejecutado directamente **no lee `.env`**: exporta las variables en PowerShell, configura el servicio Tomcat o pásalas como propiedades JVM.

## Ejecutar sin Docker en Windows

Necesitas JDK 17+, MySQL iniciado y el esquema aplicado como explica la fase 1. Define `JAVA_HOME` con tu ruta real, por ejemplo:

```powershell
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:APP_ENV='development'
$env:DB_URL='jdbc:mysql://127.0.0.1:3306/rastro_rural?sslMode=DISABLED&allowPublicKeyRetrieval=true&connectionTimeZone=-05:00&forceConnectionTimeZoneToSession=true'
$env:DB_USER='rastro'
$env:DB_PASSWORD=Read-Host 'Contraseña del usuario MySQL'
.\scripts\run-local.ps1
```

La URL sin TLS es solo para la base local o la red privada de contenedores. En MySQL remoto usa TLS con verificación de identidad y configuración de truststore. `Read-Host` en este ejemplo solicita la contraseña en la terminal; para uso habitual configura un gestor de secretos.

Abre `http://localhost:8080/rastro-rural/`. Ctrl+C detiene Tomcat. También puedes compilar con `mvnw.cmd clean verify` y copiar `target/rastro-rural.war` al directorio `webapps` de un Tomcat 10.1 instalado.

## Diseñar y extender

- Cambia colores globales en `app.css`; se preservan verde `#007A33`, rojo institucional y azul de foco. El rojo oscuro en botones mejora legibilidad.
- El tablero vacío es un estado real. No contiene cifras simuladas ni reportes de ejemplo.
- La búsqueda de coincidencias usa texto literal mediante `LOCATE`, con parámetros SQL; no interpreta `%` o `_` como comodines.
- Para añadir campos, actualiza esquema/migración, validación del servicio, consulta y formulario conjuntamente.
- Si cambia la redacción de la encuesta, incrementa su versión, valida esa versión en backend y acuerda la migración con el módulo central.
- No añadas persistencia del navegador, precaché o reenvíos automáticos sin cambiar explícitamente el alcance.

El navegador mantiene exclusivamente el estado de la vista y el token en memoria. La cookie de sesión no es necesaria; las solicitudes llevan Bearer y `credentials: omit`. La aplicación no habilita CORS público.
