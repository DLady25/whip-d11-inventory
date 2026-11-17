-- Municao e pentes (whip_gunny), dois atalhos sobre o carregar nativo do gunny (server/magazines.lua: a barra, a
-- animacao e as balas sao do servidor dele):
--   * arrastar a municao ate um pente compativel carrega o pente: o renderer pergunta aqui que municao cada pente
--     leva (gunnyInfo) e roda a opcao nativa do pente ('whip_gunny:load_mag', o "Carregar" do menu);
--   * carregar todos (/pentes, tecla em Configuracoes > Atalhos > FiveM, ou "Carregar todos os pentes" no menu da
--     arma): com a arma na mao, um pente compativel por vez, cada um com a sua barra. Cancelar: o cancelar da barra
--     (X, correr) ou /pentes de novo.
-- Sem patch no whip_gunny: o que cada pente leva vem das definicoes dos itens (calibre no cartao) e dos arquivos de
-- dados do gunny (items/calibers.lua, items/weapons.lua), lidos como dados.

local STR = {
    en = {
        noWeapon = 'Hold a gun to load its magazines.',
        none     = 'No magazine to load for this gun.',
        noAmmo   = 'No ammo for these magazines.',
        stopping = 'Stopping after this magazine.',
        done     = 'Magazines loaded: %d (%d rounds).',
        stopped  = 'Loading stopped: %d magazines (%d rounds).',
        keyLabel = 'Load all magazines (gun in hand)',
    },
    ['pt-BR'] = {
        noWeapon = 'Saque uma arma para carregar os pentes dela.',
        none     = 'Nenhum pente para carregar dessa arma.',
        noAmmo   = 'Sem munição para esses pentes.',
        stopping = 'Para depois deste pente.',
        done     = 'Pentes carregados: %d (%d balas).',
        stopped  = 'Carregamento parado: %d pentes (%d balas).',
        keyLabel = 'Carregar todos os pentes (arma na mão)',
    },
}
local function L(key)
    local t = STR[GetConvar('d11_locale', 'en')] or STR.en
    return t[key] or STR.en[key]
end
local function notify(text, kind) pcall(function() exports.whip_core:Notify(text, kind or 'info') end) end

--- Uma tabela de dados do whip_gunny (Config.<key> de um arquivo so de dados), ou {}.
local cache = {}
local function gunnyData(file, key)
    if cache[file] then return cache[file] end
    local src = LoadResourceFile('whip_gunny', file)
    local env = { Config = {} }
    local fn = src and load(src, '@whip_gunny/' .. file, 't', env)
    cache[file] = (fn and pcall(fn) and env.Config[key]) or {}
    return cache[file]
end
AddEventHandler('onResourceStart', function(res) if res == 'whip_gunny' then cache = {} end end)

local function defs()
    local ok, d = pcall(function() return exports.whip_core:GetItemDefs() end)
    return ok and type(d) == 'table' and d or {}
end

--- O calibre do cartao de um item do gunny (arma ou pente), ou nil.
local function caliberOf(def)
    for _, row in ipairs(type(def) == 'table' and def.metaFields or {}) do
        if row.key == 'caliber' then return row.value end
    end
end

local function isMag(def) return type(def) == 'table' and def.defaultAction == 'whip_gunny:load_mag' end

--- [pente] = item da municao que ele leva (pentes de packs incluidos: vem das definicoes).
local function ammoOfMags()
    local calibers, out = gunnyData('items/calibers.lua', 'Calibers'), {}
    for item, def in pairs(defs()) do
        if isMag(def) then
            local c = calibers[caliberOf(def) or '']
            if c and c.ammoItem then out[item] = c.ammoItem end
        end
    end
    return out
end

RegisterNUICallback('gunnyInfo', function(_, cb)
    cb({ ammoOf = ammoOfMags() })
end)

-- ---- carregar todos ----

local running, cancel = false, false
local ASK_BASE = 1500000000   -- longe dos pedidos do proprio gunny (1, 2, 3...), que ele ignora por nao conhecer
local askSeq, asks = 0, {}

