# Dokploy: configuración preparada, despliegue pendiente

Por solicitud del equipo, **no se despliega ningún servicio por ahora**. Las pruebas se ejecutan localmente. Estas instrucciones documentan lo que se hará cuando el servidor central esté preparado.

## Archivos

`Dockerfile` compila Flutter con SDK 3.47.5, verifica la interfaz, compila/prueba Java y copia el WAR a Tomcat 10.1 con usuario sin privilegios. `docker-compose.yml` contiene el servicio `rastro-rural`, expone el puerto interno 8080 y lo une a la red externa `dokploy-network`. No publica puertos del host ni crea MySQL adicional.

En Dokploy: crear servicio tipo **Compose**, conectar GitHub `MrMichi117/rastro-rural`, rama `main`, archivo `docker-compose.yml`, contexto raíz. No activar auto deploy antes de completar la integración central. El workflow GitHub solo verifica y empaqueta, no despliega.

## Variables futuras

```dotenv
DB_URL=jdbc:mysql://HOST_INTERNO_CONFIRMADO:3306/rastro_rural?connectionTimeZone=-05:00&forceConnectionTimeZoneToSession=true
DB_USER=USUARIO_DEL_SERVICIO
DB_PASSWORD=VALOR_PRIVADO
JWT_ISSUER=EMISOR_CONFIRMADO
JWT_PUBLIC_KEY_PATH=/ruta/servidor/platform-public.pem
PLATFORM_ORIGIN=https://ORIGEN_DEL_PORTAL
CENTRAL_LOGIN_URL=https://URL_LOGIN
CENTRAL_DASHBOARD_URL=https://URL_PORTAL
```

El adaptador de producción actual valida RS256 con emisor y audiencia `rastro-rural`. La plantilla recibida solo demuestra HS256 sin esos claims, por lo que está habilitada únicamente en desarrollo local. **El contrato final de producción sigue pendiente.** No trasladar `LOCAL_JWT_SECRET` ni los tokens `dev-vecino-*` al servidor.

Confirmar con el equipo la red del MySQL ya creado, su hostname interno y permisos de aplicación; el host interno mostrado en Dokploy se resuelve entre contenedores de la misma red, no desde Workbench del PC. La dirección Tailscale y el puerto externo 3326 son para acceso desde el PC. Verificar TLS/política de red con infraestructura antes de fijar opciones JDBC.

El proxy debe enviar `/rastro-rural/` al puerto 8080, conservar la ruta y servir la app por HTTPS. El build está configurado para ese prefijo; si cambia, actualizar `--base-href` en Dockerfile y el pipeline. Comprobar `/rastro-rural/api/health`, navegación, fotos y login antes de habilitar usuarios.

Inicializar las cinco tablas solo si la base está vacía. No recrear tablas sobre datos existentes. Respaldar y probar restauración antes de una actualización. Las credenciales se cargan como variables privadas de Dokploy, nunca en GitHub.

## Alternativa local Docker

Usar explícitamente `docker compose -f compose.yaml up -d --build` con `.env` privado. Este archivo sí crea un MySQL local independiente. `compose.production.yaml` corresponde al complemento histórico de esa alternativa y no es el archivo que se conectará a Dokploy. No usar comandos `down -v` sobre volúmenes con datos.
