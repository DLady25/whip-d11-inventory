-- d11_ptrunk (servidor): abre o store nativo do porta-malas, guarda quem esta no modo fisico de cada carro e a pose
-- de cada item (onde o jogador deixou o objeto). O inventario (mover, pesar, empilhar, trava do carro, log) e todo
-- do WHIP. Um jogador por carro no modo fisico (decisao 3 do plano); quem chega depois ve o porta-malas normal.
-- Idioma: setr d11_locale en | pt-BR (padrao en), como o config.lua.
local PT_BR = GetConvar('d11_locale', 'en') == 'pt-BR'
local function L(en, pt) return PT_BR and pt or en end
local W = exports.whip_core

local holder = {}   -- [vehicleId] = src no modo fisico
local held = {}     -- [src] = { vehicleId, missingSince }
local poses = {}    -- [vehicleId] = { [key] = { item, x, y, z, yaw, pitch, roll } }, carregado sob demanda

local function release(src)
    local h = held[src]
    if not h then return end
    held[src] = nil
    if holder[h.vehicleId] == src then holder[h.vehicleId] = nil end
end

--- O carro por netId, conferido contra o vehicleId que o cliente mandou.
local function vehicleOf(net, vehicleId)
    local veh = NetworkGetEntityFromNetworkId(net)
    if not veh or veh == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return nil end
    if vehicleId then
        local snap = W:GetVehicle(vehicleId)
        if not snap or tonumber(snap.netId) ~= net then return nil end
    end
    return veh
end

-- ------------------------------------------------------------------ poses
-- A pose e de um item, nao de um slot: chave = uid do item (o WHIP carimba em cada movimento e ignora no stack).
-- Item sem uid (criado por script e nunca mexido) usa 'slot:<n>:<item>' ate ganhar um.
local function keyOf(slot, it)
    local uid = type(it.metadata) == 'table' and it.metadata.uid or nil
    if uid ~= nil then return tostring(uid) end
    return ('slot:%d:%s'):format(slot, it.item)
end

local function posesOf(vehicleId)
    local t = poses[vehicleId]
    if t then return t end
    t = {}
    local ok, rows = pcall(MySQL.query.await,
        'SELECT pose_key, item, x, y, z, yaw, pitch, roll FROM d11_ptrunk_pose WHERE vehicle_id = ?', { vehicleId })
    for _, r in ipairs(ok and rows or {}) do
        t[r.pose_key] = { item = r.item, x = r.x, y = r.y, z = r.z, yaw = r.yaw, pitch = r.pitch, roll = r.roll }
    end
    poses[vehicleId] = t
    return t
end

--- Itens de um porta-malas na ordem dos slots: { slot, item, uid, key, pose? }, ate Config.Props.max.
local function trunkItems(vehicleId)
    local store = W:StoreRead({ kind = 'vehicle', id = vehicleId, sub = 'trunk' })
    local known = posesOf(vehicleId)
    local list = {}
    for slot, it in pairs(type(store) == 'table' and store.items or {}) do
        slot = tonumber(slot)
        if type(it) == 'table' and it.item and slot then
            local key = keyOf(slot, it)
            local pose = known[key]
            list[#list + 1] = {
                slot = slot, item = it.item, key = key, amount = it.amount,
                uid = type(it.metadata) == 'table' and it.metadata.uid or nil,
                pose = pose and pose.item == it.item and pose or nil,
            }
        end
    end
    table.sort(list, function(a, b) return a.slot < b.slot end)
    while #list > Config.Props.max do list[#list] = nil end
    return list, store
end

