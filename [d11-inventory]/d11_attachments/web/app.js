/* NUI do d11_attachments (porte do html/app.js do d12-item-inspect, so a parte de arma).
   Lua manda 'open', 'hotspots', 'frame', 'camera', 'busy', 'close'. */
(function () {
    const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'd11_attachments';
    const root = document.getElementById('root');
    const pointsEl = document.getElementById('points');
    const cameraBtn = document.getElementById('camera');

    const card = document.getElementById('card');
    let iconBase = '';

    // Icone do item: .webp, senao .png, senao some (o whip_core aceita os dois).
    function icon(name, cls) {
        if (!name || !iconBase) return '';
        return '<img class="' + (cls || 'ico') + '" src="' + iconBase + esc(name) + '.webp" data-png="' + iconBase + esc(name) + '.png" alt="">';
    }
    document.addEventListener('error', function (ev) {
        const img = ev.target;
        if (!img || img.tagName !== 'IMG') return;
        if (img.dataset.png && img.src !== img.dataset.png) { img.src = img.dataset.png; img.dataset.png = ''; }
        else img.style.visibility = 'hidden';
    }, true);

    let hotspots = [];
    let nodes = {};      // i -> { el, tx, ty, cx, cy, visible }
    let hovered = null;
    let busy = false;

    function post(name, data) {
        fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).catch(function () {});
    }

    function esc(s) {
        return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
            return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
        });
    }

    function renderPanel(hs) {
        if (!hs.options || hs.options.length === 0) {
            return '<div class="opt empty">Nada na bolsa para este encaixe</div>';
        }
        return hs.options.map(function (o, idx) {
            const cls = ['opt', o.kind, o.disabled ? 'disabled' : ''].join(' ');
            const hint = (o.disabled && o.disabledReason) ? o.disabledReason : (o.hint || '');
            return '<div class="' + cls + '" data-opt="' + (idx + 1) + '">'
                + '<span class="l">' + icon(o.icon) + esc(o.label) + '</span>'
                + '<span class="h">' + esc(hint) + '</span>'
                + '</div>';
        }).join('');
    }

    // Foco: clicar no ponto fixa o menu dele (fica aberto e PARADO, mesmo se a arma mexer) ate clicar em outro
    // ponto, no mesmo ponto de novo ou fora. Sem ponto fixado, passar o mouse so mostra o menu.
    let pinned = null;

    function applyFocus(i) {
        const target = pinned != null ? pinned : i;
        Object.keys(nodes).forEach(function (k) {
            nodes[k].el.classList.toggle('focus', String(k) === String(target));
            nodes[k].el.classList.toggle('pinned', String(k) === String(pinned));
        });
    }

    function pin(i) {
        pinned = (pinned === i) ? null : i;
        applyFocus(hovered);
    }

    function build() {
        const previous = nodes;
        pointsEl.innerHTML = '';
        nodes = {};
        hotspots.forEach(function (hs) {
            const el = document.createElement('div');
            el.className = 'point offscreen';
            el.innerHTML = '<div class="dot"></div>'
                + '<div class="tag">' + icon(hs.icon, 'tag-ico')
                + '<div class="tag-txt"><span class="name">' + esc(hs.label).toUpperCase() + '</span>'
                + '<span class="current">' + esc(hs.current) + '</span></div></div>'
                + '<div class="panel">' + renderPanel(hs) + '</div>';
            pointsEl.appendChild(el);
            // Mantem a posicao suavizada de antes: um rebuild (apos acoplar) nao faz o ponto "voar" de novo.
            const old = previous[hs.i];
            nodes[hs.i] = { el: el, tx: old && old.tx, ty: old && old.ty, cx: old && old.cx, cy: old && old.cy, visible: !!(old && old.visible) };
            if (old && old.visible) {
                el.style.transform = 'translate3d(' + Math.round(old.cx) + 'px,' + Math.round(old.cy) + 'px,0)';
                el.classList.remove('offscreen');
            }
            el.classList.toggle('busy', busy);
            el.addEventListener('mouseenter', function () { hovered = hs.i; applyFocus(hs.i); });
            el.addEventListener('mouseleave', function () { if (hovered === hs.i) { hovered = null; applyFocus(null); } });
            el.querySelectorAll('.dot, .tag').forEach(function (hit) {
                hit.addEventListener('mousedown', function (ev) { ev.stopPropagation(); pin(hs.i); });
            });
            el.querySelector('.panel').addEventListener('mousedown', function (ev) { ev.stopPropagation(); });
            el.querySelectorAll('.opt[data-opt]').forEach(function (optEl) {
                optEl.addEventListener('click', function (ev) {
                    ev.stopPropagation();
                    if (busy || optEl.classList.contains('disabled')) return;
                    post('select', { hotspot: hs.i, option: Number(optEl.dataset.opt) });
                });
            });
        });
        if (pinned != null && !nodes[pinned]) pinned = null;
        applyFocus(hovered);
    }

    function renderCard(c) {
        if (!c) { card.classList.add('hidden'); return; }
        const img = document.getElementById('card-img');
        img.style.visibility = '';
        img.dataset.png = iconBase + c.icon + '.png';
        img.src = iconBase + c.icon + '.webp';
        document.getElementById('card-kind').textContent = c.kind || '';
        document.getElementById('card-name').textContent = c.label || '';
        const desc = document.getElementById('card-desc');
        desc.textContent = c.description || '';
        desc.classList.toggle('hidden', !c.description || c.description === c.label);
        document.getElementById('card-rows').innerHTML = (c.rows || []).map(function (r) {
            const cls = ['row', r.tone ? 'tone-' + r.tone : '', r.mono ? 'mono' : ''].join(' ');
            const bar = (typeof r.bar === 'number')
                ? '<span class="bar"><i style="width:' + Math.max(0, Math.min(100, r.bar)) + '%"></i></span>' : '';
            return '<div class="' + cls + '"><span class="k">' + esc(r.label) + '</span>'
                + '<span class="v">' + esc(r.value) + bar + '</span></div>';
        }).join('');
        document.getElementById('card-sec').textContent = c.partsTitle || '';
        const parts = c.parts || [];
        document.getElementById('card-parts').innerHTML = parts.length === 0
            ? '<div class="part none">' + esc(c.noParts) + '</div>'
            : parts.map(function (p) {
                return '<div class="part">' + icon(p.icon, 'part-ico')
                    + '<span class="pk">' + esc(p.label) + '</span><span class="pv">' + esc(p.value) + '</span></div>';
            }).join('');
        card.classList.remove('hidden');
    }

    // O Lua manda a projecao do bone a cada frame; cada ponto persegue o alvo (rAF) e e escrito em pixel inteiro.
    // Com a camera parada, o que sobra e a respiracao do ped: SMOOTH baixo e uma zona morta de 1.5 px seguram o texto.
    const SMOOTH = 0.18, SNAP_PX = 0.4, DEAD_PX = 1.5, JUMP_PX = 160;
    let rafId = null;

    function frame(msg) {
        const W = window.innerWidth, H = window.innerHeight;
        (msg.points || []).forEach(function (p) {
            const n = nodes[p.i];
            if (!n) return;
            if (!p.v) { n.el.classList.add('offscreen'); n.visible = false; return; }
            n.visible = true;
            const nx = p.x * W, ny = p.y * H;
            // Zona morta: tremida menor que DEAD_PX nao move o alvo.
            if (n.tx == null || Math.hypot(nx - n.tx, ny - n.ty) > DEAD_PX) { n.tx = nx; n.ty = ny; }
            if (n.cx == null) { n.cx = n.tx; n.cy = n.ty; }
        });
        if (rafId == null) rafId = requestAnimationFrame(tick);
    }

    function tick() {
        rafId = null;
        let moving = false;
        Object.keys(nodes).forEach(function (k) {
            const n = nodes[k];
            if (!n.visible || n.tx == null) return;
            if (String(k) === String(pinned) && n.cx != null) return;   // menu fixado nao anda
            const dx = n.tx - n.cx, dy = n.ty - n.cy;
            const dist = Math.hypot(dx, dy);
            if (dist > JUMP_PX || dist < SNAP_PX) { n.cx = n.tx; n.cy = n.ty; }
            else { n.cx += dx * SMOOTH; n.cy += dy * SMOOTH; moving = true; }
            n.el.style.transform = 'translate3d(' + Math.round(n.cx) + 'px,' + Math.round(n.cy) + 'px,0)';
            n.el.classList.remove('offscreen');
        });
        if (moving && !root.classList.contains('hidden')) rafId = requestAnimationFrame(tick);
    }

    window.addEventListener('message', function (ev) {
        const msg = ev.data || {};
        switch (msg.action) {
            case 'open':
                hovered = null; pinned = null; busy = false;
                document.getElementById('title').textContent = msg.title || '';
                document.getElementById('label').textContent = msg.label || '';
                document.getElementById('hint').textContent = msg.hint || '';
                cameraBtn.textContent = msg.camera || '';
                iconBase = msg.iconBase || '';
                card.classList.add('hidden');
                hotspots = []; nodes = {}; build();
                root.classList.remove('hidden');
                break;
            case 'info':
                renderCard(msg.card);
                break;
            case 'hotspots':
                hotspots = msg.hotspots || [];
                build();
                break;
            case 'frame':
                frame(msg);
                break;
            case 'camera':
                cameraBtn.textContent = msg.label || '';
                break;
            case 'busy':
                busy = !!msg.value;
                Object.keys(nodes).forEach(function (k) { nodes[k].el.classList.toggle('busy', busy); });
                break;
            case 'close':
                if (rafId != null) { cancelAnimationFrame(rafId); rafId = null; }
                root.classList.add('hidden');
                card.classList.add('hidden');
                pointsEl.innerHTML = ''; nodes = {}; hotspots = []; hovered = null; pinned = null;
                break;
        }
    });

    cameraBtn.addEventListener('click', function (ev) { ev.stopPropagation(); post('camera'); });

    document.addEventListener('keydown', function (ev) {
        if (root.classList.contains('hidden')) return;
        if (ev.key === 'Escape' || ev.key === 'Backspace') post('close');
    });
    // Clique fora de qualquer ponto fecha.
    root.addEventListener('mousedown', function (ev) {
        if (ev.target !== root && ev.target !== pointsEl) return;
        // Clique fora: primeiro solta o menu fixado; sem menu fixado, fecha a inspecao.
        if (pinned != null) { pinned = null; applyFocus(hovered); return; }
        post('close');
    });
})();
