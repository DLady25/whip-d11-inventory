// ============================================
// d11_inventory — o inventario D11 do WHIP
// (d11-hud-theme.css @ bc7f7683d: cartoes opacos empilhados, slot em faixas, carga em azul).
//
// SO DESENHA E LE O MOUSE. Estado, pesos, regras e servidor sao do whip_core: todo gesto e uma
// chamada de api.actions (docs/nui-inventory.md), e um movimento recusado volta sozinho.
// ============================================

import { LOCALES, NUMBER_LOCALE } from './locales.js';

// Idioma: setr d11_locale en | pt-BR no server.cfg (padrao en), lido pelo client/main.lua deste resource. O renderer
// e importado pela pagina do whip_core logo cedo: tenta por ate ~5 s, enquanto o client deste resource sobe. Cada
// tentativa tem prazo: uma resposta que nunca chega nao pode prender o import (o WHIP nao poe prazo nele).
let HAS_CRAFT = false;   // d11_craft rodando (resposta do locale)
const LANG = await (async () => {
    for (let i = 0; i < 8; i++) {
        try {
            const ask = fetch('https://d11_inventory/locale', { method: 'POST', body: '{}' }).then((r) => r.json());
            const j = await Promise.race([ask, new Promise((ok) => setTimeout(() => ok(null), 400))]);
            if (j && typeof j.lang === 'string') { HAS_CRAFT = j.craft === true; return j.lang; }
        } catch (e) { /* o client ainda nao subiu */ }
        await new Promise((ok) => setTimeout(ok, 250));
    }
    return 'en';
})();
const DICT = LOCALES[LANG] || null;   // pt-BR: o proprio texto
const T = (s) => (DICT && DICT[s] != null ? DICT[s] : s);
const NUM = NUMBER_LOCALE[LANG] || 'en-US';

const TYPES = {
    food: ['C', T('Comida')], drink: ['B', T('Bebida')], consumable: ['C', T('Consumível')], medical: ['M', T('Médico')],
    tool: ['T', T('Utilitário')], weapon: ['A', T('Arma')], ammo: ['A', T('Munição')], key: ['K', T('Chave')],
    document: ['D', T('Documento')], container: ['R', T('Recipiente')], accessory: ['E', T('Acessório')],
    electronics: ['E', T('Eletrônico')], currency: ['$', T('Dinheiro')], armour: ['P', T('Proteção')],
    clothing: ['V', T('Roupa')], misc: ['X', T('Diverso')],
};
const KICKER = { glovebox: T('Porta-luvas'), trunk: T('Porta-malas'), boot: T('Porta-malas'), stash: T('Armazenamento'), drop: T('No chão') };
const HOTBAR = 5;
// Faixa de acessorios: 1-5 sao os do WHIP; 6+ a roupa vestida do d11_clothing, um encaixe por categoria
const WORN_FROM = 6;
// 17+: equipamento (D11Inventory.GearSlots no config.lua): radio, colete e armas
const GEAR_FROM = 17;
// Icone do encaixe vazio pelo `icon` do RegisterAccessorySlot (iconSvg do registro tem preferencia)
const SVG = (d) => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">' + d + '</svg>';
// Silhuetas das armas do HUD (d11_hud ui/weapons), embutidas e pintadas pela cor do slot com mascara CSS: sem arquivo
// para carregar (a pagina e a do whip_core) e na mesma cor apagada dos outros icones.
const GEAR_MASK = {
    melee: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKAAAAAfCAQAAADKWg4GAAAEEklEQVR42u2aT2hcVRTGf/fPS1Jbm05DSkItndo2rSlIG6NCTErsFLtRULuIdCMVoqCudCOKiFCqoEvBTRUXKnWlFW3dqEGoxZWIRMHuWlGjxdSFNJ159x4Xc+fNvJlJTBNnMolzZzPvzH3v8r57zj3f+c4oYc0MhcI3fdE1BOCKDL1G3sMAj/BeG8Clhy+Mc6QN4FKHQ3OQ35u/sF3WnrfOQeTZzV6+a10AFTqAJngEaKXsIwiHUcQN31aVxKwrImAXcYPCIbiqXyJsy4BoyJMLUDZ6q3wFNrIwgEXoisD1cis7ybCDLBk24tnEuuazrnm32bMFMKgG+qAmZoBjeBSOt/gVhdTngQodAnUzI4xyF7fTswpSyTV+avA29dEXrn7gPn6pT6RN8Lr9HOdhbkk5r6BaLIE0m08Uz9mYTk7wItbW8T2H4SEmyWEAjw8noVkFPugbfljYZKUxwNsaOuA4wkmGAtoGvaq4om7iSh0oRFfBZ3mFzxjC4RBsSwZrq1Q+3RjEpuDr5TSH8KG2bI9/ozQVPFDh6eUswxSI2tgsvhaziZLWxUdt+G4wHydE2hDzBiNcx9ZUHKplictKh+9VHNoG+I7zGNC5AD3wAUzVBjMtJhgcOd7GcYnLzKKZ4wpCxBYU3fSwmV6iFEFwSOCGbQDx3MQ9PMkFLvJ3nRkRXWxlgD0MsontZMlU5GiHoP+nXimlnohO+LuqIaK+St/Q9JAlyz4OMJSUeaV58we4x1dR8mKFY2qUjrRfOwRTY5mf3EszMm8QcL9mFF2shRUGj9RdXiXACKRSzM3sYT93coBdZCpekHmD29d5camZ6+ts48KWWpgbK2cpYjo4xSTmRrtyZTh9Rd3Zz20MM8wdbA8+JbjklBTgPJ9ymFyAS1Cc5wxjPBCuBMUsp9A8wYbEMscHXGKSvgCYoJjiK8Y5WAFh+ZtQaDB8nRXKzyjfopbT1iwFbNkr1zHAGPdyN1sTWwHFDLuYA57ldfIoFHPs4AqQ4x36cXgsr/E8sJd3GaKAYPiYo0Afb/Ig19EorpHlT+AFTpBHI2gMZ5hmgp1McxTdsDDWxIzwKDEKz6t8EUS//+CjxIgVk1x3y7i8JF/Kz1IaT4uVSJDTieU5sdIlyP2J5TfZJh2C7BMfLF6GJRIkI3+k7osEOZdYTgqCfCgi3whN/ChBltFUSru2S3xS4/mLKaZ4mQy7GaULy9Wg7DzD9wieiBliHIZPeJx+CsB6MlzGMs0Eg+QR1rORAhGzTDBGHrDMhCc9xTFiOrnI+9hExdTNyb2oknTWmH8mlDspi5krS7DUth4+5xA/Mrh62pqL98i0xVTNqYwCF/p95Yzqgw5etpTu0xVP1sAFLNMroCi0/xvTih7IimnRTe8T/gOuL+HIrOBKewAAAABJRU5ErkJggg==',
    sidearm: 'data:image/png;base64,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',
    rifle: 'data:image/png;base64,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',
};
const GEAR_PNG = (name) => '<span class="d11-equip-png" style="-webkit-mask-image:url(' + GEAR_MASK[name] + ');mask-image:url(' + GEAR_MASK[name] + ')"></span>';
const SLOT_ICONS = {
    phone: SVG('<rect x="7" y="3" width="10" height="18" rx="2"/><path d="M11 18h2"/>'),
    cash: SVG('<rect x="3" y="7" width="18" height="10" rx="1.5"/><circle cx="12" cy="12" r="2.2"/>'),
    vehicle_key: SVG('<circle cx="8" cy="15" r="4"/><path d="M11 12l8-8M16 7l2 2M14 9l2 2"/>'),
    radio: SVG('<rect x="7" y="8" width="10" height="13" rx="1.5"/><path d="M9 8V3M10 12h4M10 15h4"/>'),
    armour: SVG('<path d="M12 3l7 3v5c0 5-3 8-7 10-4-2-7-5-7-10V6z"/>'),
    // faca, pistola e rifle: as mesmas silhuetas do HUD de armas (d11_hud, ui/weapons), embutidas em GEAR_MASK
    melee: GEAR_PNG('melee'),
    sidearm: GEAR_PNG('sidearm'),
    rifle: GEAR_PNG('rifle'),
};
const SHORT = { 'Acessório de pescoço': T('Pescoço') };
// Pastas das fotos de roupa (CLOTHING_SLOTS de whip_core/html/js/utils.js)
const CLOTHING_DIRS = {
    c: { 0: '00_head', 1: '01_masks', 2: '02_hair', 3: '03_arms_gloves', 4: '04_pants', 5: '05_bags',
         6: '06_shoes', 7: '07_accessories', 8: '08_undershirts', 9: '09_vests_armour', 10: '10_decals', 11: '11_tops' },
    p: { 0: 'p0_hats', 1: 'p1_glasses', 2: 'p2_ears', 6: 'p6_watches', 7: 'p7_bracelets' },
};
// metadata.foto = '<genero>/<c11|p0>/<colecao>/<NNN>/<CC>' -> endereco da foto da peca, ou null
function clothingPhoto(foto) {
    const m = /^(male|female)\/([cp])(\d+)\/([a-z0-9_]+)\/(\d+)\/(\d+)$/i.exec(String(foto || ''));
    if (!m || typeof globalThis.whipAssetUrl !== 'function') return null;
    const [, g, k, n, col, num, tex] = m;
    const dir = CLOTHING_DIRS[k.toLowerCase()][Number(n)];
    if (!dir) return null;
    const tag = k.toLowerCase() === 'p' ? 'prop' + Number(n) : String(Number(n));
    return globalThis.whipAssetUrl(`img/clothing/${g}/${dir}/${g}_${tag}_${col}_${num}_${tex}.webp`) || null;
}

const fmtKg = (kg) => {
    kg = Number(kg) || 0;
    if (kg > 0 && kg < 1) return Math.round(kg * 1000) + 'g';
    return kg.toLocaleString(NUM, { maximumFractionDigits: 1 }) + 'kg';
};
const fmtMoney = (n) => '$' + (Number(n) || 0).toLocaleString(NUM);

