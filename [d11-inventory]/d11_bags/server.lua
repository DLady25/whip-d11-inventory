-- Registra as bolsas (config.lua) como itens-painel do whip_core: abrir pelo menu ou duplo clique mostra um painel
-- ao lado do inventario (renderer d11_inventory). O conteudo vive no metadata `slots` do item, entao a bolsa
-- largada, guardada ou entregue leva tudo junto, e o whip_core soma o conteudo no peso de quem carrega.

local weightOf

--- Peso de uma pilha com o que houver dentro (bolsas, carteira e duffle guardam em metadata.slots).
weightOf = function(item, amount, metadata, depth)
    local def = exports.whip_core:GetItemDef(item)
    local total = ((def and def.weight) or 0) * (amount or 1)
    depth = (depth or 0) + 1
    local inner = depth <= 4 and type(metadata) == 'table' and metadata.slots
    if type(inner) == 'table' then
        for _, e in pairs(inner) do
            if type(e) == 'table' and e.item then total = total + weightOf(e.item, e.amount, e.metadata, depth) end
        end
    end
    return total
end

local function contentsWeight(host)
    local slots = host and type(host.metadata) == 'table' and host.metadata.slots
    local total = 0
    if type(slots) == 'table' then
        for _, e in pairs(slots) do
            if type(e) == 'table' and e.item then total = total + weightOf(e.item, e.amount, e.metadata) end
        end
    end
    return total
end

--- Limite interno da bolsa. Uma troca (swap) desconta o que sai do slot.
local function validator(bag)
    return function(ctx)
        if ctx.direction ~= 'in' or not ctx.item then return true end
        local now = contentsWeight(ctx.host)
        local adding = weightOf(ctx.item, ctx.amount, ctx.metadata)
        local r = ctx.replacing
        if ctx.swap and not r then   -- metade de volta de uma troca: quem esta no slot sai
            local slots = type(ctx.host.metadata) == 'table' and ctx.host.metadata.slots or {}
            r = slots[ctx.slot] or slots[tostring(ctx.slot)]
        end
        if type(r) == 'table' and r.item then now = now - weightOf(r.item, r.amount, r.metadata) end
        if now + adding > bag.maxWeight + 0.0001 then
            return false, D11BagsText.tooHeavy:format(bag.name, bag.maxWeight)
        end
        return true
    end
end

Whip.register(function()
    local n, failed = 0, {}
    for key, bag in pairs(D11Bags) do
        local ok, why = Whip.core:RegisterItem(key, {
            name = bag.name, desc = bag.desc, weight = bag.weight,
            type = 'accessory', stack = false, maxStack = 1, usable = false, cooldown = 0,
            -- sem o arquivo, o icone padrao do WHIP (o pacote publico nao traz os icones das caixas)
            image = LoadResourceFile(GetCurrentResourceName(), ('html/img/items/%s.png'):format(key))
                and ('html/img/items/%s.png'):format(key) or nil,
            prop = bag.prop,
            defaultAction = D11BagsAction,
            contextOptions = { { action = D11BagsAction, label = D11BagsText.open } },
        })
        if ok then
            ok, why = Whip.core:RegisterPanelItem(key, {
                action = D11BagsAction, slots = bag.slots, label = bag.name, storageKey = 'slots',
                onValidate = validator(bag),
            })
        end
        if ok then n = n + 1 else failed[#failed + 1] = ('%s (%s)'):format(key, tostring(why)) end
    end
    print(('[d11_bags] %d bags registered%s'):format(n, #failed > 0 and ('; failed: ' .. table.concat(failed, ', ')) or ''))
end)

