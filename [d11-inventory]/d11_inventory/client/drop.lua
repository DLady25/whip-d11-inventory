-- Largar no chao arrastando para fora (ox_inventory D12 da VPS: modules/grounddrop + modules/vehiclethrow).
-- O item vai na mao durante a animacao e, no instante em que a mao solta (RELEASE do clip), cai com fisica, como o
-- arremesso do WHIP: o mesmo caminho do servidor (whip_core:server:throwLaunched / throwSettled), entao a pilha
-- existe desde que sai da mao e fica onde o objeto parar, deitado como caiu.
--   a pe ......... se abaixa e pousa (pickup_object / putdown_low); o item escorrega um pouco a frente
--   no veiculo ... baixa o vidro e joga pela janela do lado do assento (drive-by de granada, throw_90l/90r;
--                  moto: veh@drivebybike); o item sai rente a porta, para fora, com o embalo do carro
--                  (em movimento tambem: cai e rola pela pista, ate MAX_LAUNCH)
-- So o que esta com voce (bolsos e faixa). Sem animacao possivel o renderer larga do jeito antigo (move 'ground').

local FOOT = { dict = 'pickup_object', clip = 'putdown_low', release = 0.35, flags = 0, bone = 57005 }
local SEAT_DICT = {
    [-1] = 'veh@drivebystd_ds_grenades', [0] = 'veh@drivebystd_ps_grenades',
    [1] = 'veh@drivebystd_rds_grenades', [2] = 'veh@drivebystd_rps_grenades',
}
local UPPER = 16 + 32 + 1048576   -- so o tronco, tarefa secundaria, esconde a arma (como o D12)
local MAX_LAUNCH = 28.0           -- m/s: o item sai com o embalo do carro, no maximo isso (D12)
local LOAD_MS, MAX_MS = 1000, 1600
local DEFAULT_PROP = 'prop_cs_cardbox_01'   -- whip_core Config.DefaultGroundProp
local ON_PERSON = { player = true, accessory = true }
-- Parado: velocidade abaixo de STILL_SPEED por STILL_MS (tempo para o servidor ver o objeto onde ele parou; o
-- whip_core recusa um pouso a mais de 3 m de onde o servidor o ve) e com chao logo embaixo (GROUNDED, m).
-- Parado sem chao por FROZEN_MS = congelado no ar (sem colisao do mapa em volta): vai ao chao calculado.
local STILL_SPEED, STILL_MS, FROZEN_MS, GROUNDED = 0.04, 600, 2000, 1.0
local ANSWER_MS, TRACK_MS = 5000, 10000

local function yes(value) return value == true or value == 1 end
local busy = false

local function seatOf(ped, vehicle)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end
end

--- O clipe do jogar pela janela do assento, ou nil (sem assento conhecido / sem o dicionario).
local function vehicleAnim(ped, vehicle)
    local seat = seatOf(ped, vehicle)
    if seat == nil then return nil end
    local right = seat >= 0 and seat % 2 == 0
    local dict = SEAT_DICT[seat] or SEAT_DICT[right and 2 or 1]
    if GetVehicleClass(vehicle) == 8 then
        dict = seat == -1 and 'veh@drivebybike@sport@front@grenade' or 'veh@drivebybike@sport@rear@grenade'
    end
    if not yes(DoesAnimDictExist(dict)) then return nil end
    return { dict = dict, clip = right and 'throw_90r' or 'throw_90l', release = 0.35, flags = UPPER, seat = seat,
             right = right, bone = right and 57005 or 18905 }
end

--- O modelo do item no chao (o mesmo que o servidor confere no throwLaunched).
local function itemModel(item)
    local ok, def = pcall(function() return exports.whip_core:GetItemDef(item) end)
    local want = ok and type(def) == 'table' and def.prop or nil
    if want and yes(IsModelInCdimage(GetHashKey(want))) then return want end
    return DEFAULT_PROP
end

local function load(dict, model)
    RequestAnimDict(dict)
    RequestModel(model)
    local deadline = GetGameTimer() + LOAD_MS
    while (not HasAnimDictLoaded(dict) or not HasModelLoaded(model)) and GetGameTimer() < deadline do Wait(0) end
    return HasAnimDictLoaded(dict) and HasModelLoaded(model)
end

--- Onde o item sai da mao e com que velocidade (D12 grounddrop.perform).
local function launch(ped, obj, anim, vehicle)
    local pos = GetEntityCoords(obj)
    local motion = GetEntityVelocity(vehicle ~= 0 and vehicle or ped)
    if vehicle ~= 0 then
        local mn, mx = GetModelDimensions(GetEntityModel(vehicle))
        local hand = GetOffsetFromEntityGivenWorldCoords(vehicle, pos.x, pos.y, pos.z)
        local x = anim.right and math.max(hand.x, mx.x + 0.15) or math.min(hand.x, mn.x - 0.15)
        pos = GetOffsetFromEntityInWorldCoords(vehicle, x, hand.y, hand.z)
        local out = GetOffsetFromEntityInWorldCoords(vehicle, anim.right and 1.0 or -1.0, 0.0, 0.0) - GetEntityCoords(vehicle)
        local v = vector3(motion.x + out.x * 1.1, motion.y + out.y * 1.1, motion.z - 0.2)
        if #v > MAX_LAUNCH then v = v * (MAX_LAUNCH / #v) end
        return pos, v
    end
    local fwd = GetEntityForwardVector(ped)
    return pos, vector3(motion.x * 0.35 + fwd.x * 0.45, motion.y * 0.35 + fwd.y * 0.45, motion.z * 0.15 - 0.15)