--- Tira as poses de itens que ja sairam do porta-malas.
local function prunePoses(vehicleId, store)
    local known = poses[vehicleId]
    if not known or type(store) ~= 'table' then return end
    local present = {}
    for slot, it in pairs(store.items or {}) do
        if type(it) == 'table' and it.item and tonumber(slot) then present[keyOf(tonumber(slot), it)] = true end
    end
    local gone = {}
    for key in pairs(known) do
        if not present[key] then gone[#gone + 1] = key; known[key] = nil end
    end
    if #gone > 0 then
        MySQL.update(('DELETE FROM d11_ptrunk_pose WHERE vehicle_id = ? AND pose_key IN (%s)')
            :format(('?,'):rep(#gone):sub(1, -2)), { vehicleId, table.unpack(gone) })
    end
end

-- ------------------------------------------------------------------ eventos
local function onOpen(src, _, net, vehicleId)
    local veh = vehicleOf(net, vehicleId)
    if not veh then return { ok = false, reason = Config.Text.notFound } end
    if held[src] and held[src].vehicleId ~= vehicleId then release(src) end

    local busy = holder[vehicleId]
    if busy and busy ~= src and not GetPlayerName(busy) then holder[vehicleId], busy = nil, nil end
    local physical = not busy or busy == src

    -- O WHIP confere distancia, trava do carro e se o jogador ja tem outra tela aberta.
    local ok, why = W:OpenStore(src, { kind = 'vehicle', id = vehicleId, sub = 'trunk' })
    if not ok then return { ok = false, reason = why } end
    if not physical then return { ok = true, physical = false } end

    holder[vehicleId] = src
    held[src] = { vehicleId = vehicleId }
    local items, store = trunkItems(vehicleId)
    prunePoses(vehicleId, store)
    return { ok = true, physical = true, items = items }
end

local function onClose(src, _, vehicleId)
    local h = held[src]
    if h and h.vehicleId == vehicleId then release(src) end
end

--- Pose de um item, mandada por quem esta no modo fisico do carro. x/y no plano do porta-malas (espaco do carro),
--- z = quanto acima do fundo (empilhado, mais alto; um pouco abaixo de zero e o objeto encostado), yaw/pitch/roll em
--- graus.
local function onPose(src, _, vehicleId, key, x, y, z, yaw, pitch, roll)
    if holder[vehicleId] ~= src then return false end
    local store = W:StoreRead({ kind = 'vehicle', id = vehicleId, sub = 'trunk' })
    local item
    for slot, it in pairs(type(store) == 'table' and store.items or {}) do
        if type(it) == 'table' and it.item and tonumber(slot) and keyOf(tonumber(slot), it) == key then item = it.item break end
    end
    if not item then return false end
    local pose = { item = item, x = x, y = y, z = z, yaw = yaw, pitch = pitch, roll = roll }
    posesOf(vehicleId)[key] = pose
    MySQL.insert([[
        INSERT INTO d11_ptrunk_pose (vehicle_id, pose_key, item, x, y, z, yaw, pitch, roll) VALUES (?,?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE item = VALUES(item), x = VALUES(x), y = VALUES(y), z = VALUES(z),
            yaw = VALUES(yaw), pitch = VALUES(pitch), roll = VALUES(roll)]],
        { vehicleId, key, item, x, y, z, yaw, pitch, roll })
end

--- O carro do modo fisico de quem pediu, ou nil.
local function heldVehicle(src, vehicleId)
    if holder[vehicleId] ~= src then return nil end
    local snap = W:GetVehicle(vehicleId)
    local veh = snap and snap.netId and NetworkGetEntityFromNetworkId(snap.netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end
    return veh
end

--- O ponto no chao serve: perto do carro (a area fica na frente do porta-malas) e do jogador.
local function groundSpotOk(src, veh, at)
    return #(GetEntityCoords(veh) - at) <= Config.GroundReach + 1.0 and #(GetEntityCoords(GetPlayerPed(src)) - at) <= 8.0
end

local FROM = { trunk = true, player = true, accessory = true }

--- Larga no chao, no ponto escolhido, o item de `slot` do porta-malas ou dos bolsos (o WHIP so larga dos bolsos,
--- e na frente do jogador): tira do slot e cria o item no chao. Se o chao recusar, o item volta para o mesmo slot.
--- Larga no chao o item de `slot` de uma bolsa ou caixa aberta pelo jogador (o painel `panelId` dele: o WHIP so acha
--- painel deste jogador, Stores.fromAddr com owner). Mesmo caminho do porta-malas: tira, cria no chao, devolve se recusar.
local function onPanelToGround(src, _, vehicleId, panelId, slot, x, y, z, heading)
    local veh = heldVehicle(src, vehicleId)
    local at = vector3(x, y, z)
    if not veh then return false end
    if not groundSpotOk(src, veh, at) then return false, 'Longe demais.' end
    local addr = { kind = 'panel', id = panelId, owner = src, slot = slot }
    local taken, why = W:StoreTake(addr, nil, 'd11_ptrunk: largar no chao (da bolsa)')
    if not taken then return false, why end
    local ok, err = W:CreateGroundItem({ item = taken.item, amount = taken.amount, metadata = taken.metadata,
        coords = at, heading = heading, reason = 'da bolsa perto do porta-malas' })
    if not ok then
        W:StoreGive(addr, taken.item, taken.amount, taken.metadata, 'd11_ptrunk: chao recusou')
        return false, err
    end
end

local function onToGround(src, _, vehicleId, from, slot, x, y, z, heading)
    local veh = heldVehicle(src, vehicleId)
    local at = vector3(x, y, z)
    if not veh or not FROM[from] then return false end
    if not groundSpotOk(src, veh, at) then return false, 'Longe demais.' end
    local addr = from == 'trunk' and { kind = 'vehicle', id = vehicleId, sub = 'trunk', slot = slot }
        or { kind = 'player', id = src, sub = from, slot = slot }
    local taken, why = W:StoreTake(addr, nil, 'd11_ptrunk: largar no chao')
    if not taken then return false, why end
    local ok, err = W:CreateGroundItem({ item = taken.item, amount = taken.amount, metadata = taken.metadata,
        coords = at, heading = heading, reason = from == 'trunk' and 'do porta-malas' or 'largado perto do porta-malas' })
    if not ok then
        W:StoreGive(addr, taken.item, taken.amount, taken.metadata, 'd11_ptrunk: chao recusou')
        return false, err
    end
end


--- Itens no chao perto do carro do modo fisico (para pegar com o mouse e guardar no porta-malas).
local function onGroundNear(src, _, vehicleId)
    if holder[vehicleId] ~= src then return {} end
    local snap = W:GetVehicle(vehicleId)
    local veh = snap and snap.netId and NetworkGetEntityFromNetworkId(snap.netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return {} end
    local out = {}
    for _, g in ipairs(W:GetGroundItemsNearby(GetEntityCoords(veh), Config.GroundReach) or {}) do
        out[#out + 1] = { id = g.id, item = g.item, amount = g.amount, x = g.x, y = g.y, z = g.z, heading = g.heading,
            placed = g.placed, rx = g.rx, ry = g.ry, flight = g.flight }
        if #out >= 40 then break end
    end
    return out
end

--- Item do chao para o porta-malas (o WHIP nao abre o painel do chao com um store aberto). Tira do chao primeiro (se
--- outro jogador ja pegou, nada acontece) e poe no porta-malas; sem espaco, volta para o mesmo lugar no chao.
local function onFromGround(src, _, vehicleId, groundId)
    if holder[vehicleId] ~= src then return false end
    local g = W:GetGroundItem(groundId)
    local snap = W:GetVehicle(vehicleId)
    local veh = snap and snap.netId and NetworkGetEntityFromNetworkId(snap.netId)
    if not g or not veh or veh == 0 or not DoesEntityExist(veh) then return false, L('That item is not on the ground any more.', 'Esse item não está mais no chão.') end
    local at = vector3(g.x, g.y, g.z)
    if #(GetEntityCoords(veh) - at) > Config.GroundReach + 1.0 or #(GetEntityCoords(GetPlayerPed(src)) - at) > 8.0 then
        return false, 'Longe demais.'
    end
    if not W:DeleteGroundItem(groundId) then return false, L('That item is not on the ground any more.', 'Esse item não está mais no chão.') end
    local slot = W:StoreGive({ kind = 'vehicle', id = vehicleId, sub = 'trunk' }, g.item, g.amount, g.metadata,
        'd11_ptrunk: do chao')
    if not slot then
        W:CreateGroundItem({ item = g.item, amount = g.amount, metadata = g.metadata, coords = at, heading = g.heading,
            reason = 'd11_ptrunk: porta-malas cheio' })
        return false, L('It does not fit in the trunk.', 'Não cabe no porta-malas.')
    end
end

-- ------------------------------------------------------------------ itens do chao com o inventario aberto (client/ground.lua)
--- Itens do chao perto do jogador.
local function onGroundAround(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return {} end
    local out = {}
    for _, g in ipairs(W:GetGroundItemsNearby(GetEntityCoords(ped), Config.GroundFree.reach) or {}) do
        out[#out + 1] = { id = g.id, item = g.item, amount = g.amount, x = g.x, y = g.y, z = g.z, heading = g.heading,
            placed = g.placed, rx = g.rx, ry = g.ry, flight = g.flight }
        if #out >= 40 then break end
    end
    return out
end

local function nearPed(src, at, range)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - at) <= range
end


--- A pose de um item do chao que assentou com a fisica deste jogador (client/groundphys.lua): o mesmo id, no lugar e
--- com a inclinacao exata (MoveGroundItem, patch whip_core-ground-physics-d11). Perto do jogador, e nao longe de onde
--- estava (empurrado ou arrastado, nao teleportado).
local function onGroundPose(src, _, groundId, x, y, z, heading, rx, ry)
    local g = W:GetGroundItem(groundId)
    local at = vector3(x, y, z)
    if not g then return false end
    if not nearPed(src, at, 8.0) or #(vector3(g.x, g.y, g.z) - at) > 8.0 then return false end
    local ok, err = W:MoveGroundItem(groundId, at, heading, rx, ry)
    if not ok then return false, err end
end

--- O endereco de um store que o jogador tem aberto: 'player', 'container:N', 'vehicle:N:trunk' ou 'panel:<id>'.
local function openStoreAddr(src, to)
    if to == 'player' then return { kind = 'player', id = src, sub = 'player' } end
    for _, a in ipairs(W:GetOpenStores(src) or {}) do
        if a.kind == 'container' and to == ('container:%s'):format(a.id) then return { kind = 'container', id = a.id } end
        if a.kind == 'vehicle' and to == ('vehicle:%s:%s'):format(a.id, a.sub or 'trunk') then
            return { kind = 'vehicle', id = a.id, sub = a.sub or 'trunk' }
        end
        if a.kind == 'panel' and to == ('panel:%s'):format(a.id) then return { kind = 'panel', id = a.id, owner = src } end
    end
    return nil
end

--- Pega um item do chao para os bolsos ou para um store aberto (stash, porta-malas, bolsa): tira do chao primeiro (se
--- outro jogador ja pegou, nada acontece) e poe no slot pedido, ou onde couber; sem espaco, volta para o chao.
local function onGroundTake(src, _, groundId, to, slot)
    local g = W:GetGroundItem(groundId)
    if not g then return false, L('That item is not on the ground any more.', 'Esse item não está mais no chão.') end
    if not nearPed(src, vector3(g.x, g.y, g.z), Config.GroundFree.reach + 1.0) then return false, 'Longe demais.' end
    local addr = openStoreAddr(src, to)
    if not addr then return false end
    if not W:DeleteGroundItem(groundId) then return false, L('That item is not on the ground any more.', 'Esse item não está mais no chão.') end
    local put
    if slot and slot > 0 then
        local exact = {}
        for k, v in pairs(addr) do exact[k] = v end
        exact.slot = slot
        put = W:StoreGive(exact, g.item, g.amount, g.metadata, 'd11_ptrunk: do chao')
    end
    put = put or W:StoreGive(addr, g.item, g.amount, g.metadata, 'd11_ptrunk: do chao')
    if not put then
        W:CreateGroundItem({ item = g.item, amount = g.amount, metadata = g.metadata, coords = vector3(g.x, g.y, g.z),
            heading = g.heading, reason = 'd11_ptrunk: nao coube' })
        return false, L('It does not fit there.', 'Não cabe aí.')
    end
end

--- Porta-malas aberto de outro carro, so para ver: os itens (com as poses) de quem esta perto.
local function onScene(src, _, net)
    local veh = vehicleOf(net)
    if not veh then return {} end
    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - GetEntityCoords(veh)) > Config.Ambient.range + 5.0 then return {} end
    local snap = W:GetVehicle({ netId = net })
    if not snap or not snap.vehicleId then return {} end
    -- So o que se ve: o porta-malas aberto (a mascara de portas do whip, bits 4 capo e 5 porta-malas), alguem nele no
    -- modo fisico, ou quem esta junto de um carro destrancado (vai abrir a tampa: os objetos montam antes). Sem isso,
    -- um cliente adulterado lia o porta-malas fechado de qualquer carro por perto.
    local doors = tonumber(Entity(veh).state.whipVehDoors) or 0
    local lidOpen = (doors & 0x30) ~= 0
    local canOpen = not snap.locked and #(GetEntityCoords(ped) - GetEntityCoords(veh)) <= 5.0
    if not (lidOpen or holder[snap.vehicleId] or canOpen) then return {} end
    return (trunkItems(snap.vehicleId))
end

-- A vez do modo fisico acaba quando o porta-malas sai da tela do jogador (fechou, caiu, o WHIP fechou o store),
-- mesmo sem o aviso do cliente.
CreateThread(function()
    while true do
        Wait(2000)
        local now = os.time()
        for src, h in pairs(held) do
            local open = false
            for _, addr in ipairs(W:GetOpenStores(src) or {}) do
                if addr.kind == 'vehicle' and tonumber(addr.id) == h.vehicleId then open = true break end
            end
            if open then
                h.missingSince = nil
            elseif not h.missingSince then
                h.missingSince = now
            elseif now - h.missingSince >= Config.LockGraceSeconds then
                release(src)
            end
        end
    end
end)

AddEventHandler('playerDropped', function() release(source) end)

-- ------------------------------------------------------------------ admin (porte dos comandos da D12)
local function admin(src) return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce) end

local function say(src, text, kind)
    if src == 0 then print(('[d11_ptrunk] %s'):format(text)) else W:NotifyPlayer(src, text, kind or 'info') end
end

-- /ptrunkphysics [on|off]: fisica dos objetos ligada ou desligada para todos (GlobalState, como na D12).
RegisterCommand('ptrunkphysics', function(src, args)
    if not admin(src) then return end
    local a = tostring(args[1] or ''):lower()
    local current = GlobalState.d11PtrunkPhysicsEnabled ~= false
    local enabled = not current
    if a == 'on' or a == '1' or a == 'true' or a == 'ligar' then enabled = true
    elseif a == 'off' or a == '0' or a == 'false' or a == 'desligar' then enabled = false end
    GlobalState.d11PtrunkPhysicsEnabled = enabled
    say(src, enabled and L('Trunk prop physics ON.', 'Física dos objetos do porta-malas LIGADA.')
        or L('Trunk prop physics OFF.', 'Física dos objetos do porta-malas DESLIGADA.'),
        enabled and 'success' or 'info')
end, false)

-- Pacotes de teste da D12 (ptrunkdemoload*): os itens vao para os bolsos do admin. So os que existem no catalogo do
-- WHIP; os nomes que faltam aparecem no aviso.
local DEMOS = {
    ptrunkdemoload = {
        { 'water_bottle', 3 }, { 'sandwich', 2 }, { 'bandage', 2 }, { 'painkillers', 1 }, { 'repairkit', 1 },
        { 'advancedrepairkit', 1 }, { 'lockpick', 2 }, { 'lockpick_uncommon', 1 }, { 'lockpick_rare', 1 },
        { 'moneybag', 1 }, { 'radio', 1 }, { 'phone_comum', 1 },
    },
    ptrunkdemoloadplus = {
        { 'water_bottle', 8 }, { 'sandwich', 6 }, { 'tosti', 4 }, { 'kurkakola', 4 }, { 'bandage', 6 },
        { 'painkillers', 3 }, { 'firstaid', 2 }, { 'repairkit', 2 }, { 'advancedrepairkit', 1 }, { 'lockpick', 4 },
        { 'lockpick_uncommon', 2 }, { 'lockpick_rare', 1 }, { 'screwdriverset', 1 }, { 'electronickit', 2 },
        { 'radio', 1 }, { 'phone_comum', 1 }, { 'binoculars', 1 }, { 'armor', 2 }, { 'joint', 5 },
        { 'rolling_paper', 10 }, { 'lighter', 2 }, { 'plastic', 20 }, { 'metalscrap', 20 }, { 'copper', 15 },
        { 'iron', 15 }, { 'aluminum', 15 }, { 'steel', 10 }, { 'rubber', 12 }, { 'glass', 12 }, { 'moneybag', 2 },
    },
    -- Tombar/estabilidade: [A] achatados ficam deitados, [B] altos/finos deitam sozinhos, [C] toolboxes calibrados.
    ptrunkdemotopple = {
        { 'bandage', 2 }, { 'electronickit', 2 }, { 'glass', 2 }, { 'plastic', 2 }, { 'aluminum', 2 },
        { 'rubber', 2 }, { 'tosti', 2 }, { 'rolling_paper', 2 },
        { 'water_bottle', 2 }, { 'kurkakola', 2 }, { 'lockpick', 2 }, { 'screwdriverset', 1 },
        { 'metalscrap', 2 }, { 'steel', 1 },
        { 'repairkit', 2 }, { 'advancedrepairkit', 1 }, { 'sandwich', 2 },
    },
    ptrunkdemoloadweapons = {
        { 'weapon_pistol', 1 }, { 'weapon_pistol_mk2', 1 }, { 'weapon_smg', 1 }, { 'weapon_microsmg', 1 },
        { 'pistol_ammo', 10 }, { 'smg_ammo', 10 }, { 'weapon_knife', 1 }, { 'weapon_bat', 1 },
        { 'weapon_crowbar', 1 }, { 'weapon_hatchet', 1 }, { 'weapon_machete', 1 }, { 'weapon_switchblade', 1 },
    },
}

for name, list in pairs(DEMOS) do
    RegisterCommand(name, function(src)
        if src == 0 or not admin(src) then return end
        local given, missing = 0, {}
        for _, e in ipairs(list) do
            if W:GetItemDef(e[1]) and W:AddItem(src, e[1], e[2], nil, { reason = 'd11_ptrunk ' .. name }) then
                given = given + 1
            else
                missing[#missing + 1] = e[1]
            end
        end
        say(src, (L('%s: %d/%d items.%s', '%s: %d/%d itens.%s')):format(name, given, #list,
            #missing > 0 and (L(' Not in WHIP\'s catalogue: ', ' Fora do catálogo do WHIP: ') .. table.concat(missing, ', ')) or ''),
            given > 0 and 'success' or 'error')
    end, false)
end

-- /ptrunkrepack: com o porta-malas aberto no modo fisico, apaga as poses deste carro e os objetos voltam para a grade.
RegisterCommand('ptrunkrepack', function(src)
    if src == 0 or not admin(src) then return end
    local h = held[src]
    if not h then return say(src, L('Open the trunk in physical mode before /ptrunkrepack.', 'Abra o porta-malas no modo físico antes de usar /ptrunkrepack.'), 'error') end
    poses[h.vehicleId] = {}
    MySQL.update('DELETE FROM d11_ptrunk_pose WHERE vehicle_id = ?', { h.vehicleId })
    TriggerClientEvent('d11_ptrunk:client:repack', src, h.vehicleId)
    say(src, L('Repack: the props went back to the automatic packing.', 'Repack: os objetos voltaram para a arrumação automática.'), 'success')
end, false)

-- ------------------------------------------------------------------ perfis por modelo (fase 4)
-- data/profiles (retrato da D12 de 25/09) e a base; o que o wizard grava ou o /ptrunkimport traz fica na tabela
-- d11_ptrunk_profiles e vale por cima, sem nunca escrever codigo nem arquivo (o incidente de 19/09 da D12).
local profiles = { camera = {}, spawn = {}, light = {} }   -- [kind][modelHash] = dados
local KINDS = { camera = true, spawn = true, light = true }

local function num(v, lo, hi)
    v = tonumber(v)
    if not v or v ~= v or v < lo or v > hi then return nil end
    return v
end

local function vec3(t, lo, hi)
    if type(t) ~= 'table' then return nil end
    local x, y, z = num(t.x, lo, hi), num(t.y, lo, hi), num(t.z, lo, hi)
    return x and y and z and { x = x, y = y, z = z } or nil
end

--- Confere e limpa um perfil vindo do cliente ou do arquivo da D12; nil se nao serve.
local CLEAN = {
    camera = function(p)
        local out = { access = p.access == 'front' and 'front' or 'rear' }
        for k, r in pairs({ triggerRadius = { 0.5, 8 }, standOffset = { 0, 6 }, fov = { 20, 110 },
            camLocalX = { -15, 15 }, camLocalY = { -15, 15 }, camLocalZ = { -15, 15 },
            lookLocalX = { -15, 15 }, lookLocalY = { -15, 15 }, lookLocalZ = { -15, 15 },
            rearDistance = { -2, 3 }, rearHeight = { -2, 3 }, lookHeight = { -2, 3 }, sideOffset = { -2, 2 } }) do
            out[k] = num(p[k], r[1], r[2])
        end
        if type(p.mode) == 'string' and #p.mode <= 16 then out.mode = p.mode end
        if p.doorless == true then out.doorless = true end
        return out
    end,
    spawn = function(p)
        local x, y, z = num(p.x, -10, 10), num(p.y, -10, 10), num(p.z, -3, 3)
        if not (x and y and z) or type(p.areaPoints) ~= 'table' then return nil end
        local pts = {}
        for i, q in ipairs(p.areaPoints) do
            if i > 40 or type(q) ~= 'table' then return nil end
            local qx, qy = num(q.x, -10, 10), num(q.y, -10, 10)
            if not (qx and qy) then return nil end
            pts[i] = { x = qx, y = qy }
        end
        if #pts < 3 then return nil end
        return { x = x, y = y, z = z, areaPoints = pts }
    end,
    light = function(p)
        if type(p.spots) ~= 'table' then return nil end
        local spots = {}
        for i, sp in ipairs(p.spots) do
            if i > 8 or type(sp) ~= 'table' then return nil end
            local pos, look = vec3(sp.pos, -10, 10), vec3(sp.look, -10, 10)
            if not (pos and look) then return nil end
            local c = type(sp.color) == 'table' and sp.color or {}
            spots[i] = {
                pos = pos, look = look,
                color = { r = math.floor(num(c.r, 0, 255) or 255), g = math.floor(num(c.g, 0, 255) or 235),
                    b = math.floor(num(c.b, 0, 255) or 190) },
                brightness = num(sp.brightness, 0, 30), spotFov = num(sp.spotFov, 0.5, 120),
                distance = num(sp.distance, 0, 30), radius = num(sp.radius, 0, 120),
                falloff = num(sp.falloff, 0, 200), roundness = num(sp.roundness, 0, 1),
            }
        end
        if #spots == 0 then return nil end
        return { spots = spots }
    end,
}

local function storeProfile(kind, hash, data, by)
    profiles[kind][hash] = data
    MySQL.insert([[
        INSERT INTO d11_ptrunk_profiles (model_hash, kind, data, updated_by) VALUES (?,?,?,?)
        ON DUPLICATE KEY UPDATE data = VALUES(data), updated_by = VALUES(updated_by)]],
        { hash, kind, json.encode(data), by })
end

-- Um booleano de verdade: IsPlayerAceAllowed responde 1 ou false na Lua do whip, nunca true (whip_core
-- server/devtools_base.lua), e o cliente pergunta `== true`.
local function canCalibrate(src)
    if src == 0 then return true end
    local a = IsPlayerAceAllowed(src, Config.AdminAce)
    return a == true or a == 1
end

--- { modelHash, camera?, spawn?, light? }: grava o que veio (so admin) e manda para todo mundo.
local function onSaveProfiles(src, player, data)
    if not canCalibrate(src) then return false, L('No permission to calibrate trunks.', 'Sem permissão para calibrar o porta-malas.') end
    local hash = math.tointeger(tonumber(data.modelHash))
    if not hash then return false, L('Invalid model.', 'Modelo inválido.') end
    local saved = { modelHash = hash }
    for kind in pairs(KINDS) do
        if type(data[kind]) == 'table' then
            local clean = CLEAN[kind](data[kind])
            if not clean then return false, (L('Invalid %s profile.', 'Perfil de %s inválido.')):format(kind) end
            saved[kind] = clean
        end
    end
    for kind in pairs(KINDS) do
        if saved[kind] then storeProfile(kind, hash, saved[kind], player and player.charId or nil) end
    end
    TriggerClientEvent('d11_ptrunk:client:profiles', -1, saved)
    W:NotifyPlayer(src, L('Trunk profile saved.', 'Perfil do porta-malas salvo.'), 'success')
end

-- /ptrunkimport: traz as calibracoes da D12 de arquivos que o usuario copiou para d11_ptrunk/import/:
--   config.lua           -> Config.ItemSpawnProfiles (area) e Config.TrunkLightProfiles (luz)
--   vehicle_profiles.lua -> Config.ModelProfiles (camera)
-- Os arquivos rodam isolados (sem natives, so a tabela Config); o que passa no CLEAN vai para a tabela, por cima.
local function readD12(file)
    local raw = LoadResourceFile(GetCurrentResourceName(), 'import/' .. file)
    if not raw or raw == '' then return nil end
    raw = raw:gsub('`([%w_]+)`', 'H("%1")')
    local env = { Config = {}, H = joaat, math = math, tostring = tostring, tonumber = tonumber, pairs = pairs }
    local chunk, err = load(raw, '@import/' .. file, 't', env)
    if not chunk then return nil, err end
    local ok, runErr = pcall(chunk)
    if not ok then return nil, runErr end
    return env.Config
end

RegisterCommand('ptrunkimport', function(src)
    if not canCalibrate(src) then return end
    local total = { camera = 0, spawn = 0, light = 0 }
    local skipped = 0
    local function take(kind, map)
        for hash, data in pairs(type(map) == 'table' and map or {}) do
            hash = math.tointeger(tonumber(hash))
            local clean = hash and type(data) == 'table' and CLEAN[kind](data)
            if clean then
                storeProfile(kind, hash, clean, nil)
                total[kind] = total[kind] + 1
            else
                skipped = skipped + 1
            end
        end
    end
    local cfg, err = readD12('config.lua')
    if err then return say(src, L('import/config.lua has an error: ', 'import/config.lua com erro: ') .. tostring(err), 'error') end
    local veh, err2 = readD12('vehicle_profiles.lua')
    if err2 then return say(src, L('import/vehicle_profiles.lua has an error: ', 'import/vehicle_profiles.lua com erro: ') .. tostring(err2), 'error') end
    if not cfg and not veh then
        return say(src, L('Nothing to import: copy velocity-physicaltrunk\'s config.lua and/or vehicle_profiles.lua into d11_ptrunk/import/.',
            'Nada para importar: copie config.lua e/ou vehicle_profiles.lua da D12 para d11_ptrunk/import/.'), 'error')
    end
    if cfg then take('spawn', cfg.ItemSpawnProfiles); take('light', cfg.TrunkLightProfiles) end
    if veh then take('camera', veh.ModelProfiles) end
    TriggerClientEvent('d11_ptrunk:client:profilesReload', -1)
    say(src, (L('Imported: %d cameras, %d areas, %d lights (%d skipped).', 'Importado da D12: %d câmeras, %d áreas, %d luzes (%d ignorados).'))
        :format(total.camera, total.spawn, total.light, skipped), 'success')
end, false)

-- /ptrunkexport [modelo ...] (admin ou console): o que o wizard gravou no banco vira um arquivo no formato dos
-- data/profiles (export/profiles_<data>.lua), pronto para virar um pack seu em Config.ProfilePacks ou para mandar de
-- volta ao repositorio. O arquivo fica em export/, que nada carrega. O nome do modelo sai dos packs; um carro que
-- nenhum pack conhece sai pelo hash, ou pelo nome se ele vier no comando (/ptrunkexport meucarro outrocarro).
local function luaValue(v)
    local t = type(v)
    if t == 'number' then
        if math.type(v) == 'integer' then return tostring(v) end
        return (('%.3f'):format(v):gsub('0+$', ''):gsub('%.$', ''))
    elseif t == 'boolean' then return tostring(v)
    elseif t == 'string' then return ('%q'):format(v)
    elseif t ~= 'table' then return 'nil' end
    local out = {}
    if #v > 0 then
        for _, x in ipairs(v) do out[#out + 1] = luaValue(x) end
    else
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            local key = (type(k) == 'string' and k:match('^[%a_][%w_]*$')) and k or ('[%s]'):format(luaValue(k))
            out[#out + 1] = key .. ' = ' .. luaValue(v[k])
        end
    end
    return '{ ' .. table.concat(out, ', ') .. ' }'
end

RegisterCommand('ptrunkexport', function(src, args)
    if not admin(src) then return end
    local names = {}
    for _, pack in ipairs(Config.ProfilePacks or {}) do
        local code = pack.file and LoadResourceFile(GetCurrentResourceName(), pack.file)
        local fn = code and load(code, '@' .. pack.file)
        local ok, data = false, nil
        if fn then ok, data = pcall(fn) end
        for key in pairs(ok and type(data) == 'table' and data.vehicles or {}) do
            if type(key) == 'string' then names[joaat(key)] = key end
        end
    end
    for _, a in ipairs(args) do names[joaat(tostring(a))] = tostring(a):lower() end
    local cars = {}
    for kind in pairs(KINDS) do
        for hash, data in pairs(profiles[kind]) do
            cars[hash] = cars[hash] or {}
            cars[hash][kind] = data
        end
    end
    local list = {}
    for hash, v in pairs(cars) do list[#list + 1] = { hash = hash, name = names[hash], v = v } end
    if #list == 0 then return say(src, L('Nothing in the database to export: calibrate a car with the wizard first.', 'Nada no banco para exportar: calibre um carro com o wizard primeiro.'), 'error') end
    table.sort(list, function(a, b) return (a.name or tostring(a.hash)) < (b.name or tostring(b.hash)) end)
    local lines = {
        '-- d11_ptrunk: perfis exportados do banco por /ptrunkexport em ' .. os.date('%Y-%m-%d %H:%M') .. '.',
        '-- Formato: ver data/profiles/base.lua. Carro pelo hash: troque [hash] pelo nome do modelo.',
        'return {', ' vehicles = {',
    }
    local unnamed = 0
    for _, c in ipairs(list) do
        local key = c.name and (c.name:match('^[%a_][%w_]*$') and c.name or ('[%q]'):format(c.name)) or ('[%d]'):format(c.hash)
        if not c.name then unnamed = unnamed + 1 end
        lines[#lines + 1] = ('  %s = {%s'):format(key, c.name and '' or '   -- modelo sem nome: troque pelo nome')
        for _, kind in ipairs({ 'spawn', 'camera', 'light' }) do
            if c.v[kind] then lines[#lines + 1] = ('   %s = %s,'):format(kind, luaValue(c.v[kind])) end
        end
        lines[#lines + 1] = '  },'
    end
    lines[#lines + 1] = ' },'
    lines[#lines + 1] = '}'
    local file = ('export/profiles_%s.lua'):format(os.date('%Y%m%d_%H%M%S'))
    if not SaveResourceFile(GetCurrentResourceName(), file, table.concat(lines, '\n') .. '\n', -1) then
        return say(src, L('Could not write ', 'Não deu para gravar ') .. file .. '.', 'error')
    end
    say(src, (L('%d car(s) exported to d11_ptrunk/%s%s.', '%d carro(s) exportado(s) em d11_ptrunk/%s%s.')):format(#list, file,
        unnamed > 0 and (L(' (%d by hash: pass their names to the command)', ' (%d pelo hash: passe o nome no comando)')):format(unnamed) or ''), 'success')
end, false)

CreateThread(function()
    Wait(1000)   -- a tabela nasce no Whip.register
    local ok, rows = pcall(MySQL.query.await, 'SELECT model_hash, kind, data FROM d11_ptrunk_profiles')
    for _, r in ipairs(ok and rows or {}) do
        local data = KINDS[r.kind] and json.decode(r.data or '')
        if type(data) == 'table' then profiles[r.kind][math.tointeger(r.model_hash)] = data end
    end
end)

Whip.register(function()
    Whip.core:EnsureTable('d11_ptrunk_profiles', [[
        CREATE TABLE IF NOT EXISTS `d11_ptrunk_profiles` (
            `model_hash` INT NOT NULL,
            `kind` VARCHAR(8) NOT NULL,
            `data` TEXT NOT NULL,
            `updated_by` INT UNSIGNED NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`model_hash`, `kind`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    W:SecureCallback('d11_ptrunk:profiles', { rateLimit = 2000, burst = 2, whileDead = true }, function()
        return profiles
    end)
    W:SecureCallback('d11_ptrunk:canCalibrate', { rateLimit = 500, burst = 4, whileDead = true }, function(src)
        return canCalibrate(src)
    end)
    W:SecureEvent('d11_ptrunk:server:saveProfiles', { rateLimit = 1000, burst = 2, params = {
        { 'data', 'any' },
    } }, function(src, player, data)
        if type(data) ~= 'table' then return false end
        return onSaveProfiles(src, player, data)
    end)
    Whip.core:EnsureTable('d11_ptrunk_pose', [[
        CREATE TABLE IF NOT EXISTS `d11_ptrunk_pose` (
            `vehicle_id` INT UNSIGNED NOT NULL,
            `pose_key` VARCHAR(64) NOT NULL,
            `item` VARCHAR(64) NOT NULL,
            `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
            `yaw` FLOAT NOT NULL, `pitch` FLOAT NOT NULL, `roll` FLOAT NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`vehicle_id`, `pose_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    local net = { 'net', 'id', 1, 65535 }
    local vid = { 'vehicleId', 'id', 1 }
    W:SecureCallback('d11_ptrunk:open', { rateLimit = 1000, burst = 2, params = { net, vid } }, onOpen)
    W:SecureCallback('d11_ptrunk:scene', { rateLimit = 1000, burst = 3, params = { net } }, onScene)
    W:SecureCallback('d11_ptrunk:groundNear', { rateLimit = 700, burst = 3, params = { vid } }, onGroundNear)
    W:SecureCallback('d11_ptrunk:groundAround', { rateLimit = 700, burst = 3 }, onGroundAround)
    W:SecureEvent('d11_ptrunk:server:groundPose', { rateLimit = 50, burst = 20, params = {
        { 'groundId', 'id', 1 }, { 'x', 'number', -10000, 10000 }, { 'y', 'number', -10000, 10000 },
        { 'z', 'number', -1000, 2000 }, { 'heading', 'number', -3600, 3600 },
        { 'rx', 'number', -360, 360 }, { 'ry', 'number', -360, 360 },
    } }, onGroundPose)
    W:SecureEvent('d11_ptrunk:server:groundTake', { rateLimit = 300, burst = 3, params = {
        { 'groundId', 'id', 1 }, { 'to', 'string', 64 }, { 'slot', 'int', 0, 500, 0 },
    } }, onGroundTake)
    W:SecureEvent('d11_ptrunk:server:fromGround', { rateLimit = 300, burst = 3, params = {
        vid, { 'groundId', 'id', 1 },
    } }, onFromGround)
    local xyz = { { 'x', 'number', -10000, 10000 }, { 'y', 'number', -10000, 10000 }, { 'z', 'number', -1000, 2000 },
        { 'heading', 'number', -360, 360 } }
    W:SecureEvent('d11_ptrunk:server:toGround', { rateLimit = 300, burst = 3, params = {
        vid, { 'from', 'enum', { 'trunk', 'player', 'accessory' } }, { 'slot', 'id', 1, 500 },
        xyz[1], xyz[2], xyz[3], xyz[4],
    } }, onToGround)
    W:SecureEvent('d11_ptrunk:server:panelToGround', { rateLimit = 300, burst = 3, params = {
        vid, { 'panelId', 'string', 80 }, { 'slot', 'id', 1, 500 },
        xyz[1], xyz[2], xyz[3], xyz[4],
    } }, onPanelToGround)
    W:SecureEvent('d11_ptrunk:server:close', { rateLimit = 250, burst = 3, whileDead = true, params = { vid } }, onClose)
    W:SecureEvent('d11_ptrunk:server:pose', { rateLimit = 100, burst = 8, params = {
        vid, { 'key', 'string', 64 },
        { 'x', 'number', -3.0, 3.0 }, { 'y', 'number', -8.0, 8.0 }, { 'z', 'number', -0.3, 1.5 },
        { 'yaw', 'number', -360.0, 360.0 }, { 'pitch', 'number', -360.0, 360.0 }, { 'roll', 'number', -360.0, 360.0 },
    } }, onPose)
end)

-- ------------------------------------------------------------------ /ptrunkpreflight (admin ou console)
-- Confere a instalacao: resources, convars, os patches do whip_core (docs/patches, lidos do arquivo), as tabelas e os
-- perfis. Problema = algo nao funciona; aviso = uma parte fica sem (o resto funciona).
local PATCHES = {
    { 'trunk-opener', 'client/vehicle_prompts.lua', 'whip_trunk_opener', true },
    { 'ground-physics (client)', 'client/ground.lua', 'HoldGroundProp', true },
    { 'ground-physics (server)', 'server/ground.lua', 'MoveGroundItem', true },
    { 'item-prop-resolver', 'client/inventory.lua', 'whip_item_prop_resolver', false },
    { 'item-prop-amount', 'client/inventory.lua', 'ItemPropModel(itemKey, amount)', false },
    { 'store-panel', 'server/panels.lua', 'openStorePanel', false },
}

RegisterCommand('ptrunkpreflight', function(src)
    if src ~= 0 and not admin(src) then return end
    CreateThread(function()
        local issues, warns, oks = {}, {}, {}
        local function check(cond, okText, failText, isIssue)
            if cond then oks[#oks + 1] = okText
            elseif isIssue then issues[#issues + 1] = failText
            else warns[#warns + 1] = failText end
        end
        for _, res in ipairs({ { 'whip_core', true }, { 'oxmysql', true }, { 'd11_inventory', true }, { 'd11_bags', false } }) do
            check(GetResourceState(res[1]) == 'started', res[1] .. L(' started', ' iniciado'), res[1] .. L(' is not started', ' não está iniciado'), res[2])
        end
        check(GetConvar('whip_trunk_opener', '') == 'd11_ptrunk', 'setr whip_trunk_opener d11_ptrunk',
            L('missing setr whip_trunk_opener d11_ptrunk in server.cfg ("View trunk" opens WHIP\'s own)',
            'falta setr whip_trunk_opener d11_ptrunk no server.cfg (o "Ver porta-malas" abre o do WHIP)'), true)
        check(GetConvar('whip_item_prop_resolver', '') == 'd11_ptrunk', 'setr whip_item_prop_resolver d11_ptrunk',
            L('missing setr whip_item_prop_resolver d11_ptrunk (ground and hand use the WHIP catalogue model)',
            'falta setr whip_item_prop_resolver d11_ptrunk (chão e mão com o modelo do catálogo do WHIP)'), false)
        for _, p in ipairs(PATCHES) do
            local src2 = LoadResourceFile('whip_core', p[2]) or ''
            check(src2:find(p[3], 1, true) ~= nil, 'patch ' .. p[1],
                (L('patch %s missing in whip_core/%s (whip_core-patches/whip_core-%s-d11.patch)', 'patch %s ausente em whip_core/%s (docs/patches/whip_core-%s-d11.patch)')):format(p[1], p[2], p[1]:match('^%S+')), p[4])
        end
        for _, t in ipairs({ 'd11_ptrunk_pose', 'd11_ptrunk_profiles' }) do
            local ok = pcall(MySQL.scalar.await, ('SELECT COUNT(*) FROM `%s`'):format(t))
            check(ok, L('table ', 'tabela ') .. t, L('table ', 'tabela ') .. t .. L(' does not exist or the database did not answer', ' não existe ou o banco não respondeu'), true)
        end
        local n = 0
        for _ in pairs(profiles.spawn) do n = n + 1 end
        oks[#oks + 1] = (L('%d area profile(s) in the database (data/profiles apply under them)', '%d perfil(is) de área no banco (os do data/profiles valem por baixo)')):format(n)
        print((L('[d11_ptrunk] /ptrunkpreflight: %d problem(s), %d warning(s)', '[d11_ptrunk] /ptrunkpreflight: %d problema(s), %d aviso(s)')):format(#issues, #warns))
        for _, t in ipairs(issues) do print(L('  PROBLEM  ', '  PROBLEMA ') .. t) end
        for _, t in ipairs(warns) do print(L('  warning  ', '  aviso    ') .. t) end
        for _, t in ipairs(oks) do print('  ok       ' .. t) end
        if src ~= 0 then
            say(src, #issues > 0 and (L('Preflight: %d problem(s). See the server console.', 'Preflight: %d problema(s). Veja o console do servidor.')):format(#issues)
                or #warns > 0 and (L('Preflight ok with %d warning(s). See the server console.', 'Preflight ok com %d aviso(s). Veja o console do servidor.')):format(#warns)
                or 'Preflight ok.', #issues > 0 and 'error' or 'success')
        end
    end)
end, false)
