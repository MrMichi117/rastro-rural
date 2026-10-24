# Base de datos 1.2

El esquema vigente está en `database/001_schema.sql`. Se ejecuta una sola vez sobre una base vacía seleccionada previamente. No contiene credenciales ni sentencias de borrado.

| Tabla | Contenido |
|---|---|
| especie | Catálogo de tipos de animal |
| sector | Sectores comunitarios, pendientes de validación con la comunidad |
| reporte | Pérdida, señas, estado, foto y referencia del autor autenticado |
| avistamiento | Pista, fecha/hora, sector y referencia de quien la registró |
| encuesta | Cinco respuestas, versión e identidad para evitar duplicados |

No hay tablas `login`, `usuario_referencia` ni réplicas de usuarios centrales. El backend valida la identidad antes de escribir y toma de ella `usuario_id`, `usuario_emisor` y `usuario_nombre`; ignora los valores de identidad enviados en formularios. El nombre es una instantánea del perfil al crear el registro, no una cuenta. La autoría compara identificador **y emisor**; el mismo identificador en otro emisor no puede modificar el reporte.

Los reportes públicos no exponen las referencias de autor. No se guardan contraseñas, correos ni JWT en estas tablas. Los nombres y teléfonos solo se incorporarán si existe un contrato de datos y una necesidad funcional acordada.

Las relaciones internas son `reporte.especie_id`, `reporte.sector_id`, `avistamiento.reporte_id` y `avistamiento.sector_id`. No se intenta una FK a otra base del servidor. `encuesta` tiene unicidad por usuario, emisor, subproyecto y versión. Los índices cubren tablero, filtros y reportes del autor. Las escrituras usan transacciones y parámetros JDBC; edición y cierre bloquean el reporte y verifican su versión.

## Entornos

- Nativo local de este equipo: `127.0.0.1:3310`, esquema `rastro_rural_local`.
- Alternativa Compose local: `127.0.0.1:3309`, esquema `rastro_rural`.
- Futuro servidor: MySQL de Dokploy existente, esquema `rastro_rural`. No se conectó ni modificó durante estas pruebas.

`database/legacy` conserva los scripts 1.0/1.1 como historial. **No aplicarlos a una instalación nueva.** Tampoco ejecutar 001 sobre una base anterior con tablas/datos existentes. Las bases anteriores de este equipo se conservaron: las pruebas nuevas usan un esquema separado. Una migración de datos históricos requiere respaldo y revisión de los identificadores del antiguo login antes de cambiar tablas; no hay migración destructiva automática.
