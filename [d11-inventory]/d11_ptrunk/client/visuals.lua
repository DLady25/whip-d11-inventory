-- d11_ptrunk (cliente): como cada item aparece no porta-malas (modelo, categoria, escala, pivo e footprint).
-- Porte de PT.ResolveVisualModel (client/props.lua) e da escolha de modelo/categoria do servidor (buildVisualSnapshot)
-- do velocity-physicaltrunk, com as calibracoes da D12 em data/item_visuals.lua.
-- Modelo: propbrowser da D12 > VisualItemModels da D12 > prop do catalogo do WHIP (item novo, se couber) > modelo
-- compacto da categoria. A escala nao muda o objeto na tela: e a medida que a fisica usa para o collider (como na D12).
local W = exports.whip_core

local V = load(LoadResourceFile(GetCurrentResourceName(), 'data/item_visuals.lua'), '@data/item_visuals.lua')()
local D = V.d12
PT.Visuals = V

-- Parametros do motor e da area (os da D12), com os ajustes do config.lua por cima.
Config.VisualPropPhysics = D.physics
for k, v in pairs(Config.PhysicsOverrides or {}) do Config.VisualPropPhysics[k] = v end
Config.VisualPlacement = D.placement

local cache = {}

--- Nome do item na D12 (os dados vem de la); Config.ItemAliases cobre os que mudaram de nome no WHIP.
local function d12Name(item)
    return tostring((Config.ItemAliases or {})[item] or item):lower()
end

--- Categoria como o servidor da D12 decidia: a tabela, depois arma pelo nome, depois municao, senao default.
local function categoryOf(name, def)
    local cat = D.itemCategories[name]
    if cat then return cat end
    local label = tostring(def and def.name or ''):lower()
    if (def and def.type == 'weapon') or name:find('weapon_') == 1 or name:find('pistol') or name:find('smg')
        or name:find('rifle') or name:find('shotgun') or name:find('mg') or name:find('sniper')
        or name == 'microsmg' or label:find('smg') then
        return 'weapon'
    end
    if name:find('ammo') or name:find('municao') or name:find('muni') or (def and (def.type == 'ammo' or def.type == 'magazine')) then
        return 'mechanic'
    end
    return 'default'
end

--- O prop do catalogo do WHIP, se existir e couber: hash e nome (nome nil quando o catalogo da um hash).
local function catalogProp(def)
    local prop = def and def.prop
    if type(prop) == 'table' then prop = prop.model end
    local name = type(prop) == 'string' and prop ~= '' and prop or nil
    if name then prop = joaat(name) end
    if type(prop) ~= 'number' or not IsModelInCdimage(prop) then return nil end
    local mn, mx = GetModelDimensions(prop)
    if math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z) > Config.Props.maxModelSize then return nil end
    return prop, name
end

local function hashOf(model)
    if type(model) == 'number' then return model end
    return joaat(tostring(model))
end

--- { model (hash), scale, category, pivot, name (D12) } de um item do WHIP.
--- O modelo da faixa de quantidade (Config.ItemModelsByAmount) que serve para `amount`, ou nil.
local AMOUNT_TESTS = {
    below = function(n, v) return n < v end, above = function(n, v) return n > v end,
    atLeast = function(n, v) return n >= v end, atMost = function(n, v) return n <= v end,
}
local function amountModel(item, amount)
    local tiers = (Config.ItemModelsByAmount or {})[item]
    local n = tonumber(amount)
    if not tiers or not n then return nil end
    for _, t in ipairs(tiers) do
        local fits = true
        for test, fn in pairs(AMOUNT_TESTS) do
            if t[test] ~= nil and not fn(n, t[test]) then fits = false break end
        end
        if fits and type(t.model) == 'string' and IsModelInCdimage(joaat(t.model)) then return t.model end
    end
    return nil
end

--- A arma de um item de arma (gunny_<arma> do whip_gunny, weapon_<arma> da D12), ou nil. Um modelo de arma (w_*) so e
--- desenhado com o asset da arma carregado: sem ele o objeto existe mas fica invisivel.
local function weaponOf(item)
    local base = item:match('^gunny_(.+)$') or item:match('^weapon_(.+)$')
    if not base then return nil end
    local hash = joaat('WEAPON_' .. base:upper())
    return IsWeaponValid(hash) and hash or nil
end

--- Carrega o que o modelo do item precisa alem dele mesmo (o asset da arma), ate 2 s. Fica carregado: e pouco e
--- outros objetos da mesma arma usam.
function PT.LoadItemAssets(v)
    if not v or not v.weapon or HasWeaponAssetLoaded(v.weapon) then return end
    RequestWeaponAsset(v.weapon, 31, 0)
    local deadline = GetGameTimer() + 2000
    while not HasWeaponAssetLoaded(v.weapon) and GetGameTimer() < deadline do Wait(0) end
end