export default function createRenderer({ api, mount, close, addStylesheet, signal }) {
    const { actions } = api;
    // Arrastar ate o personagem de verdade usa/equipa. Sem o anel do whip_core (api.body): o alvo e o corpo inteiro
    // na tela (client/body.lua projeta os ossos) e, com o item em cima, o personagem ganha um contorno. Mesma
    // interface do anel: begin(at), over(x, y), hit(x, y), end().
    const BODY_LABELS = { equip: T('Equipar'), use: T('Usar') };
    const body = (() => {
        const cb = (name, data) => fetch('https://d11_inventory/' + name, {
            method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data || {}),
        }).then((r) => r.json()).catch(() => null);
        let rect = null, timer = 0, hot = false, run = 0, off = false;
        const setHot = (on) => { if (on === hot) return; hot = on; cb('bodyHot', { on }); };
        const poll = (mine) => cb('bodyBox').then((r) => {
            if (mine !== run) return;
            rect = r && !r.hidden ? r : null;
            off = !!(r && r.off);   // gesto desligado (config.lua ou bloqueio): nem corpo nem ficha
            timer = setTimeout(() => poll(mine), 150);
        });
        // So no espaco livre: em cima de uma janela do inventario o alvo e a janela, nunca o corpo atras dela
        const hit = (x, y) => {
            if (!rect || x < rect.x0 * innerWidth || x > rect.x1 * innerWidth
                || y < rect.y0 * innerHeight || y > rect.y1 * innerHeight) return false;
            const el = document.elementFromPoint(x, y);
            return !(el && el.closest && el.closest('.d11inv .d11-card, .d11inv .d11-menu, .d11inv .d11-help'));
        };
        return {
            begin(at) {
                this.end();
                if (actions.equipKind ? !actions.equipKind(at) : !usable(at)) return;
                poll(++run);
            },
            hit,
            over(x, y) { const on = hit(x, y); setHot(on); return on; },
            isOff: () => off,
            end() { run++; clearTimeout(timer); rect = null; setHot(false); },
        };
    })();
    addStylesheet('style.css');
    mount.classList.add('d11inv');

    // camada fixa (fantasma do arrasto, menu, dica, aviso) separada do que o render refaz
    const root = div('d11-root');
    const overlay = div('d11-overlay');
    mount.replaceChildren(root, overlay);

    let drag = null;      // { from, sx, sy, active, ghost, over, slotEl }
    let menu = null;      // { at, el }
    let tip = null;
    let toastTimer = 0;
    let helpOpen = false; // painel do "?" com os comandos

    // ---------------- helpers de DOM ----------------
    function div(cls, text) {
        const e = document.createElement('div');
        if (cls) e.className = cls;
        if (text != null) e.textContent = text;
        return e;
    }
    function span(cls, text) {
        const e = document.createElement('span');
        if (cls) e.className = cls;
        if (text != null) e.textContent = text;
        return e;
    }
    const defs = () => api.getItemDefs() || {};
    const addr = (container, slot) => ({ container, slot: Number(slot) });

    function weightOf(container) {
        try { return actions.weightOf(container) || { now: 0, max: 0 }; } catch (e) { return { now: 0, max: 0 }; }
    }
    function usedSlots(items) {
        let n = 0;
        for (const k in items || {}) if (items[k]) n++;
        return n;
    }

    // ---------------- slot ----------------
    function slotEl(container, slot, opts) {
        opts = opts || {};
        const at = addr(container, slot);
        const d = actions.slotAt(container, slot);
        const el = div('d11-slot' + (opts.small ? ' small' : ''));
        el.dataset.c = container;
        el.dataset.s = String(slot);
        // tecla de uso rapido: no canto do slot pequeno ou vazio; no slot cheio da grade, no lugar do emblema
        if (opts.key != null && (opts.small || !d)) el.appendChild(span('d11-key', String(opts.key)));
        if (!d) { el.classList.add('empty'); return el; }

        const def = defs()[d.item] || {};
        const t = TYPES[def.type] || [String(def.type || d.item || '?').charAt(0).toUpperCase(), def.type || 'Item'];
        const money = def.type === 'currency' || d.item === 'cash';
        el.classList.add('filled');
        const rarity = d.metadata && d.metadata.rarity;
        if (rarity) el.classList.add('rarity-' + String(rarity).toLowerCase());
        const ownPanel = panelOfItem(d);
        if (ownPanel) {
            el.classList.add('bag-open');
            if (ownPanel === fillingPanel()) el.classList.add('bag-filling');
            el.appendChild(span('d11-bag-tag', ownPanel === fillingPanel() ? T('Enchendo') : T('Aberta')));
        }

        if (!opts.small) {
            const top = div('d11-slot-top');
            top.appendChild(opts.key != null ? span('d11-key in-top', String(opts.key)) : span('d11-emblem', t[0]));
            const kg = d.w != null ? d.w : (Number(def.weight) || 0) * (Number(d.amount) || 1);
            const info = div('d11-slot-info');
            info.appendChild(span('d11-weight', fmtKg(kg)));
            info.appendChild(span('d11-qty', money ? fmtMoney(d.amount) : (Number(d.amount) || 1) + 'x'));
            top.appendChild(info);
            el.appendChild(top);
        } else if ((Number(d.amount) || 1) > 1 || money) {
            el.appendChild(span('d11-qty corner', money ? fmtMoney(d.amount) : String(d.amount)));
        }

        const img = document.createElement('img');
        img.className = 'd11-img';
        img.alt = '';
        img.draggable = false;
        api.setItemImage(img, d);
        // roupa do d11_clothing: a foto real da peca; sem ela fica o icone da categoria
        const photo = clothingPhoto(d.metadata && d.metadata.foto);
        if (photo) {
            const fallback = img.src;
            img.classList.add('photo');
            img.onerror = () => { img.onerror = null; img.classList.remove('photo'); if (fallback) img.src = fallback; else api.setItemImage(img, d); };
            img.src = photo;
        }
        el.appendChild(img);

        if (!opts.small) {
            const foot = div('d11-slot-foot');
            foot.appendChild(span('d11-name', def.name || d.item));
            foot.appendChild(span('d11-type', t[1]));
            el.appendChild(foot);
        }
        const price = inv().stockMode && container === 'container' && inv().stockPrices && inv().stockPrices[d.item];
        if (price) el.appendChild(span('d11-price' + (price.forSale ? '' : ' off'), fmtMoney(price.price)));

        el.addEventListener('pointerdown', (e) => onDown(e, at, el));
        el.addEventListener('contextmenu', (e) => { e.preventDefault(); if (!drag || !drag.active) openMenu(at, e.clientX, e.clientY); });
        el.addEventListener('dblclick', () => {
            if (container === 'ground' && opensAsPanel(d)) return openGround(at);
            if (container === 'container' && opensAsPanel(d)) return openStore(at);
            run(actions.use(at));
        });
        el.addEventListener('mouseenter', (e) => showTip(at, e));
        el.addEventListener('mousemove', moveTip);
        el.addEventListener('mouseleave', hideTip);
        return el;
    }

    // A tecla (1-5) que usa este slot: Config.HotbarSlots do whip_core (patch hotbar-slots: 1-3 nas armas do
    // equipamento), ou, sem ele, os bolsos 1-5. null = nenhuma.
    function keyOf(container, slot) {
        const map = api.slotConfig && api.slotConfig.hotbar;
        for (let i = 1; i <= HOTBAR; i++) {
            const t = map && (Array.isArray(map) ? map[i - 1] : map[String(i)]);
            if (((t && t.container) || 'player') === container && ((t && t.slot) || i) === slot) return i;
        }
        return null;
    }

    function grid(container, count, cols, opts) {
        const g = div('d11-grid');
        g.style.setProperty('--cols', String(cols));
        // numero da tecla de uso rapido no canto do slot que ela usa (o cartao "Acesso rapido" saiu)
        for (let s = 1; s <= count; s++) {
            const k = keyOf(container, s);
            g.appendChild(slotEl(container, s, k ? Object.assign({}, opts, { key: k }) : opts));
        }
        return g;
    }

    // ---------------- cartoes ----------------
    function card(cls) { return div('d11-card ' + (cls || '')); }

    function gridHeader(kicker, title, container, slots, used) {
        const h = div('d11-grid-head');
        const left = div('d11-grid-title');
        if (kicker) left.appendChild(div('d11-kicker', kicker));
        const row = div('d11-title-row');
        row.appendChild(div('d11-title', title));
        if (slots) row.appendChild(span('d11-chip', used + '/' + slots + ' slots'));
        left.appendChild(row);
        h.appendChild(left);
        const w = weightOf(container);
        if (w.max > 0) {
            const box = div('d11-load');
            const label = div('d11-load-label');
            label.appendChild(span('d11-load-k', T('Carga')));
            label.appendChild(span('d11-load-v', (Number(w.now) || 0).toLocaleString(NUM, { maximumFractionDigits: 2 })));
            label.appendChild(span('d11-load-max', ' / ' + w.max + ' kg'));
            box.appendChild(label);
            const bar = div('d11-bar');
            const fill = div('d11-bar-fill');
            const p = Math.max(0, Math.min(1, w.now / w.max));
            fill.style.transform = 'scaleX(' + p + ')';
            if (p >= 0.9) bar.classList.add('full'); else if (p >= 0.75) bar.classList.add('near');
            bar.appendChild(fill);
            box.appendChild(bar);
            h.appendChild(box);
        }
        return h;
    }

    function shellHeader() {
        const c = card('d11-shell');
        const brand = div('d11-brand');
        const mark = div('d11-brand-mark');
        mark.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 8h14l-1 12H6L5 8Z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/></svg>';
        brand.appendChild(mark);
        brand.appendChild(div('d11-shell-title', T('Inventário')));
        c.appendChild(brand);

        const ctrls = div('d11-ctrls');
        // Crafting (d11_craft): o resource fecha o inventario e abre o crafting; de la, "Inventario" volta para ca.
        const craft = document.createElement('button');
        craft.className = 'd11-pill-btn wide';
        craft.textContent = T('Crafting');
        craft.title = T('Crafting');
        craft.addEventListener('click', () => {
            fetch('https://d11_craft/openFromInventory', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }).catch(() => {});
        });
        if (HAS_CRAFT) ctrls.appendChild(craft);
        const help = document.createElement('button');
        help.className = 'd11-pill-btn' + (helpOpen ? ' on' : '');
        help.textContent = '?';
        help.title = T('Comandos');
        help.addEventListener('click', () => { helpOpen = !helpOpen; render(); });
        ctrls.appendChild(help);
        const esc = document.createElement('button');
        esc.className = 'd11-pill-btn wide';
        esc.textContent = 'Esc';
        esc.addEventListener('click', () => close());
        ctrls.appendChild(esc);
        c.appendChild(ctrls);
        if (helpOpen) c.appendChild(helpPanel());
        return c;
    }

    // "?": os comandos do inventario, teclado/mouse e controle
    const HELP = [
        [T('Mouse e teclado'), [
            [T('Arrastar'), T('Mover o item')],
            [T('No personagem'), T('Arraste até o anel no seu personagem (ou a ficha) para usar ou equipar')],
            [T('Fora da janela'), T('Arraste para fora para largar no chão')],
            [T('Shift + clique'), T('Enviar para o outro lado')],
            [T('Duplo clique'), T('Usar')],
            [T('Botão direito'), T('Opções (Usar, Dar, Dividir…)')],
            ['1 – 5', T('Acesso rápido, fora do inventário')],
            ['Esc', T('Fechar')],
        ]],
        [T('Controle'), [
            [T('Analógico esq.'), T('Mover o cursor')],
            [T('D-pad'), T('Pular para o slot vizinho')],
            ['A', T('Toque: clicar · Segurar: arrastar · 2x: usar')],
            ['X', T('Opções · Arrastando: mover 1')],
            ['Y', T('Usar')],
            [T('RB + A'), T('Enviar para o outro lado')],
            [T('LB / RB'), T('Trocar de coluna')],
            ['B', T('Voltar / soltar / fechar')],
        ]],
    ];
    function helpPanel() {
        const p = div('d11-help');
        for (const [title, rows] of HELP) {
            p.appendChild(div('d11-kicker', title));
            const list = div('d11-help-list');
            for (const [k, v] of rows) {
                list.appendChild(span('d11-help-key', k));
                list.appendChild(span('d11-help-val', v));
            }
            p.appendChild(list);
        }
        p.appendChild(div('d11-help-note', T('Dar e Dividir pedem a quantidade no próprio menu.')));
        return p;
    }

    function characterCard() {
        const i = inv();
        const c = card('d11-character');
        c.dataset.dropLabel = T('Soltar para usar');   // style.css: .use-target::after
        const top = div('d11-char-top');
        const who = div('d11-char-who');
        who.appendChild(div('d11-char-name', i.charName || T('Sem personagem')));
        if (i.accountNum) who.appendChild(span('d11-chip', T('Conta ') + i.accountNum));
        top.appendChild(who);
        if (i.charId) top.appendChild(div('d11-char-id', T('ID ') + i.charId));
        c.appendChild(top);

        let cash = 0, items = 0;
        const st = i.state || {};
        const all = [].concat(Object.values(st.player || {}), Object.values(st.accessory || {}));
        for (const d of all) {
            if (!d) continue;
            items++;
            const def = defs()[d.item] || {};
            if (def.type === 'currency' || d.item === 'cash') cash += Number(d.amount) || 0;
        }
        const w = weightOf('player');
        const chips = div('d11-char-chips');
        chips.appendChild(stat(T('Em mãos'), fmtMoney(cash)));
        chips.appendChild(stat(T('Itens'), String(items)));
        chips.appendChild(stat(T('Carga'), fmtKg(w.now) + (w.max ? ' / ' + w.max + 'kg' : '')));
        c.appendChild(chips);
        const eq = equipSection();
        if (eq) c.appendChild(eq);
        return c;
    }
    function stat(k, v) {
        const s = div('d11-stat');
        s.appendChild(span('d11-stat-k', k));
        s.appendChild(span('d11-stat-v', v));
        return s;
    }

    // Equipado: secao da ficha com dois blocos da faixa de acessorios do WHIP, sem nome embaixo (nome no hover):
    //   Equipado = encaixes 1-5 + divisor + equipamento (17+), numa linha; Roupa (6-16, compacta, com o nome embaixo)
    function equipSection() {
        const cfg = (api.slotConfig && api.slotConfig.accessorySlots) || [];
        if (!cfg.length) return null;
        const sec = div('d11-equip');
        const base = cfg.filter((s) => s.slot < WORN_FROM);
        const gear = cfg.filter((s) => s.slot >= GEAR_FROM);
        const groups = [
            [T('Equipado'), base.concat(gear), '', base.length && gear.length ? base.length : 0],
            [T('Roupa'), cfg.filter((s) => s.slot >= WORN_FROM && s.slot < GEAR_FROM), ' worn', 0],
        ];
        for (const [title, list, cls, splitAt] of groups) {
            if (!list.length) continue;
            const head = div('d11-sec-head');
            head.appendChild(div('d11-kicker', title));
            let used = 0;
            for (const s of list) if (actions.slotAt('accessory', s.slot)) used++;
            head.appendChild(span('d11-chip', used + '/' + list.length));
            sec.appendChild(head);
            const row = div('d11-equip-row' + cls);
            row.style.setProperty('--cols', String(list.length));
            list.forEach((s, i) => {
                const cell = div('d11-equip-cell' + (splitAt && i === splitAt ? ' split' : ''));
                const el = slotEl('accessory', s.slot, { small: true, key: keyOf('accessory', s.slot) });
                const svg = s.iconSvg || SLOT_ICONS[s.icon];
                if (el.classList.contains('empty') && svg) {
                    const ic = div('d11-equip-icon' + (svg.includes('d11-equip-png') ? ' png' : ''));
                    ic.innerHTML = svg;
                    el.appendChild(ic);
                }
                const label = s.label || T('Acessório');
                cell.title = SHORT[label] || T(label);
                cell.appendChild(el);
                // roupa vazia nao tem icone: o nome fica embaixo
                if (cls) cell.appendChild(span('d11-equip-label', cell.title));
                row.appendChild(cell);
            });
            sec.appendChild(row);
        }
        return sec;
    }

    function pocketsCard() {
        const i = inv();
        const c = card('d11-pockets');
        const slots = (i.maxSlots && i.maxSlots.player) || 0;
        c.appendChild(gridHeader(T('Mochila'), T('Bolsos'), 'player', slots, usedSlots(i.state && i.state.player)));
        const g = grid('player', slots, 5);
        g.classList.add('scroll');
        c.appendChild(g);
        return c;
    }

    function externalCards() {
        const i = inv();
        const out = [];
        if (i.playerInvOpen) {
            const c = card('d11-external');
            const slots = (i.playerInvMaxSlots && i.playerInvMaxSlots.player) || 30;
            c.appendChild(gridHeader(T('Revista'), i.playerInvCharName || T('Jogador'), 'targetPlayer', slots, usedSlots(i.playerInvItems && i.playerInvItems.player)));
            c.appendChild(grid('targetPlayer', slots, 5));
            out.push(c);
        }
        if (i.containerOpen) {
            const def = i.containerDef || {};
            const c = card('d11-external');
            const slots = def.slots || 20;
            c.appendChild(gridHeader(KICKER[def.type] || T('Armazenamento externo'), def.name || T('Armazenamento'), 'container', slots, usedSlots(i.containerItems)));
            // Com uma bolsa ou caixa aberta, a grade do store encolhe (rola por dentro) para o painel dela aparecer sem
            // descer a coluna: senao parece que nao abriu.
            if ((i.panels || []).length) c.classList.add('d11-compact');
            if (pt.on) {
                c.classList.add('d11-pt-card');   // nao 'pt-card': o whip_core usa esse nome (property-themes.css, com hover)
                c.appendChild(ptTools());
                if (pt.help) c.appendChild(ptKeys());
            }
            c.appendChild(grid('container', slots, 5));
            out.push(c);
        }
        if (i.ignitionOpen) {
            const c = card('d11-ignition');
            c.appendChild(div('d11-kicker', T('Ignição')));
            c.appendChild(slotEl('ignition', 1, { small: true }));
            out.push(c);
        }
        // Bolsas e carteiras abertas. A mais nova e onde o Shift+clique dos bolsos vai parar (quickMove do WHIP):
        // ela fica marcada "Enchendo" e a bolsa dona dela brilha nos bolsos. O "x" fecha so aquela aba.
        const target = fillingPanel();
        for (const p of i.panels || []) {
            const filling = p === target;
            const c = card('d11-external d11-panel' + (filling ? ' filling' : ''));
            c.dataset.panel = p.key;
            const used = usedSlots(p.items);
            const head = gridHeader(p.readOnly ? T('Somente leitura') : filling ? T('Enchendo') : T('Aberto'), p.label || T('Painel'), p.key, p.slots, used);
            if (p.id != null) {
                const x = document.createElement('button');
                x.className = 'd11-pill-btn d11-panel-close';
                x.textContent = '×';
                x.title = T('Fechar');
                x.addEventListener('click', () => closePanel(p, c));
                head.appendChild(x);
            }
            c.appendChild(head);
            c.appendChild(grid(p.key, p.slots || 0, 5));
            out.push(c);
        }
        let ground = false;
        try { ground = actions.groundShowing(); } catch (e) { ground = false; }
        if (ground) {
            const piles = i.groundItems || {};
            let n = 0;
            for (const k in piles) if (piles[k]) n = Math.max(n, Number(k) || 0);
            const count = Math.max(10, Math.ceil((n + 1) / 5) * 5);
            const c = card('d11-external d11-ground');
            c.appendChild(gridHeader(T('Por perto'), T('Chão'), 'ground', 0, 0));
            c.appendChild(grid('ground', count, 5));
            out.push(c);
        }
        return out;
    }

    function inv() { return api.inv; }

    // ---------------- abas de bolsa ----------------
    function fillingPanel() {
        let best = null;
        for (const p of inv().panels || []) if (!p.readOnly && (!best || (p.openedAt || 0) >= (best.openedAt || 0))) best = p;
        return best;
    }
    // A bolsa dona de um painel: o id do item-painel do whip_core termina no uid do item (<acao>_<source>_<uid>).
    function panelOfItem(d) {
        const uid = d && d.metadata && d.metadata.uid;
        if (uid == null) return null;
        const tail = '_' + uid;
        for (const p of inv().panels || []) if (p.id != null && String(p.id).endsWith(tail)) return p;
        return null;
    }
    function post(name, body) {
        return fetch('https://d11_inventory/' + name, {
            method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(body || {}),
        }).catch(() => null);
    }
    function closePanel(p, c) {
        if (c) c.classList.add('closing');
        post('closePanel', { id: p.id });
    }
    // Item-painel (bolsa, carteira): o que se abre pelo defaultAction e esta no menu
    function opensAsPanel(d) {
        const def = d && defs()[d.item];
        return !!(def && def.defaultAction && (def.contextOptions || []).some((o) => o.action === def.defaultAction));
    }
    function openGround(at) {
        const g = (inv().groundItems || {})[String(at.slot)];
        if (!g || g.groundId == null) return;
        post('openGround', { id: g.groundId })
            .then((r) => (r && r.json ? r.json() : null))
            .then((r) => { if (r && r.fallback) pickUpAndOpen(at, g); })
            .catch(() => {});
    }
    // Bolsa ou caixa dentro do porta-malas ou da stash aberta: abre ali (patch whip_core-store-panel-d11); sem o patch
    // (fallback), pega para os bolsos e abre ali, como no chao.
    function openStore(at) {
        const i = inv();
        const d = actions.slotAt(at.container, at.slot);
        if (!d || i.containerStoreId == null) return;
        post('openStore', { store: String(i.containerStoreId), slot: at.slot })
            .then((r) => (r && r.json ? r.json() : null))
            .then((r) => { if (r && r.fallback) pickUpAndOpen(at, d); })
            .catch(() => {});
    }
    // Sem o patch do whip_core (client/main.lua responde fallback): pega a bolsa do chao para os bolsos, como o
    // Shift+clique, e quando o servidor confirmar abre ali pelo defaultAction dela.
    function pickUpAndOpen(at, g) {
        const action = (defs()[g.item] || {}).defaultAction;
        const uid = g.metadata && g.metadata.uid;
        const r = actions.quickMove(at);
        run(r);
        if (!r || !r.ok || !action) return;
        const deadline = Date.now() + 3000;
        const tryOpen = () => {
            const pending = api.ops && api.ops.hasPendingOps && api.ops.hasPendingOps();
            const at2 = pending ? null : pocketWith(g.item, uid);
            if (at2) return run(actions.runOption(at2, action, {}));
            if (Date.now() < deadline) setTimeout(tryOpen, 150);
        };
        setTimeout(tryOpen, 150);
    }
    function pocketWith(item, uid) {
        for (const c of ['player', 'accessory']) {
            const st = (inv().state || {})[c] || {};
            for (const k in st) {
                const d = st[k];
                if (d && d.item === item && (uid == null || (d.metadata && d.metadata.uid === uid))) return addr(c, k);
            }
        }
        return null;
    }

    // ---------------- porta-malas fisico (d11_ptrunk) ----------------
    // Com um porta-malas aberto, pergunta ao d11_ptrunk se ele esta no modo fisico daquele carro (camera atras do
    // carro, itens como objetos). Ligado: sem o escurecido do fundo, o espaco entre as colunas mostra o porta-malas e
    // soltar ali guarda no porta-malas; o conteudo vai para o Lua montar os objetos. Sem o resource, nada muda.
    const pt = { on: false, polling: false, sig: null, state: { light: true, grid: false, highlights: false, gizmo: false, hud: false }, help: false };
    function ptPost(name, body) {
        return fetch('https://d11_ptrunk/' + name, {
            method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(body || {}),
        }).then((r) => r.json()).catch(() => null);
    }
    function ptStore() {
        const i = inv();
        const id = i && i.open && i.containerOpen ? String(i.containerStoreId || '') : '';
        return /^vehicle:\d+:trunk$/.test(id) ? id : null;
    }
    function ptSet(on) {
        if (pt.on === on) return;
        pt.on = on;
        pt.sig = null;
        mount.classList.toggle('d11pt', on);
        document.documentElement.classList.toggle('d11pt', on);
        ptWorldReset();
        if (on) ptSync();
        queueMicrotask(render);   // o cabecalho do porta-malas entra ou sai
    }
    function ptPoll() {
        const store = ptStore();
        if (!store) { pt.polling = false; ptSet(false); return; }
        ptPost('mode', { store }).then((r) => {
            if (ptStore() !== store) { pt.polling = false; ptSet(false); return; }
            const on = !!(r && r.active);
            if (on) {
                const s = ptStateOf(r);
                const changed = JSON.stringify(s) !== JSON.stringify(pt.state);
                pt.state = s;
                if (changed && pt.on) queueMicrotask(render);
            }
            ptSet(on);
            if (on) ptSync();
            setTimeout(ptPoll, 400);
        });
    }
    function ptSync() {
        if (!pt.on) return;
        const items = [];
        const ci = inv().containerItems || {};
        for (const k in ci) {
            const d = ci[k];
            if (d && d.item) items.push({ slot: Number(k), item: d.item, amount: d.amount || 1, uid: d.metadata && d.metadata.uid != null ? d.metadata.uid : null });
        }
        items.sort((a, b) => a.slot - b.slot);
        const sig = JSON.stringify(items);
        if (sig === pt.sig) return;
        pt.sig = sig;
        // Recusado (o modo fisico ainda nao estava ativo): esquece a assinatura, o proximo ptPoll manda de novo.
        ptPost('items', { items }).then((r) => { if (!(r && r.ok) && pt.sig === sig) pt.sig = null; });
    }
    function ptRender() {
        if (ptStore()) {
            if (!pt.polling) { pt.polling = true; ptPoll(); }
            ptSync();
        } else if (pt.on) ptSet(false);
    }
    // Soltar um item dos bolsos no meio da tela: vai para o primeiro slot livre do porta-malas, e o objeto nasce onde
    // o mouse soltou (o Lua guarda o ponto para aquele slot antes do movimento chegar).
    function isPanelKey(c) { return typeof c === 'string' && c.indexOf('panel:') === 0; }
    // O primeiro slot livre de uma bolsa aberta (aba do painel), ou null se cheia.
    function freePanelSlot(key) {
        const p = (inv().panels || []).find((q) => q.key === key);
        if (!p) return null;
        const items = p.items || {};
        for (let s = 1; s <= (p.slots || 0); s++) if (!items[s] && !items[String(s)]) return s;
        return null;
    }
    // A aba da direita sob (x, y), pelo retangulo de cada uma (nao pelo elemento sob o cursor): { card, key } ou null.
    function rightCardAt(x, y) {
        for (const card of root.querySelectorAll('.d11-right .d11-card')) {
            const r = card.getBoundingClientRect();
            if (x >= r.left && x <= r.right && y >= r.top && y <= r.bottom) return { card, key: card.dataset.panel || null };
        }
        return null;
    }
    // O slot da bolsa `key` onde soltar em (x, y): o slot sob o cursor, senao o primeiro livre.
    function panelSlotAt(key, x, y) {
        const at = targetAt(x, y);
        return at && at.container === key ? at.slot : freePanelSlot(key);
    }
    function ptDeposit(at, x, y) {
        const i = inv();
        const slots = (i.containerDef && i.containerDef.slots) || 0;
        const ci = i.containerItems || {};
        for (let s = 1; s <= slots; s++) {
            if (!ci[s] && !ci[String(s)]) {
                ptPost('place', { slot: s, x: x / innerWidth, y: y / innerHeight });
                return run(actions.move(at, { container: 'container', slot: s }));
            }
        }
        notify(T('O porta-malas está cheio.'));
        render();
    }
    api.events.on('close', () => {
        if (pt.on) ptPost('closed');
        ptSet(false);
    });

    // ---- os objetos no porta-malas (d11_ptrunk, client/edit.lua): o mouse no meio da tela e as teclas vao para o Lua.
    // Passar o mouse mostra a dica do item; clicar e arrastar move o objeto; soltar no painel do jogador retira;
    // botao direito abre as opcoes; WASD, R/F, Q/E, Shift, Ctrl e Backspace vao para o objeto selecionado.
    const wd = { pending: null, inflight: false, hover: null, last: null, down: null, grab: null, keys: {},
        overTrunk: false, orbit: null, orbitAcc: { dx: 0, dy: 0 }, orbitBusy: false, groundTag: null,
        panAcc: { dx: 0, dy: 0 }, panBusy: false };
    function ptFree(x, y) {
        const el = document.elementFromPoint(x, y);
        return !(el && el.closest && el.closest('.d11inv .d11-card, .d11inv .d11-menu, .d11inv .d11-help'));
    }
    function ptOverLeft(x, y) {
        const el = document.elementFromPoint(x, y);
        return !!(el && el.closest && el.closest('.d11inv .d11-left'));
    }
    function ptWithdrawHint(on) {
        const left = root.querySelector('.d11-left');
        if (!left) return;
        left.dataset.hint = T('Solte para retirar');
        left.classList.toggle('pt-withdraw', on);
    }
    // Arrastando um objeto (do porta-malas ou do chao) por cima das abas da direita: a bolsa ou caixa sob o cursor acende
    // e a etiqueta diz que vai para ela; no proprio porta-malas, nada (volta). Devolve a aba sob o cursor, ou null.
    function ptBagHint(e) {
        const rc = e ? rightCardAt(e.clientX, e.clientY) : null;
        root.querySelectorAll('.d11-panel.drop-here').forEach((n) => { if (!rc || n !== rc.card) n.classList.remove('drop-here'); });
        if (!rc) return null;
        if (rc.key) {
            rc.card.classList.add('drop-here');
            const p = (inv().panels || []).find((q) => q.key === rc.key);
            ptTag(T('Guardar em') + ' ' + ((p && p.label) || T('Painel')), 'trunk', e);
        } else {
            ptTag(null);
        }
        return rc;
    }
    // Etiqueta que segue o cursor: zone 'drop' (amarela) ou 'trunk' (azul); text vazio tira.
    function ptTag(text, zone, e) {
        if (!text) { if (wd.groundTag) { wd.groundTag.remove(); wd.groundTag = null; } return; }
        if (!wd.groundTag) {
            wd.groundTag = div('d11-ghost d11-pt-tag');
            overlay.appendChild(wd.groundTag);
        }
        wd.groundTag.dataset.zone = zone || 'drop';
        wd.groundTag.dataset.label = text;
        if (e) wd.groundTag.style.transform = 'translate(' + e.clientX + 'px,' + e.clientY + 'px)';
    }
    function ptGroundHint(on, e) { ptTag(on ? T('Largar no chão') : null, 'drop', e); }
    // Largar no chao no modo porta-malas, do porta-malas ou dos bolsos: vai para o ponto do cursor no chao (qualquer chao
    // perto do carro), senao para o primeiro lugar livre na frente do porta-malas. Quem tira do slot e poe no chao e o servidor
    // do d11_ptrunk; se o chao recusar, o item volta para o slot.
    function ptToGround(at, x, y) {
        if (!at || !(at.container === 'container' || ON_PERSON[at.container] || isPanelKey(at.container))) return;
        const body = { from: at.container, slot: at.slot };
        if (x != null) { body.x = x / innerWidth; body.y = y / innerHeight; }
        ptPost('toGround', body);
    }
    function ptWorldReset() {
        for (const k in wd.keys) if (wd.keys[k]) ptPost('key', { key: k, down: false });
        wd.keys = {};
        wd.grab = null;
        wd.down = null;
        wd.pending = null;
        if (wd.hover != null) { wd.hover = null; hideTip(); }
        wd.orbit = null;
        wd.overTrunk = false;
        ptWithdrawHint(false);
        ptGroundHint(false);
        ptBagHint(null);
    }
    function ptHover(slot) {
        if (wd.grab || drag || menu) { if (wd.hover != null) { wd.hover = null; hideTip(); } return; }
        if (slot === wd.hover) { if (slot != null && wd.last) moveTip(wd.last); return; }
        wd.hover = slot;
        if (slot != null && wd.last) showTip({ container: 'container', slot }, wd.last);
        else hideTip();
    }
    // Um pedido de cada vez: o ultimo ponto espera o anterior responder (o Lua so precisa do mais novo).
    function ptPointer() {
        if (wd.inflight || !wd.pending) return;
        const p = wd.pending;
        wd.pending = null;
        wd.inflight = true;
        ptPost('pointer', p).then((r) => {
            wd.inflight = false;
            if (pt.on) {
                wd.overTrunk = !!(r && r.overTrunk);
                ptHover(r && r.hover != null ? r.hover : null);
                if (wd.grab && wd.last && ptBagHint(wd.last)) {
                    // Em cima de uma aba: ptBagHint ja disse o que acontece.
                } else if (wd.grab && wd.grab.ground && wd.last) {
                    // Item do chao na mao: em cima do porta-malas, "Guardar"; fora, o nome dele.
                    ptTag(wd.overTrunk ? T('Guardar no porta-malas') : wd.grab.label, wd.overTrunk ? 'trunk' : 'drop', wd.last);
                } else if (wd.grab && wd.last) {
                    ptGroundHint(p.free && !wd.overTrunk && !ptOverLeft(wd.last.clientX, wd.last.clientY), wd.last);
                } else if (!drag && wd.last) {
                    // Passando em cima de um item do chao: o nome dele.
                    ptTag(r && r.ground ? r.ground : null, 'drop', wd.last);
                }
                if (drag && drag.active && wd.last) setOver(wd.last.clientX, wd.last.clientY);
            }
            ptPointer();
        });
    }
    // Camera orbital: o botao direito arrastando no meio da tela gira; os deltas juntam enquanto o anterior nao volta.
    function ptOrbitSend() {
        if (wd.orbitBusy) return;
        const a = wd.orbitAcc;
        if (!a.dx && !a.dy) return;
        wd.orbitAcc = { dx: 0, dy: 0 };
        wd.orbitBusy = true;
        ptPost('orbit', a).then(() => { wd.orbitBusy = false; ptOrbitSend(); });
    }
    // Ponto de foco: como o giro, os deltas juntam enquanto o anterior nao volta.
    function ptPanSend() {
        if (wd.panBusy) return;
        const a = wd.panAcc;
        if (!a.dx && !a.dy) return;
        wd.panAcc = { dx: 0, dy: 0 };
        wd.panBusy = true;
        ptPost('pan', a).then(() => { wd.panBusy = false; ptPanSend(); });
    }
    document.addEventListener('pointermove', (e) => {
        if (!pt.on) return;
        wd.last = e;
        if (wd.orbit) {
            // Botao direito (girar ou, com Shift, mover o foco) ou do meio (mover o foco).
            if (!(e.buttons & (wd.orbit.pan && wd.orbit.button === 1 ? 4 : 2))) { wd.orbit = null; return; }
            const dx = e.clientX - wd.orbit.x, dy = e.clientY - wd.orbit.y;
            wd.orbit.x = e.clientX;
            wd.orbit.y = e.clientY;
            if (Math.abs(e.clientX - wd.orbit.sx) + Math.abs(e.clientY - wd.orbit.sy) > 4) wd.orbit.moved = true;
            const acc = wd.orbit.pan ? wd.panAcc : wd.orbitAcc;
            acc.dx += dx / innerWidth;
            acc.dy += dy / innerHeight;
            if (wd.orbit.pan) ptPanSend(); else ptOrbitSend();
            return;
        }
        const free = ptFree(e.clientX, e.clientY);
        wd.pending = { x: e.clientX / innerWidth, y: e.clientY / innerHeight, free: free || !!wd.grab,
            carrying: !!(drag && drag.active) };
        ptPointer();
        if (wd.grab) ptWithdrawHint(ptOverLeft(e.clientX, e.clientY));
    }, { signal });
    document.addEventListener('wheel', (e) => {
        if (!pt.on || drag || !ptFree(e.clientX, e.clientY)) return;
        ptPost('zoom', { delta: e.deltaY });
    }, { signal, passive: true });
    document.addEventListener('pointerdown', (e) => {
        if (pt.on && (e.button === 2 || e.button === 1) && !drag && ptFree(e.clientX, e.clientY)) {
            if (e.button === 1) e.preventDefault();   // sem a rolagem automatica do botao do meio
            wd.orbit = { x: e.clientX, y: e.clientY, sx: e.clientX, sy: e.clientY, moved: false,
                button: e.button, pan: e.button === 1 || e.shiftKey };
            return;
        }
        if (!pt.on || e.button !== 0 || drag || !ptFree(e.clientX, e.clientY)) return;
        if (wd.hover != null) { wd.hover = null; hideTip(); }
        const p = ptPost('down', { x: e.clientX / innerWidth, y: e.clientY / innerHeight });
        wd.down = p;
        p.then((r) => {
            if (wd.down !== p || !r) return;
            if (r.gizmo) wd.grab = { gizmo: true };
            else if (r.grab) wd.grab = r.grab;
            else if (r.grabGround) wd.grab = { ground: true, id: r.grabGround.id, label: r.grabGround.label };
        });
    }, { signal });
    document.addEventListener('pointerup', (e) => {
        // Clique do meio sem arrastar: o foco volta para o centro do porta-malas.
        if (pt.on && e.button === 1 && wd.orbit) {
            const o = wd.orbit;
            wd.orbit = null;
            if (!o.moved) ptPost('recenter');
            return;
        }
        // Botao direito sem arrastar: opcoes do objeto (com arrasto foi so girar a camera).
        if (pt.on && e.button === 2 && wd.orbit) {
            const o = wd.orbit;
            wd.orbit = null;
            if (!o.moved && !o.pan) {
                const x = e.clientX, y = e.clientY;
                ptPost('ctx', { x: x / innerWidth, y: y / innerHeight }).then((r) => { if (r && r.slot != null) ptMenu(r, x, y); });
            }
            return;
        }
        if (!pt.on || e.button !== 0 || !wd.down) return;
        const p = wd.down;
        wd.down = null;
        const x = e.clientX, y = e.clientY;
        p.then((r) => {
            const grab = r && r.grab;
            const ground = r && r.grabGround;
            // Gizmo: so termina (o Lua grava a pose).
            if (r && r.gizmo) { wd.grab = null; ptPost('up', { x: x / innerWidth, y: y / innerHeight }); return; }
            wd.grab = null;
            ptWithdrawHint(false);
            ptGroundHint(false);
            ptBagHint(null);
            const right = rightCardAt(x, y);
            // Item do chao: numa bolsa aberta guarda nela; no painel do jogador guarda nos bolsos; em cima do porta-malas
            // guarda nele (o Lua confere e chama o servidor).
            if (ground) {
                if (right && right.key) {
                    const slot = panelSlotAt(right.key, x, y);
                    if (slot == null) { notify(T('Não cabe mais nada aí.')); ptPost('up', { x: x / innerWidth, y: y / innerHeight, back: true }); return; }
                    ptPost('up', { x: x / innerWidth, y: y / innerHeight, to: right.key, slot });
                    return;
                }
                ptPost('up', { x: x / innerWidth, y: y / innerHeight, cancel: ptOverLeft(x, y) });
                return;
            }
            if (!grab) return;
            // Em cima de uma aba da direita: numa bolsa aberta guarda nela; no proprio porta-malas (ou outra aba), volta.
            if (right) {
                ptPost('up', { cancel: true });
                if (!right.key) return;
                const slot = panelSlotAt(right.key, x, y);
                if (slot == null) { notify(T('Não cabe mais nada aí.')); return; }
                run(actions.move({ container: 'container', slot: grab.slot }, { container: right.key, slot }));
                return;
            }
            if (!ptOverLeft(x, y)) {
                // Solto fora do porta-malas: o Lua devolve o objeto e manda largar o item no chao.
                ptPost('up', { x: x / innerWidth, y: y / innerHeight }).then((u) => {
                    if (u && u.ground) ptToGround({ container: 'container', slot: u.slot }, x, y);
                });
                return;
            }
            // No painel do jogador: retira. Em cima de um slot dos bolsos vai para ele; senao, onde couber.
            ptPost('up', { cancel: true });
            const from = { container: 'container', slot: grab.slot };
            const to = targetAt(x, y);
            run(to && ON_PERSON[to.container] ? actions.move(from, to) : actions.quickMove(from));
        });
    }, { signal });
    // Botao do meio no modo porta-malas e do foco: sem a rolagem automatica do navegador.
    document.addEventListener('mousedown', (e) => {
        if (pt.on && e.button === 1) e.preventDefault();
    }, { signal });
    // O menu do objeto abre no pointerup do botao direito (acima); aqui so o menu do navegador sai de cena.
    document.addEventListener('contextmenu', (e) => {
        if (pt.on && ptFree(e.clientX, e.clientY)) e.preventDefault();
    }, { signal });
    function ptMenu(r, x, y) {
        closeMenu();
        hideTip();
        wd.hover = null;
        const at = { container: 'container', slot: r.slot };
        const d = actions.slotAt('container', r.slot);
        if (!d) return;
        const el = div('d11-menu');
        el.appendChild(div('d11-menu-title', (defs()[d.item] || {}).name || d.item));
        const add = (label, fn) => {
            const b = document.createElement('button');
            b.className = 'd11-menu-item';
            b.textContent = label;
            b.addEventListener('click', () => { closeMenu(); fn(); });
            el.appendChild(b);
        };
        if (opensAsPanel(d)) add(T('Abrir'), () => openStore(at));   // bolsa ou caixa: o painel ao lado
        add(T('Retirar'), () => run(actions.quickMove(at)));
        add(T('Largar no chão'), () => ptToGround(at));
        add(T('Inspecionar'), () => ptPost('action', { what: 'inspect', key: r.key }));
        add(T('Posicionar com o teclado'), () => ptPost('action', { what: 'select', key: r.key }));
        add(T('Endireitar'), () => ptPost('action', { what: 'reset', key: r.key }));
        overlay.appendChild(el);
        place(el, x, y);
        menu = { at, el };
    }
    // Duplo clique num objeto do porta-malas que e bolsa ou caixa: abre o painel dela (como o duplo clique no card).
    document.addEventListener('dblclick', (e) => {
        if (!pt.on || drag || !ptFree(e.clientX, e.clientY)) return;
        ptPost('ctx', { x: e.clientX / innerWidth, y: e.clientY / innerHeight }).then((r) => {
            if (!r || r.slot == null) return;
            const at = { container: 'container', slot: r.slot };
            if (opensAsPanel(actions.slotAt('container', r.slot))) openStore(at);
        });
    }, { signal });
    const PT_KEYS = { KeyW: 'w', KeyA: 'a', KeyS: 's', KeyD: 'd', KeyQ: 'q', KeyE: 'e', KeyR: 'r', KeyF: 'f',
        ShiftLeft: 'shift', ShiftRight: 'shift', ControlLeft: 'control', ControlRight: 'control', Backspace: 'backspace' };
    function ptKey(e, down) {
        if (!pt.on) return;
        const k = PT_KEYS[e.code];
        if (!k) return;
        const t = e.target;
        if (down && t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA')) return;
        if (!!wd.keys[k] === down) return;
        wd.keys[k] = down;
        ptPost('key', { key: k, down });
    }
    document.addEventListener('keydown', (e) => ptKey(e, true), { signal });
    document.addEventListener('keyup', (e) => ptKey(e, false), { signal });
    window.addEventListener('blur', () => { if (pt.on) ptWorldReset(); }, { signal });
    function ptStateOf(s) {
        return { light: !!s.light, grid: !!s.grid, highlights: !!s.highlights, gizmo: !!s.gizmo, hud: !!s.hud };
    }
    // Cabecalho do porta-malas (pedido de 2026-11-16, no lugar da barra do rodape): a esquerda o que se ve no porta-malas
    // (luz, grade da area util, contorno em todos, gizmo); a direita a tela (Ocultar HUD: as abas 98% transparentes,
    // menos este cabecalho; camera de volta a vista inicial) e "?", que abre os atalhos em teclas logo abaixo.
    function ptTools() {
        const bar = div('d11-pt-tools');
        const view = div('d11-pt-group');
        const screen = div('d11-pt-group');
        const pill = (into, label, on, click, title) => {
            const b = document.createElement('button');
            b.className = 'd11-pill-btn' + (on ? ' on' : '');
            b.textContent = label;
            if (title) b.title = title;
            b.addEventListener('click', click);
            into.appendChild(b);
        };
        const toggle = (into, what, label) => pill(into, label, pt.state[what], () => ptPost('toggle', { what }).then((s) => {
            if (s) { pt.state = ptStateOf(s); render(); }
        }));
        toggle(view, 'light', T('Luz'));
        toggle(view, 'grid', T('Grade'));
        toggle(view, 'highlights', T('Destaques'));
        toggle(view, 'gizmo', T('Gizmo'));
        toggle(screen, 'hud', T('Ocultar HUD'));
        pill(screen, T('Câmera'), false, () => ptPost('camreset'), T('Voltar a câmera para a vista inicial'));
        pill(screen, '?', pt.help, () => { pt.help = !pt.help; render(); }, T('Atalhos'));
        bar.appendChild(view);
        bar.appendChild(screen);
        return bar;
    }
    // Os atalhos do modo porta-malas, em teclas.
    const PT_LEGEND = [
        ['Arrastar', 'Mover objeto · fora do porta-malas: chão'],
        ['Clique', 'Selecionar objeto'],
        ['W A S D', 'Mover o selecionado'],
        ['R / F', 'Subir / descer'],
        ['Q / E', 'Girar'],
        ['Botão direito', 'Opções · arrastando: girar câmera'],
        ['Duplo clique', 'Abrir bolsa ou caixa'],
        ['Meio · Shift+direito', 'Mover o foco'],
        ['Roda', 'Zoom'],
    ];
    function ptKeys() {
        const box = div('d11-pt-keys');
        for (const [key, what] of PT_LEGEND) {
            const row = div('d11-pt-key');
            const k = document.createElement('kbd');
            k.textContent = T(key);
            row.appendChild(k);
            row.appendChild(span('', T(what)));
            box.appendChild(row);
        }
        return box;
    }

    // ---------------- itens do chao com o mouse (d11_ptrunk, client/ground.lua) ----------------
    // Com o inventario aberto e fora do modo porta-malas: passar o mouse num item do chao mostra o nome; arrastar leva o
    // fantasma dele pelo chao (Q/E giram); soltar no mundo muda de lugar, no painel do jogador guarda nos bolsos, num
    // stash, porta-malas ou bolsa aberta guarda ali. Sem o d11_ptrunk, nada disso liga.
    const gw = { on: false, pending: null, inflight: false, last: null, down: null, grab: null, keys: {},
        cam: null, camAcc: { dx: 0, dy: 0 }, camBusy: false };
    function gwActive() { const i = inv(); return gw.on && !pt.on && !!(i && i.open); }
    function gwReset() {
        for (const k in gw.keys) if (gw.keys[k]) ptPost('gkey', { key: k, down: false });
        gw.keys = {};
        gw.grab = null;
        gw.down = null;
        gw.pending = null;
        ptTag(null);
    }
    api.events.on('open', () => {
        gw.on = false;
        ptPost('gmode').then((r) => { gw.on = !!(r && r.active); });
    });
    api.events.on('close', () => {
        if (gw.on) ptPost('gclosed');
        gw.on = false;
        gwReset();
    });
    // Para onde vai o item do chao solto em (x, y): { to, slot } (bolsos, stash/porta-malas, bolsa) ou {} (mundo).
    function gwDest(x, y) {
        const el = document.elementFromPoint(x, y);
        if (!el || !el.closest) return {};
        const at = targetAt(x, y);
        if (el.closest('.d11inv .d11-left')) {
            return { to: 'player', slot: at && at.container === 'player' ? at.slot : 0 };
        }
        const card = el.closest('.d11inv .d11-right .d11-card');
        if (!card) return {};
        if (card.dataset.panel) {
            return { to: card.dataset.panel, slot: at && at.container === card.dataset.panel ? at.slot : 0 };
        }
        const i = inv();
        if (i.containerOpen && i.containerStoreId && card.querySelector('[data-c="container"]')) {
            return { to: String(i.containerStoreId), slot: at && at.container === 'container' ? at.slot : 0 };
        }
        return { none: true };
    }
    function gwLabel(x, y) {
        const d = gwDest(x, y);
        if (d.none) return null;
        if (d.to === 'player') return T('Guardar nos bolsos');
        if (d.to) return T('Guardar aqui');
        return T('Mover para cá') + ' · ' + T('R/F: altura · Q/E: girar (Shift/Ctrl: outro eixo)');
    }
    // Botao direito ou do meio arrastando no espaco livre: gira a camera do jogo (os deltas juntam enquanto o anterior
    // nao volta); a roda aproxima/afasta (como a camera do porta-malas).
    function gwCamSend() {
        if (gw.camBusy) return;
        const a = gw.camAcc;
        if (!a.dx && !a.dy) return;
        gw.camAcc = { dx: 0, dy: 0 };
        gw.camBusy = true;
        ptPost('gcam', a).then(() => { gw.camBusy = false; gwCamSend(); });
    }
    function gwPointer() {
        if (gw.inflight || !gw.pending) return;
        const p = gw.pending;
        gw.pending = null;
        gw.inflight = true;
        ptPost('gpointer', p).then((r) => {
            gw.inflight = false;
            if (gwActive() && !gw.grab && !drag && gw.last) ptTag(r && r.ground ? r.ground : null, 'drop', gw.last);
            gwPointer();
        });
    }
    document.addEventListener('pointermove', (e) => {
        if (!gwActive() || (drag && drag.active)) return;
        if (gw.cam) {
            if (!(e.buttons & gw.cam.mask)) { gw.cam = null; return; }
            gw.camAcc.dx += (e.clientX - gw.cam.x) / innerWidth;
            gw.camAcc.dy += (e.clientY - gw.cam.y) / innerHeight;
            gw.cam = { x: e.clientX, y: e.clientY };
            gwCamSend();
            return;
        }
        gw.last = e;
        gw.pending = { x: e.clientX / innerWidth, y: e.clientY / innerHeight, free: ptFree(e.clientX, e.clientY) || !!gw.grab };
        gwPointer();
        if (gw.grab) ptTag(gwLabel(e.clientX, e.clientY), 'trunk', e);
    }, { signal });
    document.addEventListener('pointerdown', (e) => {
        if (gwActive() && (e.button === 1 || e.button === 2) && !drag && ptFree(e.clientX, e.clientY)) {
            e.preventDefault();
            gw.cam = { x: e.clientX, y: e.clientY, mask: e.button === 1 ? 4 : 2 };
            return;
        }
        if (!gwActive() || e.button !== 0 || drag || !ptFree(e.clientX, e.clientY)) return;
        const p = ptPost('gdown', { x: e.clientX / innerWidth, y: e.clientY / innerHeight });
        gw.down = p;
        p.then((r) => {
            if (gw.down !== p || !r || !r.grab) return;
            gw.grab = r.grab;
            hideTip();
        });
    }, { signal });
    document.addEventListener('pointerup', (e) => {
        if ((e.button === 1 || e.button === 2) && gw.cam) { gw.cam = null; return; }
        if (e.button !== 0 || !gw.down) return;
        const p = gw.down;
        gw.down = null;
        const x = e.clientX, y = e.clientY;
        p.then((r) => {
            if (!r || !r.grab) return;
            const dest = gwDest(x, y);
            gwReset();
            if (dest.none) { ptPost('gup', { x: x / innerWidth, y: y / innerHeight, to: 'cancel' }); return; }
            ptPost('gup', Object.assign({ x: x / innerWidth, y: y / innerHeight }, dest));
        });
    }, { signal });
    const GW_KEYS = { KeyQ: 'q', KeyE: 'e', KeyR: 'r', KeyF: 'f', ShiftLeft: 'shift', ShiftRight: 'shift',
        ControlLeft: 'control', ControlRight: 'control' };
    function gwKey(e, down) {
        if (!gw.grab && down) return;
        const k = GW_KEYS[e.code];
        if (!k || !!gw.keys[k] === down) return;
        gw.keys[k] = down;
        ptPost('gkey', { key: k, down });
    }
    document.addEventListener('keydown', (e) => gwKey(e, true), { signal });
    document.addEventListener('keyup', (e) => gwKey(e, false), { signal });
    // Roda no espaco livre (ou com um item do chao na mao): aproxima/afasta a camera. Botao do meio e direito no espaco
    // livre: sem a rolagem e o menu do navegador.
    document.addEventListener('wheel', (e) => {
        if (gwActive() && (gw.grab || ptFree(e.clientX, e.clientY))) ptPost('gzoom', { delta: e.deltaY });
    }, { signal, passive: true });
    document.addEventListener('mousedown', (e) => {
        if (gwActive() && e.button === 1) e.preventDefault();
    }, { signal });
    document.addEventListener('contextmenu', (e) => {
        if (gwActive() && ptFree(e.clientX, e.clientY)) e.preventDefault();
    }, { signal });

    // ---------------- render ----------------
    function render() {
        hideTip();
        const left = div('d11-col d11-left');
        left.appendChild(shellHeader());
        left.appendChild(characterCard());
        left.appendChild(pocketsCard());

        const right = div('d11-col d11-right');
        for (const c of externalCards()) right.appendChild(c);

        root.replaceChildren(left, right);
        // Ocultar HUD no porta-malas: as abas ficam quase invisiveis (style.css .pt-clear) para ver os objetos.
        mount.classList.toggle('pt-clear', !!(pt.on && pt.state.hud));
        if (menu) closeMenu();
        if (pad.on) { pad.over = null; padUpdate(); }
        ptRender();
    }

    // ---------------- acoes ----------------
    function run(r) {
        if (!r) return;
        if (!r.ok && r.reason) notify(r.reason);
        render();
    }

    // ---------------- arrastar ----------------
    function onDown(e, at, el) {
        if (e.button === 2 && drag && drag.active) {     // botao direito arrastando = so um
            e.preventDefault();
            const target = targetAt(e.clientX, e.clientY);
            if (target) run(actions.moveOne(drag.from, target));
            return;
        }
        if (e.button !== 0) return;
        closeMenu();
        drag = { from: at, sx: e.clientX, sy: e.clientY, active: false, ghost: null, over: null, el, shift: e.shiftKey };
    }

    function targetAt(x, y) {
        const hit = document.elementFromPoint(x, y);
        const s = hit && hit.closest && hit.closest('.d11inv .d11-slot');
        return s ? addr(s.dataset.c, s.dataset.s) : null;
    }

    // ---------------- zonas fora da grade (como no inventario D11 anterior) ----------------
    // Soltar no cartao do personagem usa o item; soltar fora das janelas larga a pilha no chao, com a animacao de
    // pousar (client/main.lua deste resource). So o que esta com voce (bolsos e faixa), como no WHIP.
    const ON_PERSON = { player: true, accessory: true };

    // ---------------- municao no pente (whip_gunny; client/ammo.lua) ----------------
    // Soltar a municao num pente que a leva carrega o pente pela opcao nativa ('whip_gunny:load_mag': a barra e a
    // animacao do gunny). Num pente de outro calibre o item nao vai e o jogador e avisado. So nos bolsos e na faixa:
    // o gunny carrega com a municao que voce leva.
    let ammoOf = {};   // [pente] = item da municao que ele leva
    const gunnyInfo = () => fetch('https://d11_inventory/gunnyInfo', {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: '{}',
    }).then((r) => r.json()).then((r) => { if (r && r.ammoOf) ammoOf = r.ammoOf; }).catch(() => {});
    gunnyInfo();
    /** 'ok' (carrega), 'no' (pente de outro calibre) ou null (nao e municao num pente). */
    function ammoOnMag(from, to) {
        if (!to || !ON_PERSON[from.container] || !ON_PERSON[to.container]) return null;
        const a = actions.slotAt(from.container, from.slot), m = actions.slotAt(to.container, to.slot);
        if (!a || !m || !ammoOf[m.item] || (defs()[a.item] || {}).type !== 'ammo') return null;
        return ammoOf[m.item] === a.item ? 'ok' : 'no';
    }
    function zoneAt(x, y) {
        if (!drag) return null;
        const c = drag.from.container;
        const person = !!ON_PERSON[c];
        // No modo porta-malas tambem os cards do porta-malas tem zona no meio da tela (chao, fora dele).
        if (!person && !(pt.on && (c === 'container' || isPanelKey(c)))) return null;
        if (person && body && body.hit(x, y)) return 'body';
        const hit = document.elementFromPoint(x, y);
        if (hit && hit.closest && hit.closest('.d11inv .d11-slot')) return null;
        if (person && hit && hit.closest && hit.closest('.d11inv .d11-character')) return body.isOff() ? null : 'use';
        if (!hit || !hit.closest || !hit.closest('.d11inv .d11-card, .d11inv .d11-menu, .d11inv .d11-help')) {
            if (!pt.on) return 'drop';
            // Em cima do porta-malas guarda; fora dele larga no chao (o Lua diz pelo raio da camera).
            if (wd.overTrunk) return c === 'container' ? null : 'trunk';
            return 'drop';
        }
        return null;
    }
    function usable(at) {
        if (actions.equipKind) return !!actions.equipKind(at);
        const d = actions.slotAt(at.container, at.slot);
        const def = d && defs()[d.item];
        return !!(def && def.usable);
    }
    // Usar ou equipar (faixa de acessorios quando cabe, senao o uso: arma saca, roupa veste, comida come)
    const equip = (at) => (actions.equip ? actions.equip(at) : actions.use(at));
    function showZone(zone) {
        const ch = mount.querySelector('.d11-character');
        const use = (zone === 'use' || zone === 'body') && usable(drag.from);
        if (ch) {
            ch.classList.toggle('use-target', use && zone === 'use');   // no corpo, o contorno e no personagem
            ch.classList.toggle('use-refuse', zone === 'use' && !use);
        }
        if (drag.ghost) {
            drag.ghost.dataset.zone = zone === 'drop' || zone === 'trunk' ? zone : use ? 'use' : '';
            const kind = use && actions.equipKind ? actions.equipKind(drag.from) : null;
            drag.ghost.dataset.label = zone === 'drop' ? T('Largar no chão')
                : zone === 'trunk' ? T('Guardar no porta-malas') : (BODY_LABELS[kind] || BODY_LABELS.use);
        }
    }
    function clearZone() {
        const ch = mount.querySelector('.d11-character');
        if (ch) ch.classList.remove('use-target', 'use-refuse');
        mount.querySelectorAll('.d11-panel.drop-here, .d11-slot.bag-drop').forEach((n) => n.classList.remove('drop-here', 'bag-drop'));
    }

    // Largar no chao: pede ao Lua deste resource (client/drop.lua). physics: ele larga, o item cai com fisica da
    // mao (a pilha vem do servidor); ok sem physics: larga aqui, do jeito antigo; ok false: recusou (com o motivo).
    // Sem resposta (resource parado), larga do mesmo jeito, sem animacao.
    function dropToGround(at) {
        const d = actions.slotAt(at.container, at.slot);
        if (!d) return;
        const ground = Object.keys((inv() && inv().groundItems) || {}).length + 1;
        const slotEl = mount.querySelector('.d11-slot[data-c="' + at.container + '"][data-s="' + at.slot + '"]');
        if (slotEl) slotEl.classList.add('dropping');
        let done = false;
        const go = () => { if (done) return; done = true; run(actions.move(at, { container: 'ground', slot: ground })); };
        const timer = setTimeout(go, 2500);
        fetch('https://d11_inventory/dropAnim', {
            method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ item: d.item, container: at.container, slot: at.slot, amount: Number(d.amount) || 1 }),
        }).then((r) => r.json()).then((r) => {
            clearTimeout(timer);
            if (done) return;
            if (r && r.physics) {
                done = true;
                if (slotEl) setTimeout(() => slotEl.classList.remove('dropping'), 3000);
                return;
            }
            if (r && r.ok === false) {
                done = true;
                if (slotEl) slotEl.classList.remove('dropping');
                if (r.reason) notify(r.reason);
                return;
            }
            go();
        }).catch(() => { clearTimeout(timer); go(); });
    }

    function setOver(x, y) {
        // no anel o alvo e ele: nenhum slot embaixo acende
        const onBody = !!(body && ON_PERSON[drag.from.container] && body.over(x, y));
        showZone(zoneAt(x, y));
        const hit = onBody ? null : document.elementFromPoint(x, y);
        const s = hit && hit.closest && hit.closest('.d11inv .d11-slot');
        if (drag.over && drag.over !== s) drag.over.classList.remove('drop-ok', 'drop-no');
        drag.over = s || null;
        // A aba de bolsa sob o cursor acende, e a bolsa dela nos bolsos tambem: e ali que o item vai entrar
        const card = s && s.closest('.d11-panel');
        mount.querySelectorAll('.d11-panel.drop-here, .d11-slot.bag-drop').forEach((n) => n.classList.remove('drop-here', 'bag-drop'));
        if (card) {
            card.classList.add('drop-here');
            const p = (inv().panels || []).find((q) => q.key === card.dataset.panel);
            const uid = p && p.id != null ? String(p.id) : null;
            if (uid) mount.querySelectorAll('.d11-slot.bag-open').forEach((n) => {
                const d = actions.slotAt(n.dataset.c, n.dataset.s);
                if (d && panelOfItem(d) === p) n.classList.add('bag-drop');
            });
        }
        if (!s) return;
        const to = addr(s.dataset.c, s.dataset.s);
        let no = false;
        try { no = actions.refused(drag.from, to) === true; } catch (e) { no = false; }
        const mag = ammoOnMag(drag.from, to);
        if (mag) no = mag === 'no';
        s.classList.toggle('drop-no', no);
        s.classList.toggle('drop-ok', !no);
    }

    document.addEventListener('pointermove', (e) => {
        if (!drag) return;
        if (!drag.active) {
            if (Math.abs(e.clientX - drag.sx) + Math.abs(e.clientY - drag.sy) < 5) return;
            drag.active = true;
            gunnyInfo();   // pentes de um pack que chegou depois
            hideTip();
            drag.el.classList.add('dragging');
            const g = div('d11-ghost');
            const img = drag.el.querySelector('.d11-img');
            if (img) g.appendChild(img.cloneNode());
            overlay.appendChild(g);
            drag.ghost = g;
            if (body && ON_PERSON[drag.from.container]) body.begin(drag.from, BODY_LABELS);
        }
        drag.ghost.style.transform = 'translate(' + e.clientX + 'px,' + e.clientY + 'px)';
        setOver(e.clientX, e.clientY);
    }, { signal });

    document.addEventListener('pointerup', (e) => {
        if (!drag || e.button !== 0) return;
        const d = drag;
        drag = null;
        if (d.ghost) d.ghost.remove();
        if (d.over) d.over.classList.remove('drop-ok', 'drop-no');
        clearZone();
        if (d.active) {
            drag = d;   // zoneAt le a origem do arrasto
            const onBody = zoneAt(e.clientX, e.clientY) === 'body';
            const to = onBody ? null : targetAt(e.clientX, e.clientY);
            const zone = onBody ? 'use' : to ? null : zoneAt(e.clientX, e.clientY);
            drag = null;
            if (body) body.end();
            const mag = ammoOnMag(d.from, to);
            if (mag === 'ok') run(actions.runOption(to, 'whip_gunny:load_mag', {}));
            else if (mag === 'no') { notify(T('Essa munição não serve nesse pente.')); render(); }
            else if (to && (to.container !== d.from.container || to.slot !== d.from.slot)) run(actions.move(d.from, to));
            else if (zone === 'use') {
                if (usable(d.from)) run(equip(d.from));
                else { notify(T('Esse item não tem uso.')); render(); }
            }
            else if (zone === 'drop') { if (pt.on) ptToGround(d.from, e.clientX, e.clientY); else dropToGround(d.from); }
            else if (zone === 'trunk') ptDeposit(d.from, e.clientX, e.clientY);
            else render();
        } else if (d.shift || e.shiftKey) {
            run(actions.quickMove(d.from));
        }
    }, { signal });

    // ---------------- menu de opcoes ----------------
    function openMenu(at, x, y) {
        closeMenu();
        let m = null;
        try { m = actions.menuFor(at); } catch (e) { m = null; }
        // "Destruir" (so no modo dev do whip_core) nao aparece aqui: apagar um item de vez pelo menu e perigoso demais.
        if (m && m.options) m = Object.assign({}, m, { options: m.options.filter((o) => o.action !== 'destroy') });
        const groundBag = at.container === 'ground' && opensAsPanel(actions.slotAt(at.container, at.slot));
        // Bolsa ou caixa num porta-malas ou stash aberto: abre ali (whip_core-store-panel-d11.patch)
        const storeBag = at.container === 'container' && opensAsPanel(actions.slotAt(at.container, at.slot));
        if (!groundBag && !storeBag && (!m || !m.options || !m.options.length)) return;
        const el = div('d11-menu');
        el.appendChild(div('d11-menu-title', (m && m.title) || (defs()[actions.slotAt(at.container, at.slot).item] || {}).name || ''));
        if (groundBag || storeBag) {   // bolsa no chao ou num store: abre ali (patches ground-panel / store-panel)
            const b = document.createElement('button');
            b.className = 'd11-menu-item';
            b.textContent = T('Abrir');
            b.addEventListener('click', () => { closeMenu(); if (groundBag) openGround(at); else openStore(at); });
            el.appendChild(b);
            if (m && m.options && m.options.length) el.appendChild(div('d11-menu-sep'));
        }
        if (!m || !m.options) m = { options: [] };
        // Arma do gunny: carregar todos os pentes dela, um por vez (com ela na mao; client/ammo.lua)
        const gun = ON_PERSON[at.container] && defs()[(actions.slotAt(at.container, at.slot) || {}).item];
        if (gun && gun.defaultAction === 'whip_gunny:equip_weapon' && (gun.metaFields || []).some((r) => r.key === 'caliber')) {
            const b = document.createElement('button');
            b.className = 'd11-menu-item';
            b.textContent = T('Carregar todos os pentes');
            b.addEventListener('click', () => {
                closeMenu();
                fetch('https://d11_inventory/loadAllMags', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }).catch(() => {});
            });
            el.appendChild(b);
            if (m.options.length) el.appendChild(div('d11-menu-sep'));
        }
        let group = null;
        for (const o of m.options) {
            if (group && o.group !== group) el.appendChild(div('d11-menu-sep'));
            group = o.group;
            const b = document.createElement('button');
            b.className = 'd11-menu-item' + (o.group === 'danger' ? ' danger' : '');
            b.textContent = o.label;
            b.addEventListener('click', () => {
                if (o.amount > 1 && (o.action === 'give' || o.action === 'split')) return askAmount(el, at, o);
                closeMenu();
                run(actions.runOption(at, o.action, {}));
            });
            el.appendChild(b);
        }
        overlay.appendChild(el);
        place(el, x, y);
        menu = { at, el };
    }

    function askAmount(el, at, o) {
        const row = div('d11-menu-amount');
        const input = document.createElement('input');
        input.type = 'number';
        input.min = '1';
        input.max = String(o.amount);
        const def = o.action === 'split' ? Math.floor(o.amount / 2) : o.amount;
        input.value = String(Math.max(1, def));
        const ok = document.createElement('button');
        ok.className = 'd11-pill-btn light';
        ok.textContent = o.label;
        const go = () => {
            const n = Math.max(1, Math.min(o.amount, Math.floor(Number(input.value) || 1)));
            closeMenu();
            run(actions.runOption(at, o.action, { amount: n }));
        };
        ok.addEventListener('click', go);
        input.addEventListener('keydown', (e) => { e.stopPropagation(); if (e.key === 'Enter') go(); });
        row.append(input, ok);
        el.querySelectorAll('.d11-menu-amount').forEach((r) => r.remove());
        el.appendChild(row);
        input.focus();
        input.select();
    }

    function closeMenu() {
        if (menu) { menu.el.remove(); menu = null; }
    }
    document.addEventListener('pointerdown', (e) => {
        if (menu && !menu.el.contains(e.target)) closeMenu();
    }, { signal, capture: true });

    function place(el, x, y) {
        const r = el.getBoundingClientRect();
        el.style.left = Math.min(x + 8, innerWidth - r.width - 8) + 'px';
        el.style.top = Math.min(y + 8, innerHeight - r.height - 8) + 'px';
    }

    // ---------------- dica ----------------
    function showTip(at, e) {
        if (drag && drag.active) return;
        hideTip();
        let d = null;
        try { d = actions.describe(at); } catch (err) { d = null; }
        if (!d) return;
        const el = div('d11-tip');
        el.appendChild(div('d11-tip-name', d.name || ''));
        if (d.desc) el.appendChild(div('d11-tip-desc', d.desc));
        const rows = div('d11-tip-rows');
        const row = (k, v) => { const r = div('d11-tip-row'); r.append(span('', k), span('', v)); rows.appendChild(r); };
        if (d.amount > 1) row(T('Quantidade'), String(d.amount));
        if (d.weight != null) row(T('Peso'), fmtKg(d.weight) + (d.amount > 1 && d.weightEach != null ? ' (' + fmtKg(d.weightEach) + T(' cada)') : ''));
        for (const l of d.lines || []) row(l.label, String(l.value));
        if (rows.children.length) el.appendChild(rows);
        overlay.appendChild(el);
        tip = el;
        moveTip(e);
    }
    function moveTip(e) {
        if (tip && e) place(tip, e.clientX + 6, e.clientY + 6);
    }
    function hideTip() {
        if (tip) { tip.remove(); tip = null; }
    }

    // ---------------- aviso ----------------
    function notify(text) {
        if (!text) return;
        let t = overlay.querySelector('.d11-toast');
        if (!t) { t = div('d11-toast'); overlay.appendChild(t); }
        t.textContent = text;
        t.classList.add('on');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => t.classList.remove('on'), 3500);
    }

    // ---------------- controle (gamepad) ----------------
    // O mesmo esquema do cursor de controle do WHIP (pad-cursor.js): um circulo que o analogico move e
    // que aperta os botoes do mouse onde esta, entao arrastar, menu e dica sao os mesmos do mouse.
    //   LS mover | A segurar = arrastar, tocar = clicar, dois toques = usar | X opcoes (arrastando: so um)
    //   Y usar | RB+A enviar | B fecha menu / solta / fecha | D-pad pula de slot | LB/RB troca de coluna
    const PAD_SPEED = 1.3, PAD_CURVE = 1.6, PAD_SLOW = 0.45, PAD_CLICK = 6, PAD_DOUBLE = 400;
    const pad = { on: false, x: 0, y: 0, sx: 0, sy: 0, a: false, sawA: false, raf: 0, last: 0,
        downX: 0, downY: 0, tapAt: 0, tapSlot: null, over: null, el: null, placed: false };

    function padEl() {
        if (!pad.el) { pad.el = div('d11-pad-cursor'); overlay.appendChild(pad.el); }
        return pad.el;
    }
    function center(el) {
        const r = el.getBoundingClientRect();
        return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
    }
    function padPlace() {
        if (pad.placed) return;
        const first = root.querySelector('.d11-pockets .d11-slot');
        if (first) { const c = center(first); pad.x = c.x; pad.y = c.y; pad.placed = true; }
    }
    function padUnder() {
        const n = document.elementFromPoint(pad.x, pad.y);
        return n && mount.contains(n) ? n : null;
    }
    function padUpdate() {
        if (!pad.on) return;
        padEl().style.transform = 'translate(' + pad.x + 'px,' + pad.y + 'px)';
        const n = padUnder();
        const btn = (n && n.closest('button, input')) || null;
        if (btn !== pad.overBtn) {
            if (pad.overBtn) pad.overBtn.classList.remove('pad-over');
            pad.overBtn = btn;
            if (btn) btn.classList.add('pad-over');
        }
        const slot = n && n.closest('.d11-slot');
        if (slot !== pad.over) {
            if (pad.over) pad.over.classList.remove('pad-over');
            pad.over = slot || null;
            if (slot) slot.classList.add('pad-over');
            if (!drag || !drag.active) {
                if (slot && slot.classList.contains('filled')) showTip(addr(slot.dataset.c, slot.dataset.s), { clientX: pad.x, clientY: pad.y });
                else hideTip();
            }
        }
        if (drag) document.dispatchEvent(new PointerEvent('pointermove', { bubbles: true, clientX: pad.x, clientY: pad.y }));
    }
    function padShow() {
        if (!pad.on) { pad.on = true; mount.classList.add('pad'); padPlace(); }
        padUpdate();
    }
    function padHide() {
        if (!pad.on) return;
        pad.on = false;
        mount.classList.remove('pad');
        if (pad.over) { pad.over.classList.remove('pad-over'); pad.over = null; }
    }
    document.addEventListener('mousemove', (e) => { if (e.isTrusted && pad.on && e.movementX + e.movementY !== 0) padHide(); }, { signal });

    function padLoop(now) {
        const dt = pad.last ? Math.min(0.05, (now - pad.last) / 1000) : 0.016;
        pad.last = now;
        const m = Math.hypot(pad.sx, pad.sy);
        if (m < 0.001) { pad.raf = 0; pad.last = 0; return; }
        const speed = PAD_SPEED * innerHeight * Math.pow(Math.min(1, m), PAD_CURVE) * (pad.over ? PAD_SLOW : 1);
        pad.x = Math.max(0, Math.min(innerWidth - 1, pad.x + (pad.sx / m) * speed * dt));
        pad.y = Math.max(0, Math.min(innerHeight - 1, pad.y - (pad.sy / m) * speed * dt));
        padUpdate();
        pad.raf = requestAnimationFrame(padLoop);
    }

    function padPress() {
        pad.downX = pad.x; pad.downY = pad.y;
        const n = padUnder();
        const slot = n && n.closest('.d11-slot.filled');
        if (slot) slot.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, clientX: pad.x, clientY: pad.y, button: 0 }));
    }
    function padRelease() {
        const moved = Math.hypot(pad.x - pad.downX, pad.y - pad.downY) > PAD_CLICK;
        document.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, clientX: pad.x, clientY: pad.y, button: 0 }));
        if (moved) return;
        const n = padUnder();
        if (!n) return;
        const btn = n.closest('button');
        if (btn) { btn.click(); return; }
        const field = n.closest('input');
        if (field) { field.focus(); field.select(); return; }
        const slot = n.closest('.d11-slot.filled');
        const now = performance.now();
        const key = slot ? slot.dataset.c + ':' + slot.dataset.s : null;
        if (key && pad.tapSlot === key && now - pad.tapAt < PAD_DOUBLE) {
            pad.tapAt = 0;
            run(actions.use(addr(slot.dataset.c, slot.dataset.s)));
            return;
        }
        pad.tapAt = now;
        pad.tapSlot = key;
    }

    function padJump(dir) {
        const list = menu ? [...menu.el.querySelectorAll('button, input')]
            : [...mount.querySelectorAll('.d11-slot, .d11-shell button, .d11-shell input')];
        let best = null, bestScore = Infinity;
        for (const el of list) {
            const c = center(el);
            const dx = c.x - pad.x, dy = c.y - pad.y;
            const along = dir === 'right' ? dx : dir === 'left' ? -dx : dir === 'down' ? dy : -dy;
            const across = dir === 'right' || dir === 'left' ? Math.abs(dy) : Math.abs(dx);
            if (along < 4) continue;
            const score = along + across * 2;
            if (score < bestScore) { bestScore = score; best = c; }
        }
        if (best) { pad.x = best.x; pad.y = best.y; padUpdate(); }
    }
    function padColumn(side) {
        const el = root.querySelector(side === 'right' ? '.d11-right .d11-slot' : '.d11-pockets .d11-slot');
        if (el) { const c = center(el); pad.x = c.x; pad.y = c.y; padUpdate(); }
    }
    function padSlot() {
        const n = padUnder();
        return (n && n.closest('.d11-slot')) || null;
    }

    function onAnalog(a) {
        if (!a) return;
        pad.sx = Number(a.x) || 0;
        pad.sy = Number(a.y) || 0;
        if (pad.sx || pad.sy || a.a) padShow();
        if (typeof a.a === 'boolean') {
            pad.sawA = true;
            if (a.a !== pad.a) { pad.a = a.a; if (a.a) padPress(); else padRelease(); }
        }
        if ((pad.sx || pad.sy) && !pad.raf) { pad.last = 0; pad.raf = requestAnimationFrame(padLoop); }
    }

    function onNav(nav, mods) {
        padShow();
        mods = mods || {};
        const focused = document.activeElement;
        if (focused && mount.contains(focused) && focused.tagName === 'INPUT' && (nav === 'up' || nav === 'down')) {
            const step = (mods.held || 0) > 1200 ? 10 : 1;
            const max = focused.max ? Number(focused.max) : Infinity;
            const next = (Number(focused.value) || 0) + (nav === 'up' ? step : -step);
            focused.value = String(Math.max(Number(focused.min) || 0, Math.min(max, next)));
            focused.dispatchEvent(new Event('input', { bubbles: true }));
            return;
        }
        if (nav === 'up' || nav === 'down' || nav === 'left' || nav === 'right') return padJump(nav);
        if (nav === 'tabNext') return padColumn('right');
        if (nav === 'tabPrev') return padColumn('left');
        if (nav === 'select') {
            if (mods.rb) {
                const slot = padSlot();
                cancelDrag();
                if (slot && slot.classList.contains('filled')) run(actions.quickMove(addr(slot.dataset.c, slot.dataset.s)));
                return;
            }
            if (!pad.sawA) { padPress(); padRelease(); }   // sem o estado de A: vale como um toque
            return;
        }
        if (nav === 'buttonX') {
            const slot = padSlot();
            if (drag && drag.active) {
                if (slot) run(actions.moveOne(drag.from, addr(slot.dataset.c, slot.dataset.s)));
                return;
            }
            if (slot && slot.classList.contains('filled')) openMenu(addr(slot.dataset.c, slot.dataset.s), pad.x, pad.y);
            return;
        }
        if (nav === 'buttonY') {
            const slot = padSlot();
            if (slot && slot.classList.contains('filled')) run(actions.use(addr(slot.dataset.c, slot.dataset.s)));
            return;
        }
        if (nav === 'back') {
            if (menu) return closeMenu();
            if (helpOpen) { helpOpen = false; return render(); }
            if (drag) return cancelDrag();
            close();
        }
    }

    function padHints() {
        if (menu) return [['dpad', T('Escolher')], ['a', T('Confirmar')], ['b', T('Voltar')]];
        return [['ls', T('Mover')], ['a', T('Segurar: arrastar')], [['rb', 'a'], T('Enviar')], ['x', T('Opções')], ['y', T('Usar')], ['b', T('Fechar')]];
    }

    function cancelDrag() {
        if (body) body.end();
        if (!drag) return;
        if (drag.ghost) drag.ghost.remove();
        if (drag.over) drag.over.classList.remove('drop-ok', 'drop-no');
        clearZone();
        if (drag.el) drag.el.classList.remove('dragging');
        drag = null;
    }

    return {
        render,
        notify,
        onNav,
        onAnalog,
        padHints,
        isMidDrag: () => !!(drag && drag.active),
        cancelInteractions() {
            cancelDrag();
            closeMenu();
            hideTip();
            render();
        },
        flashPanels() { root.querySelectorAll('.d11-right .d11-card').forEach((c) => { c.classList.remove('flash'); void c.offsetWidth; c.classList.add('flash'); }); },
        destroy() { clearTimeout(toastTimer); if (pad.raf) cancelAnimationFrame(pad.raf); },
    };
}