end

--- A pilha voando: avisa o servidor e conta onde parou (o TrackThrow do whip_core, sem derrubar ninguem).
local pending = {}
RegisterNetEvent('whip_core:client:throwAccepted', function(netId, groundId)
    if pending[netId] then pending[netId].groundId = groundId end
end)
RegisterNetEvent('whip_core:client:throwRefused', function(netId)
    if pending[netId] then pending[netId].groundId = false end
end)

--- Esta pousado de verdade: colisao do mapa carregada em volta e o chao logo embaixo.
local function grounded(obj)
    return yes(HasCollisionLoadedAroundEntity(obj)) and GetEntityHeightAboveGround(obj) < GROUNDED
end

--- O z do chao embaixo de c (nil: sem chao achado). Pede a colisao do lugar antes.
local function groundZ(c)
    RequestCollisionAtCoord(c.x, c.y, c.z)
    for _, up in ipairs({ 2.0, 25.0 }) do
        local found, z = GetGroundZFor_3dCoord(c.x, c.y, c.z + up, false)
        if yes(found) then return z end
    end
end

local function track(obj, data, visual)
    local deadline = GetGameTimer() + 1000
    while not yes(NetworkGetEntityIsNetworked(obj)) and GetGameTimer() < deadline do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(obj)
    SetNetworkIdCanMigrate(netId, false)
    local t = {}
    pending[netId] = t
    TriggerServerEvent('whip_core:server:throwStarted', netId)
    TriggerServerEvent('whip_core:server:throwLaunched', data.container, data.slot, data.amount, netId)
    local started, stillSince = GetGameTimer(), nil
    while true do
        Wait(0)
        local now = GetGameTimer()
        -- recusado ou sem resposta: o item nunca saiu do bolso, o objeto tambem nao
        if t.groundId == false or (t.groundId == nil and now - started > ANSWER_MS) then
            if DoesEntityExist(obj) then DeleteEntity(obj) end
            break
        end
        if not DoesEntityExist(obj) then break end   -- pego no ar
        if #GetEntityVelocity(obj) < STILL_SPEED then stillSince = stillSince or now else stillSince = nil end
        local stillMs = stillSince and now - stillSince or 0
        local landed = stillMs >= STILL_MS and grounded(obj)
        -- parado no ar (congelado longe do foco, em alta velocidade) ou demorou demais: vai ao chao, em pe
        local stuck = stillMs >= FROZEN_MS or now - started > TRACK_MS
        if t.groundId and (landed or stuck) then
            -- com corpo de caixa (visual) a pose e da caixa, nao do item: vai em pe, no chao
            local settled = landed and not visual
            local c, rot = GetEntityCoords(obj), GetEntityRotation(obj, 2)
            if not settled then
                local z = groundZ(c)
                if z then c = vector3(c.x, c.y, z) end
            end
            TriggerServerEvent('whip_core:server:throwSettled', t.groundId, c.x, c.y, c.z, rot.z % 360.0, rot.x, rot.y, settled)
            SetTimeout(5000, function() if DoesEntityExist(obj) then DeleteEntity(obj) end end)
            break
        end
    end
    pending[netId] = nil
    if visual then
        -- o visual some quando a pilha do whip_core aparece (o servidor apaga o corpo) ou em 5 s
        local untilAt = GetGameTimer() + 5000
        while DoesEntityExist(obj) and GetGameTimer() < untilAt do Wait(100) end
        if DoesEntityExist(visual) then DeleteEntity(visual) end
    end
end

--- Solta com fisica: o objeto no ponto, girado como estava, com a velocidade dada.
local function fly(obj, pos, rot, vel)
    SetEntityCoordsNoOffset(obj, pos.x, pos.y, pos.z, false, false, false)
    SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true)
    SetEntityDynamic(obj, true)
    SetEntityCollision(obj, true, true)
    SetEntityHasGravity(obj, true)
    ActivatePhysics(obj)
    SetEntityVelocity(obj, vel.x, vel.y, vel.z)
    -- a colisao do mapa segue o objeto: deixado para tras em alta velocidade, ele nao congela no ar
    SetEntityLoadCollisionFlag(obj, true, 1)
end

