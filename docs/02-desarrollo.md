# Desarrollo Flutter y Java

El frontend está implementado en Flutter/Dart. Conserva la navegación, bienvenida, tarjetas, filtros y formularios de Rastro Rural. El backend sigue siendo Java, separado en `backend/`. Maven reúne el resultado de `frontend/build/web` con la API en un solo WAR; Tomcat sirve ambos en el mismo origen bajo `/rastro-rural/`, sin necesidad de CORS para la aplicación publicada.

## Frontend

`lib/theme.dart` define Material 3 con Verde Amazonia #007A33, Rojo Institucional #E20613, Azul Sistemas #0085CA, fondo #F8F9FA y texto #212529. Montserrat se usa en títulos y Roboto en el cuerpo; ambas fuentes se empaquetan localmente. Las tarjetas tienen radio 12, elevación 2 y padding mínimo 16; los botones tienen radio 8 y altura mínima 60, con opciones de encuesta de 64. Las imágenes tienen placeholder y los tres logos mantienen su proporción.

- `lib/main.dart`: arranque, navegación, cabecera, pie e inicio con ayuda.
- `lib/screens/board.dart`: tablero, filtros, estadísticas y paginación.
- `lib/screens/report_form.dart`: alta/edición, validación y foto seleccionada por el usuario.
- `lib/screens/detail.dart`: detalle, pistas, confirmación de cierre y avistamiento.
- `lib/screens/survey.dart`: preguntas y escala del módulo de encuesta entregado, adaptadas a botones grandes.
- `lib/api.dart`: peticiones HTTP, token en memoria, manejo de errores y expiración.
- `lib/browser_web.dart`: recepción de token URL de la plantilla y postMessage del portal configurado.

No se utiliza Google Fonts por red, Bootstrap ni un WebView para envolver HTML. El diseño se implementa con widgets Flutter. `web/flutter_bootstrap.js` carga CanvasKit local y no registra SW. El compilador puede producir un stub de limpieza de SW antiguos; este proyecto no lo registra.

## Backend

`Identity` verifica identidad; `SecurityFilter` aplica cabeceras y protege operaciones; `ApiServlet` enruta; `ReportService` aplica reglas; `Repository` utiliza SQL parametrizado; `Database` administra HikariCP. `/api/me` devuelve el perfil del token validado sin consultar una tabla de usuarios. Ver `IDENTIDAD.md`.

## Comandos

```powershell
./scripts/build.ps1
./scripts/run-local.ps1
```

El segundo comando carga `.local/settings.json` y ejecuta Tomcat de desarrollo. Requiere el build Flutter existente y MySQL iniciado. Para iterar con recarga en Flutter puede usarse un proxy local que sirva `/api` hacia Tomcat o configurar CORS explícito; la forma verificada es compilar y servir el WAR/preview desde el mismo origen.

Los formularios anuncian el resultado del servidor y conservan lo escrito en memoria ante un error para permitir su revisión. No se reintenta automáticamente un POST incierto. Las fechas del negocio se interpretan en Bogotá; el backend limita fechas y valida fotos JPEG/PNG de hasta 2 MB y 16 MP y las recodifica sin EXIF.

En teléfono (ancho menor que 800 px), AppBar fija y Drawer con cuatro módulos de altura 76. En escritorio se conserva la barra de navegación. Los ChoiceChip usan verde explícito para evitar los colores por defecto de Material. La política connect-src admite blob: para que file_selector pueda leer el archivo elegido, manteniendo la validación de imagen y tamaño en el servidor.
