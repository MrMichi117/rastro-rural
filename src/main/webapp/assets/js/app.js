import { api, authenticated, setToken, escape as e, message, submit } from './api.js';
import { welcome, addGuidance, confirmClosing } from './guidance.js';

const main = document.querySelector('#main');
let catalog = { especies: [], sectores: [] }, config = {}, generation = 0, currentUser = null, pendingNotice = null;
const icons = { Bovino:'🐄', Canino:'🐕', Equino:'🐎', Felino:'🐈' };
const stateLabels = { BUSCANDO: 'EN BÚSQUEDA', ENCONTRADO: 'ENCONTRADO', CANCELADO: 'CANCELADO' };
const dateLabel = value => new Intl.DateTimeFormat('es-CO', { dateStyle:'medium' }).format(new Date(`${value.slice(0,10)}T12:00:00`));
const today = () => new Intl.DateTimeFormat('en-CA',{timeZone:'America/Bogota',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
const options = (items, selected = '') => items.map(x => `<option value="${x.id}" ${String(x.id)===String(selected)?'selected':''}>${e(x.nombre)}</option>`).join('');
function photo(r) {
  return r.tiene_foto ? `<img class="animal-photo" src="api/reportes/${r.id}/foto" alt="Fotografía de ${e(r.nombre_animal || r.especie)}" loading="lazy">` : `<div class="animal-placeholder"><span aria-hidden="true">${icons[r.especie] || '🐾'}</span>Sin fotografía · ${e(r.especie_otro || r.especie)}</div>`;
}
function badge(r) { return `<span class="status ${e(r.estado)}">${stateLabels[r.estado]}</span>`; }
function card(r) {
  return `<div class="col-sm-6 col-lg-4"><article class="animal-card">${photo(r)}<div class="card-body"><div class="d-flex justify-content-between align-items-center mb-3">${badge(r)}<small class="text-secondary">#${r.id}</small></div><h2>${e(r.nombre_animal || r.especie_otro || r.especie)}</h2><p class="card-meta">${e(r.especie_otro || r.especie)}${r.identificador_campo ? ' · '+e(r.identificador_campo):''}</p><p class="clamp">${e(r.senas)}</p><div class="card-meta">⌖ ${e(r.sector)}</div><div class="card-bottom"><small class="text-secondary">${dateLabel(r.fecha_perdida)}</small><a href="#reporte/${r.id}">Ver animal y avisar dónde lo vi <span aria-hidden="true">→</span></a></div></div></article></div>`;
}
function requireAccess() {
  if (authenticated()) return true;
  main.innerHTML = '<div class="empty"><h1>Participa con tu comunidad</h1><p>Usa la misma cuenta con la que ingresaste al servidor de la comunidad. No necesitas crear otra cuenta para Rastro Rural.</p><p id="login-cta">Entra a Rastro Rural desde el servidor de la comunidad para continuar.</p></div>';
  return false;
}
async function board(mine, run) {
  if (mine && !requireAccess()) return;
  main.innerHTML = `<section class="d-flex align-items-end justify-content-between gap-4 flex-wrap mb-4"><div><p class="eyebrow">Una red que nos acerca</p><h1>${mine?'Mis reportes':'Ayudemos a que vuelvan a casa'}</h1><p class="lede mb-0">${mine?'Consulta tus publicaciones, comparte novedades y cierra las búsquedas resueltas.':'Cada avistamiento cuenta. Consulta los animales que busca nuestra comunidad y comparte lo que has visto.'}</p></div><a href="#crear" class="btn btn-primary">+ Reportar pérdida</a></section><div id="stats" class="d-flex flex-wrap gap-3 mb-4"></div><section class="panel filters mb-4" aria-label="Filtros de búsqueda"><form id="search" class="row g-3"><div class="col-md-7"><label for="query" class="form-label">Busca una coincidencia</label><input id="query" class="form-control" maxlength="100" placeholder="Nombre, señas, arete o descripción…"></div><div class="col-md-3"><label for="sector" class="form-label">Sector</label><select id="sector" class="form-select"><option value="">Todos los sectores</option>${options(catalog.sectores)}</select></div><div class="col-md-2 d-flex align-items-end"><button class="btn btn-outline-primary w-100" type="submit">Buscar</button></div></form><div class="chips mt-3" role="group" aria-label="Especies"><button class="chip" aria-pressed="true" data-species="">Todas</button>${catalog.especies.map(x=>`<button class="chip" aria-pressed="false" data-species="${x.id}">${e(x.nombre)}</button>`).join('')}</div></section><div class="d-flex justify-content-between mb-3"><h2>${mine?'Tus publicaciones':'Reportes de la comunidad'}</h2><span id="count" class="small text-secondary" aria-live="polite"></span></div><div id="results" class="row g-4" aria-live="polite"></div><div id="pages" class="d-flex justify-content-center align-items-center gap-3 mt-4"></div><aside class="panel mt-5"><h3>¿Encontraste un animal?</h3><p class="mb-0 text-secondary">Busca coincidencias por especie, sector o señas. Entra al reporte del animal y registra un avistamiento con el lugar y la fecha. Evita publicar datos personales o acercarte a animales que puedan ser peligrosos.</p></aside>`;
  let species='',page=1,searchRun=0;
  async function load() {
    const current=++searchRun;
    document.querySelector('#results').innerHTML='<p>Consultando reportes…</p>';
    const params=new URLSearchParams({mine:String(mine),q:document.querySelector('#query').value,sector:document.querySelector('#sector').value,especie:species,page:String(page)});
    try {
      const data=await api('/reportes?'+params);
      if(run!==generation || current!==searchRun) return;
      document.querySelector('#count').textContent=`${data.total} ${Number(data.total)===1?'reporte':'reportes'}`;
      document.querySelector('#results').innerHTML=data.items.length?data.items.map(card).join(''):'<div class="col-12"><div class="empty"><div class="empty-symbol" aria-hidden="true">⌕</div><h3>No hay reportes para esta búsqueda</h3><p class="text-secondary mb-0">Prueba otro sector o especie. También puedes crear el primer reporte.</p></div></div>';
      const max=Math.max(1,Math.ceil(data.total/12));
      document.querySelector('#pages').innerHTML=`<button id="prev" class="btn btn-outline-secondary" ${page===1?'disabled':''}>Anterior</button><span>${page} de ${max}</span><button id="next" class="btn btn-outline-secondary" ${page>=max?'disabled':''}>Siguiente</button>`;
      document.querySelector('#prev').onclick=()=>{page--;load();};document.querySelector('#next').onclick=()=>{page++;load();};
    } catch(error) {if(run===generation && current===searchRun){document.querySelector('#results').innerHTML='<p>No se pudieron cargar los reportes. Usa Buscar para volver a consultar.</p>';message(error.message);}}
  }
  document.querySelector('#search').onsubmit=event=>{event.preventDefault();page=1;load();};
  document.querySelectorAll('[data-species]').forEach(button=>button.onclick=()=>{species=button.dataset.species;page=1;document.querySelectorAll('[data-species]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));load();});
  await load();
  try {
    const stats=await api('/estadisticas');if(run!==generation)return;
    document.querySelector('#stats').innerHTML=`<div class="stat"><strong>${stats.buscando}</strong><small>En búsqueda</small></div><div class="stat"><strong>${stats.encontrados}</strong><small>Ya encontrados</small></div><div class="stat"><strong>${stats.avistamientos}</strong><small>Avistamientos compartidos</small></div>`;
  } catch { /* El listado conserva su manejo de errores; estadísticas no esenciales. */ }
}
async function reportForm(id, run) {
  if(!requireAccess()) return;
  const r=id?await api(`/reportes/${id}`):{};if(run!==generation)return;
  if(id && (!r.es_autor || r.estado!=='BUSCANDO')) throw new Error('Solo puedes editar tus reportes en búsqueda.');
  main.innerHTML=`<p class="breadcrumbs"><a href="#tablero">Tablero</a> / ${id?'Editar reporte':'Nueva búsqueda'}</p><div class="row g-4"><div class="col-lg-8"><p class="eyebrow">La comunidad puede ayudarte</p><h1>${id?'Editar reporte':'Reporta un animal perdido'}</h1><p class="lede">Cuéntanos cómo reconocerlo y dónde fue visto por última vez.</p><form id="report-form" class="panel"><h2 class="mb-4">Datos del animal</h2><div class="row g-3"><div class="col-sm-6"><label for="especie_id" class="form-label">Especie *</label><select name="especie_id" id="especie_id" class="form-select" required><option value="">Selecciona una especie</option>${options(catalog.especies,r.especie_id)}</select></div><div class="col-sm-6" id="other-wrap" hidden><label for="especie_otro" class="form-label">¿Qué especie? *</label><input class="form-control" id="especie_otro" name="especie_otro" maxlength="80" value="${e(r.especie_otro)}"></div><div class="col-sm-6"><label for="nombre_animal" class="form-label">Nombre del animal</label><input id="nombre_animal" name="nombre_animal" class="form-control" maxlength="100" value="${e(r.nombre_animal)}" placeholder="Si lo tiene"></div><div class="col-12"><label for="identificador_campo" class="form-label">Arete, marca o identificación</label><input id="identificador_campo" name="identificador_campo" class="form-control" maxlength="100" value="${e(r.identificador_campo)}"></div><div class="col-12"><label for="senas" class="form-label">Señas particulares *</label><textarea id="senas" name="senas" class="form-control" maxlength="1000" rows="3" required placeholder="Color, tamaño, manchas, collar…">${e(r.senas)}</textarea></div><div class="col-sm-6"><label for="sector_id" class="form-label">Último sector conocido *</label><select id="sector_id" name="sector_id" class="form-select" required><option value="">Selecciona un sector</option>${options(catalog.sectores,r.sector_id)}</select></div><div class="col-sm-6"><label for="fecha_perdida" class="form-label">Fecha de pérdida *</label><input id="fecha_perdida" name="fecha_perdida" type="date" class="form-control" required min="2000-01-01" max="${today()}" value="${e(r.fecha_perdida)}"></div><div class="col-12"><label for="descripcion" class="form-label">Descripción de lo ocurrido *</label><textarea id="descripcion" name="descripcion" class="form-control" maxlength="2000" rows="4" required>${e(r.descripcion)}</textarea></div><div class="col-12"><label for="foto" class="form-label">Fotografía opcional</label><input id="foto" class="form-control" type="file" accept="image/jpeg,image/png"><p class="form-text">JPEG o PNG. Máximo 2 MB y 16 megapíxeles.${id?' Deja vacío para conservar la fotografía.':''}</p>${id&&r.tiene_foto?'<label class="d-flex gap-2 align-items-center"><input id="remove-photo" type="checkbox"> Quitar fotografía actual</label>':''}</div></div><p class="small text-secondary mt-4">Los datos del reporte serán públicos. No incluyas teléfonos, documentos ni direcciones privadas. * Campos obligatorios.</p><div class="d-flex gap-3 flex-wrap"><button type="submit" class="btn btn-primary">${id?'Guardar cambios':'Publicar reporte'}</button><a class="btn btn-outline-secondary" href="${id?'#reporte/'+id:'#tablero'}">Volver</a></div></form></div><aside class="col-lg-4"><div class="panel mt-lg-5"><p class="eyebrow">Un buen reporte ayuda</p><h2>Los detalles hacen la diferencia</h2><p>Describe una marca que permita reconocer al animal. Indica el sector más cercano y una fecha precisa.</p><hr><p class="small mb-0">Necesitas conexión para publicar. El reporte solo queda guardado cuando el servidor confirma el envío.</p></div></aside></div>`;
  const species=document.querySelector('#especie_id');
  function other(){const required=catalog.especies.find(x=>x.id===Number(species.value))?.nombre==='Otro';document.querySelector('#other-wrap').hidden=!required;document.querySelector('#especie_otro').required=required;}
  species.onchange=other;other();
  const form=document.querySelector('#report-form');
  form.onsubmit=event=>{event.preventDefault();submit(form,async()=>{
    const body=Object.fromEntries(new FormData(form));body.especie_id=Number(body.especie_id);body.sector_id=Number(body.sector_id);
    if(id)body.version=r.version;
    const file=document.querySelector('#foto').files[0];
    if(file){if(file.size>2_000_000)throw new Error('La fotografía supera los 2 MB.');body.foto=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result);reader.onerror=()=>reject(new Error('No se pudo leer la fotografía.'));reader.readAsDataURL(file);});}
    else if(document.querySelector('#remove-photo')?.checked)body.foto=null;
    const saved=await api(id?`/reportes/${id}`:'/reportes',{method:id?'PUT':'POST',body:JSON.stringify(body)});
    pendingNotice='Tu reporte quedó guardado. Ya puedes verlo y recibir pistas de tus vecinos.';
    location.hash=`reporte/${id||saved.id}`;
  });};
}
async function detail(id, run) {
  const r=await api(`/reportes/${id}`);if(run!==generation)return;
  main.innerHTML=`<p class="breadcrumbs"><a href="#tablero">Tablero</a> / Reporte #${r.id}</p><div class="row g-4"><section class="col-lg-7"><div class="detail-photo mb-4">${photo(r)}</div><div class="panel">${badge(r)}<h1 class="mt-3">${e(r.nombre_animal||r.especie_otro||r.especie)}</h1><p class="text-secondary">${e(r.especie_otro||r.especie)} · Reporte #${r.id}</p><dl class="row"><dt class="col-sm-4">Último sector</dt><dd class="col-sm-8">${e(r.sector)}</dd><dt class="col-sm-4">Fecha de pérdida</dt><dd class="col-sm-8">${dateLabel(r.fecha_perdida)}</dd><dt class="col-sm-4">Identificación</dt><dd class="col-sm-8">${e(r.identificador_campo||'No especificada')}</dd></dl><h2>Señas particulares</h2><p class="prewrap">${e(r.senas)}</p><h2>Lo que sabemos</h2><p class="prewrap">${e(r.descripcion)}</p>${r.es_autor&&r.estado==='BUSCANDO'?`<hr><div class="d-flex gap-2 flex-wrap"><a class="btn btn-outline-primary" href="#editar/${r.id}">Editar</a><button class="btn btn-primary" id="found">Ya lo encontré</button><button class="btn btn-outline-danger" id="cancel">Cancelar reporte</button></div>`:''}</div></section><section class="col-lg-5"><div class="panel mb-4"><p class="eyebrow">La comunidad aporta</p><h2>Avistamientos <span class="text-secondary">(${r.avistamientos.length})</span></h2><p class="small text-secondary">Observaciones registradas por vecinos, ordenadas de la más reciente a la más antigua.</p>${r.avistamientos.length?`<ol class="timeline mt-4">${r.avistamientos.map(a=>`<li><strong>${e(a.sector)}</strong><p class="small text-secondary mb-2">${dateLabel(a.fecha_avistamiento)} · ${e(a.fecha_avistamiento.slice(11,16))} (Bogotá)</p><p class="prewrap mb-0">${e(a.observacion)}</p></li>`).join('')}</ol>`:'<p class="py-3 text-secondary">Todavía no hay avistamientos. Tu información puede ser la primera pista.</p>'}</div>${r.estado==='BUSCANDO'?`<div class="panel" id="sighting-panel"><h2>¿Lo has visto?</h2><p class="text-secondary">Indica el sector, el día y la hora en que viste al animal. Luego cuenta algo que ayude a reconocerlo, por ejemplo: “Estaba junto al puente”. Toca “Registrar avistamiento” al terminar.</p>${authenticated()?`<form id="sighting" tabindex="-1"><label class="form-label" for="sighting-sector">Sector *</label><select class="form-select mb-3" id="sighting-sector" name="sector_id" required><option value="">Selecciona un sector</option>${options(catalog.sectores)}</select><label class="form-label" for="sighting-date">Fecha y hora (Bogotá) *</label><input id="sighting-date" class="form-control mb-3" name="fecha_avistamiento" type="datetime-local" min="${e(r.fecha_perdida)}T00:00" required><label class="form-label" for="observation">¿Qué observaste? *</label><textarea id="observation" placeholder="Ejemplo: lo vi al lado del puente, caminando hacia la escuela." class="form-control mb-3" name="observacion" rows="4" maxlength="2000" required></textarea><button type="submit" class="btn btn-primary w-100">Registrar avistamiento</button></form>`:'<p id="sighting-access" tabindex="-1">Entra a Rastro Rural desde el servidor de la comunidad para registrar una pista.</p>'}</div>`:'<div class="panel"><h2>Búsqueda cerrada</h2><p class="mb-0">Este reporte ya no recibe avistamientos.</p></div>'}</section></div>`;
  if(r.estado==='BUSCANDO') {
    const jump=document.createElement('button');jump.type='button';jump.className='btn btn-primary sighting-jump';jump.textContent='Lo vi: contar dónde';
    jump.onclick=()=>{document.querySelector('#sighting-panel').scrollIntoView({block:'start'});(document.querySelector('#sighting-sector') || document.querySelector('#sighting-access')).focus({preventScroll:true});};
    main.prepend(jump);
  }
  const form=document.querySelector('#sighting');
  if(form)form.onsubmit=event=>{event.preventDefault();submit(form,async()=>{const body=Object.fromEntries(new FormData(form));body.sector_id=Number(body.sector_id);await api(`/reportes/${id}/avistamientos`,{method:'POST',body:JSON.stringify(body)});await route();message('Avistamiento registrado. Gracias por ayudar.','success');});};
  async function change(state,button){if(!await confirmClosing(state==='ENCONTRADO'))return;button.disabled=true;try{await api(`/reportes/${id}/estado`,{method:'PATCH',body:JSON.stringify({estado:state,version:r.version})});await route();message('El estado del reporte fue actualizado.','success');}catch(error){message(error.message);}finally{button.disabled=false;}}
  document.querySelector('#found')?.addEventListener('click',event=>change('ENCONTRADO',event.currentTarget));document.querySelector('#cancel')?.addEventListener('click',event=>change('CANCELADO',event.currentTarget));
}
function survey() {
  if(!requireAccess())return;
  const questions=['Me resultó fácil aprender a utilizar este subproyecto.','Pude encontrar fácilmente las opciones y funciones que necesitaba.','La información y los textos de la interfaz fueron claros y comprensibles.','Logré realizar las tareas que necesitaba sin dificultades innecesarias.','En general, estoy satisfecho con la experiencia de uso de este subproyecto.'];
  const labels=['Totalmente en desacuerdo','En desacuerdo','Ni de acuerdo ni en desacuerdo','De acuerdo','Totalmente de acuerdo'];
  main.innerHTML=`<div class="row justify-content-center"><div class="col-lg-9"><p class="eyebrow">Tu experiencia nos ayuda a mejorar</p><h1>¿Cómo te fue con Rastro Rural?</h1><p class="lede">Cinco preguntas sobre tu experiencia. Selecciona una respuesta en cada afirmación.</p><form id="survey" class="panel"><h2>Encuesta de usabilidad y satisfacción</h2><p class="small text-secondary">Cuestionario propio · Versión 1 · Una respuesta por persona</p>${questions.map((q,i)=>`<fieldset class="survey-question"><legend>${i+1}. ${q}</legend><div class="ratings">${labels.map((label,j)=>`<label class="rating"><input type="radio" name="respuesta_${i+1}" value="${j+1}" required><span><strong>${j+1}</strong> · ${label}</span></label>`).join('')}</div></fieldset>`).join('')}<p class="small text-secondary mt-4">Guardamos tus respuestas asociadas a tu referencia de usuario para evitar duplicados. No se publican en el tablero. Tus respuestas nos ayudan a hacer la aplicación más fácil de usar.</p><button type="submit" class="btn btn-primary">Enviar mi opinión</button></form></div></div>`;
  const form=document.querySelector('#survey');form.onsubmit=event=>{event.preventDefault();submit(form,async()=>{const respuestas=Object.fromEntries([...new FormData(form)].map(([k,v])=>[k,Number(v)]));await api('/v1/encuestas/usabilidad',{method:'POST',body:JSON.stringify({subproyecto_id:'rastro-rural',version_encuesta:1,respuestas})});main.innerHTML='<div class="empty"><h1>Gracias por compartir tu experiencia</h1><p>Tu respuesta quedó guardada en el servidor.</p><a class="btn btn-primary" href="#tablero">Volver al tablero</a></div>';});};
}
function displayName(){return currentUser?.nombre_visible || currentUser?.nombre_usuario || 'vecino';}
function updateAccess(){
  const greeting=document.querySelector('#account-greeting');
  greeting.hidden=!authenticated();
  greeting.textContent=authenticated()?`Hola, ${displayName()}. Ya ingresaste con tu cuenta de la comunidad.`:'';
}
async function route() {
  const run=++generation, hash=location.hash.slice(1)||'inicio';
  updateAccess();document.querySelectorAll('nav a').forEach(a=>{if(a.hash===`#${hash}`)a.setAttribute('aria-current','page');else a.removeAttribute('aria-current');});
  try {
    if(hash==='inicio') {main.innerHTML=welcome(authenticated()?displayName():null);return;}
    if(!catalog.especies.length)catalog=await api('/catalogos');
    if(run!==generation)return;
    if(hash==='tablero'||hash==='mis-reportes')await board(hash==='mis-reportes',run);
    else if(hash==='crear')await reportForm(null,run);
    else if(/^editar\/\d+$/.test(hash))await reportForm(Number(hash.split('/')[1]),run);
    else if(/^reporte\/\d+$/.test(hash))await detail(Number(hash.split('/')[1]),run);
    else if(hash==='encuesta')survey();
    else main.innerHTML='<div class="empty"><h1>Página no encontrada</h1><a href="#inicio">Volver al inicio</a></div>';
    if(run!==generation)return;
    addGuidance(main,hash.split('/')[0]);
    if(pendingNotice){message(pendingNotice,'success');pendingNotice=null;}
  } catch(error) {if(run===generation){main.innerHTML='<div class="empty"><h1>No pudimos cargar esta vista</h1><p>Comprueba la conexión y vuelve a intentarlo.</p><button id="retry" class="btn btn-primary">Reintentar</button></div>';document.querySelector('#retry').onclick=route;message(error.message);}}
}
window.addEventListener('hashchange',()=>{document.querySelector('#feedback').className='mt-3';document.querySelector('#feedback').textContent='';main.scrollIntoView({block:'start'});route();});
window.addEventListener('rastro:access-cleared',()=>{currentUser=null;updateAccess();});
window.addEventListener('offline',()=>{document.querySelector('#connection').textContent='Sin conexión';message('No hay conexión. Los formularios no se guardan localmente. Mantén la pestaña abierta y verifica el estado en el servidor antes de reenviar.','warning');});
// Contrato de integración: solo el opener de un origen configurado puede entregar un token.
window.addEventListener('message',async event=>{
  if(!config.platform_origin || event.origin!==config.platform_origin || event.source!==window.opener || event.data?.type!=='rastro:identity' || typeof event.data.token!=='string')return;
  setToken(event.data.token);try{currentUser=(await api('/me')).usuario;updateAccess();route();}catch(error){setToken(null);message(error.message);}
});
try {
  config=await api('/config');
  // Solo desarrollo: permite probar los formularios sin un selector de acceso.
  // En producción la identidad debe llegar de la plataforma central.
  if(config.development) {
    setToken('dev-vecino-1');
    currentUser=(await api('/me')).usuario;
    updateAccess();
  }
  if(config.platform_origin&&window.opener)window.opener.postMessage({type:'rastro:ready'},config.platform_origin);
} catch(error) {setToken(null);message(error.message);}
await route();
