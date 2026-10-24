# MySQL Workbench local

La base de Dokploy queda pendiente. Las pruebas usan MySQL de este PC.

En Workbench, pulsa **+** junto a MySQL Connections y configura:

| Campo | Valor |
|---|---|
| Connection Name | Rastro Rural - Local |
| Connection Method | Standard (TCP/IP) |
| Hostname | 127.0.0.1 |
| Port | 3310 |
| Username | rastro_local |
| Default Schema | rastro_rural_local |
| Password | Valor DB_PASSWORD de .local/settings.json, privado |

Pulsa **Test Connection** y abre la conexión. La base y las cinco tablas ya fueron creadas para esta prueba; refresca Schemas. Ejecuta:

```sql
USE rastro_rural_local;
SHOW TABLES;
SELECT id,nombre_animal,usuario_id,usuario_emisor,usuario_nombre,estado FROM reporte;
SELECT reporte_id,usuario_id,sector_id,fecha_avistamiento,observacion FROM avistamiento;
```

`rastro_local` tiene SELECT/INSERT/UPDATE solo en el esquema de la aplicación. Para cambiar estructura usa una conexión administrativa local. No copies la contraseña al código o GitHub.

Para otra máquina: iniciar MySQL local, configurar MYSQL_PWD del administrador si procede y ejecutar `python scripts/setup-local.py --port PUERTO`. Ajustar el cliente con `--mysql RUTA` si MySQL está en otra ubicación. El script crea un esquema independiente y evita modificar un esquema incompatible.

El MySQL nativo que usamos está en `.tools/mysql-v12` de la carpeta superior y escucha solo en loopback. Se preparó en esta sesión; después de reiniciar Windows hay que volver a iniciarlo o usar la alternativa Docker. No confundir este puerto 3310 con 3309 de `compose.yaml` ni con 3326 del servidor remoto.

Cuando el equipo reactive el servidor y decida habilitar pruebas remotas: Tailscale conectado, host `100.79.246.82`, puerto externo `3326`, esquema `rastro_rural`, credenciales de MySQL de Dokploy. No usar el puerto 3000 (panel web) ni el hostname interno del contenedor como hostname de Workbench. No se modificó la base remota en esta sesión.

Referencias: [Conexión TCP/IP de Workbench](https://dev.mysql.com/doc/workbench/en/wb-mysql-connections-methods-standard.html), [Conexiones de bases en Dokploy](https://docs.dokploy.com/docs/core/databases/connection).
