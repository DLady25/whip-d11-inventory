-- d11_ptrunk (cliente): calibracao por modelo de carro (fase 4). Porte do wizard do velocity-physicaltrunk (D12):
--   /ptrunkwizard start   Etapa 1 camera (camera livre) -> Etapa 2 pivo e area util -> Etapa 3 luz -> confirmar
--   /ptrunkwizard auto    preset automatico (camera do perfil atual, area de 8 pontos, luz base)
--   /ptrunkwizard load <modelo> | /ptrunkwizardload <modelo>   copia camera, area e luz de outro modelo
--   /ptrunkwizard save|next|back|cancel|status
--   avulsos: /ptrunkcam + /ptrunkcamsave, /ptrunkitempivot + /ptrunkitemsave, /ptrunkarea add|del|reset|finish|status,
--            /ptrunklightadd, /ptrunklightspot [new|n], /ptrunklightsave, /ptrunklight, /ptrunkinfo, /ptrunkprops (diagnostico dos objetos), /ptrunkmodels (modelos do mapa que faltam)
-- Teclas (as da D12): camera livre WASD + mouse, Q sobe, E desce, Shift rapido, Ctrl fino, Z/X fov; setas movem o pivo,
-- o ponto da area ou a luz; R/F altura; ENTER avanca; BACKSPACE volta; ESC cancela; Y/U adiciona/apaga ponto da area.
-- O que mudou: na D12 o save avulso ia para log e so o wizard escrevia arquivo; aqui tudo grava na tabela
-- d11_ptrunk_profiles pelo servidor (so com a ACE de admin) e vale na hora para todo mundo.
local W = exports.whip_core

local DEFAULT_POINTS, MIN_POINTS = 8, 4
local ENTER, BACK, ESC = 191, 177, 322

local Calib = { active = false }       -- camera
local Pivot = { active = false }       -- pivo e area util
local Light = { active = false }       -- luz
local Wizard = { active = false, step = 1, total = 3, confirm = false }

local STEPS = {
    { title = 'Etapa 1/3 - Câmera', hint = 'Ajuste a câmera do porta-malas. ENTER salva e avança.' },
    { title = 'Etapa 2/3 - Pivô e Área', hint = 'Ajuste o pivô e a área dos itens. Nasce com 8 pontos; mínimo 4.' },
    { title = 'Etapa 3/3 - Luz', hint = 'Ajuste posição, alvo e intensidade da luz. ENTER salva.' },
}

local function notify(text, kind) W:Notify(text, kind or 'info') end
local function pressed(c) return IsDisabledControlPressed(0, c) or IsControlPressed(0, c) end
local function just(c) return IsDisabledControlJustPressed(0, c) or IsControlJustPressed(0, c) end

-- Painel do wizard (html/wizard.*): o estado vai por SendNUIMessage so quando muda; nil esconde.
local lastUi = nil
local function ui(state)
    local enc = state and json.encode(state) or 'null'
    if enc == lastUi then return end
    lastUi = enc
    SendNUIMessage({ action = 'wizard', state = state })
end

local function f3(v) return ('%.2f  %.2f  %.2f'):format(v.x, v.y, v.z) end

local function modelName(model) return GetDisplayNameFromVehicleModel(model) or tostring(model) end

-- ------------------------------------------------------------------ permissao e carro
--- So admin (ACE no servidor). Espera no maximo 5 s e diz por que nao (ptrunk-calibration-gate da D12).
local function allowed()
    local p = promise.new()
    CreateThread(function() p:resolve(W:Callback('d11_ptrunk:canCalibrate')) end)
    SetTimeout(5000, function() if p.state == 0 then p:resolve('timeout') end end)
    local ok = Citizen.Await(p)
    if ok == true then return true end
    notify(ok == 'timeout' and 'O servidor não respondeu à permissão de calibração.' or 'Sem permissão para calibrar o porta-malas.', 'error')
    return false
end

local function nearestVehicle(maxDist)
    local me = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(GetEntityCoords(veh) - me)
        if d <= (maxDist or 7.0) and (not bestDist or d < bestDist) then best, bestDist = veh, d end
    end
    return best
end

local function resolveVehicle()
    for _, m in ipairs({ Pivot, Calib, Light }) do
        if m.active and m.vehicle and DoesEntityExist(m.vehicle) then return m.vehicle end
    end
    return nearestVehicle(7.0)
end

-- ------------------------------------------------------------------ ped, porta e camera
local function setPed(locked)
    local ped = PlayerPedId()
    SetPlayerControl(PlayerId(), not locked, 0)
    if not locked then
        ResetPedMovementClipset(ped, 0.0)
        SetPedStealthMovement(ped, false, '')
    end
    SetPedCanRagdoll(ped, not locked)
end

local function door(veh) return PT.AccessData(veh).access == 'front' and 4 or 5 end

local openedDoor = nil
local function openDoor(veh)
    local d = door(veh)
    if GetIsDoorValid(veh, d) and GetVehicleDoorAngleRatio(veh, d) < 0.1 then
        SetVehicleDoorOpen(veh, d, false, false)
        openedDoor = { veh = veh, door = d }
    end
end

local function closeDoor()
    if openedDoor and DoesEntityExist(openedDoor.veh) then SetVehicleDoorShut(openedDoor.veh, openedDoor.door, false) end
    openedDoor = nil
end

