// d11_ptrunk: painel do wizard. O Lua (client/wizard.lua) manda { action: 'wizard', state } a cada mudanca; state nulo
// esconde. Sem foco de NUI: as teclas continuam no jogo.
//   state = { steps?: { current, confirm }, kicker, title, model, hint, values: [[label, valor, cor?]],
//             keys: [[[tecla, acao, principal?], ...], ...] (grupos), confirm?: { title, text, keys } }
const STEPS = ['Câmera', 'Pivô e área', 'Luz', 'Confirmar'];
const $ = (id) => document.getElementById(id);

function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
}

function keyRow(k) {
    const row = el('div', 'key' + (k[2] ? ' main' : ''));
    row.appendChild(el('kbd', null, k[0]));
    row.appendChild(el('span', null, k[1]));
    return row;
}

function render(s) {
    const panel = $('panel');
    const confirm = $('confirm');
    if (!s) { panel.hidden = true; confirm.hidden = true; return; }

    // Passos (so no wizard; calibracao avulsa nao tem)
    const steps = $('steps');
    steps.replaceChildren();
    steps.hidden = !s.steps;
    if (s.steps) {
        const cur = s.steps.confirm ? 4 : s.steps.current;
        STEPS.forEach((name, i) => {
            const n = i + 1;
            steps.appendChild(el('li', n === cur ? 'on' : n < cur ? 'done' : '', n + ' ' + name));
        });
    }
    $('kicker').textContent = s.kicker || '';
    $('title').textContent = s.title || '';
    $('model').textContent = s.model || '';
    $('hint').textContent = s.hint || '';
    $('hint').hidden = !s.hint;

    const values = $('values');
    values.replaceChildren();
    for (const v of s.values || []) {
        values.appendChild(el('dt', null, v[0]));
        const dd = el('dd', null, v[1]);
        if (v[2]) {
            const sw = el('i', 'swatch');
            sw.style.background = v[2];
            dd.prepend(sw);
        }
        values.appendChild(dd);
    }
    values.hidden = !(s.values && s.values.length);

    const keys = $('keys');
    keys.replaceChildren();
    for (const group of s.keys || []) {
        const g = el('div', 'group');
        for (const k of group) g.appendChild(keyRow(k));
        keys.appendChild(g);
    }

    panel.hidden = false;
    if (s.confirm) {
        $('confirm-title').textContent = s.confirm.title || '';
        $('confirm-text').textContent = s.confirm.text || '';
        const ck = $('confirm-keys');
        ck.replaceChildren();
        for (const k of s.confirm.keys || []) ck.appendChild(keyRow(k));
        confirm.hidden = false;
    } else {
        confirm.hidden = true;
    }
}

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d && d.action === 'wizard') render(d.state);
});
