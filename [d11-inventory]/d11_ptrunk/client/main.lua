-- d11_ptrunk (cliente): o modo fisico. "Ver porta-malas" (patch whip_trunk_opener) chama OpenVehicleTrunk; o
-- servidor abre o store nativo do porta-malas e, se ninguem mais esta no modo fisico deste carro, a camera vai para
-- tras do carro com a luz e os itens como objetos (client/props.lua), que o jogador mexe com o mouse e o teclado
-- (client/edit.lua) e que a fisica da D12 assenta (client/physics.lua). A tela e o inventario D11 (d11_inventory) em
-- modo porta-malas: ele pergunta 'mode', manda o conteudo do porta-malas ('items'), o mouse e as teclas, e avisa
-- quando fecha ('closed').
-- Porte do fluxo de PT.OpenPhysicalTrunk / closePhysicalTrunk do velocity-physicaltrunk (D12).
local W = exports.whip_core

local mode = nil      -- { vehicle, vehicleId, net, pending, active, scene, seenOpen, openedAt, nextItems, syncing }
local ambient = nil   -- { vehicle, sig, scene, nextRefresh }: porta-malas aberto de outro carro, so para ver

local function clearAmbient()
    if not ambient then return end
    PT.ClearScene(ambient.scene)
    ambient = nil
end

-- ------------------------------------------------------------------ objetos do modo
--- Acerta os objetos com o conteudo (um por vez: montar um objeto espera o modelo carregar). Um modelo que nao
--- carregou a tempo (2 s) e tentado de novo, ate 10 vezes: antes o objeto so aparecia quando a lista mudava.
local RETRY_MS, RETRY_MAX = 500, 10

local function syncMode(items)
    local m = mode
    if not m or not m.active then return false end
    m.nextItems = items
    m.lastItems = items
    m.retries = 0
    if m.syncing then return true end
    m.syncing = true
    CreateThread(function()
        while m.nextItems and mode == m do
            local list = m.nextItems
            m.nextItems = nil
            local toSave, missing = PT.SyncScene(m.scene, list)
            for _, rec in ipairs(toSave) do PT.SavePose(rec) end
            if missing > 0 and not m.nextItems and mode == m and m.retries < RETRY_MAX then
                m.retries = m.retries + 1
                Wait(RETRY_MS)
                m.nextItems = m.nextItems or list
            end
        end
        m.syncing = false
        if not m.ready and mode == m then
            m.ready = true
            if ambient and ambient.vehicle == m.vehicle then clearAmbient() end
        end
        if mode ~= m then PT.ClearScene(m.scene) end
    end)
end

-- ------------------------------------------------------------------ sair
local function exitMode(closeInventory)
    local m = mode
    if not m then return end
    mode = nil
    if m.active then
        -- A fisica grava as poses pendentes antes de a edicao soltar a cena.
        PT.PhysicsEnd()
        PT.EditEnd()
        PT.DestroyTrunkCamera(false)
    end
    if not m.syncing then PT.ClearScene(m.scene) end
    if closeInventory and W:IsInventoryOpen() then W:CloseInventory() end
    TriggerServerEvent('d11_ptrunk:server:close', m.vehicleId)
end

-- ------------------------------------------------------------------ entrar
-- Com o porta-malas aberto o personagem pode andar (pedido de 2026-11-16, "por enquanto"); ataque, mira, pulo, entrar
-- em carro e afins continuam travados. Com um objeto selecionado, WASD e do objeto: o andar trava enquanto isso.
local BLOCKED = { 22, 23, 24, 25, 26, 36, 37, 38, 44, 45, 73, 85, 86, 140, 141, 142, 257, 263, 264 }
local WALK = { 21, 30, 31, 32, 33, 34, 35 }

local function modeLoop()
    while mode and mode.active do
        local m = mode
        local veh = m.vehicle
        -- O carro sumiu ou o jogador saiu de perto (empurrado, carro andou): fecha tudo.
        if not DoesEntityExist(veh) or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(veh)) > 8.0 then
            exitMode(true)
            break
        end
        -- O inventario do WHIP fechou (ESC, F2, o servidor fechou o store): sai da camera.
        if W:IsInventoryOpen() then
            m.seenOpen = true
        elseif m.seenOpen or GetGameTimer() - m.openedAt > 3000 then
            exitMode(false)
            break
        end
        for _, c in ipairs(BLOCKED) do DisableControlAction(0, c, true) end
        if PT.EditSelecting() then
            for _, c in ipairs(WALK) do DisableControlAction(0, c, true) end
        end
        if PT.EditLightOn() then PT.DrawTrunkLight(veh) end
        PT.OrbitTick()
        PT.EditTick()
        -- Fisica da D12: parada enquanto o jogador inspeciona um item (como no loop do ptrunk).
        if not PT.EditInspecting() then PT.StepVisualPropPhysics(false) end
        Wait(0)
    end
