-- d11_attachments (client): porte da inspecao de arma do d12-item-inspect (client/main.lua + client/weapon.lua)
-- sobre o whip_gunny. Entrada: "Acessórios" no menu da arma (server.lua) -> saca a arma se preciso, levanta ela
-- na pose de inspecao e projeta cada ponto de encaixe (bones WAP*) na tela com Acoplar / Remover.

-- Natives deste build devolvem 1/0 (0 e verdadeiro no Lua): tudo passa por yes().
local function yes(v) return v == true or v == 1 end

local T = Config.Text
local state = nil     -- sessao aberta
local acting = false

local function notify(msg, kind) exports.whip_core:Notify(msg, kind or 'info') end
local function call(name, ...) return Whip.core:Callback('d11_attachments:' .. name, ...) end
local function gunny() local ok, w = pcall(function() return exports.whip_gunny:GetDrawnWeapon() end) return ok and w or nil end

local function waitFor(pred, timeout)
    local deadline = GetGameTimer() + timeout
    while GetGameTimer() < deadline do
        if pred() then return true end
        Wait(50)
    end
    return pred()
end

local function itemLabel(item)
    local def = exports.whip_core:GetItemDef(item)
    local att = Catalog.attachments[item]
    return (def and def.name) or (att and att.label) or item
end

---------------------------------------------------------------------------
-- Pose congelada (sincronizada com os outros pelo state bag, como no D12)
---------------------------------------------------------------------------
local POSE_BAG = 'd11AttachPose'

local function publishPose(anim, phase)
    LocalPlayer.state:set(POSE_BAG, phase and { dict = anim.dict, anim = anim.anim, phase = phase } or nil, true)
end

local function ensureAnim(ped, session)
    local a = session.anim
    if yes(IsEntityPlayingAnim(ped, a.dict, a.anim, 3)) then
        if a.freezeAt and not session.frozen and GetEntityAnimCurrentTime(ped, a.dict, a.anim) >= a.freezeAt then
            SetEntityAnimCurrentTime(ped, a.dict, a.anim, a.freezeAt)
            SetEntityAnimSpeed(ped, a.dict, a.anim, 0.0)
            session.frozen = true
            publishPose(a, a.freezeAt)
        end
        return
    end
    session.frozen = false
    -- Sem esperar: o loop de frame chama de novo ate o dicionario carregar.
    if not yes(HasAnimDictLoaded(a.dict)) then RequestAnimDict(a.dict) return end
    TaskPlayAnim(ped, a.dict, a.anim, 8.0, -8.0, -1, a.flag, 0.0, false, false, false)
end

local function stopAnim(ped, session)
    local a = session.anim
    publishPose(a, nil)
    if yes(IsEntityPlayingAnim(ped, a.dict, a.anim, 3)) then StopAnimTask(ped, a.dict, a.anim, 1.0) end
    RemoveAnimDict(a.dict)
end

local remotePoses = {}
AddStateBagChangeHandler(POSE_BAG, nil, function(bagName, _, value)
    local player = GetPlayerFromStateBagName(bagName)
    if not player or player == 0 or player == PlayerId() then return end
    if type(value) == 'table' and value.dict and value.anim and value.phase then
        remotePoses[player] = value
    else
        local prev = remotePoses[player]
        remotePoses[player] = nil
        local ped = prev and GetPlayerPed(player)
        if ped and ped ~= 0 and yes(IsEntityPlayingAnim(ped, prev.dict, prev.anim, 3)) then
            SetEntityAnimSpeed(ped, prev.dict, prev.anim, 1.0)
        end
    end
end)

CreateThread(function()
    while true do
        if next(remotePoses) == nil then
            Wait(500)
        else
            for player, pose in pairs(remotePoses) do
                local ped = GetPlayerPed(player)
                if ped == 0 or not yes(DoesEntityExist(ped)) then
                    if not yes(NetworkIsPlayerActive(player)) then remotePoses[player] = nil end
                elseif yes(IsEntityPlayingAnim(ped, pose.dict, pose.anim, 3)) then
                    if math.abs(GetEntityAnimCurrentTime(ped, pose.dict, pose.anim) - pose.phase) > 0.02 then
                        SetEntityAnimCurrentTime(ped, pose.dict, pose.anim, pose.phase)
                    end
                    SetEntityAnimSpeed(ped, pose.dict, pose.anim, 0.0)
                end
            end
            Wait(100)
        end
    end
end)