--- Camera livre (WASD, mouse, Q/E, Shift/Ctrl, Z/X fov). Mexe em m.pos/m.rot/m.fov.
local function freecam(m, allowFov)
    local fast, fine = pressed(21), pressed(36)
    local step = fine and 0.01 or (fast and 0.12 or 0.03)
    local mx, my = GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)
    local sens = fine and 2.0 or (fast and 6.0 or 3.5)
    local changed = math.abs(mx) > 0.0005 or math.abs(my) > 0.0005
    m.rot = vector3(math.max(-89.0, math.min(89.0, m.rot.x - my * sens)), 0.0, m.rot.z - mx * sens * 1.2)
    local fwd = PT.RotationToDirection(m.rot)
    local right = vector3(fwd.y, -fwd.x, 0.0)
    local move = vector3(0.0, 0.0, 0.0)
    if pressed(32) then move = move + fwd end
    if pressed(33) then move = move - fwd end
    if pressed(34) then move = move - right end
    if pressed(35) then move = move + right end
    if pressed(44) then move = move + vector3(0.0, 0.0, 1.0) end   -- Q sobe
    if pressed(38) then move = move - vector3(0.0, 0.0, 1.0) end   -- E desce
    if #move > 0.001 then
        m.pos = m.pos + (move / #move) * step
        changed = true
    end
    if allowFov and not fast then
        if pressed(20) then m.fov = math.max(35.0, m.fov - (fine and 0.15 or 0.5)) changed = true end   -- Z
        if pressed(73) then m.fov = math.min(90.0, m.fov + (fine and 0.15 or 0.5)) changed = true end   -- X
    end
    if changed then PT.SetFreeCameraTransform(m.pos, m.rot, m.fov) end
end

local function startFreecam(m, veh, look)
    local from, at, fov = PT.CameraPlacement(veh)
    m.pos, m.fov = from, fov
    m.rot = PT.RotationFromPoints(from, look or at)
    if m.rot.x ~= m.rot.x or math.abs(m.rot.x) > 88.0 then m.rot = PT.RotationFromPoints(from, at) end
    PT.CreateFreeCamera(m.pos, m.rot, m.fov)
end

local function disableControls()
    DisableFrontendThisFrame()
    SetPauseMenuActive(false)
    for _, c in ipairs({ 24, 25, 37, 44, 140, 141, 142, 257, 263, 264, 303, 322, 199, 200 }) do
        DisableControlAction(0, c, true)
    end
end

-- ------------------------------------------------------------------ gravar
local function send(model, kinds)
    kinds.modelHash = model
    TriggerServerEvent('d11_ptrunk:server:saveProfiles', kinds)
end

local function copy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = copy(v) end
    return out
end

-- Perfil trocado so na tela (etapa do wizard, previa da luz): guarda o original para desfazer se cancelar.
local undo = {}
local function stage(kind, model, data)
    local k = kind .. ':' .. model
    if undo[k] == nil then undo[k] = { kind = kind, model = model, data = PT.Profiles[kind][model] or false } end
    PT.SetProfile(kind, model, data)
end
local function rollback()
    for _, u in pairs(undo) do PT.SetProfile(u.kind, u.model, u.data or nil) end
    undo = {}
end
local function commit() undo = {} end

-- ------------------------------------------------------------------ luz (normalizeTrunkLightSpot da D12)
local function normalizeSpot(raw, fallbackY, pivot)
    raw = type(raw) == 'table' and raw or {}
    local L = Config.TrunkLight
    local px = pivot and tonumber(pivot.x) or 0.0
    local py = pivot and tonumber(pivot.y) or ((fallbackY or -1.0) - 0.45)
    local pz = pivot and tonumber(pivot.z) or 0.32
    return {
        pos = raw.pos and { x = raw.pos.x, y = raw.pos.y, z = raw.pos.z } or { x = px, y = py + 0.10, z = pz + 0.40 },
        look = raw.look and { x = raw.look.x, y = raw.look.y, z = raw.look.z } or { x = px, y = py - 0.65, z = pz - 0.05 },
        color = raw.color and { r = raw.color.r, g = raw.color.g, b = raw.color.b } or { r = 255, g = 235, b = 190 },
        brightness = raw.brightness or L.brightness,
        spotFov = raw.spotFov or raw.radius or L.radius,
        distance = raw.distance or L.distance,
        radius = raw.radius or raw.spotFov or L.radius,
        falloff = raw.falloff or L.falloff,
        roundness = raw.roundness or L.roundness,
    }
end

local function defaultPoints(pivot)
    local px, py = pivot.x or 0.0, pivot.y or -1.0
    return {
        { x = px - 0.50, y = py + 0.45 }, { x = px - 0.15, y = py + 0.55 }, { x = px + 0.15, y = py + 0.55 },
        { x = px + 0.50, y = py + 0.45 }, { x = px + 0.58, y = py - 0.15 }, { x = px + 0.30, y = py - 0.75 },
        { x = px - 0.30, y = py - 0.75 }, { x = px - 0.58, y = py - 0.15 },
    }
end

-- ------------------------------------------------------------------ etapa 1: camera
local function closeCalib(silent)
    if not Calib.active then return end
    Calib.active, Calib.vehicle = false, nil
    PT.DestroyTrunkCamera(false)
    closeDoor()
    setPed(false)
    if not silent then notify('Calibração de câmera encerrada.') end
end

local function closePivot(silent)
    if not Pivot.active then return end
    Pivot.active, Pivot.vehicle = false, nil
    PT.DestroyTrunkCamera(false)
    closeDoor()
    setPed(false)
    if not silent then notify('Calibração de pivô e área encerrada.') end
end

local function closeLight(silent)
    if not Light.active then return end
    Light.active, Light.vehicle = false, nil
    if not Wizard.active then rollback() end
    PT.DestroyTrunkCamera(false)
    closeDoor()
    setPed(false)
    if not silent then notify('Calibração de luz encerrada.') end
end

local function closeAll()
    closeCalib(true)
    closePivot(true)
    closeLight(true)
end

local function openCalib(veh)
    if Calib.active then closeCalib() return end
    closeAll()
    if PT.ModeActive() then notify('Feche o porta-malas antes de calibrar.', 'error') return end
    Calib.active, Calib.vehicle, Calib.model = true, veh, GetEntityModel(veh)
    setPed(true)
    openDoor(veh)
    startFreecam(Calib, veh)
    notify('Câmera livre ativa: posicione e salve (ENTER no wizard, /ptrunkcamsave avulso).', 'success')
end

local function saveCalib(persist)
    if not Calib.active then notify('Ative /ptrunkcam antes de salvar.', 'error') return false end
    local veh = Calib.vehicle
    local look = Calib.pos + PT.RotationToDirection(Calib.rot) * 2.5
    local c = GetOffsetFromEntityGivenWorldCoords(veh, Calib.pos.x, Calib.pos.y, Calib.pos.z)
    local l = GetOffsetFromEntityGivenWorldCoords(veh, look.x, look.y, look.z)
    local a = PT.AccessData(veh)
    local profile = copy(PT.Profiles.camera[Calib.model]) or {}
    profile.access, profile.triggerRadius, profile.standOffset = a.access, a.triggerRadius, PT.StandOffset(veh)
    profile.camLocalX, profile.camLocalY, profile.camLocalZ = c.x, c.y, c.z
    profile.lookLocalX, profile.lookLocalY, profile.lookLocalZ = l.x, l.y, l.z
    profile.fov = Calib.fov
    stage('camera', Calib.model, profile)
    if persist then send(Calib.model, { camera = profile }) commit() end
    return true
end

-- ------------------------------------------------------------------ etapa 2: pivo e area
local function openPivot(veh)
    if Pivot.active then closePivot() return end
    closeAll()
    if PT.ModeActive() then notify('Feche o porta-malas antes de calibrar.', 'error') return end
    local model = GetEntityModel(veh)
    local profile = PT.Profiles.spawn[model]
    Pivot.active, Pivot.vehicle, Pivot.model = true, veh, model
    Pivot.pivot = { x = profile and profile.x or 0.0, y = profile and profile.y or PT.AccessY(veh), z = profile and profile.z or 0.32 }
    Pivot.points = (profile and profile.areaPoints and #profile.areaPoints >= MIN_POINTS) and copy(profile.areaPoints)
        or defaultPoints(Pivot.pivot)
    Pivot.autoAnchored = profile == nil
    Pivot.stage, Pivot.index = 'pivot', 1
    setPed(true)
    openDoor(veh)
    startFreecam(Pivot, veh)
    notify(('Pivô e área: ENTER fixa o pivô e avança pelos pontos. A área nasce com %d pontos; Y adiciona, U apaga.'):format(DEFAULT_POINTS), 'success')
end

local function areaAdd()
    if not Pivot.active or Pivot.stage ~= 'area' then notify('Entre na etapa da área antes.', 'error') return end
    local n = #Pivot.points
    local cur = Pivot.points[Pivot.index]
    local nxt = Pivot.points[(Pivot.index % n) + 1] or cur
    table.insert(Pivot.points, Pivot.index + 1, { x = (cur.x + nxt.x) * 0.5, y = (cur.y + nxt.y) * 0.5 })
    Pivot.index = Pivot.index + 1
    notify(('Ponto adicionado. A área tem %d pontos.'):format(#Pivot.points), 'success')
end

local function areaDelete()
    if not Pivot.active or Pivot.stage ~= 'area' then notify('Entre na etapa da área antes.', 'error') return end
    if #Pivot.points <= MIN_POINTS then notify(('A área precisa de pelo menos %d pontos.'):format(MIN_POINTS), 'error') return end
    table.remove(Pivot.points, Pivot.index)
    Pivot.index = math.min(Pivot.index, #Pivot.points)
    notify(('Ponto apagado. A área tem %d pontos.'):format(#Pivot.points))
end

local function areaReset()
    if not Pivot.active then notify('Ative /ptrunkitempivot antes.', 'error') return end
    Pivot.points = defaultPoints(Pivot.pivot)
    Pivot.autoAnchored, Pivot.stage, Pivot.index = true, 'area', 1
    notify(('Área refeita com %d pontos em volta do pivô.'):format(DEFAULT_POINTS), 'success')
end

local function areaFinish()
    if not Pivot.active or Pivot.stage ~= 'area' then notify('Entre na etapa da área antes.', 'error') return false end
    if #Pivot.points < MIN_POINTS then notify(('Defina pelo menos %d pontos.'):format(MIN_POINTS), 'error') return false end
    Pivot.stage = 'done'
    notify(('Área confirmada com %d pontos.'):format(#Pivot.points), 'success')
    return true
end

local function savePivot(persist)
    if not Pivot.active then notify('Ative /ptrunkitempivot antes de salvar.', 'error') return false end
    if Pivot.stage ~= 'done' then notify(('Finalize a área com pelo menos %d pontos antes.'):format(MIN_POINTS), 'error') return false end
    local profile = { x = Pivot.pivot.x, y = Pivot.pivot.y, z = Pivot.pivot.z, areaPoints = copy(Pivot.points) }
    stage('spawn', Pivot.model, profile)
    if persist then send(Pivot.model, { spawn = profile }) commit() end
    return true
end

-- ------------------------------------------------------------------ etapa 3: luz
local function openLight(veh, which)
    if Light.active then closeLight() return end
    closeAll()
    if PT.ModeActive() then notify('Feche o porta-malas antes de calibrar.', 'error') return end
    local model = GetEntityModel(veh)
    local accessY = PT.AccessY(veh)
    local pivot = PT.Profiles.spawn[model]
    local spots = {}
    for i, sp in ipairs((PT.Profiles.light[model] or {}).spots or {}) do spots[i] = normalizeSpot(sp, accessY, pivot) end
    if #spots == 0 then spots[1] = normalizeSpot({}, accessY, pivot) end
    local index = tonumber(which)
    if which == 'new' then
        spots[#spots + 1] = normalizeSpot({}, accessY, pivot)
        index = #spots
    end
    index = math.max(1, index or 1)
    for i = #spots + 1, index do spots[i] = normalizeSpot({}, accessY, pivot) end
    Light.active, Light.vehicle, Light.model = true, veh, model
    Light.spots, Light.index, Light.stage = spots, index, 'position'
    setPed(true)
    openDoor(veh)
    local s = spots[index]
    startFreecam(Light, veh, GetOffsetFromEntityInWorldCoords(veh, s.look.x, s.look.y, s.look.z))
    notify(('Luz #%d: ajuste a posição, ENTER para o alvo, ENTER para terminar.'):format(index), 'success')
end

local function saveLight(persist)
    if not Light.active then notify('Ative /ptrunklightadd antes de salvar.', 'error') return false end
    if Light.stage ~= 'done' then notify('Termine com ENTER na etapa do alvo antes.', 'error') return false end
    local profile = { spots = copy(Light.spots) }
    stage('light', Light.model, profile)
    if persist then send(Light.model, { light = profile }) commit() end
    return true
end

-- ------------------------------------------------------------------ wizard
--- Cancelar desfaz o que as etapas trocaram so na tela (a confirmacao ja chamou commit).
local function wizardCancel()
    Wizard.active, Wizard.confirm = false, false
    closeAll()
    rollback()
end

local function wizardStart(step)
    Wizard.confirm = false
    local veh = resolveVehicle()
    if not veh then notify('Chegue perto de um carro para o wizard.', 'error') return end
    closeAll()
    if step == 1 then openCalib(veh) elseif step == 2 then openPivot(veh) else openLight(veh) end
end

local function wizardBegin()
    Wizard.active, Wizard.step = true, 1
    wizardStart(1)
end

local function wizardReady(step)
    if step == 1 then return Calib.active end
    if step == 2 then return Pivot.active and Pivot.stage == 'done' end
    return Light.active and Light.stage == 'done'
end

--- ENTER na confirmacao final: grava camera, area e luz do modelo de uma vez.
local function wizardConfirm()
    if not Wizard.active or Wizard.step ~= 3 or not wizardReady(3) then return end
    saveLight(false)
    local model = Light.model
    local cam, spawn, light = PT.Profiles.camera[model], PT.Profiles.spawn[model], PT.Profiles.light[model]
    if not (cam and spawn and light) then
        notify('Falta câmera, área ou luz deste modelo: refaça as etapas.', 'error')
        return
    end
    send(model, { camera = cam, spawn = spawn, light = light })
    commit()
    notify(('Perfil de %s enviado ao servidor.'):format(modelName(model)), 'success')
    wizardCancel()
end

local function wizardSave()
    if not Wizard.active then return end
    if not wizardReady(Wizard.step) then notify('Termine a etapa atual antes de avançar.', 'error') return end
    if Wizard.step == 3 then
        if not Wizard.confirm then
            Wizard.confirm = true
            notify('Revise. ENTER salva e aplica, BACKSPACE volta para o feixe.')
        else
            wizardConfirm()
        end
        return
    end
    if Wizard.step == 1 then saveCalib(false) else savePivot(false) end
    Wizard.step = Wizard.step + 1
    wizardStart(Wizard.step)
end

local function wizardBack()
    if not Wizard.active then return end
    if Wizard.step > 1 then
        Wizard.step = Wizard.step - 1
        wizardStart(Wizard.step)
    end
end

--- /ptrunkwizard auto: camera do perfil atual, area de 8 pontos em volta do acesso e uma luz base.
local function autoPreset(veh)
    if not veh then notify('Chegue perto de um carro para o preset automático.', 'error') return end
    closeAll()
    local model = GetEntityModel(veh)
    local from, look, fov = PT.CameraPlacement(veh)
    local c = GetOffsetFromEntityGivenWorldCoords(veh, from.x, from.y, from.z)
    local l = GetOffsetFromEntityGivenWorldCoords(veh, look.x, look.y, look.z)
    local a = PT.AccessData(veh)
    local cam = { access = a.access, triggerRadius = a.triggerRadius, standOffset = PT.StandOffset(veh),
        camLocalX = c.x, camLocalY = c.y, camLocalZ = c.z, lookLocalX = l.x, lookLocalY = l.y, lookLocalZ = l.z, fov = fov }
    local pivot = { x = 0.0, y = PT.AccessY(veh), z = 0.32 }
    local spawn = { x = pivot.x, y = pivot.y, z = pivot.z, areaPoints = defaultPoints(pivot) }
    local light = { spots = { normalizeSpot({}, PT.AccessY(veh), pivot) } }
    PT.SetProfile('camera', model, cam)
    PT.SetProfile('spawn', model, spawn)
    PT.SetProfile('light', model, light)
    send(model, { camera = cam, spawn = spawn, light = light })
    notify(('Preset automático de %s: câmera, área de %d pontos e luz base.'):format(modelName(model), DEFAULT_POINTS), 'success')
end

--- /ptrunkwizardload <modelo>: copia camera, area e luz de outro modelo para o carro mais perto.
local function loadFrom(args)
    local name = tostring(args and args[1] or ''):lower():gsub('[^%w_]', '')
    if name == '' then notify('Use: /ptrunkwizardload <modeloBase>', 'error') return end
    local src = joaat(name)
    local cam, spawn, light = PT.Profiles.camera[src], PT.Profiles.spawn[src], PT.Profiles.light[src]
    if not cam and not spawn and not light then notify(('Nenhum perfil de porta-malas para %s.'):format(name), 'error') return end
    if not (cam and spawn and light) then notify(('O perfil de %s está incompleto: precisa de câmera, área e luz.'):format(name), 'error') return end
    local veh = resolveVehicle()
    if not veh then notify('Chegue perto do carro que vai receber o perfil.', 'error') return end
    local model = GetEntityModel(veh)
    if model == src then notify('Esse carro já é desse modelo.', 'error') return end
    cam, spawn, light = copy(cam), copy(spawn), copy(light)
    PT.SetProfile('camera', model, cam)
    PT.SetProfile('spawn', model, spawn)
    PT.SetProfile('light', model, light)
    send(model, { camera = cam, spawn = spawn, light = light })
    notify(('Perfil de %s aplicado em %s.'):format(name, modelName(model)), 'success')
end

-- ------------------------------------------------------------------ desenho
local function drawPivot()
    local veh = Pivot.vehicle
    local p = Pivot.pivot
    local h, z = 0.055, p.z + 0.02
    local a = GetOffsetFromEntityInWorldCoords(veh, p.x - h, p.y - h, z)
    local b = GetOffsetFromEntityInWorldCoords(veh, p.x + h, p.y - h, z)
    local c = GetOffsetFromEntityInWorldCoords(veh, p.x + h, p.y + h, z)
    local d = GetOffsetFromEntityInWorldCoords(veh, p.x - h, p.y + h, z)
    for _, e in ipairs({ { a, b }, { b, c }, { c, d }, { d, a } }) do
        DrawLine(e[1].x, e[1].y, e[1].z, e[2].x, e[2].y, e[2].z, 40, 190, 255, 240)
    end
    local areaZ = p.z + math.abs(p.z) * 0.10
    local first, last
    for i, q in ipairs(Pivot.points) do
        local w = GetOffsetFromEntityInWorldCoords(veh, q.x, q.y, areaZ)
        local cur = Pivot.stage == 'area' and Pivot.index == i
        DrawMarker(2, w.x, w.y, w.z + 0.01, 0, 0, 0, 0, 0, 0, 0.035, 0.035, 0.035,
            cur and 255 or 70, cur and 200 or 150, cur and 80 or 255, 220, false, false, 2, false, nil, nil, false)
        if last then DrawLine(last.x, last.y, last.z + 0.01, w.x, w.y, w.z + 0.01, 70, 190, 255, 220) else first = w end
        last = w
    end
    if first and last then DrawLine(last.x, last.y, last.z + 0.01, first.x, first.y, first.z + 0.01, 70, 190, 255, 220) end
end

--- O que vai em todo painel: passos do wizard (ou nada, na calibracao avulsa) e o modelo.
local function base(m, kicker, title)
    return {
        steps = Wizard.active and { current = Wizard.step, confirm = Wizard.confirm } or nil,
        kicker = Wizard.active and 'Wizard do porta-malas' or 'Calibração avulsa',
        title = title,
        model = m.vehicle and DoesEntityExist(m.vehicle) and modelName(GetEntityModel(m.vehicle)) or nil,
    }
end

--- Teclas de fim de etapa, iguais em todas.
local function flowKeys(enterLabel)
    return {
        { 'Enter', enterLabel, true },
        { 'Backspace', Wizard.active and 'Voltar' or 'Voltar ou sair' },
        { 'Esc', Wizard.active and 'Cancelar o wizard' or 'Sair' },
    }
end

local CAM_KEYS = { { 'W A S D', 'Mover' }, { 'Mouse', 'Olhar' }, { 'Q / E', 'Subir / descer' }, { 'Shift', 'Rápido' },
    { 'Ctrl', 'Fino' } }

-- ------------------------------------------------------------------ laco
local function tickCalib()
    freecam(Calib, true)
    local st = base(Calib, nil, 'Câmera')
    st.hint = 'Deixe a câmera como o jogador deve ver o porta-malas aberto: de trás, um pouco acima, pegando o fundo todo.'
    st.values = { { 'Posição', f3(Calib.pos) }, { 'Campo de visão', ('%.1f°'):format(Calib.fov) } }
    local keys = { table.unpack(CAM_KEYS) }
    keys[#keys + 1] = { 'Z / X', 'Fechar / abrir o campo de visão' }
    st.keys = { keys, flowKeys(Wizard.active and 'Salvar e ir para a área' or 'Salvar a câmera') }
    ui(st)
    if just(BACK) then
        if Wizard.active then wizardBack() else closeCalib() end
    elseif just(ESC) then
        if Wizard.active then wizardCancel() else closeCalib() end
    elseif just(ENTER) then
        if Wizard.active then wizardSave() elseif saveCalib(true) then notify('Câmera salva.', 'success') end
    end
end

local function tickPivot()
    local fast, fine = pressed(21), pressed(36)
    local step = fine and 0.003 or (fast and 0.02 or 0.008)
    local target = Pivot.stage == 'pivot' and Pivot.pivot or (Pivot.stage == 'area' and Pivot.points[Pivot.index])
    if target then
        if pressed(174) then target.x = target.x - step end
        if pressed(175) then target.x = target.x + step end
        if pressed(172) then target.y = target.y + step end
        if pressed(173) then target.y = target.y - step end
        if Pivot.stage == 'pivot' then
            if pressed(45) then target.z = target.z + step end
            if pressed(23) then target.z = target.z - step end
        end
    end
    freecam(Pivot, false)
    drawPivot()
    local st = base(Pivot, nil, Pivot.stage == 'pivot' and 'Pivô' or 'Área útil')
    local move = { { 'Setas', Pivot.stage == 'pivot' and 'Mover o pivô' or 'Mover o ponto amarelo' } }
    if Pivot.stage == 'pivot' then
        st.hint = 'Ponha o quadrado azul no centro do fundo do porta-malas, rente ao piso. É a altura onde os itens apoiam.'
        move[#move + 1] = { 'R / F', 'Subir / descer o pivô' }
    elseif Pivot.stage == 'area' then
        st.hint = ('Leve cada ponto até um canto do fundo do porta-malas, no sentido da borda. Ponto %d de %d.')
            :format(Pivot.index, #Pivot.points)
        move[#move + 1] = { 'Y', 'Acrescentar ponto' }
        move[#move + 1] = { 'U', ('Apagar ponto (mínimo %d)'):format(MIN_POINTS) }
    else
        st.hint = 'Área pronta. Confira se a linha azul contorna o fundo inteiro.'
    end
    for _, k in ipairs(CAM_KEYS) do move[#move + 1] = k end
    st.values = { { 'Pivô', f3(Pivot.pivot) } }
    if Pivot.stage ~= 'pivot' then st.values[2] = { 'Ponto', ('%d de %d'):format(Pivot.index, #Pivot.points) } end
    local enter = Pivot.stage == 'pivot' and 'Fixar o pivô e ir para a área'
        or Pivot.stage == 'area' and (Pivot.index < #Pivot.points and 'Próximo ponto' or 'Terminar a área')
        or (Wizard.active and 'Salvar e ir para a luz' or 'Salvar pivô e área')
    st.keys = { move, flowKeys(enter) }
    ui(st)
    if just(246) then areaAdd()          -- Y
    elseif just(303) then areaDelete()   -- U
    elseif just(BACK) then
        if Pivot.stage == 'done' then
            Pivot.stage, Pivot.index = 'area', #Pivot.points
        elseif Pivot.stage == 'area' and Pivot.index > 1 then
            Pivot.index = Pivot.index - 1
        elseif Pivot.stage == 'area' then
            Pivot.stage, Pivot.index = 'pivot', 1
        elseif Wizard.active then
            wizardBack()
        else
            closePivot()
        end
    elseif just(ESC) then
        if Wizard.active then wizardCancel() else closePivot() end
    elseif just(ENTER) then
        if Pivot.stage == 'pivot' then
            if Pivot.autoAnchored then Pivot.points = defaultPoints(Pivot.pivot) end
            Pivot.stage, Pivot.index = 'area', 1
        elseif Pivot.stage == 'area' then
            if Pivot.index < #Pivot.points then
                Pivot.index = Pivot.index + 1
            elseif areaFinish() then
                if Wizard.active then wizardSave() else notify('Área pronta. Use /ptrunkitemsave para salvar.', 'success') end
            end
        elseif Pivot.stage == 'done' then
            if Wizard.active then wizardSave() elseif savePivot(true) then notify('Pivô e área salvos.', 'success') end
        end
    end
end

local function tickLight()
    local veh = Light.vehicle
    local s = Light.spots[Light.index]
    if Wizard.active and Wizard.confirm then
        PT.DrawTrunkLight(veh)
        local st = base(Light, nil, 'Confirmar')
        st.hint = 'Câmera, área e luz prontas.'
        st.confirm = {
            title = 'Salvar o perfil',
            text = ('Gravar câmera, área e luz para %s? Vale na hora para todo mundo, e o porta-malas físico passa a abrir neste modelo.')
                :format(st.model or 'este modelo'),
            keys = { { 'Enter', 'Salvar e aplicar', true }, { 'Backspace', 'Voltar para a luz' }, { 'Esc', 'Cancelar o wizard' } },
        }
        ui(st)
        if just(ENTER) then wizardConfirm()
        elseif just(BACK) then Wizard.confirm, Light.stage = false, 'look'
        elseif just(ESC) then wizardCancel() end
        return
    end
    local fast, fine = pressed(21), pressed(36)
    local step = fine and 0.003 or (fast and 0.02 or 0.008)
    local valStep = fine and 1 or (fast and 8 or 3)
    local t = Light.stage == 'position' and s.pos or s.look
    if pressed(174) then t.x = t.x - step end
    if pressed(175) then t.x = t.x + step end
    if pressed(172) then t.y = t.y + step end
    if pressed(173) then t.y = t.y - step end
    if pressed(45) then t.z = t.z + step end
    if pressed(23) then t.z = t.z - step end
    if pressed(246) then       -- Y: fov (Ctrl: intensidade)
        if fine then s.brightness = math.min(25.0, s.brightness + (fast and 0.30 or 0.08)) else s.spotFov = math.min(60.0, s.spotFov + 0.10) end
    end
    if pressed(74) then        -- H
        if fine then s.brightness = math.max(0.1, s.brightness - (fast and 0.30 or 0.08)) else s.spotFov = math.max(1.0, s.spotFov - 0.10) end
    end
    if fast and pressed(20) then s.color.r = math.min(255, s.color.r + valStep) end   -- Shift+Z
    if fast and pressed(73) then s.color.r = math.max(0, s.color.r - valStep) end     -- Shift+X
    if pressed(26) then s.color.g = math.min(255, s.color.g + valStep) end            -- C
    if pressed(0) then s.color.g = math.max(0, s.color.g - valStep) end               -- V
    if pressed(29) then s.color.b = math.min(255, s.color.b + valStep) end            -- B
    if pressed(249) then s.color.b = math.max(0, s.color.b - valStep) end             -- N
    s.radius = s.spotFov
    freecam(Light, true)
    stage('light', Light.model, { spots = Light.spots })   -- previa: a luz do jogo ja usa o que esta sendo ajustado
    PT.DrawTrunkLight(veh)
    local pw = GetOffsetFromEntityInWorldCoords(veh, s.pos.x, s.pos.y, s.pos.z)
    local lw = GetOffsetFromEntityInWorldCoords(veh, s.look.x, s.look.y, s.look.z)
    DrawMarker(28, pw.x, pw.y, pw.z + 0.02, 0, 0, 0, 0, 0, 0, 0.05, 0.05, 0.05, 255, 210, 90, 220, false, false, 2, false, nil, nil, false)
    DrawMarker(2, lw.x, lw.y, lw.z + 0.01, 0, 0, 0, 0, 0, 0, 0.03, 0.03, 0.03, 80, 220, 255, 220, false, false, 2, false, nil, nil, false)
    DrawLine(pw.x, pw.y, pw.z, lw.x, lw.y, lw.z, 255, 220, 120, 220)
    local st = base(Light, nil, ('Luz %d'):format(Light.index))
    local which = Light.stage == 'position' and 'fonte' or 'alvo'
    st.hint = Light.stage == 'position'
        and 'Ponha a fonte (ponto amarelo) onde fica a lâmpada do porta-malas, na tampa ou no teto.'
        or 'Agora o alvo (ponto azul): para onde a luz aponta, normalmente o centro do fundo.'
    st.values = {
        { 'Ajustando', which },
        { 'Cor', ('%d  %d  %d'):format(s.color.r, s.color.g, s.color.b), ('rgb(%d,%d,%d)'):format(s.color.r, s.color.g, s.color.b) },
        { 'Intensidade', ('%.2f'):format(s.brightness) },
        { 'Abertura', ('%.1f°'):format(s.spotFov) },
    }
    local adjust = { { 'Setas', 'Mover a ' .. which }, { 'R / F', 'Subir / descer a ' .. which }, { 'Y / H', 'Abrir / fechar o feixe' },
        { 'Ctrl + Y / H', 'Mais / menos intensidade' }, { 'Shift + Z / X', 'Vermelho + / -' }, { 'C / V', 'Verde + / -' },
        { 'B / N', 'Azul + / -' } }
    local enter = Light.stage == 'position' and 'Fixar a fonte e ajustar o alvo'
        or (Wizard.active and 'Revisar e salvar' or 'Salvar a luz')
    st.keys = { adjust, CAM_KEYS, flowKeys(enter) }
    ui(st)
    if just(ESC) then
        if Wizard.active then wizardCancel() else closeLight() end
    elseif just(BACK) then
        if Light.stage == 'look' then Light.stage = 'position'
        elseif Wizard.active then wizardBack()
        else closeLight() end
    elseif just(ENTER) then
        if Light.stage == 'position' then
            Light.stage = 'look'
        elseif Light.stage == 'look' then
            Light.stage = 'done'
            if Wizard.active then wizardSave() elseif saveLight(true) then notify(('Luz #%d salva.'):format(Light.index), 'success') end
        end
    end
end

CreateThread(function()
    while true do
        local m = (Calib.active and Calib) or (Pivot.active and Pivot) or (Light.active and Light) or nil
        if not m then
            ui(nil)
            Wait(300)
        elseif not m.vehicle or not DoesEntityExist(m.vehicle) then
            if Wizard.active then wizardCancel() else closeAll() end
            Wait(0)
        else
            disableControls()
            SetEntityNoCollisionEntity(PlayerPedId(), m.vehicle, true)
            if m == Calib then tickCalib() elseif m == Pivot then tickPivot() else tickLight() end
            Wait(0)
        end
    end
end)

-- ------------------------------------------------------------------ comandos
local function command(name, fn)
    RegisterCommand(name, function(_, args)
        CreateThread(function()
            if allowed() then fn(args or {}) end
        end)
    end, false)
end

local function needVehicle(fn)
    return function(args)
        local veh = nearestVehicle(7.0)
        if not veh then notify('Chegue perto de um carro para calibrar.', 'error') return end
        fn(veh, args)
    end
end

command('ptrunkwizard', function(args)
    local action = tostring(args[1] or 'start'):lower()
    if action == 'load' or action == 'carregar' then
        table.remove(args, 1)
        loadFrom(args)
    elseif action == 'start' then wizardBegin()
    elseif action == 'auto' or action == 'preset' or action == 'automatico' then autoPreset(resolveVehicle())
    elseif action == 'next' then
        if not Wizard.active then wizardBegin()
        elseif Wizard.step < Wizard.total then Wizard.step = Wizard.step + 1 wizardStart(Wizard.step)
        else wizardCancel() end
    elseif action == 'back' then wizardBack()
    elseif action == 'save' then wizardSave()
    elseif action == 'cancel' then wizardCancel()
    elseif action == 'status' then
        notify(('Wizard: %s, etapa %d/%d. Use /ptrunkwizard start|auto|load|save|next|back|cancel.')
            :format(Wizard.active and 'ativo' or 'inativo', Wizard.step, Wizard.total))
    else
        notify('Use: /ptrunkwizard start|auto|load|save|next|back|cancel|status', 'error')
    end
end)
command('ptrunkwizardload', loadFrom)
command('ptrunkcam', needVehicle(function(veh) openCalib(veh) end))
command('ptrunkcamsave', function() if saveCalib(true) then notify('Câmera salva.', 'success') end end)
command('ptrunkitempivot', needVehicle(function(veh) openPivot(veh) end))
command('ptrunkitemsave', function() if savePivot(true) then notify('Pivô e área salvos.', 'success') end end)
command('ptrunkarea', function(args)
    local a = tostring(args[1] or 'status'):lower()
    if a == 'add' or a == 'adicionar' then areaAdd()
    elseif a == 'del' or a == 'apagar' or a == 'remover' then areaDelete()
    elseif a == 'reset' or a == 'padrao' then areaReset()
    elseif a == 'finish' or a == 'finalizar' then areaFinish()
    elseif not Pivot.active then notify('Área inativa. Use /ptrunkitempivot ou /ptrunkwizard.')
    else notify(('Área: etapa %s, ponto %d/%d, mínimo %d.'):format(Pivot.stage, Pivot.index, #Pivot.points, MIN_POINTS)) end
end)
command('ptrunklightadd', needVehicle(function(veh) openLight(veh) end))
command('ptrunklightspot', needVehicle(function(veh, args)
    local a = args[1]
    if a and a ~= 'new' and not tonumber(a) then notify('Use: /ptrunklightspot [new|número]', 'error') return end
    openLight(veh, a)
end))
command('ptrunklightsave', function() if saveLight(true) then notify('Luz salva.', 'success') end end)
command('ptrunkinfo', function()
    local veh = nearestVehicle(10.0)
    if not veh then notify('Nenhum carro perto.', 'error') return end
    local model = GetEntityModel(veh)
    local a = PT.AccessData(veh)
    local has = function(k) return PT.Profiles[k][model] and 'sim' or 'não' end
    local line = ('%s hash=%d classe=%d acesso=%s raio=%.2f | câmera %s, área %s, luz %s')
        :format(modelName(model), model, GetVehicleClass(veh), a.access, a.triggerRadius, has('camera'), has('spawn'), has('light'))
    print('[d11_ptrunk] ' .. line)
    notify(line)
end)

-- /ptrunkprops: diagnostico dos objetos do porta-malas aberto. Para cada item da ultima lista: se ha registro, se o
-- objeto existe, esta visivel e preso ao carro, e onde esta no espaco do carro. Vai para o F8 (e o log do cliente).
-- Sem permissao: so le o que ja esta no jogo de quem roda, nao muda nada.
RegisterCommand('ptrunkprops', function()
    local m = PT.ModeState()
    if not m or not m.active or not m.scene then notify('Abra um porta-malas no modo físico.', 'error') return end
    local scene, veh = m.scene, m.vehicle
    local seen = {}
    local mnx, mxx, mny, mxy = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(scene.area.areaPoints or {}) do
        mnx, mxx, mny, mxy = math.min(mnx, p.x), math.max(mxx, p.x), math.min(mny, p.y), math.max(mxy, p.y)
    end
    print(('[d11_ptrunk] /ptrunkprops: %d itens na lista, ready=%s syncing=%s retries=%s area x=%.2f..%.2f y=%.2f..%.2f z=%.2f'):format(
        #(m.lastItems or {}), tostring(m.ready), tostring(m.syncing), tostring(m.retries), mnx, mxx, mny, mxy, scene.area.z or 0.0))
    local bad = 0
    for _, it in ipairs(m.lastItems or {}) do
        local key = PT.KeyOf(it)
        local rec = scene.props[key]
        seen[key] = true
        local line
        if not rec then
            line = 'SEM REGISTRO'
        elseif not rec.entity or not DoesEntityExist(rec.entity) then
            line = 'registro sem objeto'
        else
            local e = rec.entity
            local c = GetEntityCoords(e)
            local l = GetOffsetFromEntityGivenWorldCoords(veh, c.x, c.y, c.z)
            local it2 = rec.item
            local v = PT.ItemVisual(it.item, it.amount)
            local inside = PT.InsidePolygon(scene.area.areaPoints, it2.visualX or 0.0, it2.visualY or 0.0)
            -- Base e topo do modelo no espaco do carro (os 8 cantos), contra o piso da area: topo abaixo = enterrado.
            local mn, mx = GetModelDimensions(GetEntityModel(e))
            local lo, hi = math.huge, -math.huge
            for _, x in ipairs({ mn.x, mx.x }) do
                for _, y in ipairs({ mn.y, mx.y }) do
                    for _, z in ipairs({ mn.z, mx.z }) do
                        local w = GetOffsetFromEntityInWorldCoords(e, x, y, z)
                        local q = GetOffsetFromEntityGivenWorldCoords(veh, w.x, w.y, w.z)
                        lo, hi = math.min(lo, q.z), math.max(hi, q.z)
                    end
                end
            end
            local r = GetEntityRotation(e, 2)
            local fw, rt, up = GetEntityMatrix(e)
            local dmn, dmx = GetModelDimensions(rec.model)
            print(('[d11_ptrunk]     modeloEntidade=%s modeloRec=%s carregado=%s dimsEnt=(%s|%s) dimsRec=(%s|%s) matriz f=%s r=%s u=%s itemRot=(%s,%s,%s)'):format(
                tostring(GetEntityModel(e)), tostring(rec.model), tostring(HasModelLoaded(rec.model)),
                tostring(mn), tostring(mx), tostring(dmn), tostring(dmx), tostring(fw), tostring(rt), tostring(up),
                tostring(it2.visualYaw), tostring(it2.visualPitch), tostring(it2.visualRoll)))
            print(('[d11_ptrunk]     base=%.2f topo=%.2f piso=%.2f rot=(%.0f,%.0f,%.0f) restZ=%.2f lift=%.2f'):format(
                lo, hi, scene.area.z or 0.0, r.x, r.y, r.z, PT.RestZ(scene, rec), PT.LiftOf(scene, rec)))
            line = ('obj=%d vis=%s alpha=%d preso=%s dentro=%s local=(%.2f,%.2f,%.2f) visual=(%.2f,%.2f,%.2f) modelo=%s (%s) wobble=%s posed=%s')
                :format(e, tostring(IsEntityVisible(e)), GetEntityAlpha(e), tostring(IsEntityAttachedToEntity(e, veh)),
                    tostring(inside), l.x, l.y, l.z, it2.visualX or -99, it2.visualY or -99, it2.visualZ or -99,
                    tostring(v.modelName or rec.model), tostring(v.source), tostring(it2._ptPhysicsNeedsWobble), tostring(rec.posed))
        end
        if not rec or not rec.entity then bad = bad + 1 end
        print(('[d11_ptrunk]   slot %s %s key=%s: %s'):format(it.slot, it.item, key, line))
    end
    for key, rec in pairs(scene.props) do
        if not seen[key] then print(('[d11_ptrunk]   SOBRA key=%s item=%s obj=%s'):format(key, tostring(rec.itemName), tostring(rec.entity))) end
    end
    notify(('%d itens, %d sem objeto. Detalhes no F8.'):format(#(m.lastItems or {}), bad))
end, false)

-- /ptrunkmodels: os modelos do Config.ItemModels que nao existem neste jogo (esses itens caem no modelo da categoria).
RegisterCommand('ptrunkmodels', function()
    local missing, total = {}, 0
    for item, model in pairs(Config.ItemModels or {}) do
        total = total + 1
        if not IsModelInCdimage(joaat(model)) then missing[#missing + 1] = ('%s=%s'):format(item, model) end
    end
    for item, tiers in pairs(Config.ItemModelsByAmount or {}) do
        for i, t in ipairs(tiers) do
            total = total + 1
            if not IsModelInCdimage(joaat(t.model)) then missing[#missing + 1] = ('%s[%d]=%s'):format(item, i, t.model) end
        end
    end
    table.sort(missing)
    print(('[d11_ptrunk] /ptrunkmodels: %d de %d modelos nao existem: %s'):format(#missing, total, table.concat(missing, ', ')))
    notify(('%d de %d modelos do mapa não existem. Detalhes no F8.'):format(#missing, total), #missing > 0 and 'error' or 'success')
end, false)

-- /ptrunklight: no modo fisico liga/desliga a luz (o botao Luz da barra); na calibracao de luz, sai dela.
RegisterCommand('ptrunklight', function()
    if Light.active then closeLight() return end
    if not PT.ModeActive() then notify('Abra o porta-malas primeiro.', 'error') return end
    local on = PT.EditToggle('light')
    notify(on and 'Luz do porta-malas ligada.' or 'Luz do porta-malas desligada.')
end, false)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if Calib.active or Pivot.active or Light.active then
        PT.DestroyTrunkCamera(true)
        setPed(false)
        closeDoor()
    end
end)
