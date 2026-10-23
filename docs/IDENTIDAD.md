# Integración con la plataforma general

Los sprints no entregan un endpoint de login, claves ni formato de token. Este proyecto propone un contrato y lo implementa, pero **la compatibilidad con la plataforma real está pendiente de acuerdo y prueba conjunta**. No se debe aceptar un `usuario_id` recibido en un formulario o una cabecera arbitraria de proxy.

## Contrato propuesto

JWT firmado con RS256 por la plataforma, con:

```json
{
  "iss": "https://plataforma.example.org",
  "aud": "rastro-rural",
  "sub": "identificador-opaco-del-habitante",
  "preferred_username": "mauro",
  "name": "Mauro Pérez",
  "exp": 1792600000
}
```

`exp` es ilustrativo: el emisor debe generar una expiración futura y breve. La plataforma solo debe emitir audiencia `rastro-rural` para habitantes autorizados a este subproyecto. El backend comprueba algoritmo, firma RSA, emisor exacto, audiencia, expiración obligatoria y sujeto no vacío de máximo 128 caracteres. `nbf`, si está presente, lo verifica la biblioteca. La clave privada jamás se entrega a Rastro Rural.

En el servidor se configura `JWT_PUBLIC_KEY_FILE` apuntando a un PEM con encabezado `BEGIN PUBLIC KEY`, `JWT_ISSUER` y `PLATFORM_ORIGIN`. Este MVP usa una clave estática: una rotación requiere actualizar la clave y reiniciar. Si la plataforma usa JWKS/OIDC, implementa ese adaptador con la biblioteca correspondiente antes del despliegue; no desactives verificación para conectarla.

## Entrega del token al navegador

La plataforma abre una pestaña a Rastro Rural y espera el mensaje de disponibilidad. Ejemplo para implementar **en la plataforma central**, ajustando los orígenes:

```javascript
const rastroOrigin = 'https://rastro.example.org';
const child = window.open(`${rastroOrigin}/rastro-rural/`, 'rastro-rural');
window.addEventListener('message', async event => {
  if (event.origin !== rastroOrigin || event.source !== child) return;
  if (event.data?.type !== 'rastro:ready') return;
  // Obtener el token desde el flujo autenticado real de la plataforma.
  const token = await obtenerTokenParaRastroRural();
  child.postMessage({ type: 'rastro:identity', token }, rastroOrigin);
});
```

Rastro Rural valida `event.origin` contra PLATFORM_ORIGIN y exige `event.source === window.opener`. Después llama `/api/me`: el servidor verifica criptográficamente el token. Solo entonces habilita la participación. El token no se pasa por URL ni se escribe en almacenamiento persistente. No uses `targetOrigin: '*'`.

Esta modalidad requiere conservar `window.opener`; si el portal abre con `noopener` o políticas COOP que lo separan, será necesario otro mecanismo acordado (por ejemplo un intercambio de código de un solo uso en backend). Al recargar, Rastro Rural vuelve a emitir `rastro:ready`. Ante expiración el usuario debe volver a entrar desde la plataforma; no se implementa refresh token.

## Desarrollo

Solo `APP_ENV=development` habilita `dev-vecino-1` y `dev-vecino-2`. Son identidades públicas de prueba, sin contraseñas, y no deben exponerse a Internet. El Compose local publica únicamente `127.0.0.1:8080`. El complemento de producción cambia obligatoriamente a `production`; si faltan clave o emisor, el filtro no inicializa.

## Tabla local login y flujo del habitante

1. Mauro ingresa con su usuario y contraseña en el servidor central, que administra el registro y la validación de credenciales para todos los servicios.
2. Elige Rastro Rural (Grupo 2). La plataforma entrega su sesión mediante el contrato acordado; el adaptador actual espera un token firmado.
3. Rastro Rural valida la identidad y crea o actualiza `login`, vinculado a `usuario_referencia`, en una transacción. El identificador central es la clave estable.
4. `/api/me` devuelve el perfil propio y la pantalla lo saluda por su nombre. Mauro puede reportar animales y compartir pistas sin crear otra cuenta.

`preferred_username` y `name` son claims opcionales firmados, de máximo 120 y 160 caracteres respectivamente. No se aceptan controles ni valores no textuales. Si faltan se conserva el acceso con el identificador central y un saludo genérico. Los nombres recibidos se escapan al mostrarlos en HTML.

La tabla login guarda usuario_id, emisor, nombre_usuario, nombre_visible, primer_acceso y ultimo_acceso. No almacena contraseña, hash de contraseña, JWT ni refresh token; la contraseña se valida solamente en el servidor central. `ultimo_acceso` cambia con las peticiones autenticadas. La existencia de la fila no autoriza peticiones por sí sola: cada token se vuelve a verificar. No se copian usuarios del servidor que todavía no hayan entrado al servicio.

La migración `002_login_unico.sql` agrega la tabla sin modificar los reportes existentes. Al recibir un perfil actualizado se mantienen su identificador y autoría. Se rechaza que un emisor distinto reutilice una referencia ya vinculada. La información pública de reportes y avistamientos no expone el perfil de login.

Pendiente de recibir del equipo central: mecanismo real de transferencia de sesión, emisor y validación (clave pública/JWKS o endpoint), campos de ID/usuario/nombre y autorización del Grupo 2. Si usan sesión PHP/Java, OIDC o introspección en lugar de JWT, se adapta Identity conservando LoginService y los permisos del dominio. No es necesario replicar sus contraseñas.
