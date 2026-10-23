import { escape as e } from './api.js';

export function welcome(name) {
  return `<section class="welcome"><p class="eyebrow">Rastro Rural · Grupo 2 · Travesías</p><h1>${name ? `Hola, ${e(name)}` : 'Bienvenido a Rastro Rural'}</h1><p class="welcome-intro">Aquí nos ayudamos a encontrar los animales que se han perdido.</p><p>Si perdiste un animal, cuéntanos cómo es. Si viste uno, avisa dónde lo viste para ayudar a su dueño.</p>${name?'<p class="access-note">Ya ingresaste con tu cuenta de la comunidad. No necesitas registrarte otra vez.</p>':'<p class="access-note">Puedes mirar los animales sin ingresar. Para publicar o avisar dónde viste uno, usa tu cuenta de la comunidad.</p>'}<h2 class="mt-4">¿Qué quieres hacer?</h2><div class="home-actions">
    <a class="home-action" href="#tablero"><span class="action-symbol" aria-hidden="true">⌕</span><span><strong>Ver animales perdidos</strong><span>Mira las fotos y las señas. Si reconoces uno, abre su reporte para avisar dónde lo viste.</span></span><span aria-hidden="true">→</span></a>
    <a class="home-action" href="#crear"><span class="action-symbol" aria-hidden="true">+</span><span><strong>Reportar un animal perdido</strong><span>Cuenta cómo es tu animal y dónde se perdió para que tus vecinos te ayuden.</span></span><span aria-hidden="true">→</span></a>
    <a class="home-action" href="#mis-reportes"><span class="action-symbol" aria-hidden="true">✓</span><span><strong>Revisar mis reportes</strong><span>Lee las pistas de tus vecinos, corrige tus datos o avisa que ya encontraste tu animal.</span></span><span aria-hidden="true">→</span></a>
    <a class="home-action" href="#encuesta"><span class="action-symbol" aria-hidden="true">♡</span><span><strong>Dar mi opinión</strong><span>Responde cinco preguntas para contarnos si fue fácil usar esta aplicación.</span></span><span aria-hidden="true">→</span></a>
  </div></section><section class="panel mt-4" aria-labelledby="how-title"><h2 id="how-title">¿Cómo nos ayudamos?</h2><ol class="simple-steps"><li><strong>Una persona publica su animal perdido.</strong><span>Comparte sus señas y el lugar donde se perdió.</span></li><li><strong>Un vecino cuenta dónde lo vio.</strong><span>Abre el reporte del animal y registra una pista.</span></li><li><strong>El dueño avisa cuando lo encuentra.</strong><span>Así la comunidad sabe que la búsqueda terminó.</span></li></ol><p class="mb-0">Necesitas conexión para enviar información. Espera siempre el mensaje que confirma que quedó guardada.</p></section>`;
}

const guides = {
  tablero: ['Aquí puedes ver los animales perdidos', 'Mira sus fotos y señas. Puedes buscar por nombre, especie o sector. Toca “Ver animal y avisar dónde lo vi” para abrir su información y compartir una pista.'],
  'mis-reportes': ['Aquí están los animales que tú reportaste', 'Abre un reporte para leer las pistas de tus vecinos. Usa “Editar” para corregir datos o “Ya lo encontré” cuando recuperes tu animal.'],
  crear: ['Vamos a contarle a la comunidad qué animal perdiste', 'Completa los datos marcados con *. Si no conoces el nombre o no tienes foto, puedes dejarlos vacíos. Al terminar, toca “Publicar reporte” y espera la confirmación.'],
  editar: ['Aquí puedes corregir tu reporte', 'Revisa los datos, cambia lo necesario y toca “Guardar cambios”. Si ya recuperaste al animal, vuelve a su reporte y toca “Ya lo encontré”.'],
  reporte: ['Revisa si este es el animal que viste', 'Compara la foto y sus señas. Si lo reconoces, ve a “¿Lo has visto?” y cuenta el lugar, la fecha y lo que observaste. A esta pista la llamamos avistamiento.'],
  encuesta: ['Tu opinión nos ayuda a mejorar', 'Lee cada frase y toca una respuesta, del 1 al 5. El 1 significa que no estás de acuerdo y el 5 que estás totalmente de acuerdo. Responde las cinco y toca “Enviar mi opinión”. No hay respuestas buenas o malas.']
};
export function addGuidance(main, view) {
  const guide=guides[view];
  if(!guide || main.querySelector('#login-cta'))return;
  const section=document.createElement('section');
  section.className='module-guide';section.setAttribute('aria-label','Cómo usar esta pantalla');
  section.innerHTML=`<p class="eyebrow">Te acompañamos paso a paso</p><h2>${guide[0]}</h2><p>${guide[1]}</p><a href="#inicio" class="help-link">Volver a la guía de inicio</a>`;
  main.prepend(section);
}

export function confirmClosing(found) {
  return new Promise(resolve=>{
    const dialog=document.createElement('dialog');
    dialog.setAttribute('aria-labelledby','confirmation-title');
    dialog.innerHTML=`<h2 id="confirmation-title">${found?'¿Ya encontraste tu animal?':'¿Quieres cancelar esta búsqueda?'}</h2><p>${found?'Al confirmar, tus vecinos sabrán que lo recuperaste.':'Al confirmar, el animal dejará de aparecer entre los animales perdidos.'} Este reporte dejará de recibir pistas.</p><div class="confirmation-actions"><button type="button" class="btn ${found?'btn-primary':'btn-danger'}" data-confirm>${found?'Sí, ya lo encontré':'Sí, cancelar la búsqueda'}</button><button type="button" class="btn btn-outline-secondary" data-back>Volver sin cambiar nada</button></div>`;
    let accepted=false;
    dialog.addEventListener('close',()=>{dialog.remove();resolve(accepted);},{once:true});
    dialog.querySelector('[data-confirm]').onclick=()=>{accepted=true;dialog.close();};
    dialog.querySelector('[data-back]').onclick=()=>dialog.close();
    document.body.append(dialog);dialog.showModal();dialog.querySelector('[data-back]').focus();
  });
}