--- amount: quantos ha na pilha (o modelo pode mudar com ele, Config.ItemModelsByAmount); nil = o modelo do item.
function PT.ItemVisual(item, amount)
    local byAmount = amountModel(item, amount)
    local cacheKey = byAmount and (item .. '#' .. byAmount) or item
    local hit = cache[cacheKey]
    if hit then return hit end
    local name = d12Name(item)
    local def = W:GetItemDef(item)
    local category = categoryOf(name, def)
    -- Ordem: o mapa do WHIP (Config.ItemModels, se o modelo existe), o propbrowser e o modelo da D12, o `prop` do
    -- catalogo do WHIP, e por fim o modelo da categoria.
    local source = byAmount and 'quantidade' or 'whip'
    local modelName = byAmount or (Config.ItemModels or {})[item]
    local model = modelName and hashOf(modelName)
    if model and not IsModelInCdimage(model) then model, modelName = nil, nil end
    if not model then
        source = V.propbrowserModels[name] and 'propbrowser' or 'd12'
        modelName = V.propbrowserModels[name] or D.itemModels[name]
        model = modelName and hashOf(modelName)
    end
    if not model then
        source = 'catalogo'
        model, modelName = catalogProp(def)
    end
    if not model then
        source = 'categoria'
        modelName = (D.useCompact and (D.compact[category] or D.compact.default)) or (D.categories[category] or D.categories.default).model
        model = hashOf(modelName)
    end
    local scale = (D.baseScale or 1.0) * ((D.categoryScale or {})[category] or (D.categoryScale or {}).default or 1.0)
    local itemScale = tonumber((D.itemScale or {})[name])
    if itemScale and itemScale > 0.0 then scale = scale * itemScale end
    hit = { model = model, modelName = type(modelName) == 'string' and modelName or nil, scale = scale,
        category = category, pivot = V.propbrowserPivots[name], name = name, source = source,
        weapon = type(modelName) == 'string' and modelName:sub(1, 2) == 'w_' and weaponOf(item) or nil }
    cache[cacheKey] = hit
    return hit
end

-- O mesmo modelo no chao e na mao (patch whip_core-item-prop-resolver-d11: o WHIP pergunta aqui pelo modelo de cada
-- item que ele desenha no chao ou na mao). nil = o WHIP usa o prop do catalogo dele.
exports('ItemPropModel', function(item, amount)
    if type(item) ~= 'string' then return nil end
    local ok, v = pcall(PT.ItemVisual, item, tonumber(amount))
    return ok and v and v.modelName or nil
end)

--- Escala automatica da D12 (applyAutoScale): modelos grandes encolhem o collider. Com o modelo ja carregado.
function PT.AutoScale(baseScale, model)
    local cfg = D.autoScale or {}
    if not cfg.enabled then return baseScale end
    local mn, mx = GetModelDimensions(model)
    local maxDim = math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)
    local threshold = tonumber(cfg.dimensionThreshold) or 0.45
    if maxDim <= threshold then return baseScale end
    local clampMax = tonumber(cfg.maxDimensionClamp) or 1.10
    local ratio = math.max(0.0, math.min(1.0, (math.min(maxDim, clampMax) - threshold) / math.max(0.001, clampMax - threshold)))
    return baseScale * (1.0 - (1.0 - (tonumber(cfg.minMultiplier) or 0.58)) * ratio)
end

-- ------------------------------------------------------------------ pivo e footprint do propbrowser
--- Offsets do propbrowser do item (px/py/pz, colliderRadius, footprint), no formato que a fisica le.
function PT.GetPropBrowserOffsets(item)
    return type(item) == 'table' and type(item.propPivot) == 'table' and item.propPivot or nil
end

function PT.GetPropBrowserFootprint(item)
    local o = PT.GetPropBrowserOffsets(item)
    return o and type(o.footprint) == 'table' and o.footprint or nil
end

--- Desloca a origem pelo pivo calibrado, girado pela pose (applyPropBrowserPivotOffset da D12).
function PT.ApplyPropBrowserPivotOffset(item, scale, x, y, z, yaw, pitch, roll)
    local o = PT.GetPropBrowserOffsets(item)
    if not o then return x, y, z end
    local s = tonumber(scale) or 1.0
    local px, py, pz = (tonumber(o.px) or 0.0) * s, (tonumber(o.py) or 0.0) * s, (tonumber(o.pz) or 0.0) * s
    if px == 0.0 and py == 0.0 and pz == 0.0 then return x, y, z end
    local Y, P, R = math.rad(tonumber(yaw) or 0.0), math.rad(tonumber(pitch) or 0.0), math.rad(tonumber(roll) or 0.0)
    local cosY, sinY = math.cos(Y), math.sin(Y)
    local cosP, sinP = math.cos(P), math.sin(P)
    local cosR, sinR = math.cos(R), math.sin(R)
    local y1 = cosP * py - sinP * pz
    local z1 = sinP * py + cosP * pz
    local x2 = cosR * px + sinR * z1
    local z2 = -sinR * px + cosR * z1
    return x - (cosY * x2 - sinY * y1), y - (sinY * x2 + cosY * y1), z - z2
end
