# Contrato HTTP

Base: `/rastro-rural/api`. JSON UTF-8. Métodos de escritura con `Content-Type: application/json` y `Authorization: Bearer <token>`. No se admiten cookies como identidad. Límite de solicitud JSON: 4,2 MB.

| Método | Ruta | Acceso | Resultado |
|---|---|---|---|
| GET | /health | Público | Comprueba conexión de base; no expone configuración. |
| GET | /config | Público | Modo de desarrollo y origen de plataforma. |
| GET | /me | Identidad | Perfil del token validado en esta petición, sin tabla local de cuentas. |
| GET | /catalogos | Público | Especies y sectores. |
| GET | /estadisticas | Público | Totales de búsquedas, encontrados y avistamientos. |
| GET | /reportes | Público | Activos, más recientes primero. |
| GET | /reportes?mine=true | Identidad | Reportes propios en todos los estados. |
| GET | /reportes/{id} | Público | Detalle, avistamientos y es_autor. |
| GET | /reportes/{id}/foto | Público | JPEG/PNG; 404 si no existe. |
| POST | /reportes | Identidad | Crea BUSCANDO, 201 con id. |
| PUT | /reportes/{id} | Autor | Edita un reporte activo, 200. |
| PATCH | /reportes/{id}/estado | Autor | Cierra reporte activo, 200. |
| POST | /reportes/{id}/avistamientos | Identidad | Añade observación, 201 con id. |
| POST | /v1/encuestas/usabilidad | Identidad | Guarda una encuesta, 201. |

Filtros de listado: `q` (máximo 100 caracteres), `especie` y `sector` (ID), `page` (desde 1). Respuesta: `{items, total, page, page_size:12}`. No se listan autores ni contactos públicos. Las cifras de estadísticas son totales históricos, no recuperados del mes.

## Crear o editar reporte

```json
{
  "especie_id": 1,
  "especie_otro": null,
  "nombre_animal": "Lucero",
  "identificador_campo": "Arete 23",
  "senas": "Pelaje café y mancha blanca en la frente",
  "descripcion": "Se perdió cerca del camino principal",
  "sector_id": 1,
  "fecha_perdida": "2026-10-20"
}
```

Opcional: `foto` como `data:image/jpeg;base64,...` o `data:image/png;base64,...`. En PUT se requiere `version` leída del detalle. Omitir `foto` conserva la existente; enviarla en null la elimina. Usuario y estado no se toman de este cuerpo. En «Otro», especie_otro es obligatorio. Fechas desde 2000 y no futuras, calendario de Bogotá.

## Cerrar

```json
{ "estado": "ENCONTRADO", "version": 0 }
```

También acepta CANCELADO. Responde 403 para otro autor y 409 si está cerrado o cambió la versión.

## Avistamiento

```json
{
  "sector_id": 2,
  "fecha_avistamiento": "2026-10-21T14:30",
  "observacion": "Lo vi junto al puente, caminando hacia el sector alto."
}
```

La hora se interpreta como hora civil de Bogotá. No acepta fechas anteriores a la pérdida o futuras.

## Encuesta

```json
{
  "subproyecto_id": "rastro-rural",
  "version_encuesta": 1,
  "respuestas": {
    "respuesta_1": 5,
    "respuesta_2": 4,
    "respuesta_3": 5,
    "respuesta_4": 4,
    "respuesta_5": 5
  }
}
```

Exactamente cinco enteros 1–5. Respuesta repetida: 409. Subproyecto distinto: 403. No se implementa un endpoint público de resultados.

## Errores

Formato `{ "error": "Mensaje comprensible" }`. Códigos: 400 JSON inválido, 401 identidad ausente/incorrecta/vencida, 403 autoría o subproyecto, 404 recurso, 409 conflicto, 413 tamaño, 415 tipo de contenido, 422 validación, 503 base inaccesible, 500 inesperado. El servidor registra detalles técnicos y no los expone al cliente.

No hay reenvíos automáticos. Si la respuesta se pierde después del COMMIT, el recurso puede existir: el usuario debe consultar el tablero antes de publicar nuevamente.


## Identidad

GET /me devuelve `{authenticated: true, usuario: {usuario_id, nombre_usuario, nombre_visible}}` del token validado. No se aceptan esos valores en formularios para determinar autoría. La referencia y emisor del autor se conservan en cada registro y no se publican en el tablero. Ver IDENTIDAD.md para el adaptador local HS256 y el contrato propuesto RS256 de producción.