end

local function enter(veh, net, vehicleId)
    mode = { vehicle = veh, net = net, vehicleId = vehicleId, pending = true, openedAt = GetGameTimer() }
    local r = W:Callback('d11_ptrunk:open', net, vehicleId)
    local m = mode
    if not m or m.vehicle ~= veh then return end
    if type(r) ~= 'table' or not r.ok then
        mode = nil
        if type(r) == 'table' and r.reason then W:Notify(r.reason, 'error') end
        return
    end
    if not r.physical then
        -- Outro jogador esta no modo fisico deste carro: o servidor abriu o porta-malas do jeito normal.
        mode = nil
        W:Notify(Config.Text.busy, 'info')
        return
    end
    m.pending = false
    m.active = true
    m.openedAt = GetGameTimer()
    m.scene = PT.NewScene(veh, true)
    PT.PhysicsBegin(m.scene)
    PT.CreateOrbitCamera(veh, m.scene.area)
    PT.EditBegin(m.scene, vehicleId, PT.AccessData(veh).access == 'front')
    syncMode(r.items or {})
    modeLoop()
end

--- Chamado pelo prompt "Ver porta-malas" do WHIP (patch whip_trunk_opener). true = este resource cuida.
--- Sem area calibrada do modelo (ou com o porta-malas fisico desligado), devolve false e o WHIP abre o porta-malas
--- do jeito dele.
local function openVehicleTrunk(veh)
    if not Config.PhysicalTrunk then return false end
    if mode then return true end
    if not veh or veh == 0 or not DoesEntityExist(veh) or not NetworkGetEntityIsNetworked(veh) then return false end
    if not PT.HasFullProfile(veh) then return false end
    local net = VehToNet(veh)
    CreateThread(function()
        local vehicleId, why = W:GetVehicleId(veh), nil
        if not vehicleId then vehicleId, why = W:ResolveVehicle(veh) end
        if not vehicleId then
            W:Notify(why or Config.Text.notFound, 'error')
            return
        end
        enter(veh, net, vehicleId)
    end)
    return true
end

--- Algum modo fisico aberto ou abrindo (a calibracao nao abre junto).
function PT.ModeActive() return mode ~= nil end

--- O modo aberto agora (para o diagnostico /ptrunkprops), ou nil.
function PT.ModeState() return mode end

exports('OpenVehicleTrunk', openVehicleTrunk)
exports('HasPhysicalTrunkProfile', function(veh) return PT.HasFullProfile(veh) end)
exports('IsPhysicalTrunkOpen', function() return mode ~= nil and mode.active == true end)

-- ------------------------------------------------------------------ o renderer (d11_inventory, na pagina do WHIP)
-- { store = 'vehicle:<id>:trunk' }: o porta-malas aberto na tela e o do modo fisico (ou o que esta abrindo)?
-- Junto, o estado dos botoes da barra (luz, grade, destaques).
RegisterNUICallback('mode', function(data, cb)
    local store = type(data) == 'table' and data.store
    local on = mode ~= nil and store == ('vehicle:%s:trunk'):format(math.tointeger(mode.vehicleId) or mode.vehicleId)
    local out = PT.EditState()
    out.active = on
    cb(out)
end)