RegisterNetEvent('whip_gunny:client:loadDone', function(ask, ok, result)
    local p = asks[ask]
    if not p then return end
    asks[ask] = nil
    p:resolve({ ok == true, result })
end)

--- Carrega o pente no endereco pelo caminho nativo do gunny e espera o fim da barra.
local function loadOne(slot, pocket)
    askSeq = askSeq + 1
    local ask, p = ASK_BASE + askSeq, promise.new()
    asks[ask] = p
    TriggerServerEvent('whip_gunny:server:loadMagazine', { sub = pocket, slot = slot }, ask)
    SetTimeout(120000, function() if asks[ask] then asks[ask] = nil; p:resolve({ false, 'timeout' }) end end)
    local r = Citizen.Await(p)
    return r[1], r[2]
end

--- Os pentes da arma na mao ainda com espaco, nos bolsos e na faixa: { slot, pocket, ammoItem }.
local function magsFor(weapon)
    local all, ammoOf = defs(), ammoOfMags()
    local fits = {}
    local w = gunnyData('items/weapons.lua', 'Weapons')[weapon.item]
    if w and type(w.compatibleMags) == 'table' then
        for _, m in ipairs(w.compatibleMags) do fits[m] = true end
    else   -- arma de pack (fora do arquivo): o mesmo calibre
        local cal = caliberOf(all[weapon.item])
        for item, def in pairs(all) do if isMag(def) and cal and caliberOf(def) == cal then fits[item] = true end end
    end
    local mags = gunnyData('items/magazines.lua', 'Magazines')
    local ok, inv = pcall(function() return exports.whip_core:GetInventory() end)
    local list = {}
    for _, pocket in ipairs({ 'player', 'accessory' }) do
        for slot, d in pairs(ok and type(inv) == 'table' and inv[pocket] or {}) do
            if fits[d.item] and ammoOf[d.item] then
                local cap = tonumber(exports.whip_core:GetItemSetting(d.item, 'capacity'))
                    or (mags[d.item] and tonumber(mags[d.item].capacity)) or math.huge
                local has = type(d.metadata) == 'table' and tonumber(d.metadata.ammo) or 0
                if has < cap then
                    list[#list + 1] = { slot = math.tointeger(tonumber(slot)), pocket = pocket, ammoItem = ammoOf[d.item] }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.pocket ~= b.pocket then return a.pocket == 'player' end
        return a.slot < b.slot
    end)
    return list
end

local function loadAll()
    if running then
        cancel = true
        notify(L('stopping'))
        return
    end
    local okW, weapon = pcall(function() return exports.whip_gunny:GetDrawnWeapon() end)
    if not okW or type(weapon) ~= 'table' or weapon.kind ~= 'gun' then return notify(L('noWeapon'), 'error') end
    local list = magsFor(weapon)
    if #list == 0 then return notify(L('none'), 'error') end

    running, cancel = true, false
    CreateThread(function()
        -- o inventario fica aberto: a barra do gunny pede keepInventory (whip_core-progress-keep-inventory-d11.patch)
        local mags, rounds, stopped = 0, 0, false
        for _, m in ipairs(list) do
            if cancel then stopped = true break end
            if (exports.whip_core:GetItemCount(m.ammoItem) or 0) < 1 then
                if mags == 0 then notify(L('noAmmo'), 'error') end
                break
            end
            local ok, res = loadOne(m.slot, m.pocket)
            if ok then
                mags, rounds = mags + 1, rounds + (tonumber(res) or 0)
            elseif res == 'Loading cancelled' or res == 'Busy' or res == 'timeout' then
                stopped = true
                break
            end
            Wait(250)   -- a arma volta a mao entre um pente e outro (whip_gunny:client:magLoading)
        end
        if mags > 0 then notify((stopped and L('stopped') or L('done')):format(mags, rounds), stopped and 'info' or 'success') end
        running, cancel = false, false
    end)
end

RegisterCommand('pentes', loadAll, false)
RegisterKeyMapping('pentes', L('keyLabel'), 'keyboard', '')
exports('LoadAllMagazines', loadAll)

RegisterNUICallback('loadAllMags', function(_, cb)
    cb({ ok = true })
    loadAll()
end)
