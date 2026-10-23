# Actualización 1.1

## Acceso único y tabla login

El habitante inicia sesión en el servidor comunitario y usa ese acceso para entrar a Rastro Rural, Grupo 2. El backend valida la identidad, carga o actualiza su perfil en la tabla local `login` y mantiene la autoría de sus reportes. No necesita otra cuenta ni otra contraseña.

La tabla guarda identificador central, emisor, nombre de usuario, nombre visible y fechas de acceso. Las contraseñas siguen en el sistema central. El adaptador de sesión se mantiene preparado para RS256 hasta recibir el contrato real del equipo del servidor; no se ha conectado a una base central desconocida.

Instalación nueva: `database/001_schema.sql` incluye login. Instalación existente: ejecutar `database/002_login_unico.sql` con una cuenta de migración y luego desplegar el WAR actualizado. El script es aditivo y conserva datos. Compose no ejecuta automáticamente scripts nuevos sobre volúmenes ya inicializados.

## Interfaz para celular

- Inicio con explicación sencilla y cuatro acciones: ver animales, reportar una pérdida, revisar reportes propios y dar opinión.
- Guía visible en cada pantalla con el nombre exacto del botón que debe tocarse.
- Botón “Lo vi: contar dónde” que lleva directamente al formulario de avistamiento.
- Texto base de 18 px, botones de 60 px en celular, separación entre acciones y opciones de encuesta de 64 px.
- Confirmación amplia antes de cerrar o cancelar una búsqueda, con “Volver sin cambiar nada”.
- Mensaje de guardado después de publicar, saludo con el perfil validado y regreso a Inicio y ayuda desde cada módulo.
- Se mantiene la operación exclusivamente online.

## Comprobaciones

Nueve pruebas Java aprobadas en MySQL real y H2; recorrido completo en navegador y revisión a cuatro anchos de pantalla. Se preservó el reporte existente en la base de vista previa. Detalles en `PRUEBAS.md`.