---------------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------------
local function cameraLabel(mode) return T.cameraButton:format(mode == 'scripted' and T.cameraScripted or T.cameraFirst) end

local function startCamera(ped, mode)
    if mode == 'firstperson' then
        local previous = GetFollowPedCamViewMode()
        SetFollowPedCamViewMode(4)
        return { mode = mode, previous = previous }
    end
    -- Camera parada: mira um ponto fixo (onde a arma esta agora, ja na pose congelada), nao a entidade. Seguir a
    -- arma passava para a tela cada micro-movimento da mao (respiracao, idle) e os pontos tremiam.
    local o = Config.Camera.offset
    local pos = GetOffsetFromEntityInWorldCoords(ped, o.x, o.y, o.z)
    local obj = GetCurrentPedWeaponEntityIndex(ped, 0)
    local target = obj ~= 0 and GetEntityCoords(obj) or GetPedBoneCoords(ped, 28422, 0.0, 0.0, 0.0)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamFov(cam, Config.Camera.fov)
    PointCamAtCoord(cam, target.x, target.y, target.z)
    RenderScriptCams(true, true, Config.Camera.interp, true, true)
    return { mode = mode, cam = cam }
end

local function stopCamera(cam)
    if not cam then return end
    if cam.mode == 'firstperson' then
        SetFollowPedCamViewMode(cam.previous or 1)
    elseif cam.cam then
        RenderScriptCams(false, true, Config.Camera.interp, true, true)
        DestroyCam(cam.cam, false)
    end
end

---------------------------------------------------------------------------
-- Pontos e opcoes
---------------------------------------------------------------------------
local function buildHotspots(weaponItem)
    local cats = Catalog.weapons[weaponItem] or {}
    local list = {}
    for _, def in ipairs(Config.Slots) do
        if (def.category and cats[def.category]) or def.magazine then
            list[#list + 1] = { id = def.id, label = def.label, category = def.category, magazine = def.magazine,
                                bones = def.bones, offset = def.offset }
        end
    end
    return list
end

local function magazineOptions()
    local w = gunny()
    if not w then return {}, nil end
    local hint = { { kind = 'info', label = T.magazineHint, disabled = true } }
    if not w.magazine then
        if w.capacity then return hint, ('%d/%d'):format(w.ammo or 0, w.capacity) end
        return hint, T.noMagazine
    end
    return hint, ('%s %d/%d'):format(itemLabel(w.magazine), w.ammo or 0, w.capacity or 0), w.magazine
end

local function buildOptions(hs)
    if hs.magazine then return magazineOptions() end
    local data = state.data
    local options = {}
    local fitted = data.attachments[hs.category]
    if fitted then
        options[1] = { kind = 'detach', category = hs.category, icon = fitted, label = T.detach:format(itemLabel(fitted)) }
    end
    local seen = {}
    for _, c in ipairs(data.carried) do
        local comp, att = Catalog.component(data.weapon, c.name)
        if comp and att.category == hs.category and not seen[c.name] then
            seen[c.name] = true
            options[#options + 1] = {
                kind = 'attach', slot = c.slot, pocket = c.pocket, icon = c.name, label = T.attach:format(itemLabel(c.name)),
                hint = (c.amount or 1) > 1 and ('x%d'):format(c.amount) or nil,
                disabled = fitted ~= nil,
                disabledReason = fitted and T.attachBlocked:format(itemLabel(fitted)) or nil,
            }
        end
    end
    return options, fitted and itemLabel(fitted) or nil, fitted
end