--- Modelos sem fisica (props de anexo como as bolsas, props personalizados): um corpo invisivel de caixa
--- (whip_core Config.DefaultGroundProp, que o servidor aceita para qualquer item) cai com fisica e o modelo do
--- item vai preso nele, so local. Devolve o corpo e o visual, ou nil (sem caixa: segue com o objeto parado).
local function proxyFor(obj, model, pos, rot, vel)
    local box = GetHashKey(DEFAULT_PROP)
    RequestModel(box)
    local deadline = GetGameTimer() + LOAD_MS
    while not HasModelLoaded(box) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(box) then return nil end
    local body = CreateObject(box, pos.x, pos.y, pos.z, true, true, false)
    SetModelAsNoLongerNeeded(box)
    if not body or body == 0 then return nil end
    SetEntityVisible(body, false, false)
    DeleteEntity(obj)
    RequestModel(model)
    deadline = GetGameTimer() + LOAD_MS
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
    local visual = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
    if visual and visual ~= 0 then
        SetEntityCollision(visual, false, false)
        AttachEntityToEntity(visual, body, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        SetModelAsNoLongerNeeded(model)
    end
    fly(body, pos, rot, vel)
    return body, visual
end

local function perform(ped, anim, model, data, vehicle)
    local c = GetEntityCoords(ped)
    local obj = CreateObject(model, c.x, c.y, c.z - 2.0, true, true, false)
    SetModelAsNoLongerNeeded(model)
    if not obj or obj == 0 then
        -- sem objeto: pousa nos pes, como o fallback do arremesso do whip_core
        TriggerServerEvent('whip_core:server:throwItemLanded', data.container, data.slot, data.amount,
            c.x, c.y, c.z - 0.5, GetEntityHeading(ped))
        return
    end
    SetEntityCollision(obj, false, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, anim.bone), 0.12, 0.0, -0.02, 0.0, 0.0, 0.0,
        true, true, false, true, 1, true)

    TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, -4.0, -1, anim.flags, 0.0, false, false, false)
    local deadline = GetGameTimer() + MAX_MS
    while GetGameTimer() < deadline do
        if yes(IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3))
            and GetEntityAnimCurrentTime(ped, anim.dict, anim.clip) >= anim.release then break end
        Wait(0)
    end

    -- a mao soltou: cai com fisica
    local pos, vel = launch(ped, obj, anim, vehicle)
    local rot = GetEntityRotation(obj, 2)
    DetachEntity(obj, true, true)
    fly(obj, pos, rot, vel)
    -- sem fisica (o modelo nao tem colisao): fica parado onde soltou, entao vai num corpo de caixa
    Wait(0)
    local visual
    if not yes(DoesEntityHavePhysics(obj)) then
        local body
        body, visual = proxyFor(obj, model, pos, rot, vel)
        if body then obj = body end
    end
    CreateThread(function() track(obj, data, visual) end)

    -- deixa o clipe terminar e libera
    deadline = GetGameTimer() + 1500
    while yes(IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3)) and GetGameTimer() < deadline do Wait(50) end
    RemoveAnimDict(anim.dict)
end

-- Responde { ok = false, reason } (recusado), { ok = true, physics = true } (este arquivo larga) ou { ok = true }
-- (o renderer larga do jeito antigo, sem animacao).
RegisterNUICallback('dropAnim', function(data, cb)
    data = type(data) == 'table' and data or {}
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local anim
    if vehicle ~= 0 then
        anim = vehicleAnim(ped, vehicle)
    else
        anim = FOOT
    end
    -- desligado (config.lua ou um bloqueio): nao larga; o motivo, se houver, aparece no inventario
    local allowed, why = D11Gestures.allowed('dropOut')
    if not allowed then return cb({ ok = false, reason = why }) end
    if vehicle ~= 0 and D11Inventory.DropInVehicle == false then return cb({ ok = false }) end
    local slot, amount = math.tointeger(tonumber(data.slot)), math.tointeger(tonumber(data.amount))
    -- sem animacao (D11Inventory.DropAnimated = false) o renderer larga na hora
    if D11Inventory.DropAnimated == false then return cb({ ok = true }) end
    -- sem animacao onde ela nao cabe (nadando, caindo, ragdoll, ja largando, fora dos bolsos): larga na hora
    if not anim or busy or not ON_PERSON[data.container] or not slot or not amount or amount < 1
        or type(data.item) ~= 'string' or yes(IsPedSwimming(ped)) or yes(IsPedFalling(ped))
        or yes(IsPedRagdoll(ped)) or yes(IsEntityDead(ped)) then
        return cb({ ok = true })
    end
    busy = true
    CreateThread(function()
        local model = GetHashKey(itemModel(data.item))
        if not load(anim.dict, model) then
            busy = false
            return cb({ ok = true })
        end
        cb({ ok = true, physics = true })
        if vehicle ~= 0 and anim.seat >= -1 and anim.seat <= 2 then RollDownWindow(vehicle, anim.seat + 1) end
        local ok, err = pcall(perform, ped, anim, model, { container = data.container, slot = slot, amount = amount }, vehicle)
        if not ok then print(('[d11_inventory] drop with physics failed: %s'):format(tostring(err))) end
        busy = false
    end)
end)
