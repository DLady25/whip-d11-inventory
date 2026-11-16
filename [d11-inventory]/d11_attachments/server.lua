-- d11_attachments (server): o "Acessorios" no menu das armas do gunny, e acoplar / remover com a arma em maos.
-- Mesma regra da bancada do gunny (server/attachments.lua): tira antes de dar, desfaz o que ficou pela metade,
-- grava em metadata.attachments (+ attachmentMeta, o metadata do item acoplado) e avisa o cliente do gunny
-- (whip_gunny:client:attachmentInstalled/Removed) para por/tirar o componente da arma sacada.
-- Diferenca: sem a checagem de distancia da bancada (BENCH_NEAR).

--- O que o painel precisa: os acessorios na arma e os que o jogador carrega (com o endereco de cada um).
local function panelData(source, weaponItem, meta)
    local carried = {}
    for attName in pairs(Catalog.attachments) do
        local all = Whip.core:FindAllItems(source, attName)
        for _, found in ipairs(type(all) == 'table' and all or {}) do
            carried[#carried + 1] = { slot = found.addr.slot, pocket = found.addr.sub, name = found.item,
                                      amount = found.amount }
        end
    end
    return { weapon = weaponItem, attachments = (meta or {}).attachments or {}, carried = carried }
end

local function weaponSchema(extra)
    local params = { { 'weapon', 'slot' } }
    for _, p in ipairs(extra or {}) do params[#params + 1] = p end
    return { rateLimit = 300, burst = 6, params = params }
end

local function takesAttachments(item)
    return Catalog.weapons[item] ~= nil and next(Catalog.weapons[item]) ~= nil
end

local Calls = {}

function Calls.data(source, weapon)
    if not takesAttachments(weapon.item) then return false, Config.Text.noAttachments end
    return true, panelData(source, weapon.item, weapon.metadata)
end

function Calls.install(source, weapon, attachment)
    if not takesAttachments(weapon.item) then return false, Config.Text.noAttachments end
    local componentHash, att = Catalog.component(weapon.item, attachment.item)
    if not componentHash then return false, 'Esta arma não aceita esse acessório.' end

    local meta = weapon.metadata or {}
    meta.attachments = meta.attachments or {}
    if meta.attachments[att.category] then return false, 'Esse encaixe já está ocupado.' end

    local removed, why = exports.whip_core:StoreTake(attachment.addr, 1, { reason = 'acoplado na arma' })
    if not removed then return false, why or 'Não foi possível pegar o acessório.' end

    local fitted = {}
    for k, v in pairs(type(removed) == 'table' and type(removed.metadata) == 'table' and removed.metadata or {}) do
        fitted[k] = v
    end
    meta.attachments[att.category] = attachment.item
    meta.attachmentMeta = meta.attachmentMeta or {}
    meta.attachmentMeta[att.category] = fitted
    if not exports.whip_core:SetItemMetadata(weapon.addr, meta) then
        local back = Whip.core:AddItem(source, attachment.item, 1, next(fitted) and fitted or nil, 'acoplar desfeito')
        if not back then print(('[d11_attachments] %s PERDIDO: arma nao gravou e o item nao voltou'):format(attachment.item)) end
        return false, 'Não foi possível salvar a arma.'
    end

    TriggerClientEvent('whip_gunny:client:attachmentInstalled', source, weapon.addr.slot, att.category, attachment.item, componentHash)
    return true, panelData(source, weapon.item, meta)
end

function Calls.remove(source, weapon, category)
    local meta = weapon.metadata or {}
    local attName = (meta.attachments or {})[category]
    if not attName then return false, 'Nada acoplado aí.' end
    local componentHash = Catalog.component(weapon.item, attName)

    -- Sai da arma primeiro; o AddItem pode esperar (bolsos cheios largam no chao).
    meta.attachments[category] = nil
    local fitted = type(meta.attachmentMeta) == 'table' and meta.attachmentMeta[category] or nil
    if not fitted and type(meta.attachmentUids) == 'table' and meta.attachmentUids[category] then
        fitted = { uid = meta.attachmentUids[category] }
    end
    if type(meta.attachmentMeta) == 'table' then meta.attachmentMeta[category] = nil end
    if type(meta.attachmentUids) == 'table' then meta.attachmentUids[category] = nil end
    if not exports.whip_core:SetItemMetadata(weapon.addr, meta) then return false, 'Não foi possível salvar a arma.' end

    if not Whip.core:AddItem(source, attName, 1, fitted, 'retirado da arma') then
        -- Sem lugar nenhum: volta para a arma, se ela ainda estiver no mesmo slot.
        local now = Whip.core:GetItemAt(weapon.addr)
        local ok = false
        if type(now) == 'table' and now.item == weapon.item then
            local nowMeta = now.metadata or {}
            if nowMeta.serial == meta.serial then
                nowMeta.attachments = nowMeta.attachments or {}
                nowMeta.attachments[category] = attName
                if fitted then
                    nowMeta.attachmentMeta = nowMeta.attachmentMeta or {}
                    nowMeta.attachmentMeta[category] = fitted
                end
                ok = Whip.core:SetItemMetadata(weapon.addr, nowMeta) == true
            end
        end
        if not ok then print(('[d11_attachments] %s PERDIDO: sem espaco e a arma nao aceitou de volta'):format(attName)) end
        return false, 'Sem espaço para o acessório.'
    end

    TriggerClientEvent('whip_gunny:client:attachmentRemoved', source, weapon.addr.slot, category, componentHash)
    return true, panelData(source, weapon.item, meta)
end

local SCHEMAS = {
    data = weaponSchema(),
    install = weaponSchema({ { 'attachment', 'slot' } }),
    remove = weaponSchema({ { 'category', 'key', 64 } }),
}

Whip.register(function()
    for name, schema in pairs(SCHEMAS) do
        Whip.core:SecureCallback('d11_attachments:' .. name, schema, function(source, _, ...)
            return Calls[name](source, ...)
        end)
    end

    Whip.core:RegisterContextAction(Config.MenuAction, function(source, _, slotData, addr)
        if not (slotData and takesAttachments(slotData.item)) then return end
        TriggerClientEvent('d11_attachments:open', source, addr.sub or 'player', addr.slot)
    end)

    local count = 0
    for weaponItem in pairs(Catalog.weapons) do
        if takesAttachments(weaponItem) then
            local ok, why = Whip.core:AddItemOption(weaponItem, { action = Config.MenuAction, label = Config.MenuLabel, order = 5 })
            if ok then count = count + 1 else print(('[d11_attachments] %s: %s'):format(weaponItem, tostring(why))) end
        end
    end
    print(('[d11_attachments] "%s" em %d armas do gunny'):format(Config.MenuLabel, count))
end)
