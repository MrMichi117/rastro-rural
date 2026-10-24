# Verificación 1.2

La migración se verifica localmente; no se desplegó el servicio ni se modificó MySQL del servidor.

- `flutter analyze`: sin errores ni advertencias.
- `flutter test`: seis casos para Bearer/expiración, bienvenida en 360/390/1280, validación previa a enviar reportes y encuesta incompleta.
- `flutter build web --release --base-href /rastro-rural/ --no-web-resources-cdn`: build compilado, recursos locales.
- Maven: diez pruebas aprobadas, incluidas pruebas HTTP reales en Tomcat para autorización, autoría por emisor, cinco tablas sin cuentas, ciclo de reportes, pistas, filtros, fechas, fotos, encuesta y validación JWT.
- Flujo local con login de plantilla: docente crea reporte; estudiante agrega avistamiento; modificación por otro usuario devuelve 403; token retirado de la URL; sin errores de consola en navegador.

El esquema real local usa MySQL 8.0.46. Se ejecutó también la suite completa sobre un esquema MySQL 8.0.46 temporal aislado, con diez pruebas aprobadas; el esquema de prueba se retiró después. Las pruebas Maven usan H2 en modo MySQL por defecto; CI usa MySQL 8.4 y una base vacía independiente. Si se define TEST_DB_URL, debe apuntar a un esquema de prueba recién creado, nunca a la base de aplicación: la suite crea sus tablas.

No se declara validado Docker en un motor local mientras Docker Desktop esté detenido. Se comprueba la sintaxis de Compose y el build Flutter/Java por separado. La compatibilidad final del login y el despliegue Dokploy siguen pendientes del equipo del servidor.