-- O conteudo do porta-malas como o renderer ve: { items = { { slot, item, uid } } }, na ordem dos slots.
-- { ok }: false quando o modo ainda nao esta ativo (o renderer manda de novo).
RegisterNUICallback('items', function(data, cb)
    if not mode or not mode.active or type(data) ~= 'table' or type(data.items) ~= 'table' then return cb({ ok = false }) end
    local items = {}
    for _, it in ipairs(data.items) do
        if type(it) == 'table' and type(it.item) == 'string' and tonumber(it.slot) then
            items[#items + 1] = { slot = tonumber(it.slot), item = it.item, uid = it.uid, amount = tonumber(it.amount) }
        end
    end
    table.sort(items, function(a, b) return a.slot < b.slot end)
    cb({ ok = syncMode(items) })
end)

-- /ptrunkrepack (admin): o servidor apagou as poses deste carro; os objetos voltam para a grade automatica.
RegisterNetEvent('d11_ptrunk:client:repack', function(vehicleId)
    local m = mode
    if not m or not m.active or m.vehicleId ~= vehicleId or not m.lastItems then return end
    local items = {}
    for i, it in ipairs(m.lastItems) do items[i] = { slot = it.slot, item = it.item, uid = it.uid, key = it.key } end
    PT.ClearScene(m.scene)
    PT.PhysicsBegin(m.scene)
    syncMode(items)
end)

RegisterNUICallback('closed', function(_, cb)
    cb({})
    if mode and mode.active then exitMode(false) end
end)

-- ------------------------------------------------------------------ porta-malas aberto de outros carros
local function trunkDoor(veh)
    return PT.AccessData(veh).access == 'front' and 4 or 5
end

--- O carro do modo fisico sai da cena "de fora" so quando a cena do modo ja esta montada.
local function ownedByMode(veh) return mode ~= nil and mode.ready == true and mode.vehicle == veh end

local function openTrunkNearby()
    local me = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if not ownedByMode(veh) then
            local d = #(GetEntityCoords(veh) - me)
            if d < Config.Ambient.range and (not bestDist or d < bestDist) and NetworkGetEntityIsNetworked(veh)
                and PT.HasFullProfile(veh) and GetVehicleDoorAngleRatio(veh, trunkDoor(veh)) > 0.1 then
                best, bestDist = veh, d
            end
        end
    end
    return best
end

-- Monta (ou atualiza) a cena de um carro com os itens do servidor. Uma de cada vez: a thread de fora e o
-- BeforeTrunkLid podem pedir juntas.
local building = false
local function refreshAmbient(veh)
    if building then return end
    building = true
    local items = W:Callback('d11_ptrunk:scene', VehToNet(veh))
    if DoesEntityExist(veh) then
        if ambient and ambient.vehicle ~= veh then clearAmbient() end
        if type(items) == 'table' then
            local sig = PT.Signature(items)
            if not ambient or ambient.sig ~= sig then
                local keep = ambient and ambient.prepUntil
                clearAmbient()
                ambient = { vehicle = veh, sig = sig, scene = PT.NewScene(veh, false), prepUntil = keep }
                PT.SyncScene(ambient.scene, items)
            end
        elseif not ambient then
            ambient = { vehicle = veh, sig = '', scene = PT.NewScene(veh, false) }
        end
        if ambient then ambient.nextRefresh = GetGameTimer() + Config.Ambient.refreshMs end
    end
    building = false
end

--- Chamado pela opcao "Abrir porta-malas" do WHIP (patch whip_trunk_opener) antes de a tampa abrir: os objetos ja
--- estao no lugar quando ela sobe, em vez de aparecerem com ela aberta (pedido de 2026-11-16). Devolve quanto o WHIP
--- espera (ms); 0 = abre na hora.
local function beforeTrunkLid(veh)
    if not Config.PhysicalTrunk then return 0 end
    if not veh or veh == 0 or not DoesEntityExist(veh) or not NetworkGetEntityIsNetworked(veh) then return 0 end
    if not PT.HasFullProfile(veh) or ownedByMode(veh) then return 0 end
    CreateThread(function()
        if ambient and ambient.vehicle ~= veh then clearAmbient() end
        if ambient then ambient.nextRefresh = 0 end
        refreshAmbient(veh)
        if ambient and ambient.vehicle == veh then ambient.prepUntil = GetGameTimer() + Config.LidDelayMs + 3000 end
    end)
    return Config.LidDelayMs
end

exports('BeforeTrunkLid', beforeTrunkLid)

CreateThread(function()
    if not Config.PhysicalTrunk then return end
    while true do
        local now = GetGameTimer()
        local veh = openTrunkNearby()
        -- Cena preparada pelo BeforeTrunkLid: fica enquanto a tampa sobe, mesmo fechada.
        if not veh and ambient and ambient.prepUntil and now < ambient.prepUntil and DoesEntityExist(ambient.vehicle) then
            veh = ambient.vehicle
        end
        if not veh then
            if not building then clearAmbient() end
            Wait(500)
        else
            if not building and (not ambient or ambient.vehicle ~= veh or now >= (ambient.nextRefresh or 0)) then
                refreshAmbient(veh)
            end
            local door = trunkDoor(veh)
            local untilAt = GetGameTimer() + 500
            repeat
                -- Luz so com a tampa aberta, e nao em dobro com a do modo fisico.
                if GetVehicleDoorAngleRatio(veh, door) > 0.1 and not (mode and mode.active and mode.vehicle == veh) then
                    PT.DrawTrunkLight(veh)
                end
                Wait(0)
            until GetGameTimer() >= untilAt or not DoesEntityExist(veh) or ownedByMode(veh)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearAmbient()
    if mode then
        if mode.active then
            -- A fisica grava as poses pendentes antes de a edicao soltar a cena.
            PT.PhysicsEnd()
            PT.EditEnd()
            PT.DestroyTrunkCamera(true)
        end
        PT.ClearScene(mode.scene)
        mode = nil
    end
end)
