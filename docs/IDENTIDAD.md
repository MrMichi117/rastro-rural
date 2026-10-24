# Identidad central y pruebas de la plantilla

Rastro Rural no registra cuentas ni guarda credenciales. La contraseña se comprueba en el login central. Nuestro backend recibe un Bearer token y valida firma, vencimiento e identificador antes de usar los datos del usuario.

## Plantilla entregada

Se revisó `Plantilla tokens.zip`: el login responde `access_token`/`token`, `nombre_usuario`/`usuario`, `token_type=bearer` y `expires_in=1800`. El JWT de demostración está firmado con **HS256**, contiene `sub`, `iat`, `exp`, y no incluye `iss` ni `aud`. El frontend de la plantilla entrega `?usuario=...&token=...` al servicio. Las cuentas de la imagen son fixtures de prueba; se configuraron solo en el archivo local privado.

El ZIP original contiene valores de conexión a una base ajena. No se usan, no se incorporan al repositorio y no se consulta esa base. El simulador `tools/auth-local/server.py` reproduce el contrato HTTP/JWT sobre loopback y mantiene hashes PBKDF2 de las cuentas de prueba en memoria. No es el sistema central real ni un componente de producción.

## Flujo local

1. Ejecutar el login local en `127.0.0.1:8110` y la aplicación en `localhost:8080/rastro-rural/`.
2. El usuario entra con una cuenta de prueba. El simulador emite un JWT de 30 minutos y redirige a Rastro Rural según la plantilla.
3. Flutter lee el token, elimina `token` y `usuario` de la URL y lo conserva solo en memoria. El parámetro `usuario` nunca determina la identidad.
4. Flutter consulta `/api/me` con Authorization Bearer. Java verifica HS256 con `LOCAL_JWT_SECRET` privado y usa `sub` como usuario. Si falta nombre firmado, muestra ese identificador.
5. Reportes, pistas y encuestas guardan `usuario_id`, `usuario_emisor` y `usuario_nombre` del principal validado. No existen tablas locales de cuentas.

`LOCAL_JWT_SECRET` solo se lee con `APP_ENV=development`; el emisor de este adaptador es `urn:rastro:local-central`. Los tokens directos de Vecino 1/2 se conservan como fixtures para pruebas sin login. No aparece un selector de acceso. Abrir directamente la app en desarrollo usa Vecino 1; para probar admin/docente/estudiante se entra desde el login local. Recargar la página elimina la identidad de plantilla en memoria: volver a entrar desde ese login para recuperar esa cuenta. No se guardan tokens en almacenamiento del navegador.

## Producción pendiente

Se conserva la validación RS256, clave pública, issuer configurado, audiencia `rastro-rural`, exp obligatorio y sub. Producción rechaza tokens de desarrollo. No se supone que este contrato sea compatible con el sistema central definitivo: acordar algoritmo, claves, claims, expiración, URL y método de renovación con el equipo antes de desplegar.

También se admite entrega mediante postMessage si `PLATFORM_ORIGIN` coincide exactamente y el emisor es `window.opener`. Después se verifica el token en el backend. Nunca se acepta una identidad por cabecera de usuario o por datos de formulario.

El uso de token en query reproduce la plantilla solo para pruebas locales. Para producción debe acordarse la entrega por código de un solo uso o postMessage, evitando tokens en URLs/logs de infraestructura. Las respuestas del servicio usan no-store y Referrer-Policy same-origin; el HTML inicial agrega no-referrer.
