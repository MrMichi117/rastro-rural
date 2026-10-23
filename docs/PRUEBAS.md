# Trazabilidad y verificación

## Actualización 1.1 — Login único y uso en celular

- Nueve pruebas Java aprobadas: ocho de integración HTTP y una de identidad firmada. Ejecutadas con H2 y con MySQL 8.0.46 real sobre Tomcat 10.1.61.
- Nuevos casos: perfil derivado solo de identidad validada, rechazo de nombres/IDs enviados por parámetros, carga repetida sin duplicados, actualización del nombre conservando usuario y primer acceso, rechazo de colisión entre emisores y rechazo de firma falsa.
- Migración aplicada sobre la base de vista previa existente: un reporte antes y un reporte después; no se borraron sus datos. La tabla login se completa al acceder.
- Navegador en base de pruebas independiente: bienvenida, acceso desde pantalla protegida, saludo, creación, confirmación visible de guardado, botón directo de avistamiento, envío de pista, regreso sin cerrar, cierre confirmado, encuesta y salida.
- Bienvenida comprobada a 360, 390, 768 y 1440 px sin desbordamiento horizontal. Opciones de encuesta con 64 px de alto; controles generales de al menos 56 px, ampliados a 60 px en celular. Se inspeccionaron capturas de escritorio y celular.
- Sin errores JavaScript. Comprobación en navegador: 0 entradas en localStorage, 0 en sessionStorage y 0 Service Workers.
- La integración con el servidor central real queda pendiente de recibir su contrato; no se considera verificada con la plataforma real.

## Evidencia de esta entrega — 21 de octubre de 2026

- `IdentityTest`: 1 prueba aprobada; `IntegrationTest`: 6 pruebas aprobadas; 0 fallos y 0 errores.
- Ejecución HTTP real con Tomcat 10.1.61 y MySQL 8.0.46 en una instancia aislada del equipo; también se verificó el respaldo H2.
- Navegador Chromium automatizado: tablero vacío, acceso local, creación, avistamiento, tablero, edición, cierre y encuesta completados.
- Vistas revisadas a 1440 × 1000 y 390 × 844; sin errores JavaScript ni desbordamiento horizontal en el tablero móvil. Se inspeccionaron capturas de tablero de escritorio y detalle móvil.
- Los registros del recorrido de navegador fueron temporales y se retiraron de la base de vista previa.
- Docker Desktop tenía el motor detenido: se validó la configuración Compose, pero no se ejecutó una construcción de contenedores. Java/MySQL/Tomcat sí se ejecutaron directamente.
- El workflow de GitHub está preparado; su ejecución remota, el despliegue público y el login central siguen pendientes.

| Requisito del sprint | Implementación |
|---|---|
| RF-001 / HU-01 Identidad | Identity + SecurityFilter; adaptador RS256 configurable. Acuerdo con plataforma pendiente. |
| RF-002 / HU-02 Reportar pérdida | POST /reportes y formulario con foto opcional. |
| RF-003 / HU-03 Tablero | GET /reportes, filtros y paginación. |
| RF-004 / HU-04 Avistamiento | POST vinculado, sector y fecha. |
| RF-005 / HU-05 Encontrado | PATCH por autor, control de versión. |
| RF-006/007, HU-06/07 | Excluidos expresamente: sin persistencia offline ni sincronización. |
| RF-008 / HU-08 Otro | Catálogo y nombre alternativo validado. |
| RF-009 / HU-09 Editar/cancelar | PUT y PATCH con autoría y transacción. |
| Encuesta de mockups y módulo común | Cinco preguntas originales, Likert 1–5 y unicidad por versión. |
| PB-12 Contenedores | Dockerfile, Compose local y complemento de producción. |

## Pruebas automatizadas

```powershell
.\mvnw.cmd clean verify
```

Sin TEST_DB_URL se usa H2 en modo MySQL únicamente como respaldo rápido de pruebas. La aplicación distribuida usa Connector/J y MySQL; H2 y Tomcat embebido de prueba no se incluyen en el WAR.

Para verificar con MySQL real crea una **base nueva y vacía exclusiva para pruebas**, porque el test instala el esquema. El usuario necesita permisos de creación de tablas y escritura en esa base:

```powershell
$env:TEST_DB_URL='jdbc:mysql://127.0.0.1:3306/rastro_test?sslMode=DISABLED&allowPublicKeyRetrieval=true&connectionTimeZone=-05:00&forceConnectionTimeZoneToSession=true'
$env:TEST_DB_USER='USUARIO_DE_PRUEBAS'
$env:TEST_DB_PASSWORD=Read-Host 'Contraseña de pruebas'
.\mvnw.cmd clean verify
```

No apuntes TEST_DB_URL a una base de aplicación. Prepara una nueva base vacía para cada ejecución. Los resultados JUnit están en `target/surefire-reports/`. CI crea MySQL 8.4 vacío en cada job.

Los tests lanzan Tomcat, realizan llamadas HTTP y comprueban creación, edición, cierre, cancelación, avistamientos, autoría, conflictos, entradas inválidas, inyección SQL literal, suplantación del ID del formulario, foto y encuesta duplicada. La prueba de identidad genera claves RSA efímeras y verifica el contrato de producción.

## Revisión manual

Prueba Chrome/Edge y un navegador Android, teclado, foco, lectura de mensajes, formularios a 390 px y escritorio, retorno al tablero y filtro sin resultados. Comprueba pérdida de conexión durante un envío y consulta posterior antes de reenviar. No recargues ni cierres esperando recuperar un borrador: no se guarda.

Pendiente en infraestructura real: integración con el login central, rendimiento con 3G simulado, usuarios concurrentes, disponibilidad mensual, certificados, respaldos restaurables y aprobación de catálogo/política de datos. No se ha modificado ni declarado aprobado el contenido académico original.