local function sendHotspots()
    if not state then return end
    local list = {}
    for i, hs in ipairs(state.hotspots) do
        local options, current, icon = buildOptions(hs)
        hs.options = options
        list[i] = { i = i, id = hs.id, label = hs.label, current = current or T.empty, icon = icon, options = options }
    end
    SendNUIMessage({ action = 'hotspots', hotspots = list })
end

--- Card do canto esquerdo (como o info.lua do D12, so para arma): nome, descricao, serie, municao, pente, pecas.
local function sendInfo()
    if not state then return end
    local w = gunny()
    local data = state.data
    local def = exports.whip_core:GetItemDef(data.weapon) or {}
    local rows = {}
    if w and w.serial then rows[#rows + 1] = { label = T.serial, value = tostring(w.serial), mono = true } end
    if w and w.capacity then
        local pct = w.capacity > 0 and math.floor((w.ammo or 0) / w.capacity * 100) or 0
        rows[#rows + 1] = { label = T.ammo, value = ('%d/%d'):format(w.ammo or 0, w.capacity), bar = pct,
                            tone = (w.ammo or 0) == 0 and 'bad' or nil }
    end
    if w and w.magazine then rows[#rows + 1] = { label = T.magazine, value = itemLabel(w.magazine) } end
    local parts = {}
    for _, def2 in ipairs(Config.Slots) do
        local item = def2.category and data.attachments[def2.category]
        if item then parts[#parts + 1] = { label = def2.label, value = itemLabel(item), icon = item } end
    end
    SendNUIMessage({ action = 'info', card = {
        kind = T.kindWeapon, label = (w and w.label) or def.name or data.weapon, icon = data.weapon,
        description = def.description or def.desc, rows = rows, parts = parts, noParts = T.noParts, partsTitle = T.parts,
    } })
end

local function hotspotWorldPos(obj, hs)
    if hs.boneObj ~= obj then
        hs.boneObj, hs.boneIndex = obj, -1
        for _, bone in ipairs(hs.bones) do
            local idx = GetEntityBoneIndexByName(obj, bone)
            if idx and idx ~= -1 then hs.boneIndex = idx break end
        end
    end
    if hs.boneIndex ~= -1 then return GetWorldPositionOfEntityBone(obj, hs.boneIndex) end
    local o = hs.offset
    return GetOffsetFromEntityInWorldCoords(obj, o.x, o.y, o.z)
end

---------------------------------------------------------------------------
-- Abrir / fechar
---------------------------------------------------------------------------
local function close()
    local session = state
    if not session then return end
    state = nil
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    stopCamera(session.cam)
    stopAnim(PlayerPedId(), session)
    exports.whip_core:SetScreenOpen(false)
end

local function frameLoop(session)
    local nextCheck = 0
    while state == session do
        Wait(0)
        local ped = PlayerPedId()
        DisablePlayerFiring(ped, true)
        for _, c in ipairs({ 0, 22, 23, 24, 25, 37, 44, 45, 140, 141, 142 }) do DisableControlAction(0, c, true) end

        if yes(IsEntityDead(ped)) or yes(IsPedRagdoll(ped)) or yes(IsPedInAnyVehicle(ped, false)) then close() break end

        local obj = GetCurrentPedWeaponEntityIndex(ped, 0)
        local now = GetGameTimer()
        if now >= nextCheck then
            nextCheck = now + 250
            local w = gunny()
            if not w or w.slot ~= session.slot or w.pocket ~= session.pocket then close() break end
        end
        if obj == 0 then close() break end

        ensureAnim(ped, session)
        local points = {}
        for i, hs in ipairs(session.hotspots) do
            local pos = hotspotWorldPos(obj, hs)
            local visible, sx, sy = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
            points[i] = { i = i, x = sx, y = sy, v = yes(visible) }
        end
        SendNUIMessage({ action = 'frame', points = points })
    end
end

local function open(pocket, slot)
    if state or acting then return end
    local ped = PlayerPedId()
    if yes(IsEntityDead(ped)) or yes(IsPedRagdoll(ped)) then return end
    if yes(IsPedInAnyVehicle(ped, false)) then return notify(T.inVehicle, 'error') end

    local w = gunny()
    if not w or w.slot ~= slot or w.pocket ~= pocket then
        local ok = exports.whip_gunny:DrawWeapon(slot, pocket)
        if not ok or not waitFor(function()
            local d = gunny()
            return d and d.slot == slot and d.pocket == pocket and GetCurrentPedWeaponEntityIndex(PlayerPedId(), 0) ~= 0
        end, 4000) then
            return notify(T.drawFail, 'error')
        end
        w = gunny()
    end

    local ok, data = call('data', { sub = pocket, slot = slot })
    if not ok then return notify(type(data) == 'string' and data or T.failed, 'error') end

    if yes(exports.whip_core:IsInventoryOpen()) then exports.whip_core:CloseInventory() end
    waitFor(function() return not yes(IsNuiFocused()) end, 1000)

    local hash = GetSelectedPedWeapon(ped)
    local group = GetWeapontypeGroup(hash)
    local base = Config.Anim.byGroup[group] or Config.Anim.default
    local session = {
        slot = slot, pocket = pocket, data = data,
        anim = { dict = base.dict, anim = base.anim, flag = Config.Anim.flag, freezeAt = Config.Anim.freezeAt },
        hotspots = buildHotspots(data.weapon),
        cameraMode = Config.Camera.byGroup[group] or Config.Camera.mode,
        frozen = false,
    }
    state = session
    exports.whip_core:SetScreenOpen(true)
    -- A camera so entra com a pose ja congelada: o ponto que ela mira e onde a arma fica parada.
    waitFor(function() ensureAnim(ped, session) return session.frozen end, 2000)
    session.cam = startCamera(ped, session.cameraMode)

    SendNUIMessage({ action = 'open', title = T.title, label = w and w.label or itemLabel(data.weapon), hint = T.hint,
                     camera = cameraLabel(session.cameraMode), iconBase = Config.IconBase })
    sendHotspots()
    sendInfo()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    CreateThread(function() frameLoop(session) end)
end

RegisterNetEvent('d11_attachments:open', function(pocket, slot)
    if GetInvokingResource() then return end
    if type(slot) ~= 'number' then return end
    CreateThread(function() open(pocket or 'player', slot) end)
end)

---------------------------------------------------------------------------
-- Acoes
---------------------------------------------------------------------------
local function perform(h, o)
    local session = state
    if not session or acting then return end
    local hs = session.hotspots[h]
    local option = hs and hs.options and hs.options[o]
    if not option or option.disabled then return end

    acting = true
    SendNUIMessage({ action = 'busy', value = true })
    local weapon = { sub = session.pocket, slot = session.slot }
    local ok, answer
    if option.kind == 'attach' then
        ok, answer = call('install', weapon, { sub = option.pocket, slot = option.slot })
    elseif option.kind == 'detach' then
        ok, answer = call('remove', weapon, option.category)
    end
    acting = false
    if state ~= session then return end

    if ok and type(answer) == 'table' then
        session.data = answer
    elseif not ok then
        notify(type(answer) == 'string' and answer or T.failed, 'error')
    end
    SendNUIMessage({ action = 'busy', value = false })
    sendHotspots()
    sendInfo()
end

RegisterNUICallback('select', function(data, cb)
    cb(1)
    local h, o = tonumber(data and data.hotspot), tonumber(data and data.option)
    if h and o then CreateThread(function() perform(h, o) end) end
end)

RegisterNUICallback('camera', function(_, cb)
    cb(1)
    if not state then return end
    stopCamera(state.cam)
    state.cameraMode = state.cameraMode == 'firstperson' and 'scripted' or 'firstperson'
    state.cam = startCamera(PlayerPedId(), state.cameraMode)
    SendNUIMessage({ action = 'camera', label = cameraLabel(state.cameraMode) })
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    close()
end)

AddEventHandler('whip_core:player:died', close)
AddEventHandler('whip_core:player:logout', close)
AddEventHandler('onResourceStop', function(name) if name == GetCurrentResourceName() then close() end end)
