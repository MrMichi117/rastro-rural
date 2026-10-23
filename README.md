# Rastro Rural

Aplicación web comunitaria para reportar animales extraviados y compartir avistamientos en Travesías, Florencia, Caquetá. Implementada con **Java 17, Jakarta Servlet 6, Tomcat 10.1, MySQL y HTML/CSS/JavaScript con Bootstrap 5.3.8**.

Se revisaron los sprints 0 y 1, la guía de estilos, los mockups y el módulo de encuesta de esta carpeta. Por instrucción del equipo, esta implementación cambia Express/Flutter por Java/Bootstrap y funciona **exclusivamente en línea**. Los documentos originales permanecen intactos.

## Empezar en Windows con Docker

1. Abre Docker Desktop y espera a que el motor esté disponible.
2. Abre PowerShell dentro de esta carpeta `rastro-rural`.
3. Ejecuta:

```powershell
Copy-Item .env.example .env
notepad .env
# Reemplaza las dos contraseñas por valores largos, aleatorios y distintos.
docker compose up -d --build
docker compose logs -f web
```

Abre [Rastro Rural local](http://localhost:8080/rastro-rural/). En **Acceso comunitario** puedes seleccionar **Vecino 1** o **Vecino 2**, exclusivamente en este entorno de desarrollo. Publica con uno y registra un avistamiento con el otro. No se incluyen animales ficticios en la base inicial; el tablero empieza vacío.

```powershell
docker compose ps
docker compose stop
docker compose start
```

El volumen `mysql_data` conserva los datos. El SQL inicial solo se ejecuta cuando el volumen está vacío. No uses `docker compose down -v` para actualizar la aplicación: elimina la base.

## Las cuatro fases

1. **Base de datos:** [script MySQL](database/001_schema.sql) y [modelo de datos](docs/01-base-de-datos.md).
2. **Backend y frontend:** [arquitectura y ejecución](docs/02-desarrollo.md), [contrato HTTP](docs/API.md) e [integración de identidad](docs/IDENTIDAD.md).
3. **GitHub:** [comandos exactos, ramas, commits y publicación](docs/03-github.md).
4. **Despliegue:** [guía de producción y recuperación](docs/04-despliegue.md).

También se incluye [trazabilidad con los sprints y plan de pruebas](docs/PRUEBAS.md).

## Funciones implementadas

- Tablero público ordenado por creación, filtros por especie/sector y búsqueda por nombre, señas, identificación o descripción; paginación de 12 reportes.
- Reporte de pérdida con especie «Otro», identificación, señas, sector, fecha, descripción y fotografía JPEG/PNG opcional.
- Detalle público, avistamientos con fecha y hora de Bogotá, y lista cronológica de observaciones.
- Mis reportes, edición, eliminación de fotografía y cierre como ENCONTRADO o CANCELADO, solo por el autor.
- Encuesta de cinco preguntas con escala 1–5, una respuesta por identidad y versión.
- Tabla local `login` vinculada al usuario del servidor central; carga automática de nombre/usuario verificados, sin otro registro ni copia de contraseñas.
- Inicio con bienvenida y cuatro acciones explicadas; instrucciones visibles en cada módulo y acceso directo para contar dónde se vio al animal.
- Validación en servidor, consultas parametrizadas, transacciones, control de edición concurrente y validación de identidad JWT RS256 en producción.
- Diseño adaptable con texto de 18 px, botones de al menos 60 px en celular, opciones de encuesta de 64 px y confirmaciones amplias; logos y fuentes incluidos en el WAR.

## Compilar sin Docker

Instala un JDK 17 o superior y configura `JAVA_HOME`. El wrapper descarga Maven en su primera ejecución.

```powershell
.\mvnw.cmd clean verify
# Resultado: target/rastro-rural.war
```

Para ejecutar con MySQL local consulta [desarrollo](docs/02-desarrollo.md). El WAR debe desplegarse en **Tomcat 10.1**; no en Tomcat 9 (`javax.servlet`).

## Identidad central y límites conocidos

El usuario inicia sesión una sola vez en el servidor central y entra a Rastro Rural (Grupo 2) con ese acceso. `login` guarda su perfil local de acceso: identificador central, emisor, nombre de usuario, nombre visible y fechas de acceso. Se crea o actualiza automáticamente después de validar la identidad. No guarda contraseñas, hashes de contraseña ni tokens. `usuario_referencia` conserva los vínculos de los reportes existentes.

El contrato real del servidor central todavía no está disponible. Se entrega un **adaptador verificable RS256**, con emisor, audiencia y clave pública configurables; el equipo central debe aprobar o adaptar este contrato antes de producción. Los campos `preferred_username` y `name` del token firmado cargan el perfil y el saludo. Si faltan, se muestra un saludo genérico.

**Actualizar una instalación existente:** respalda la base, aplica solamente [002_login_unico.sql](database/002_login_unico.sql) y despliega el WAR actualizado. No vuelvas a ejecutar el esquema inicial ni borres el volumen. La migración conserva reportes, avistamientos y encuestas; los perfiles se completan cuando cada persona entra con su sesión validada. La instalación desde cero ya incluye la tabla en `001_schema.sql`.

No hay `localStorage`, `sessionStorage`, IndexedDB, Service Workers ni colas/reintentos automáticos. Las respuestas llevan `Cache-Control: no-store`. El token existe únicamente en memoria de la pestaña; al recargar se solicita nuevamente a la plataforma. Un formulario no enviado puede permanecer en la memoria de la página, pero no sobrevive al cierre. Ante una respuesta perdida, consulta el tablero antes de reenviar: esta versión no garantiza idempotencia entre envíos manuales distintos.

La búsqueda de coincidencias es textual, por especie y sector; no utiliza reconocimiento de fotos, mapas, GPS ni rastreo en vivo. Se registra el avistamiento desde un reporte existente, conforme al MVP de los sprints. No se crea un flujo independiente de animales encontrados sin reporte de pérdida.

Los sectores proceden de los mockups y deben validarse con la comunidad. La encuesta se adaptó a Java conservando preguntas y contrato; no se conecta al backend FastAPI existente. Falta acordar si su almacenamiento será centralizado. Las metas de 2,5 s bajo 3G y 95 % de disponibilidad requieren medición en el servidor real.

## Referencias técnicas

- [Tomcat 10.1 y Jakarta Servlet 6](https://tomcat.apache.org/tomcat-10.1-doc/)
- [MySQL Connector/J](https://dev.mysql.com/doc/connector-j/en/)
- [Bootstrap 5.3](https://getbootstrap.com/docs/5.3/getting-started/download/)

No se ha publicado un repositorio remoto ni desplegado un servidor público. Las guías incluyen los pasos para hacerlo con tus cuentas y dominio.
