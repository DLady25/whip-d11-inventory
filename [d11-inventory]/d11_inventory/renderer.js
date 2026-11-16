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
const LANG = await (async () => {
    for (let i = 0; i < 8; i++) {
        try {
            const ask = fetch('https://d11_inventory/locale', { method: 'POST', body: '{}' }).then((r) => r.json());
            const j = await Promise.race([ask, new Promise((ok) => setTimeout(() => ok(null), 400))]);
            if (j && typeof j.lang === 'string') return j.lang;
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
        if (opts.key != null) el.appendChild(span('d11-key', String(opts.key)));
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
            top.appendChild(span('d11-emblem', t[0]));
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
            run(actions.use(at));
        });
        el.addEventListener('mouseenter', (e) => showTip(at, e));
        el.addEventListener('mousemove', moveTip);
        el.addEventListener('mouseleave', hideTip);
        return el;
    }

    function grid(container, count, cols, opts) {
        const g = div('d11-grid');
        g.style.setProperty('--cols', String(cols));
        for (let s = 1; s <= count; s++) g.appendChild(slotEl(container, s, opts));
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
        ctrls.appendChild(craft);
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

    // Equipado: secao da ficha em dois grupos da faixa de acessorios do WHIP:
    //   Acessorios (encaixes 1-5, ladrilho maior) e Roupa (6-16, a roupa vestida, ladrilho compacto numa linha)
    function equipSection() {
        const cfg = (api.slotConfig && api.slotConfig.accessorySlots) || [];
        if (!cfg.length) return null;
        const sec = div('d11-equip');
        const groups = [
            [T('Equipado'), cfg.filter((s) => s.slot < WORN_FROM), ''],
            [T('Roupa'), cfg.filter((s) => s.slot >= WORN_FROM), ' worn'],
        ];
        for (const [title, list, cls] of groups) {
            if (!list.length) continue;
            const head = div('d11-sec-head');
            head.appendChild(div('d11-kicker', title));
            let used = 0;
            for (const s of list) if (actions.slotAt('accessory', s.slot)) used++;
            head.appendChild(span('d11-chip', used + '/' + list.length));
            sec.appendChild(head);
            const row = div('d11-equip-row' + cls);
            row.style.setProperty('--cols', String(list.length));
            for (const s of list) {
                const cell = div('d11-equip-cell');
                const el = slotEl('accessory', s.slot, { small: true });
                if (el.classList.contains('empty') && s.iconSvg) {
                    const ic = div('d11-equip-icon');
                    ic.innerHTML = s.iconSvg;
                    el.appendChild(ic);
                }
                cell.appendChild(el);
                const label = s.label || T('Acessório');
                const lab = span('d11-equip-label', SHORT[label] || label);
                lab.title = label;
                cell.appendChild(lab);
                row.appendChild(cell);
            }
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

    function hotbarCard() {
        const c = card('d11-hotbar');
        const lab = div('d11-hotbar-label');
        lab.appendChild(div('d11-kicker', T('Acesso rápido')));
        lab.appendChild(div('d11-hotbar-sub', T('Slots 1-') + HOTBAR));
        c.appendChild(lab);
        const row = div('d11-hotbar-row');
        for (let s = 1; s <= HOTBAR; s++) row.appendChild(slotEl('player', s, { small: true, key: s }));
        c.appendChild(row);
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

    // ---------------- render ----------------
    function render() {
        hideTip();
        const left = div('d11-col d11-left');
        left.appendChild(shellHeader());
        left.appendChild(characterCard());
        left.appendChild(pocketsCard());
        left.appendChild(hotbarCard());

        const right = div('d11-col d11-right');
        for (const c of externalCards()) right.appendChild(c);

        root.replaceChildren(left, right);
        if (menu) closeMenu();
        if (pad.on) { pad.over = null; padUpdate(); }
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
    function zoneAt(x, y) {
        if (!drag || !ON_PERSON[drag.from.container]) return null;
        if (body && body.hit(x, y)) return 'body';
        const hit = document.elementFromPoint(x, y);
        if (hit && hit.closest && hit.closest('.d11inv .d11-slot')) return null;
        if (hit && hit.closest && hit.closest('.d11inv .d11-character')) return body.isOff() ? null : 'use';
        if (!hit || !hit.closest || !hit.closest('.d11inv .d11-card, .d11inv .d11-menu, .d11inv .d11-help')) return 'drop';
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
            drag.ghost.dataset.zone = zone === 'drop' ? 'drop' : use ? 'use' : '';
            const kind = use && actions.equipKind ? actions.equipKind(drag.from) : null;
            drag.ghost.dataset.label = zone === 'drop' ? T('Largar no chão') : (BODY_LABELS[kind] || BODY_LABELS.use);
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
        s.classList.toggle('drop-no', no);
        s.classList.toggle('drop-ok', !no);
    }

    document.addEventListener('pointermove', (e) => {
        if (!drag) return;
        if (!drag.active) {
            if (Math.abs(e.clientX - drag.sx) + Math.abs(e.clientY - drag.sy) < 5) return;
            drag.active = true;
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
            if (to && (to.container !== d.from.container || to.slot !== d.from.slot)) run(actions.move(d.from, to));
            else if (zone === 'use') {
                if (usable(d.from)) run(equip(d.from));
                else { notify(T('Esse item não tem uso.')); render(); }
            }
            else if (zone === 'drop') dropToGround(d.from);
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
        const groundBag = at.container === 'ground' && opensAsPanel(actions.slotAt(at.container, at.slot));
        if (!groundBag && (!m || !m.options || !m.options.length)) return;
        const el = div('d11-menu');
        el.appendChild(div('d11-menu-title', (m && m.title) || (defs()[actions.slotAt(at.container, at.slot).item] || {}).name || ''));
        if (groundBag) {   // bolsa no chao: abre ali (whip_core-ground-panel-d11.patch)
            const b = document.createElement('button');
            b.className = 'd11-menu-item';
            b.textContent = T('Abrir');
            b.addEventListener('click', () => { closeMenu(); openGround(at); });
            el.appendChild(b);
            if (m && m.options && m.options.length) el.appendChild(div('d11-menu-sep'));
        }
        if (!m || !m.options) m = { options: [] };
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
