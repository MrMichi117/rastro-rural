let token = null;
export function setToken(value) { token = value; if(!value)window.dispatchEvent(new Event('rastro:access-cleared')); }
export function authenticated() { return Boolean(token); }
export async function api(path, options = {}) {
  const headers = { Accept: 'application/json', ...options.headers };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (options.body) headers['Content-Type'] = 'application/json';
  let response;
  try {
    response = await fetch(`api${path}`, { ...options, headers, cache: 'no-store', credentials: 'omit', signal: AbortSignal.timeout(15000) });
  } catch {
    document.querySelector('#connection').textContent = 'No se pudo contactar al servidor';
    throw new Error('No se pudo confirmar la operación. Revisa tu conexión y consulta el reporte antes de reenviar. No hay envíos automáticos ni guardado local.');
  }
  document.querySelector('#connection').textContent = 'Servidor conectado · Consulta en línea';
  let data;
  try { data = await response.json(); } catch { throw new Error('El servidor devolvió una respuesta inesperada.'); }
  if (!response.ok) {
    if (response.status === 401) setToken(null);
    throw new Error(data.error || 'No fue posible completar la solicitud.');
  }
  return data;
}
export function escape(value) { return String(value ?? '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch])); }
export function message(text, kind = 'danger') {
  const el = document.querySelector('#feedback');
  el.className = `alert alert-${kind} mt-3`;
  el.textContent = text;
  el.focus();
}
export async function submit(form, action) {
  if (!form.reportValidity()) return;
  const button = form.querySelector('[type=submit]');
  if (button.disabled) return;
  const label = button.textContent;
  button.disabled = true; button.textContent = 'Enviando…';
  try { await action(); } catch (error) { message(error.message); }
  finally { button.disabled = false; button.textContent = label; }
}
