-- d11_ptrunk (cliente): a fisica dos objetos no porta-malas (fase 3).
-- Porte LITERAL do motor do velocity-physicaltrunk (D12, client/main.lua 2916-5036, origin/main 04d4f68c6):
-- gravidade, colisao por footprint (caixa explicita > hull do propbrowser > raycast > caixa do modelo), empilhar,
-- estabilidade por face (tombar/deitar), balanco ao assentar, paredes da area util e persistencia da pose assentada.
-- So o cabecalho abaixo e novo: liga o motor ao d11_ptrunk (cena, arraste/teclado do client/edit.lua, gravacao da
-- pose). Ajustes de comportamento vao em Config.PhysicsOverrides (config.lua), nunca editando o motor.

-- ------------------------------------------------------------------ ligacao com o d11_ptrunk
-- State: o carro do modo fisico. MoveMode/Drag: o objeto que o jogador segura (o motor nao mexe nele).
local State = { active = false, vehicle = nil, scene = nil }
local MoveMode = { active = false, slot = nil, instanceId = nil, dirty = false, inFlight = false, dragging = false }
local Drag = { active = false, slot = nil, instanceId = nil, moved = false }
PT.PhysMoveMode, PT.PhysDrag = MoveMode, Drag

PT.VisualPhysicsGlobalStateKey = 'd11PtrunkPhysicsEnabled'
PT.VisualPhysicsState = {
    velocities = {}, angular = {}, settled = {}, lastStepAt = 0, lastPersistAt = 0, dirty = {}, persistSeq = 0,
    footprintCache = {}, footprintPending = {}, settleCounters = {}, stackSupports = {}, playerMovedUntil = {},
}

local function visualKey(slot, instanceId)
    return ('%s|%s'):format(tostring(tonumber(slot) or 0), tostring(instanceId or ''))
end

local function normalizeAngle180(value)
    local angle = tonumber(value) or 0.0
    while angle > 180.0 do angle = angle - 360.0 end
    while angle < -180.0 do angle = angle + 360.0 end
    return angle
end

local function clampPointToPolygon(points, x, y) return PT.ClampToArea(points, x, y) end
local function isPointInsidePolygon(points, x, y)
    if not points or #points < 3 then return true end
    return PT.InsidePolygon(points, x, y)
end

--- Altura do fundo do porta-malas (z do perfil de area util).
local function getPivotBaseZForCurrentVehicle()
    local area = State.scene and State.scene.area
    if area and tonumber(area.z) then return tonumber(area.z) end
    return tonumber(Config.VisualPlacement and Config.VisualPlacement.fixedZ) or 0.28
end

--- Caixa e poligono da area util do carro (buildVehiclePlacementContext da D12).
local function buildVehiclePlacementContext(vehicle)
    local placement = Config.VisualPlacement or {}
    local minX, maxX = tonumber(placement.minX) or -0.55, tonumber(placement.maxX) or 0.55
    local minY, maxY = tonumber(placement.minY) or -2.10, tonumber(placement.maxY) or -0.35
    local access = vehicle and PT.AccessData(vehicle) or nil
    local area = State.scene and State.scene.area or (vehicle and PT.AreaOf(vehicle))
    local areaPoints = area and area.areaPoints or nil
    if areaPoints and #areaPoints >= 3 then
        local x0, x1, y0, y1 = 1e9, -1e9, 1e9, -1e9
        for _, p in ipairs(areaPoints) do
            x0, x1 = math.min(x0, p.x), math.max(x1, p.x)
            y0, y1 = math.min(y0, p.y), math.max(y1, p.y)
        end
        if x0 < x1 and y0 < y1 then minX, maxX, minY, maxY = x0, x1, y0, y1 end
    elseif access and access.access == 'front' then
        minY, maxY = math.abs(maxY), math.abs(tonumber(placement.minY) or -2.10)
    end
    return { minX = minX, maxX = maxX, minY = minY, maxY = maxY, areaPoints = areaPoints,
        access = access and access.access or 'rear' }
end

--- Os objetos da cena do modo fisico, no formato do motor ({ entity, scale, item = { slot, instanceId, visual* } }).
PT.GetVisualProps = function()
    local list = {}
    if State.scene then
        for _, rec in pairs(State.scene.props) do
            if rec.entity and rec.item then list[#list + 1] = rec end
        end
        table.sort(list, function(a, b) return (a.item.slot or 0) < (b.item.slot or 0) end)
    end
    return list
end

--- Liga o motor a cena do carro do modo fisico; PhysicsEnd grava o que falta e desliga.
function PT.PhysicsBegin(scene)
    State.active, State.vehicle, State.scene = true, scene.vehicle, scene
    local S = PT.VisualPhysicsState
    S.velocities, S.angular, S.settled, S.dirty, S.stackSupports, S.playerMovedUntil = {}, {}, {}, {}, {}, {}
    S.footprintCache, S.footprintPending, S.settleCounters = {}, {}, {}
    MoveMode.active, Drag.active = false, false
end

--- Objeto que acabou de aparecer (placeVisualPropsInsideTrunk da D12): com pose salva entra assentado, sem cair de
--- novo; sem pose cai do spawnLift e balanca ao assentar (o que deita os itens altos).
function PT.PhysicsSpawned(prop, saved)
    local key = visualKey(prop.item.slot, prop.item.instanceId)
    local S = PT.VisualPhysicsState
    if saved then
        S.settled[key], S.velocities[key] = true, 0.0
        S.angular[key] = { yaw = 0.0, pitch = 0.0, roll = 0.0 }
        prop.item._ptPhysicsNeedsWobble = nil
    else
        S.settled[key] = nil
        prop.item._ptPhysicsNeedsWobble = true
    end
end

function PT.PhysicsEnd()
    if not State.active then return end
    if PT.VisualPhysicsEnabled() then PT.FlushSettledVisualPhysics(true) end
    State.active, State.vehicle, State.scene = false, nil, nil
    MoveMode.active, Drag.active = false, false
end

-- ------------------------------------------------------------------ motor da D12 (literal)
PT.GetVisualPropRotatedPoint = function(lx, ly, lz, yaw, pitch, roll)
    local yawRad = math.rad(tonumber(yaw) or 0.0)
    local pitchRad = math.rad(tonumber(pitch) or 0.0)
    local rollRad = math.rad(tonumber(roll) or 0.0)
    local sinYaw, cosYaw = math.sin(yawRad), math.cos(yawRad)
    local sinPitch, cosPitch = math.sin(pitchRad), math.cos(pitchRad)
    local sinRoll, cosRoll = math.sin(rollRad), math.cos(rollRad)
    local x1 = tonumber(lx) or 0.0
    local y1 = (cosPitch * (tonumber(ly) or 0.0)) - (sinPitch * (tonumber(lz) or 0.0))
    local z1 = (sinPitch * (tonumber(ly) or 0.0)) + (cosPitch * (tonumber(lz) or 0.0))
    local x2 = (cosRoll * x1) + (sinRoll * z1)
    local y2 = y1
    local z2 = (-sinRoll * x1) + (cosRoll * z1)
    local fx = (cosYaw * x2) - (sinYaw * y2)
    local fy = (sinYaw * x2) + (cosYaw * y2)
    return fx, fy, z2
end

PT.GetPropBrowserPivotOffset = function(item, scale, yaw, pitch, roll)
    local offsets = PT.GetPropBrowserOffsets and PT.GetPropBrowserOffsets(item) or nil
    if type(offsets) ~= 'table' then return 0.0, 0.0, 0.0 end
    local propScale = tonumber(scale) or 1.0
    local px = (tonumber(offsets.px) or 0.0) * propScale
    local py = (tonumber(offsets.py) or 0.0) * propScale
    local pz = (tonumber(offsets.pz) or 0.0) * propScale
    if px == 0.0 and py == 0.0 and pz == 0.0 then return 0.0, 0.0, 0.0 end
    return PT.GetVisualPropRotatedPoint(px, py, pz, yaw, pitch, roll)
end

PT.GetVisualPropColliderAnchor = function(prop, x, y, z, yaw, pitch, roll)
    local anchorX = tonumber(x) or 0.0
    local anchorY = tonumber(y) or 0.0
    local anchorZ = tonumber(z) or 0.0
    if prop and prop.item and PT.GetPropBrowserPivotOffset then
        local ox, oy, oz = PT.GetPropBrowserPivotOffset(prop.item, prop.scale, yaw, pitch, roll)
        anchorX = anchorX - (tonumber(ox) or 0.0)
        anchorY = anchorY - (tonumber(oy) or 0.0)
        anchorZ = anchorZ - (tonumber(oz) or 0.0)
    end
    return anchorX, anchorY, anchorZ
end

PT.BuildConvexFootprintHull = function(points)
    if not points or #points < 3 then return points end

    local unique = {}
    for _, point in ipairs(points) do
        local px = tonumber(point and point.x)
        local py = tonumber(point and point.y)
        if px and py then
            local duplicate = false
            for _, existing in ipairs(unique) do
                if math.abs(existing.x - px) < 0.000001 and math.abs(existing.y - py) < 0.000001 then
                    duplicate = true
                    break
                end
            end
            if not duplicate then
                unique[#unique + 1] = { x = px, y = py }
            end
        end
    end

    if #unique < 3 then return unique end

    table.sort(unique, function(a, b)
        if math.abs(a.x - b.x) > 0.000001 then
            return a.x < b.x
        end
        return a.y < b.y
    end)

    local function cross(o, a, b)
        return ((a.x - o.x) * (b.y - o.y)) - ((a.y - o.y) * (b.x - o.x))
    end

    local lower = {}
    for _, point in ipairs(unique) do
        while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], point) <= 0.000001 do
            lower[#lower] = nil
        end
        lower[#lower + 1] = point
    end

    local upper = {}
    for i = #unique, 1, -1 do
        local point = unique[i]
        while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], point) <= 0.000001 do
            upper[#upper] = nil
        end
        upper[#upper + 1] = point
    end

    lower[#lower] = nil
    upper[#upper] = nil
    for _, point in ipairs(upper) do
        lower[#lower + 1] = point
    end

    return #lower >= 3 and lower or unique
end

-- Converte um ponto world para o espaço local do veículo.
-- GetEntityMatrix retorna: rightVector, forwardVector, upVector, position
local function worldToVehicleLocal(vehicle, wx, wy, wz)
    local right, fwd, up, vpos = GetEntityMatrix(vehicle)
    local dx = wx - vpos.x
    local dy = wy - vpos.y
    local dz = wz - vpos.z
    return
        (dx * right.x) + (dy * right.y) + (dz * right.z),
        (dx * fwd.x)   + (dy * fwd.y)   + (dz * fwd.z),
        (dx * up.x)    + (dy * up.y)    + (dz * up.z)
end

-- Chave de cache: prop key + bucket de rotação (cada 5 graus).
local function footprintCacheKey(key, pitch, roll, yaw)
    local function bucket(v) return math.floor(((tonumber(v) or 0.0) + 2.5) / 5.0) * 5 end
    return key .. '_p' .. bucket(pitch) .. '_r' .. bucket(roll) .. '_y' .. bucket(yaw)
end

-- Dispara uma amostragem de footprint via raycast em thread separada.
-- Liga colisão temporariamente → 5x5 raycasts de cima pra baixo → desliga colisão → armazena hull.
PT.QueueRaycastFootprintSample = function(prop, vehicle, key, pitch, roll, yaw)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then return end
    if not vehicle or not DoesEntityExist(vehicle) then return end
    local cacheKey = footprintCacheKey(key, pitch, roll, yaw)
    local ps = PT.VisualPhysicsState
    if ps.footprintCache[cacheKey] then return end
    if ps.footprintPending[cacheKey] then return end
    ps.footprintPending[cacheKey] = true

    local entity = prop.entity
    local scale  = tonumber(prop.scale) or 1.0

    CreateThread(function()
        Wait(220) -- prop termina de assentar

        if not DoesEntityExist(entity) or not DoesEntityExist(vehicle) then
            ps.footprintPending[cacheKey] = nil
            return
        end

        local minDim, maxDim = GetModelDimensions(GetEntityModel(entity))
        if not minDim or not maxDim then
            ps.footprintPending[cacheKey] = nil
            return
        end

        local mnX = minDim.x * scale
        local mnY = minDim.y * scale
        local mxX = maxDim.x * scale
        local mxY = maxDim.y * scale
        local mnZ = minDim.z * scale
        local mxZ = maxDim.z * scale
        local above = mxZ + 0.25
        local below = mnZ - 0.25

        -- Liga colisão brevemente para os raycasts baterem na entidade.
        SetEntityCollision(entity, true, true)
        Wait(0)

        if not DoesEntityExist(entity) then
            ps.footprintPending[cacheKey] = nil
            return
        end

        local handles = {}
        local gridN = 5
        for ix = 0, gridN - 1 do
            for iy = 0, gridN - 1 do
                local lx = mnX + ((mxX - mnX) * (ix / (gridN - 1)))
                local ly = mnY + ((mxY - mnY) * (iy / (gridN - 1)))
                local startW = GetOffsetFromEntityInWorldCoords(entity, lx, ly, above)
                local endW   = GetOffsetFromEntityInWorldCoords(entity, lx, ly, below)
                handles[#handles + 1] = {
                    handle = StartShapeTestRay(startW.x, startW.y, startW.z, endW.x, endW.y, endW.z, 16, entity, 0),
                    entity = entity
                }
            end
        end

        -- Coleta resultados (espera até todos finalizarem, máx 6 frames).
        local hitPoints = {}
        local maxFrames = 6
        local frame = 0
        local pending = {}
        for i = 1, #handles do pending[i] = true end

        while frame < maxFrames do
            local anyPending = false
            for i, entry in ipairs(handles) do
                if pending[i] then
                    local retval, hit, endCoords, _, hitEnt = GetShapeTestResult(entry.handle)
                    if retval ~= 0 then
                        pending[i] = nil
                        if hit == 1 and hitEnt == entry.entity then
                            hitPoints[#hitPoints + 1] = { x = endCoords.x, y = endCoords.y, z = endCoords.z }
                        end
                    else
                        anyPending = true
                    end
                end
            end
            if not anyPending then break end
            frame = frame + 1
            Wait(0)
        end

        -- Desliga colisão imediatamente após coletar os resultados.
        if DoesEntityExist(entity) then
            local nativeColl = (Config.VisualPropPhysics and Config.VisualPropPhysics.nativeCollision == true)
                and (PT.VisualPhysicsEnabled and PT.VisualPhysicsEnabled() or false)
            SetEntityCollision(entity, nativeColl, nativeColl)
        end

        -- Converte hits para espaço local do veículo e projeta em XY.
        local localPoints = {}
        if DoesEntityExist(vehicle) then
            for _, wp in ipairs(hitPoints) do
                local lx, ly = worldToVehicleLocal(vehicle, wp.x, wp.y, wp.z)
                localPoints[#localPoints + 1] = { x = lx, y = ly }
            end
        end

        local hull = (#localPoints >= 3) and PT.BuildConvexFootprintHull(localPoints) or nil
        if hull and prop and prop.item and DoesEntityExist(entity) then
            local item = prop.item
            local anchorX, anchorY = PT.GetVisualPropColliderAnchor(
                prop,
                tonumber(item.visualX) or 0.0,
                tonumber(item.visualY) or 0.0,
                tonumber(item.visualZ) or 0.0,
                yaw,
                pitch,
                roll
            )
            local relativeHull = {}
            for _, point in ipairs(hull) do
                relativeHull[#relativeHull + 1] = {
                    x = (tonumber(point.x) or 0.0) - anchorX,
                    y = (tonumber(point.y) or 0.0) - anchorY
                }
            end
            relativeHull._relativeToAnchor = true
            hull = relativeHull
        end
        ps.footprintCache[cacheKey] = hull or false -- false = tentou mas sem hits suficientes
        ps.footprintPending[cacheKey] = nil
    end)
end

if not PT.ApplyPropBrowserPivotOffset then
    PT.ApplyPropBrowserPivotOffset = function(item, scale, x, y, z, yaw, pitch, roll)
        local ox, oy, oz = PT.GetPropBrowserPivotOffset(item, scale, yaw, pitch, roll)
        return (tonumber(x) or 0.0) - ox, (tonumber(y) or 0.0) - oy, (tonumber(z) or 0.0) - oz
    end
end

local function applyPropLocalTransform(propOrEntity, localX, localY, localZ, localYaw, localPitch, localRoll)
    local propEntity = propOrEntity
    local propItem = nil
    local propScale = nil
    if type(propOrEntity) == 'table' then
        propEntity = propOrEntity.entity
        propItem = propOrEntity.item
        propScale = tonumber(propOrEntity.scale)
    end
    if not propEntity or not DoesEntityExist(propEntity) or not State.vehicle or not DoesEntityExist(State.vehicle) then return end
    localX = tonumber(localX) or 0.0
    localY = tonumber(localY) or -1.10
    localZ = tonumber(localZ) or 0.28
    localYaw = tonumber(localYaw) or 0.0
    localPitch = tonumber(localPitch) or 0.0
    localRoll = tonumber(localRoll) or 0.0
    if localX ~= localX or localY ~= localY or localZ ~= localZ or localYaw ~= localYaw or localPitch ~= localPitch or localRoll ~= localRoll then return end
    -- d11_ptrunk: pitch exato em +-90 deixava a matriz do objeto NaN (invisivel); PT.SafePitch em client/props.lua.
    localPitch = PT.SafePitch(localPitch)
    if propItem and PT.ApplyPropBrowserPivotOffset then
        localX, localY, localZ = PT.ApplyPropBrowserPivotOffset(
            propItem,
            propScale,
            localX,
            localY,
            localZ,
            localYaw,
            localPitch,
            localRoll
        )
    end
    AttachEntityToEntity(
        propEntity,
        State.vehicle,
        0,
        localX,
        localY,
        localZ,
        localPitch,
        localRoll,
        localYaw,
        false,
        false,
        false,
        false,
        2,
        true
    )
    FreezeEntityPosition(propEntity, true)
    local physicsCfg = Config.VisualPropPhysics or {}
    SetEntityHasGravity(propEntity, false)
    local manipulating = type(propOrEntity) == 'table'
        and PT.IsVisualPropBeingManipulated
        and PT.IsVisualPropBeingManipulated(propOrEntity)
    local useNativeCollision = not manipulating
        and PT.VisualPhysicsEnabled
        and PT.VisualPhysicsEnabled()
        and physicsCfg.nativeCollision == true
    SetEntityCollision(propEntity, useNativeCollision, useNativeCollision)
end

PT.VisualPhysicsEnabled = function()
    local cfg = Config.VisualPropPhysics or {}
    if cfg.available == false then
        return false
    end
    local global = GlobalState[PT.VisualPhysicsGlobalStateKey]
    if global == nil then
        return cfg.enabledByDefault == true
    end
    return global == true
end

PT.GetVisualPhysicsKey = function(prop)
    local item = prop and prop.item or {}
    return visualKey(item.slot, item.instanceId)
end

PT.IsVisualPropBeingManipulated = function(prop)
    local item = prop and prop.item or {}
    local slot = tonumber(item.slot)
    local instanceId = tostring(item.instanceId or '')
    if MoveMode.active and not MoveMode.dragging and slot == tonumber(MoveMode.slot) and ((MoveMode.instanceId or '') == '' or instanceId == (MoveMode.instanceId or '')) then
        return true
    end
    if Drag.active and slot == tonumber(Drag.slot) and ((Drag.instanceId or '') == '' or instanceId == (Drag.instanceId or '')) then
        return true
    end
    return false
end

PT.IsVisualPropSupportDisabled = function(prop)
    local item = prop and prop.item or {}
    local slot = tonumber(item.slot)
    local instanceId = tostring(item.instanceId or '')
    if MoveMode.active
        and slot == tonumber(MoveMode.slot)
        and ((MoveMode.instanceId or '') == '' or instanceId == (MoveMode.instanceId or ''))
    then
        return MoveMode.dirty == true or MoveMode.inFlight == true
    end
    if Drag.active
        and slot == tonumber(Drag.slot)
        and ((Drag.instanceId or '') == '' or instanceId == (Drag.instanceId or ''))
    then
        return Drag.moved == true
    end
    return false
end

PT.MarkVisualPropPlayerMoved = function(prop, ttlMs)
    if not prop or not prop.item then return end
    local key = PT.GetVisualPhysicsKey and PT.GetVisualPhysicsKey(prop) or nil
    if not key then return end
    PT.VisualPhysicsState.playerMovedUntil = PT.VisualPhysicsState.playerMovedUntil or {}
    PT.VisualPhysicsState.playerMovedUntil[key] = GetGameTimer() + (tonumber(ttlMs) or 1500)
    prop.item._ptPhysicsNeedsWobble = true
    if PT.VisualPhysicsState.settled then
        PT.VisualPhysicsState.settled[key] = nil
    end
end

PT.IsVisualPropPlayerMoved = function(prop)
    local key = PT.GetVisualPhysicsKey and PT.GetVisualPhysicsKey(prop) or nil
    if not key then return false end
    local untilMs = tonumber(PT.VisualPhysicsState.playerMovedUntil and PT.VisualPhysicsState.playerMovedUntil[key]) or 0
    if untilMs <= 0 then return false end
    if GetGameTimer() > untilMs then
        PT.VisualPhysicsState.playerMovedUntil[key] = nil
        return false
    end
    return true
end

PT.FinalizeOtherVisualPropMoves = function(activeProp)
    local activeKey = activeProp and PT.GetVisualPhysicsKey and PT.GetVisualPhysicsKey(activeProp) or nil
    PT.VisualPhysicsState.playerMovedUntil = PT.VisualPhysicsState.playerMovedUntil or {}
    for key in pairs(PT.VisualPhysicsState.playerMovedUntil) do
        if key ~= activeKey then
            PT.VisualPhysicsState.playerMovedUntil[key] = nil
            PT.VisualPhysicsState.velocities[key] = 0.0
            PT.VisualPhysicsState.angular[key] = { yaw = 0.0, pitch = 0.0, roll = 0.0 }
            PT.VisualPhysicsState.settled[key] = true
        end
    end
    for _, prop in ipairs(PT.GetVisualProps and PT.GetVisualProps() or {}) do
        local key = prop and PT.GetVisualPhysicsKey and PT.GetVisualPhysicsKey(prop) or nil
        if key and key ~= activeKey and prop.item then
            prop.item._ptPhysicsNeedsWobble = nil
        end
    end
end

PT.GetVisualPropCollisionRadius = function(prop)
    local cfg = Config.VisualPropPhysics or {}
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return tonumber(cfg.minRadius) or 0.035
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    local scale = tonumber(prop.scale) or 1.0
    local sizeX = math.abs((maxDim.x or 0.0) - (minDim.x or 0.0)) * scale
    local sizeY = math.abs((maxDim.y or 0.0) - (minDim.y or 0.0)) * scale
    local radius = math.max(sizeX, sizeY) * (tonumber(cfg.radiusMultiplier) or 0.34)
    radius = math.max(tonumber(cfg.minRadius) or 0.035, radius)
    radius = math.min(tonumber(cfg.maxRadius) or 0.115, radius)
    return radius
end

PT.GetVisualPropCubeHalfSize = function(prop)
    local ext = PT.GetVisualPropColliderHalfExtents and PT.GetVisualPropColliderHalfExtents(prop) or nil
    if ext then
        return math.max(tonumber(ext.x) or 0.0, tonumber(ext.y) or 0.0, tonumber(ext.z) or 0.0)
    end
    local cfg = Config.VisualPropPhysics or {}
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return (tonumber(cfg.minCubeSize) or 0.08) * 0.5
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then
        return (tonumber(cfg.minCubeSize) or 0.08) * 0.5
    end

    local scale = tonumber(prop.scale) or 1.0
    local sizeX = math.abs((maxDim.x or 0.0) - (minDim.x or 0.0)) * scale
    local sizeY = math.abs((maxDim.y or 0.0) - (minDim.y or 0.0)) * scale
    local sizeZ = math.abs((maxDim.z or 0.0) - (minDim.z or 0.0)) * scale
    local cubeSize = math.max(sizeX, sizeY, sizeZ) * (tonumber(cfg.cubeColliderScale) or 0.72)
    cubeSize = math.max(tonumber(cfg.minCubeSize) or 0.08, cubeSize)
    cubeSize = math.min(tonumber(cfg.maxCubeSize) or 0.32, cubeSize)
    return cubeSize * 0.5
end

PT.GetVisualPropColliderHalfExtents = function(prop)
    local cfg = Config.VisualPropPhysics or {}
    local minSize = tonumber(cfg.minCubeSize) or 0.06
    local maxSize = tonumber(cfg.maxCubeSize) or 0.46
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        local fallback = minSize * 0.5
        return { x = fallback, y = fallback, z = fallback }
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then
        local fallback = minSize * 0.5
        return { x = fallback, y = fallback, z = fallback }
    end

    local scale = tonumber(prop.scale) or 1.0
    local xyScale = tonumber(cfg.cubeColliderScale) or 0.88
    local zScale = tonumber(cfg.colliderZScale) or xyScale
    local sizeX = math.abs((maxDim.x or 0.0) - (minDim.x or 0.0)) * scale * xyScale
    local sizeY = math.abs((maxDim.y or 0.0) - (minDim.y or 0.0)) * scale * xyScale
    local sizeZ = math.abs((maxDim.z or 0.0) - (minDim.z or 0.0)) * scale * zScale
    sizeX = math.max(minSize, math.min(maxSize, sizeX))
    sizeY = math.max(minSize, math.min(maxSize, sizeY))
    sizeZ = math.max(minSize, math.min(maxSize, sizeZ))
    return { x = sizeX * 0.5, y = sizeY * 0.5, z = sizeZ * 0.5 }
end

PT.GetVisualPropColliderRadius = function(prop)
    local cfg = Config.VisualPropPhysics or {}
    local shape = tostring(cfg.colliderShape or 'box')
    if shape == 'cube' then
        return PT.GetVisualPropCubeHalfSize(prop) * 1.414
    end
    if shape == 'box' then
        local ext = PT.GetVisualPropColliderHalfExtents(prop)
        local hx = tonumber(ext and ext.x) or PT.GetVisualPropCubeHalfSize(prop)
        local hy = tonumber(ext and ext.y) or PT.GetVisualPropCubeHalfSize(prop)
        return math.sqrt((hx * hx) + (hy * hy))
    end
    return PT.GetVisualPropCollisionRadius(prop)
end

local function clampFootprintOverrideNumber(value, minValue, maxValue)
    local number = tonumber(value)
    if number == nil or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end
    if number < minValue then return minValue end
    if number > maxValue then return maxValue end
    return number
end

local function getPropFootprintOverride(prop)
    local item = prop and prop.item or nil
    local raw = PT.GetPropBrowserFootprint and PT.GetPropBrowserFootprint(item) or nil
    if type(raw) ~= 'table' then return nil end

    local override = {
        scaleX = clampFootprintOverrideNumber(raw.scaleX, 0.35, 1.80),
        scaleY = clampFootprintOverrideNumber(raw.scaleY, 0.35, 1.80),
        padding = clampFootprintOverrideNumber(raw.padding, -0.08, 0.12),
        bottomClearance = clampFootprintOverrideNumber(raw.bottomClearance, -0.06, 0.06),
        meshOvershootScale = clampFootprintOverrideNumber(raw.meshOvershootScale, 0.65, 1.30),
        -- Pad aditivo (metros) no topo de suporte do prop. Sobe supportTopRelZ/topRelZ
        -- para que itens empilhados em cima assentem na altura real da malha visual,
        -- quando o topo do model bounds e mais baixo que o mesh (ex: toolbox deitado).
        -- Nao afeta o chao/repouso do proprio prop (esse usa o extent de baixo).
        stackTopPad = clampFootprintOverrideNumber(raw.stackTopPad, 0.0, 0.12)
    }

    -- Estabilidade por item (controle no propbrowser; ver ApplyVisualPropStability):
    --   stabilityMode 'lock' = nunca tomba/reorienta (mantem a pose configurada).
    --   stabilityMode 'lay'  = sempre deita na face mais baixa.
    --   ausente/'auto'       = heuristica global (onFace/tooTall).
    -- faceTol/standFactor sobrescrevem os globais (stableFaceTiltTolerance/stableStandFactor).
    local stabilityMode = type(raw.stabilityMode) == 'string' and raw.stabilityMode:lower() or nil
    if stabilityMode == 'lock' or stabilityMode == 'lay' then
        override.stabilityMode = stabilityMode
    end
    override.stabilityFaceTol = clampFootprintOverrideNumber(raw.faceTol, 2.0, 45.0)
    override.stabilityStandFactor = clampFootprintOverrideNumber(raw.standFactor, 1.05, 4.0)

    -- Caixa de colisao explicita por item (OBB). Quando presente, vira a fonte unica
    -- de geometria para footprint (XY) e extents verticais (Z), ignorando o hull de
    -- raycast que distorce props rotacionados (ex: toolbox em pitch=-90).
    local boxRaw = raw.box
    if type(boxRaw) == 'table' then
        local sx = clampFootprintOverrideNumber(boxRaw.sx, 0.01, 1.0)
        local sy = clampFootprintOverrideNumber(boxRaw.sy, 0.01, 1.0)
        local sz = clampFootprintOverrideNumber(boxRaw.sz, 0.01, 1.0)
        local useModelBounds = boxRaw.useModelBounds == true
        if useModelBounds or sx ~= nil or sy ~= nil or sz ~= nil then
            override.box = {
                useModelBounds = useModelBounds,
                sx = sx,
                sy = sy,
                sz = sz,
                inflate = clampFootprintOverrideNumber(boxRaw.inflate, 0.50, 1.60) or 1.0,
                cx = clampFootprintOverrideNumber(boxRaw.cx, -0.5, 0.5) or 0.0,
                cy = clampFootprintOverrideNumber(boxRaw.cy, -0.5, 0.5) or 0.0,
                cz = clampFootprintOverrideNumber(boxRaw.cz, -0.5, 0.5) or 0.0
            }
        end
    end

    -- Hull baked por malha (escaneado no propbrowser). Fonte mais precisa que AABB.
    -- Prioridade: box override > hull baked > raycast cache > AABB.
    local hullRaw = raw.hull
    if type(hullRaw) == 'table' and type(hullRaw.points) == 'table' and #hullRaw.points >= 4 then
        local hullPoints = {}
        for _, pt in ipairs(hullRaw.points) do
            if type(pt) == 'table' then
                local px = tonumber(pt[1])
                local py = tonumber(pt[2])
                local pz = tonumber(pt[3])
                if px and py and pz then
                    hullPoints[#hullPoints + 1] = { x = px, y = py, z = pz }
                end
            end
        end
        if #hullPoints >= 4 then
            override.hull = {
                points = hullPoints,
                minZ = tonumber(hullRaw.minZ),
                maxZ = tonumber(hullRaw.maxZ)
            }
        end
    end

    if override.scaleX == nil and override.scaleY == nil and override.padding == nil
        and override.bottomClearance == nil and override.meshOvershootScale == nil
        and override.box == nil and override.hull == nil and override.stackTopPad == nil
        and override.stabilityMode == nil and override.stabilityFaceTol == nil
        and override.stabilityStandFactor == nil then
        return nil
    end

    return override
end

-- Calcula os limites locais (min/max em XYZ, ja escalados pela escala do prop) da
-- caixa de colisao explicita do item. Parte do model bounds, aplica override por eixo
-- (sx/sy/sz como meia-extensao em metros), inflate uniforme e offset de centro.
-- Retorna nil se o item nao tiver caixa configurada.
local function getExplicitColliderLocalBounds(prop, override)
    override = override or getPropFootprintOverride(prop)
    local box = override and override.box or nil
    if not box or not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return nil
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then return nil end

    local scale = tonumber(prop.scale) or 1.0
    local minX, maxX = (minDim.x or 0.0) * scale, (maxDim.x or 0.0) * scale
    local minY, maxY = (minDim.y or 0.0) * scale, (maxDim.y or 0.0) * scale
    local minZ, maxZ = (minDim.z or 0.0) * scale, (maxDim.z or 0.0) * scale

    local function applyHalf(half, lo, hi)
        if not half then return lo, hi end
        local center = (lo + hi) * 0.5
        return center - half, center + half
    end
    minX, maxX = applyHalf(box.sx, minX, maxX)
    minY, maxY = applyHalf(box.sy, minY, maxY)
    minZ, maxZ = applyHalf(box.sz, minZ, maxZ)

    local inflate = tonumber(box.inflate) or 1.0
    if inflate ~= 1.0 then
        local function applyInflate(lo, hi)
            local center = (lo + hi) * 0.5
            local half = ((hi - lo) * 0.5) * inflate
            return center - half, center + half
        end
        minX, maxX = applyInflate(minX, maxX)
        minY, maxY = applyInflate(minY, maxY)
        minZ, maxZ = applyInflate(minZ, maxZ)
    end

    local cx = tonumber(box.cx) or 0.0
    local cy = tonumber(box.cy) or 0.0
    local cz = tonumber(box.cz) or 0.0
    return {
        minX = minX + cx, maxX = maxX + cx,
        minY = minY + cy, maxY = maxY + cy,
        minZ = minZ + cz, maxZ = maxZ + cz
    }
end

local function applyFootprintPointOverride(points, anchorX, anchorY, prop)
    local override = getPropFootprintOverride(prop)
    if not override or type(points) ~= 'table' or #points < 3 then
        return points
    end

    local scaleX = override.scaleX or 1.0
    local scaleY = override.scaleY or 1.0
    local padding = override.padding or 0.0
    if scaleX == 1.0 and scaleY == 1.0 and padding == 0.0 then
        return points
    end

    local adjusted = {}
    for _, point in ipairs(points) do
        local dx = ((tonumber(point.x) or 0.0) - anchorX) * scaleX
        local dy = ((tonumber(point.y) or 0.0) - anchorY) * scaleY
        if padding ~= 0.0 then
            local len = math.sqrt((dx * dx) + (dy * dy))
            if len > 0.0001 then
                local nextLen = math.max(0.003, len + padding)
                dx = dx * (nextLen / len)
                dy = dy * (nextLen / len)
            end
        end
        adjusted[#adjusted + 1] = {
            x = anchorX + dx,
            y = anchorY + dy
        }
    end

    return adjusted
end

local function applyFootprintPaddingOnly(points, anchorX, anchorY, prop)
    local override = getPropFootprintOverride(prop)
    local padding = override and override.padding or 0.0
    if padding == 0.0 or type(points) ~= 'table' or #points < 3 then
        return points
    end

    local adjusted = {}
    for _, point in ipairs(points) do
        local dx = (tonumber(point.x) or 0.0) - anchorX
        local dy = (tonumber(point.y) or 0.0) - anchorY
        local len = math.sqrt((dx * dx) + (dy * dy))
        if len > 0.0001 then
            local nextLen = math.max(0.003, len + padding)
            dx = dx * (nextLen / len)
            dy = dy * (nextLen / len)
        end
        adjusted[#adjusted + 1] = {
            x = anchorX + dx,
            y = anchorY + dy
        }
    end

    return adjusted
end

PT.GetVisualPropBottomClearance = function(prop, cfg)
    cfg = cfg or Config.VisualPropPhysics or {}
    local baseClearance = tonumber(cfg.bottomClearance) or 0.012
    local footprintOverride = getPropFootprintOverride(prop)
    if footprintOverride and footprintOverride.bottomClearance ~= nil then
        return footprintOverride.bottomClearance
    end
    if cfg.autoThinPropClearance == false or not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return baseClearance
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then
        return baseClearance
    end

    local scale = tonumber(prop.scale) or 1.0
    local sizeX = math.abs((maxDim.x or 0.0) - (minDim.x or 0.0)) * scale
    local sizeY = math.abs((maxDim.y or 0.0) - (minDim.y or 0.0)) * scale
    local sizeZ = math.abs((maxDim.z or 0.0) - (minDim.z or 0.0)) * scale
    local thinSize = math.min(sizeX, sizeY, sizeZ)
    local broadSize = math.max(sizeX, sizeY, sizeZ)
    local thinThreshold = tonumber(cfg.thinPropHeightThreshold) or 0.035
    local veryThinThreshold = tonumber(cfg.veryThinPropHeightThreshold) or 0.018
    local broadMin = tonumber(cfg.thinPropBroadMinSize) or 0.090

    if thinSize > 0.0 and thinSize <= veryThinThreshold and broadSize >= broadMin then
        return math.max(baseClearance, tonumber(cfg.veryThinPropBottomClearance) or 0.032)
    end

    if thinSize > 0.0 and thinSize <= thinThreshold and broadSize >= broadMin then
        return math.max(baseClearance, tonumber(cfg.thinPropBottomClearance) or 0.022)
    end

    return baseClearance
end

PT.GetVisualPropFloorOriginZ = function(prop, floorZ, pitch, roll, yaw)
    local cfg = Config.VisualPropPhysics or {}
    floorZ = tonumber(floorZ) or getPivotBaseZForCurrentVehicle()
    if cfg.useModelBottomOffset == false or not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return floorZ
    end

    yaw = tonumber(yaw) or (prop and prop.item and tonumber(prop.item.visualYaw)) or 0.0
    local bottomOffset = select(1, PT.GetVisualPropVerticalExtents(prop, pitch, roll, yaw))
    local pivotOffsetZ = 0.0
    if prop and prop.item and PT.GetPropBrowserPivotOffset then
        pivotOffsetZ = tonumber(select(3, PT.GetPropBrowserPivotOffset(prop.item, prop.scale, yaw, pitch, roll))) or 0.0
    end
    return floorZ - bottomOffset + pivotOffsetZ + PT.GetVisualPropBottomClearance(prop, cfg)
end

PT.GetVisualPropVerticalExtents = function(prop, pitch, roll, yaw)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return 0.0, 0.08
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then
        return 0.0, 0.08
    end

    local scale = tonumber(prop.scale) or 1.0

    -- Hull baked: itera pontos 3D reais e acha min/max Z rotacionados para a pose atual.
    local hullOvr = getPropFootprintOverride(prop)
    local bakedHullV = hullOvr and hullOvr.hull or nil
    if bakedHullV and bakedHullV.points and #bakedHullV.points >= 4 then
        local minRZ, maxRZ = 1e9, -1e9
        for _, pt in ipairs(bakedHullV.points) do
            local _, _, rz = PT.GetVisualPropRotatedPoint(
                (tonumber(pt.x) or 0.0) * scale,
                (tonumber(pt.y) or 0.0) * scale,
                (tonumber(pt.z) or 0.0) * scale,
                yaw, pitch, roll
            )
            if rz < minRZ then minRZ = rz end
            if rz > maxRZ then maxRZ = rz end
        end
        -- Inclui os extremos Z armazenados para geometria nao capturada pelo scan topo.
        if bakedHullV.minZ then
            local _, _, rz = PT.GetVisualPropRotatedPoint(0.0, 0.0, bakedHullV.minZ * scale, yaw, pitch, roll)
            if rz < minRZ then minRZ = rz end
        end
        if bakedHullV.maxZ then
            local _, _, rz = PT.GetVisualPropRotatedPoint(0.0, 0.0, bakedHullV.maxZ * scale, yaw, pitch, roll)
            if rz > maxRZ then maxRZ = rz end
        end
        if minRZ ~= 1e9 then
            local overshoot = hullOvr.meshOvershootScale
                or tonumber((Config.VisualPropPhysics or {}).meshOvershootScale)
                or 1.0
            if overshoot > 1.0 and minRZ < 0.0 then minRZ = minRZ * overshoot end
            return minRZ, maxRZ
        end
    end

    local explicit = getExplicitColliderLocalBounds(prop)
    local xs, ys, zs
    if explicit then
        xs = { explicit.minX, explicit.maxX }
        ys = { explicit.minY, explicit.maxY }
        zs = { explicit.minZ, explicit.maxZ }
    else
        xs = { (minDim.x or 0.0) * scale, (maxDim.x or 0.0) * scale }
        ys = { (minDim.y or 0.0) * scale, (maxDim.y or 0.0) * scale }
        zs = { (minDim.z or 0.0) * scale, (maxDim.z or 0.0) * scale }
    end
    local minZ, maxZ = 1e9, -1e9

    for _, lx in ipairs(xs) do
        for _, ly in ipairs(ys) do
            for _, lz in ipairs(zs) do
                local _, _, rotatedZ = PT.GetVisualPropRotatedPoint(lx, ly, lz, yaw, pitch, roll)
                if rotatedZ < minZ then minZ = rotatedZ end
                if rotatedZ > maxZ then maxZ = rotatedZ end
            end
        end
    end

    if minZ == 1e9 then
        return 0.0, 0.08
    end
    -- Escala o extent inferior para compensar o mesh visual ultrapassar o physics bounds.
    -- minZ é negativo (abaixo do centro), então multiplicar por >1 faz o objeto sentar mais alto.
    local footprintOverride = getPropFootprintOverride(prop)
    local overshoot = footprintOverride and footprintOverride.meshOvershootScale
        or tonumber((Config.VisualPropPhysics or {}).meshOvershootScale)
        or 1.0
    if overshoot > 1.0 and minZ < 0.0 then
        minZ = minZ * overshoot
    end
    -- NOTA: o stackTopPad NAO infla o extent aqui de proposito. Inflar o topo subiria
    -- tambem a barra do portao `recIsAbove` (no solver de stack), dificultando o item
    -- de cima ser reconhecido como empilhado. O pad e aplicado direto no candidateFloor
    -- do suporte (ver StepVisualPropPhysics), elevando so a altura de assentamento.
    return minZ, maxZ
end

PT.GetVisualPropPivotRelativeVerticalExtents = function(prop, pitch, roll, yaw)
    local minRelZ, maxRelZ = PT.GetVisualPropVerticalExtents(prop, pitch, roll, yaw)
    local pivotOffsetZ = 0.0
    if prop and prop.item and PT.GetPropBrowserPivotOffset then
        pivotOffsetZ = tonumber(select(3, PT.GetPropBrowserPivotOffset(prop.item, prop.scale, yaw, pitch, roll))) or 0.0
    end
    return (tonumber(minRelZ) or 0.0) - pivotOffsetZ, (tonumber(maxRelZ) or 0.08) - pivotOffsetZ
end

local function refreshRecordSupportExtents(rec)
    if not rec or not rec.prop then return end
    rec.supportBottomRelZ, rec.supportTopRelZ = PT.GetVisualPropPivotRelativeVerticalExtents(
        rec.prop,
        rec.pitch,
        rec.roll,
        rec.yaw
    )
end

PT.GetVisualPropWorldExtents = function(prop, yaw, pitch, roll)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return nil
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then
        return nil
    end

    local scale = tonumber(prop.scale) or 1.0
    local xs = { (minDim.x or 0.0) * scale, (maxDim.x or 0.0) * scale }
    local ys = { (minDim.y or 0.0) * scale, (maxDim.y or 0.0) * scale }
    local zs = { (minDim.z or 0.0) * scale, (maxDim.z or 0.0) * scale }
    local minX, minY, minZ = 1e9, 1e9, 1e9
    local maxX, maxY, maxZ = -1e9, -1e9, -1e9

    for _, lx in ipairs(xs) do
        for _, ly in ipairs(ys) do
            for _, lz in ipairs(zs) do
                local rx, ry, rz = PT.GetVisualPropRotatedPoint(lx, ly, lz, yaw, pitch, roll)
                if rx < minX then minX = rx end
                if rx > maxX then maxX = rx end
                if ry < minY then minY = ry end
                if ry > maxY then maxY = ry end
                if rz < minZ then minZ = rz end
                if rz > maxZ then maxZ = rz end
            end
        end
    end

    if minX == 1e9 then return nil end
    return {
        widthX = math.abs(maxX - minX),
        widthY = math.abs(maxY - minY),
        height = math.abs(maxZ - minZ)
    }
end

PT.FindVisualPropStableOrientation = function(prop, yaw, pitch, roll)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then return nil end
    local cfg = Config.VisualPropPhysics or {}
    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    local scale = tonumber(prop.scale) or 1.0
    local sizeX = minDim and maxDim and math.abs(((maxDim.x or 0.0) - (minDim.x or 0.0)) * scale) or 0.0
    local sizeY = minDim and maxDim and math.abs(((maxDim.y or 0.0) - (minDim.y or 0.0)) * scale) or 0.0
    local sizeZ = minDim and maxDim and math.abs(((maxDim.z or 0.0) - (minDim.z or 0.0)) * scale) or 0.0
    local longest = math.max(sizeX, sizeY, sizeZ, 0.001)
    local shortest = math.max(math.min(sizeX > 0.0 and sizeX or longest, sizeY > 0.0 and sizeY or longest, sizeZ > 0.0 and sizeZ or longest), 0.001)
    local isThinLong = (longest / shortest) >= (tonumber(cfg.thinLongStableRatio) or 3.0)
    local candidates = {
        { pitch = 0.0, roll = 0.0 },
        { pitch = 90.0, roll = 0.0 },
        { pitch = -90.0, roll = 0.0 },
        { pitch = 0.0, roll = 90.0 },
        { pitch = 0.0, roll = -90.0 },
        { pitch = 90.0, roll = 90.0 },
        { pitch = 90.0, roll = -90.0 },
        { pitch = -90.0, roll = 90.0 },
        { pitch = -90.0, roll = -90.0 },
        { pitch = 180.0, roll = 0.0 },
        { pitch = 0.0, roll = 180.0 }
    }
    if not isThinLong then
        table.insert(candidates, 1, { pitch = normalizeAngle180(pitch), roll = normalizeAngle180(roll) })
    else
        candidates[#candidates + 1] = { pitch = 180.0, roll = 90.0 }
        candidates[#candidates + 1] = { pitch = 180.0, roll = -90.0 }
        candidates[#candidates + 1] = { pitch = 90.0, roll = 180.0 }
        candidates[#candidates + 1] = { pitch = -90.0, roll = 180.0 }
    end
    local best = nil
    for _, candidate in ipairs(candidates) do
        local ext = PT.GetVisualPropWorldExtents(prop, yaw, candidate.pitch, candidate.roll)
        if ext then
            local height = tonumber(ext.height) or 999.0
            local base = math.max(tonumber(ext.widthX) or 0.0, tonumber(ext.widthY) or 0.0)
            local baseWeight = isThinLong
                and (tonumber(cfg.thinLongStableBaseWeight) or 0.0)
                or (tonumber(cfg.stableOrientationBaseWeight) or 0.06)
            -- Desempate por proximidade angular: peso muito pequeno, só rompe empates reais
            -- (ex: roll=+90° vs roll=-90° quando item está em -70°). Não deve sobrepor
            -- diferenças reais de altura entre poses.
            local angularDist = math.abs(normalizeAngle180(candidate.pitch - pitch))
                              + math.abs(normalizeAngle180(candidate.roll  - roll))
            local score = height - (base * baseWeight) + (angularDist * 0.0002)
            if not best or score < best.score then
                best = {
                    pitch = candidate.pitch,
                    roll = candidate.roll,
                    height = height,
                    base = base,
                    score = score
                }
            end
        end
    end
    return best
end

PT.GetVisualPropRestPitch = function(prop, currentPitch)
    local cfg = Config.VisualPropPhysics or {}
    currentPitch = normalizeAngle180(tonumber(currentPitch) or 0.0)
    local layPitch = math.abs(tonumber(cfg.tallPropPitch) or tonumber(cfg.restPitch) or 90.0)
    if cfg.preserveExistingRotation ~= false and math.abs(currentPitch) >= (tonumber(cfg.preservePitchThreshold) or 5.0) then
        return currentPitch
    end
    if cfg.layAllProps == true then
        return currentPitch < -45.0 and -layPitch or layPitch
    end
    if cfg.autoLayTallProps == false or not prop or not prop.entity or not DoesEntityExist(prop.entity) then
        return currentPitch
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then
        return currentPitch
    end

    local scale = tonumber(prop.scale) or 1.0
    local sizeX = math.abs((maxDim.x or 0.0) - (minDim.x or 0.0)) * scale
    local sizeY = math.abs((maxDim.y or 0.0) - (minDim.y or 0.0)) * scale
    local sizeZ = math.abs((maxDim.z or 0.0) - (minDim.z or 0.0)) * scale
    local flatSize = math.max(0.001, sizeX, sizeY)
    local tallRatio = tonumber(cfg.tallPropRatio) or 1.35
    if sizeZ <= flatSize * tallRatio then
        return currentPitch
    end

    return currentPitch < -45.0 and -layPitch or layPitch
end

PT.SetPropPhysicsLocal = function(prop, x, y, z, yaw, pitch, roll, pctx)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then return end
    x = math.max(pctx.minX, math.min(pctx.maxX, tonumber(x) or 0.0))
    y = math.max(pctx.minY, math.min(pctx.maxY, tonumber(y) or 0.0))
    x, y = clampPointToPolygon(pctx.areaPoints, x, y)
    z = tonumber(z) or getPivotBaseZForCurrentVehicle()

    prop.item = prop.item or {}
    prop.item.visualX = x
    prop.item.visualY = y
    prop.item.visualZ = z
    prop.item._ptPhysicsRuntimeZ = z
    prop.item.visualYaw = tonumber(yaw) or tonumber(prop.item.visualYaw) or 0.0
    prop.item.visualPitch = tonumber(pitch) or tonumber(prop.item.visualPitch) or 0.0
    prop.item.visualRoll = tonumber(roll) or tonumber(prop.item.visualRoll) or 0.0

    applyPropLocalTransform(prop, x, y, z, prop.item.visualYaw, prop.item.visualPitch, prop.item.visualRoll)
end

PT.BuildVisualPhysicsRecord = function(prop, pctx, floorZ, cfg)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) or not prop.item then return nil end
    cfg = cfg or Config.VisualPropPhysics or {}
    local item = prop.item
    local fallbackY = (pctx and pctx.access == 'front') and 1.10 or -1.10
    local x = tonumber(item.visualX) or 0.0
    local y = tonumber(item.visualY) or fallbackY
    local pitch = tonumber(item.visualPitch) or 0.0
    local roll = tonumber(item.visualRoll) or 0.0
    local yaw = tonumber(item.visualYaw) or 0.0
    local originFloorZ = PT.GetVisualPropFloorOriginZ(prop, floorZ, pitch, roll, yaw)
    local manipulating = PT.IsVisualPropBeingManipulated(prop)
    local z = manipulating
        and (tonumber(item.visualZ) or tonumber(item._ptPhysicsRuntimeZ) or originFloorZ)
        or (tonumber(item._ptPhysicsRuntimeZ) or tonumber(item.visualZ) or originFloorZ)
    local radius = PT.GetVisualPropColliderRadius(prop)

    if pctx then
        x = math.max(pctx.minX, math.min(pctx.maxX, x))
        y = math.max(pctx.minY, math.min(pctx.maxY, y))
        x, y = clampPointToPolygon(pctx.areaPoints, x, y)
        x, y = PT.ClampPropInsidePhysicsWalls(pctx, x, y, radius, prop, yaw, pitch, roll)
    end

    local minRelZ, maxRelZ = PT.GetVisualPropVerticalExtents(prop, pitch, roll, yaw)
    local supportMinRelZ, supportMaxRelZ = PT.GetVisualPropPivotRelativeVerticalExtents(prop, pitch, roll, yaw)
    local fpo = getPropFootprintOverride(prop) or {}
    local rec = {
        prop = prop,
        key = PT.GetVisualPhysicsKey(prop),
        x = x,
        y = y,
        z = z,
        floorZ = originFloorZ,
        yaw = yaw,
        pitch = pitch,
        roll = roll,
        bottomRelZ = minRelZ,
        topRelZ = maxRelZ,
        supportBottomRelZ = supportMinRelZ,
        supportTopRelZ = supportMaxRelZ,
        stackTopPad = fpo.stackTopPad,
        stabilityMode = fpo.stabilityMode,
        stabilityFaceTol = fpo.stabilityFaceTol,
        stabilityStandFactor = fpo.stabilityStandFactor,
        footprint = PT.GetVisualPropFootprintPoints(prop, x, y, yaw, pitch, roll),
        restPitch = PT.GetVisualPropRestPitch(prop, pitch),
        radius = radius,
        needsSettleWobble = item._ptPhysicsNeedsWobble == true,
        movable = not manipulating,
        manipulating = manipulating
    }
    return rec
end

PT.GetPhysicsAreaPolygon = function(pctx)
    if pctx and pctx.areaPoints and #pctx.areaPoints >= 3 then
        return pctx.areaPoints
    end
    if not pctx then return nil end
    return {
        { x = pctx.minX, y = pctx.minY },
        { x = pctx.maxX, y = pctx.minY },
        { x = pctx.maxX, y = pctx.maxY },
        { x = pctx.minX, y = pctx.maxY }
    }
end

PT.GetVisualPropFootprintPoints = function(prop, x, y, yaw, pitch, roll)
    if not prop or not prop.entity or not DoesEntityExist(prop.entity) then return nil end
    local anchorX, anchorY = PT.GetVisualPropColliderAnchor(prop, x, y, 0.0, yaw, pitch, roll)

    -- Caixa de colisao explicita por item: fonte unica de geometria. Ignora o hull de
    -- raycast (que distorce props rotacionados) e o model-bounds global; usa os 8
    -- cantos da caixa rotacionados e projetados em XY. O Z usa a mesma caixa em
    -- GetVisualPropVerticalExtents, garantindo XY e Z consistentes (sem interpenetrar).
    local boxOverride = getPropFootprintOverride(prop)
    local boxBounds = boxOverride and boxOverride.box and getExplicitColliderLocalBounds(prop, boxOverride) or nil
    if boxBounds then
        local bxs = { boxBounds.minX, boxBounds.maxX }
        local bys = { boxBounds.minY, boxBounds.maxY }
        local bzs = { boxBounds.minZ, boxBounds.maxZ }
        local boxPoints = {}
        for _, lx in ipairs(bxs) do
            for _, ly in ipairs(bys) do
                for _, lz in ipairs(bzs) do
                    local rotX, rotY = PT.GetVisualPropRotatedPoint(lx, ly, lz, yaw, pitch, roll)
                    boxPoints[#boxPoints + 1] = { x = anchorX + rotX, y = anchorY + rotY }
                end
            end
        end
        if #boxPoints < 3 then return nil end
        return applyFootprintPaddingOnly(PT.BuildConvexFootprintHull(boxPoints), anchorX, anchorY, prop)
    end

    -- Hull baked: pontos 3D em model-space escaneados no propbrowser.
    -- Roda para qualquer orientacao; mais preciso que AABB e disponivel desde o primeiro frame.
    local bakedHull = boxOverride and boxOverride.hull or nil
    if bakedHull and bakedHull.points and #bakedHull.points >= 4 then
        local scale = tonumber(prop.scale) or 1.0
        local hullProj = {}
        for _, pt in ipairs(bakedHull.points) do
            local rotX, rotY = PT.GetVisualPropRotatedPoint(
                (tonumber(pt.x) or 0.0) * scale,
                (tonumber(pt.y) or 0.0) * scale,
                (tonumber(pt.z) or 0.0) * scale,
                yaw, pitch, roll
            )
            hullProj[#hullProj + 1] = { x = anchorX + rotX, y = anchorY + rotY }
        end
        if #hullProj >= 3 then
            return applyFootprintPaddingOnly(PT.BuildConvexFootprintHull(hullProj), anchorX, anchorY, prop)
        end
    end

    -- Se o prop já assentou, tenta usar o hull de raycast cacheado (mais preciso que AABB).
    local propKey = PT.GetVisualPhysicsKey and PT.GetVisualPhysicsKey(prop) or nil
    if propKey and PT.VisualPhysicsState.settled[propKey] == true then
        local cacheKey = footprintCacheKey(propKey, pitch, roll, yaw)
        local cached = PT.VisualPhysicsState.footprintCache[cacheKey]
        if cached and cached ~= false and #cached >= 3 then
            -- Reaplica a posição XY no hull (hull está em coords locais centradas no veículo).
            if cached._relativeToAnchor == true then
                local adjusted = {}
                for _, point in ipairs(cached) do
                    adjusted[#adjusted + 1] = {
                        x = anchorX + (tonumber(point.x) or 0.0),
                        y = anchorY + (tonumber(point.y) or 0.0)
                    }
                end
                return applyFootprintPointOverride(adjusted, anchorX, anchorY, prop)
            end
            return applyFootprintPointOverride(cached, anchorX, anchorY, prop)
        end
        -- Cache ausente ou inválido: continua para AABB como fallback.
    end

    local cfg = Config.VisualPropPhysics or {}
    local shape = tostring(cfg.colliderShape or 'modelBounds')
    if shape == 'cube' or shape == 'box' then
        local ext = PT.GetVisualPropColliderHalfExtents(prop)
        local halfX = shape == 'cube' and PT.GetVisualPropCubeHalfSize(prop) or (tonumber(ext and ext.x) or PT.GetVisualPropCubeHalfSize(prop))
        local halfY = shape == 'cube' and PT.GetVisualPropCubeHalfSize(prop) or (tonumber(ext and ext.y) or PT.GetVisualPropCubeHalfSize(prop))
        local halfZ = shape == 'cube' and PT.GetVisualPropCubeHalfSize(prop) or (tonumber(ext and ext.z) or PT.GetVisualPropCubeHalfSize(prop))
        local corners = {
            { x = -halfX, y = -halfY, z = -halfZ },
            { x = halfX, y = -halfY, z = -halfZ },
            { x = halfX, y = halfY, z = -halfZ },
            { x = -halfX, y = halfY, z = -halfZ },
            { x = -halfX, y = -halfY, z = halfZ },
            { x = halfX, y = -halfY, z = halfZ },
            { x = halfX, y = halfY, z = halfZ },
            { x = -halfX, y = halfY, z = halfZ }
        }
        local minX, minY = 1e9, 1e9
        local maxX, maxY = -1e9, -1e9
        for _, corner in ipairs(corners) do
            local rotX, rotY = PT.GetVisualPropRotatedPoint(corner.x, corner.y, corner.z, yaw, pitch, roll)
            local px = anchorX + rotX
            local py = anchorY + rotY
            if px < minX then minX = px end
            if px > maxX then maxX = px end
            if py < minY then minY = py end
            if py > maxY then maxY = py end
        end
        if minX == 1e9 then return nil end
        return applyFootprintPointOverride({
            { x = minX, y = minY },
            { x = maxX, y = minY },
            { x = maxX, y = maxY },
            { x = minX, y = maxY }
        }, anchorX, anchorY, prop)
    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(prop.entity))
    if not minDim or not maxDim then return nil end

    local scale = tonumber(prop.scale) or 1.0
    -- footprintScale expande o footprint para compensar o physics bounds do GTA
    -- ser menor que o mesh visual. Quando nativeCollision for ligado, isso pode ser
    -- reduzido para 1.0 pois o GTA passará a usar a shape real do modelo.
    local fs = tonumber(cfg.footprintScale) or 1.0
    local override = getPropFootprintOverride(prop)
    local scaleX = override and override.scaleX or 1.0
    local scaleY = override and override.scaleY or 1.0
    local xs = { (minDim.x or 0.0) * scale * fs * scaleX, (maxDim.x or 0.0) * scale * fs * scaleX }
    local ys = { (minDim.y or 0.0) * scale * fs * scaleY, (maxDim.y or 0.0) * scale * fs * scaleY }
    local zs = { (minDim.z or 0.0) * scale * fs, (maxDim.z or 0.0) * scale * fs }
    local points = {}

    for _, lx in ipairs(xs) do
        for _, ly in ipairs(ys) do
            for _, lz in ipairs(zs) do
                local rotX, rotY = PT.GetVisualPropRotatedPoint(lx, ly, lz, yaw, pitch, roll)
                points[#points + 1] = {
                    x = anchorX + rotX,
                    y = anchorY + rotY
                }
            end
        end
    end

    if #points < 3 then return nil end
    return applyFootprintPaddingOnly(PT.BuildConvexFootprintHull(points), anchorX, anchorY, prop)
end

PT.ClampPropInsidePhysicsWalls = function(pctx, x, y, radius, prop, yaw, pitch, roll)
    if not pctx then return x, y end
    local cfg = Config.VisualPropPhysics or {}
    local wallGap = (tonumber(radius) or 0.0) + (tonumber(cfg.wallPadding) or tonumber(cfg.safeGap) or 0.014)
    x = math.max(pctx.minX, math.min(pctx.maxX, tonumber(x) or 0.0))
    y = math.max(pctx.minY, math.min(pctx.maxY, tonumber(y) or 0.0))
    x, y = clampPointToPolygon(pctx.areaPoints, x, y)

    local polygon = PT.GetPhysicsAreaPolygon(pctx)
    if not polygon or #polygon < 3 or wallGap <= 0.0 then
        return x, y
    end

    local centerX, centerY = 0.0, 0.0
    for _, point in ipairs(polygon) do
        centerX = centerX + (tonumber(point.x) or 0.0)
        centerY = centerY + (tonumber(point.y) or 0.0)
    end
    centerX = centerX / #polygon
    centerY = centerY / #polygon

    if cfg.useFootprintWalls == true and prop and prop.entity and DoesEntityExist(prop.entity) then
        local padding = tonumber(cfg.wallPadding) or 0.018
        for _ = 1, 5 do
            local moved = false
            local footprint = PT.GetVisualPropFootprintPoints(prop, x, y, yaw, pitch, roll) or {}
            for _, point in ipairs(footprint) do
                if not isPointInsidePolygon(polygon, point.x, point.y) then
                    local bx, by = clampPointToPolygon(polygon, point.x, point.y)
                    local inwardX = centerX - bx
                    local inwardY = centerY - by
                    local inwardLen = math.sqrt((inwardX * inwardX) + (inwardY * inwardY))
                    if inwardLen > 0.0001 then
                        bx = bx + ((inwardX / inwardLen) * padding)
                        by = by + ((inwardY / inwardLen) * padding)
                    end
                    x = x + (bx - point.x)
                    y = y + (by - point.y)
                    moved = true
                end
            end
            x = math.max(pctx.minX, math.min(pctx.maxX, x))
            y = math.max(pctx.minY, math.min(pctx.maxY, y))
            x, y = clampPointToPolygon(pctx.areaPoints, x, y)
            if not moved then
                return x, y
            end
        end
        return x, y
    end

    for _ = 1, 4 do
        local bestDist2 = 1e12
        local bestX, bestY = x, y
        for i = 1, #polygon do
            local a = polygon[i]
            local b = polygon[(i % #polygon) + 1]
            local ax, ay = tonumber(a.x) or 0.0, tonumber(a.y) or 0.0
            local bx, by = tonumber(b.x) or 0.0, tonumber(b.y) or 0.0
            local abx = bx - ax
            local aby = by - ay
            local abLen2 = (abx * abx) + (aby * aby)
            local t = 0.0
            if abLen2 > 0.000001 then
                t = (((x - ax) * abx) + ((y - ay) * aby)) / abLen2
                t = math.max(0.0, math.min(1.0, t))
            end
            local cx = ax + (abx * t)
            local cy = ay + (aby * t)
            local dx = x - cx
            local dy = y - cy
            local d2 = (dx * dx) + (dy * dy)
            if d2 < bestDist2 then
                bestDist2 = d2
                bestX, bestY = cx, cy
            end
        end

        local dist = math.sqrt(bestDist2)
        if dist >= wallGap - 0.0005 then
            break
        end

        local nx = x - bestX
        local ny = y - bestY
        local len = math.sqrt((nx * nx) + (ny * ny))
        if len < 0.0001 then
            nx = centerX - bestX
            ny = centerY - bestY
            len = math.sqrt((nx * nx) + (ny * ny))
        end
        if len < 0.0001 then
            break
        end

        local push = wallGap - dist
        x = x + ((nx / len) * push)
        y = y + ((ny / len) * push)
        x = math.max(pctx.minX, math.min(pctx.maxX, x))
        y = math.max(pctx.minY, math.min(pctx.maxY, y))
        x, y = clampPointToPolygon(pctx.areaPoints, x, y)
    end

    return x, y
end

PT.FootprintsOverlap = function(a, b)
    if not a or not b then return false end
    local aPoints = a.footprint or {}
    local bPoints = b.footprint or {}
    if #aPoints < 3 or #bPoints < 3 then
        local dx = (tonumber(a.x) or 0.0) - (tonumber(b.x) or 0.0)
        local dy = (tonumber(a.y) or 0.0) - (tonumber(b.y) or 0.0)
        local minDist = (tonumber(a.radius) or 0.0) + (tonumber(b.radius) or 0.0)
        return ((dx * dx) + (dy * dy)) <= (minDist * minDist)
    end

    local function hasSeparatingAxis(polyA, polyB)
        for i = 1, #polyA do
            local p1 = polyA[i]
            local p2 = polyA[(i % #polyA) + 1]
            local edgeX = (tonumber(p2.x) or 0.0) - (tonumber(p1.x) or 0.0)
            local edgeY = (tonumber(p2.y) or 0.0) - (tonumber(p1.y) or 0.0)
            local axisX, axisY = -edgeY, edgeX
            local axisLen = math.sqrt((axisX * axisX) + (axisY * axisY))
            if axisLen > 0.000001 then
                axisX = axisX / axisLen
                axisY = axisY / axisLen
                local minA, maxA = 1e9, -1e9
                local minB, maxB = 1e9, -1e9
                for _, point in ipairs(polyA) do
                    local projected = ((tonumber(point.x) or 0.0) * axisX) + ((tonumber(point.y) or 0.0) * axisY)
                    if projected < minA then minA = projected end
                    if projected > maxA then maxA = projected end
                end
                for _, point in ipairs(polyB) do
                    local projected = ((tonumber(point.x) or 0.0) * axisX) + ((tonumber(point.y) or 0.0) * axisY)
                    if projected < minB then minB = projected end
                    if projected > maxB then maxB = projected end
                end
                if maxA < minB or maxB < minA then
                    return true
                end
            end
        end
        return false
    end

    if hasSeparatingAxis(aPoints, bPoints) or hasSeparatingAxis(bPoints, aPoints) then
        return false
    end
    return true
end

PT.FootprintsOverlapRelaxed = function(a, b, padding)
    if PT.FootprintsOverlap(a, b) then return true end
    padding = math.max(0.0, tonumber(padding) or 0.0)
    if padding <= 0.0 or not a or not b then return false end

    local aPoints = a.footprint or {}
    local bPoints = b.footprint or {}
    if #aPoints < 3 or #bPoints < 3 then
        local dx = (tonumber(a.x) or 0.0) - (tonumber(b.x) or 0.0)
        local dy = (tonumber(a.y) or 0.0) - (tonumber(b.y) or 0.0)
        local minDist = (tonumber(a.radius) or 0.0) + (tonumber(b.radius) or 0.0) + padding
        return ((dx * dx) + (dy * dy)) <= (minDist * minDist)
    end

    local function pointSegmentDistance(px, py, ax, ay, bx, by)
        local abx, aby = bx - ax, by - ay
        local abLen2 = (abx * abx) + (aby * aby)
        local t = 0.0
        if abLen2 > 0.000001 then
            t = (((px - ax) * abx) + ((py - ay) * aby)) / abLen2
            t = math.max(0.0, math.min(1.0, t))
        end
        local cx = ax + (abx * t)
        local cy = ay + (aby * t)
        local dx, dy = px - cx, py - cy
        return math.sqrt((dx * dx) + (dy * dy))
    end

    local function closeToPoly(points, poly)
        for _, point in ipairs(points) do
            local px, py = tonumber(point.x) or 0.0, tonumber(point.y) or 0.0
            if isPointInsidePolygon(poly, px, py) then return true end
            for i = 1, #poly do
                local p1 = poly[i]
                local p2 = poly[(i % #poly) + 1]
                local dist = pointSegmentDistance(
                    px, py,
                    tonumber(p1.x) or 0.0, tonumber(p1.y) or 0.0,
                    tonumber(p2.x) or 0.0, tonumber(p2.y) or 0.0
                )
                if dist <= padding then return true end
            end
        end
        return false
    end

    return closeToPoly(aPoints, bPoints) or closeToPoly(bPoints, aPoints)
end

-- Returns MTV {nx, ny, depth} pointing from a toward b, or nil if no overlap.
-- Uses SAT minimum overlap axis — correct for elongated/rotated shapes.
PT.GetFootprintSeparation = function(a, b)
    local aPoints = a.footprint or {}
    local bPoints = b.footprint or {}

    if #aPoints < 3 or #bPoints < 3 then
        local dx = (tonumber(b.x) or 0.0) - (tonumber(a.x) or 0.0)
        local dy = (tonumber(b.y) or 0.0) - (tonumber(a.y) or 0.0)
        local minDist = (tonumber(a.radius) or 0.0) + (tonumber(b.radius) or 0.0)
        local dist2 = dx * dx + dy * dy
        if dist2 >= minDist * minDist then return nil end
        local dist = math.sqrt(dist2)
        if dist < 0.0001 then return { nx = 1.0, ny = 0.0, depth = minDist } end
        return { nx = dx / dist, ny = dy / dist, depth = minDist - dist }
    end

    local minOverlap = 1e9
    local bestNX, bestNY = 1.0, 0.0

    local function testEdges(polyA, polyB)
        for i = 1, #polyA do
            local p1 = polyA[i]
            local p2 = polyA[(i % #polyA) + 1]
            local ex = (tonumber(p2.x) or 0.0) - (tonumber(p1.x) or 0.0)
            local ey = (tonumber(p2.y) or 0.0) - (tonumber(p1.y) or 0.0)
            local len = math.sqrt(ex * ex + ey * ey)
            if len > 0.000001 then
                local ax = -ey / len
                local ay =  ex / len
                local minA, maxA = 1e9, -1e9
                local minB, maxB = 1e9, -1e9
                for _, pt in ipairs(polyA) do
                    local proj = (tonumber(pt.x) or 0.0) * ax + (tonumber(pt.y) or 0.0) * ay
                    if proj < minA then minA = proj end
                    if proj > maxA then maxA = proj end
                end
                for _, pt in ipairs(polyB) do
                    local proj = (tonumber(pt.x) or 0.0) * ax + (tonumber(pt.y) or 0.0) * ay
                    if proj < minB then minB = proj end
                    if proj > maxB then maxB = proj end
                end
                if maxA < minB or maxB < minA then return true end
                local overlap = math.min(maxA, maxB) - math.max(minA, minB)
                if overlap < minOverlap then
                    minOverlap = overlap
                    bestNX, bestNY = ax, ay
                end
            end
        end
        return false
    end

    if testEdges(aPoints, bPoints) then return nil end
    if testEdges(bPoints, aPoints) then return nil end

    local cx = (tonumber(b.x) or 0.0) - (tonumber(a.x) or 0.0)
    local cy = (tonumber(b.y) or 0.0) - (tonumber(a.y) or 0.0)
    if cx * bestNX + cy * bestNY < 0 then
        bestNX, bestNY = -bestNX, -bestNY
    end

    return { nx = bestNX, ny = bestNY, depth = minOverlap }
end

PT.ResolveVisualPropReleaseOverlap = function(prop, pctx)
    if not prop or not prop.item or not prop.entity or not DoesEntityExist(prop.entity) then return false end
    if not PT.VisualPhysicsEnabled() then return false end
    pctx = pctx or (State.vehicle and DoesEntityExist(State.vehicle) and buildVehiclePlacementContext(State.vehicle)) or nil
    if not pctx then return false end

    local cfg = Config.VisualPropPhysics or {}
    local floorZ = getPivotBaseZForCurrentVehicle() + (tonumber(cfg.groundPadding) or 0.006)
    local iterations = math.max(1, math.min(24, tonumber(cfg.releaseSeparationIterations) or 10))
    local step = math.max(0.002, math.min(0.08, tonumber(cfg.releaseSeparationStep) or 0.018))
    local rec = PT.BuildVisualPhysicsRecord(prop, pctx, floorZ, cfg)
    local changed = false
    if not rec then return false end

    for _ = 1, iterations do
        local movedThisPass = false
        local props = PT.GetVisualProps and PT.GetVisualProps() or {}
        for _, other in ipairs(props) do
            if other and other ~= prop and other.entity and DoesEntityExist(other.entity) and other.item then
                local support = PT.BuildVisualPhysicsRecord(other, pctx, floorZ, cfg)
                if support and PT.FootprintsOverlap(rec, support) then
                    local aMinZ = (tonumber(rec.z) or 0.0) + (tonumber(rec.bottomRelZ) or 0.0)
                    local aMaxZ = (tonumber(rec.z) or 0.0) + (tonumber(rec.topRelZ) or 0.0)
                    local bMinZ = (tonumber(support.z) or 0.0) + (tonumber(support.bottomRelZ) or 0.0)
                    local bMaxZ = (tonumber(support.z) or 0.0) + (tonumber(support.topRelZ) or 0.0)
                    local verticalOverlap = aMinZ <= (bMaxZ + 0.008) and bMinZ <= (aMaxZ + 0.008)
                    if verticalOverlap then
                        local dx = (tonumber(rec.x) or 0.0) - (tonumber(support.x) or 0.0)
                        local dy = (tonumber(rec.y) or 0.0) - (tonumber(support.y) or 0.0)
                        local len = math.sqrt((dx * dx) + (dy * dy))
                        if len < 0.0001 then
                            local yawRad = math.rad(tonumber(rec.yaw) or 0.0)
                            dx = math.cos(yawRad)
                            dy = math.sin(yawRad)
                            len = 1.0
                        end
                        rec.x = (tonumber(rec.x) or 0.0) + ((dx / len) * step)
                        rec.y = (tonumber(rec.y) or 0.0) + ((dy / len) * step)
                        rec.yaw = normalizeAngle180((tonumber(rec.yaw) or 0.0) + ((dx / len) * (tonumber(cfg.collisionYawImpulse) or 2.2) * 0.25))
                        rec.pitch = normalizeAngle180((tonumber(rec.pitch) or 0.0) + ((dy / len) * (tonumber(cfg.collisionPitchImpulse) or 1.1) * 0.25))
                        rec.roll = normalizeAngle180((tonumber(rec.roll) or 0.0) - ((dx / len) * (tonumber(cfg.collisionRollImpulse) or 1.1) * 0.25))
                        rec.x, rec.y = PT.ClampPropInsidePhysicsWalls(pctx, rec.x, rec.y, rec.radius, rec.prop, rec.yaw, rec.pitch, rec.roll)
                        rec.floorZ = PT.GetVisualPropFloorOriginZ(rec.prop, floorZ, rec.pitch, rec.roll, rec.yaw)
                        rec.z = math.max(tonumber(rec.z) or rec.floorZ, tonumber(rec.floorZ) or floorZ)
                        rec.bottomRelZ, rec.topRelZ = PT.GetVisualPropVerticalExtents(rec.prop, rec.pitch, rec.roll, rec.yaw)
                        refreshRecordSupportExtents(rec)
                        rec.footprint = PT.GetVisualPropFootprintPoints(rec.prop, rec.x, rec.y, rec.yaw, rec.pitch, rec.roll)
                        movedThisPass = true
                        changed = true
                    end
                end
            end
        end
        if not movedThisPass then break end
    end

    if changed then
        PT.SetPropPhysicsLocal(rec.prop, rec.x, rec.y, rec.z, rec.yaw, rec.pitch, rec.roll, pctx)
        PT.VisualPhysicsState.velocities[rec.key] = 0.0
    end
    return changed
end

PT.MarkVisualPhysicsDirty = function(prop)
    local cfg = Config.VisualPropPhysics or {}
    if cfg.persistSettled ~= true then return end
    local key = PT.GetVisualPhysicsKey(prop)
    PT.VisualPhysicsState.persistSeq = (tonumber(PT.VisualPhysicsState.persistSeq) or 0) + 1
    PT.VisualPhysicsState.dirty[key] = {
        seq = PT.VisualPhysicsState.persistSeq,
        changedAt = GetGameTimer(),
        inFlight = false,
        sentAt = 0,
        attempts = 0,
        slot = tonumber(prop and prop.item and prop.item.slot),
        instanceId = tostring(prop and prop.item and prop.item.instanceId or ''),
        x = tonumber(prop and prop.item and prop.item.visualX),
        y = tonumber(prop and prop.item and prop.item.visualY),
        z = tonumber(prop and prop.item and prop.item.visualZ),
        yaw = tonumber(prop and prop.item and prop.item.visualYaw) or 0.0,
        pitch = tonumber(prop and prop.item and prop.item.visualPitch) or 0.0,
        roll = tonumber(prop and prop.item and prop.item.visualRoll) or 0.0
    }
end

PT.FlushSettledVisualPhysics = function(forceAll)
    local cfg = Config.VisualPropPhysics or {}
    if cfg.persistSettled ~= true or not State.active then return end
    local nowMs = GetGameTimer()
    local sendIntervalMs = tonumber(cfg.persistSendIntervalMs) or 180
    if forceAll ~= true and (nowMs - (PT.VisualPhysicsState.lastPersistAt or 0)) < sendIntervalMs then return end

    local settleMs = tonumber(cfg.persistDelayMs) or 1200
    local retryMs = tonumber(cfg.persistRetryMs) or 1800

    local function sendPersist(key, data)
        data.inFlight = true
        data.sentAt = nowMs
        data.attempts = (tonumber(data.attempts) or 0) + 1
        PT.VisualPhysicsState.lastPersistAt = nowMs
        -- d11_ptrunk: grava a pose assentada (o servidor nao responde; sai da fila na hora).
        PT.PhysicsPersist(key, data)
        PT.VisualPhysicsState.dirty[key] = nil
    end

    local chosenKey, chosenData, chosenChangedAt = nil, nil, nil
    for key, data in pairs(PT.VisualPhysicsState.dirty) do
        if data and data.slot and data.x and data.y then
            local changedAt = tonumber(data.changedAt) or nowMs
            local sentAt = tonumber(data.sentAt) or 0
            if data.inFlight == true and (nowMs - sentAt) >= retryMs then
                data.inFlight = false
            end
            if forceAll == true and data.inFlight ~= true then
                sendPersist(key, data)
            elseif data.inFlight ~= true and (nowMs - changedAt) >= settleMs and (not chosenChangedAt or changedAt < chosenChangedAt) then
                chosenKey = key
                chosenData = data
                chosenChangedAt = changedAt
            end
        else
            PT.VisualPhysicsState.dirty[key] = nil
        end
    end
    if forceAll == true then return end
    if not chosenKey or not chosenData then return end

    sendPersist(chosenKey, chosenData)
end

PT.ApplyVisualPropSettleWobble = function(rec, cfg, force)
    if not rec or not rec.key or PT.VisualPhysicsState.settled[rec.key] == true then return false end
    if force ~= true and rec.needsSettleWobble ~= true then return false end
    if cfg and cfg.settleWobbleEnabled == false then
        PT.VisualPhysicsState.settled[rec.key] = true
        if rec.prop and State.vehicle and DoesEntityExist(State.vehicle) then
            PT.QueueRaycastFootprintSample(rec.prop, State.vehicle, rec.key, rec.pitch, rec.roll, rec.yaw)
        end
        return false
    end

    local maxExistingTilt = tonumber(cfg and cfg.settleWobbleMaxExistingTilt) or 2.0
    if math.abs(tonumber(rec.pitch) or 0.0) > maxExistingTilt or math.abs(tonumber(rec.roll) or 0.0) > maxExistingTilt then
        PT.VisualPhysicsState.settled[rec.key] = true
        if rec.prop and State.vehicle and DoesEntityExist(State.vehicle) then
            PT.QueueRaycastFootprintSample(rec.prop, State.vehicle, rec.key, rec.pitch, rec.roll, rec.yaw)
        end
        return false
    end

    local seed = ((tonumber(rec.x) or 0.0) * 37.0) + ((tonumber(rec.y) or 0.0) * 53.0) + ((tonumber(rec.yaw) or 0.0) * 0.11)
    local pitchForce = tonumber(cfg and cfg.settleWobblePitch) or 7.0
    local rollForce = tonumber(cfg and cfg.settleWobbleRoll) or 5.0
    local yawForce = tonumber(cfg and cfg.settleWobbleYaw) or 3.5

    local angular = PT.VisualPhysicsState.angular[rec.key] or { yaw = 0.0, pitch = 0.0, roll = 0.0 }
    angular.pitch = (tonumber(angular.pitch) or 0.0) + (math.sin(seed) * pitchForce)
    angular.roll = (tonumber(angular.roll) or 0.0) + (math.cos(seed * 1.37) * rollForce)
    angular.yaw = (tonumber(angular.yaw) or 0.0) + (math.sin(seed * 0.73) * yawForce)
    PT.VisualPhysicsState.angular[rec.key] = angular
    rec.dirty = true
    if rec.prop and rec.prop.item then
        rec.prop.item._ptPhysicsNeedsWobble = nil
    end
    PT.VisualPhysicsState.settled[rec.key] = true

    -- Dispara amostragem de footprint por raycast para este prop.
    if rec.prop and State.vehicle and DoesEntityExist(State.vehicle) then
        PT.QueueRaycastFootprintSample(rec.prop, State.vehicle, rec.key, rec.pitch, rec.roll, rec.yaw)
    end

    return true
end

PT.ApplyVisualPropStability = function(rec, cfg)
    if not rec or not rec.key or not rec.prop or rec.movable ~= true then return false end
    if PT.VisualPhysicsState.settled[rec.key] == true and rec.needsSettleWobble ~= true then return false end
    if cfg and cfg.stabilityCorrection == false then return false end

    local ext = PT.GetVisualPropWorldExtents and PT.GetVisualPropWorldExtents(rec.prop, rec.yaw, rec.pitch, rec.roll) or nil
    if not ext then return false end

    local widthX = math.max(0.001, tonumber(ext.widthX) or 0.001)
    local widthY = math.max(0.001, tonumber(ext.widthY) or 0.001)
    local height = math.max(0.001, tonumber(ext.height) or 0.001)
    local broad = math.max(widthX, widthY, height)
    local baseThin = math.min(widthX, widthY)
    local thinRatio = tonumber(cfg and cfg.unstableBaseThinRatio) or 0.24
    local minHeight = tonumber(cfg and cfg.unstableMinHeight) or 0.030
    local stable = (cfg and cfg.stableOrientationSearch ~= false and PT.FindVisualPropStableOrientation)
        and PT.FindVisualPropStableOrientation(rec.prop, rec.yaw, rec.pitch, rec.roll)
        or nil
    -- Criterio de estabilidade fisico (nao heuristica de footprint/razao, que falha em itens
    -- cubicos): o item esta APOIADO NUMA FACE ou EQUILIBRADO numa quina/aresta?
    --   onFace  = pitch E roll a <= faceTol de um multiplo de 90 (descansando numa face plana).
    --   tooTall = altura atual bem maior que a da pose mais baixa (esta "de pe", deveria deitar).
    -- Estavel = onFace E nao tooTall. Senao, reorienta ate a face mais baixa.
    -- Resolve: cubo a 49deg (nao-onFace -> deita), arma empinada (nao-onFace -> deita), kit a
    -- 0deg (onFace, razao ~1.38 < standFactor -> fica), garrafa de pe (onFace mas tooTall ->
    -- deita), arma ja deitada a -90 (onFace, nao tooTall -> fica, sem topple espurio).
    -- Override de estabilidade por item (propbrowser). 'lock' = nunca reorienta/tomba.
    local stabilityMode = rec.stabilityMode
    if stabilityMode == 'lock' then
        return false
    end

    local faceTol = tonumber(rec.stabilityFaceTol) or tonumber(cfg and cfg.stableFaceTiltTolerance) or 12.0
    local pitchN = normalizeAngle180(tonumber(rec.pitch) or 0.0)
    local rollN = normalizeAngle180(tonumber(rec.roll) or 0.0)
    local pitchFace = math.abs(normalizeAngle180(pitchN - (math.floor((pitchN + 45.0) / 90.0) * 90.0)))
    local rollFace = math.abs(normalizeAngle180(rollN - (math.floor((rollN + 45.0) / 90.0) * 90.0)))
    local onFace = pitchFace <= faceTol and rollFace <= faceTol
    local standFactor = tonumber(rec.stabilityStandFactor) or tonumber(cfg and cfg.stableStandFactor) or 1.6
    local tooTall = stable and (height > ((tonumber(stable.height) or height) * standFactor))

    -- Alvo de orientacao para o assentamento:
    --   alignToFace = item ja apoiado numa face, so levemente torto -> alinha na face EXATA
    --     (multiplo de 90 mais proximo). Limpa a inclinacao residual em vez de dormir torto
    --     (era o "nao assenta": parava em ~3deg de inclinacao).
    --   senao (tombado/de pe/'lay') -> pose mais baixa do search (deita).
    local alignToFace = (stabilityMode ~= 'lay') and onFace and not tooTall
    if height < minHeight then
        return false
    end

    local targetPitch, targetRoll
    if alignToFace then
        targetPitch = normalizeAngle180(math.floor((pitchN + 45.0) / 90.0) * 90.0)
        targetRoll  = normalizeAngle180(math.floor((rollN + 45.0) / 90.0) * 90.0)
    elseif stable then
        targetPitch = normalizeAngle180(tonumber(stable.pitch) or rec.pitch)
        targetRoll  = normalizeAngle180(tonumber(stable.roll) or rec.roll)
    end

    local maxAngular = math.max(0.2, tonumber(cfg and cfg.unstableToppleMaxAngular) or 4.8)
    local angular = PT.VisualPhysicsState.angular[rec.key] or { yaw = 0.0, pitch = 0.0, roll = 0.0 }

    -- Giro guiado ate o alvo (face exata ou pose deitada), com snap final.
    if targetPitch then
        local step = tonumber(cfg and cfg.stableOrientationStep) or 0.22
        local pitchDelta = normalizeAngle180(targetPitch - (tonumber(rec.pitch) or 0.0))
        local rollDelta  = normalizeAngle180(targetRoll  - (tonumber(rec.roll)  or 0.0))
        local snapDegrees = tonumber(cfg and cfg.stableOrientationSnapDegrees) or 2.4
        if math.abs(pitchDelta) <= snapDegrees and math.abs(rollDelta) <= snapDegrees then
            rec.pitch = targetPitch
            rec.roll = targetRoll
            angular.pitch = 0.0
            angular.roll = 0.0
            PT.VisualPhysicsState.angular[rec.key] = angular
            PT.VisualPhysicsState.settled[rec.key] = true
            rec.bottomRelZ, rec.topRelZ = PT.GetVisualPropVerticalExtents(rec.prop, rec.pitch, rec.roll, rec.yaw)
            refreshRecordSupportExtents(rec)
            rec.dirty = true
            return true
        end
        local pitchProx = math.min(1.0, math.abs(pitchDelta) / 20.0)
        local rollProx  = math.min(1.0, math.abs(rollDelta)  / 20.0)
        angular.pitch = math.max(-maxAngular, math.min(maxAngular, (tonumber(angular.pitch) or 0.0) + (pitchDelta * step * pitchProx)))
        angular.roll  = math.max(-maxAngular, math.min(maxAngular, (tonumber(angular.roll)  or 0.0) + (rollDelta  * step * rollProx)))
        PT.VisualPhysicsState.angular[rec.key] = angular
        PT.VisualPhysicsState.settled[rec.key] = nil
        rec.dirty = true
        return true
    end

    -- Sem alvo conhecido (search desativado/sem pose) e fora de face: impulso de topple
    -- para tombar naturalmente; no frame seguinte ja inclinado, cai no giro guiado acima.
    local impulse = tonumber(cfg and cfg.unstableToppleImpulse) or 2.4
    local seed = ((tonumber(rec.x) or 0.0) * 31.0) + ((tonumber(rec.y) or 0.0) * 47.0) + ((tonumber(rec.yaw) or 0.0) * 0.19)
    local seedDir = math.sin(seed) >= 0.0 and 1.0 or -1.0
    local tiltThreshold = 8.0
    if widthX <= widthY then
        local currentRoll = tonumber(rec.roll) or 0.0
        local direction = math.abs(currentRoll) > tiltThreshold
            and (currentRoll >= 0.0 and 1.0 or -1.0)
            or seedDir
        angular.roll = math.max(-maxAngular, math.min(maxAngular, (tonumber(angular.roll) or 0.0) + (impulse * direction)))
        angular.yaw  = math.max(-maxAngular, math.min(maxAngular, (tonumber(angular.yaw)  or 0.0) + (impulse * 0.10 * direction)))
    else
        local currentPitch = tonumber(rec.pitch) or 0.0
        local direction = math.abs(currentPitch) > tiltThreshold
            and (currentPitch >= 0.0 and 1.0 or -1.0)
            or seedDir
        angular.pitch = math.max(-maxAngular, math.min(maxAngular, (tonumber(angular.pitch) or 0.0) + (impulse * direction)))
        angular.yaw   = math.max(-maxAngular, math.min(maxAngular, (tonumber(angular.yaw)   or 0.0) - (impulse * 0.10 * direction)))
    end

    PT.VisualPhysicsState.angular[rec.key] = angular
    PT.VisualPhysicsState.settled[rec.key] = nil
    rec.dirty = true
    return true
end

-- d11_ptrunk (2026-11-16): correcao do motor da D12. O balanco de assentamento marca o objeto como assentado logo
-- depois do impacto; dai ele dormia com a rotacao zerada e a estabilidade desistia (settled), e um objeto que comecava a
-- tombar congelava no meio (garrafa parada a -36 graus) ou dormia torto perto da face (-80). Regra: so dorme encaixado
-- numa face (pitch e roll a ate stableOrientationSnapDegrees, o encaixe final do proprio motor, de um multiplo de 90),
-- ou com a pose travada pelo propbrowser (stabilityMode 'lock'). Fora disso a estabilidade gira ate encaixar.
local function restingOnFace(rec, cfg)
    if rec.stabilityMode == 'lock' then return true end
    local tol = (tonumber(cfg and cfg.stableOrientationSnapDegrees) or 2.4) + 0.5
    local function off(a)
        a = normalizeAngle180(tonumber(a) or 0.0)
        return math.abs(normalizeAngle180(a - math.floor((a + 45.0) / 90.0) * 90.0))
    end
    return off(rec.pitch) <= tol and off(rec.roll) <= tol
end

PT.StepVisualPropPhysics = function(force)
    if not PT.VisualPhysicsEnabled() or not State.active or not State.vehicle or not DoesEntityExist(State.vehicle) then return end
    local props = PT.GetVisualProps and PT.GetVisualProps() or {}
    if not props or #props == 0 then return end

    local cfg = Config.VisualPropPhysics or {}
    local nowMs = GetGameTimer()
    local propCount = #props
    local stepMs = tonumber(cfg.stepMs) or 16
    if propCount >= 24 then
        stepMs = math.max(stepMs, tonumber(cfg.largeInventoryStepMs) or 45)
    elseif propCount >= 14 then
        stepMs = math.max(stepMs, tonumber(cfg.mediumInventoryStepMs) or 30)
    end
    if not force and (nowMs - (PT.VisualPhysicsState.lastStepAt or 0)) < stepMs then return end

    if not force then
        local hasActivePhysics = false
        for _, prop in ipairs(props) do
            local key = prop and PT.GetVisualPhysicsKey and PT.GetVisualPhysicsKey(prop) or nil
            if key
                and (PT.VisualPhysicsState.settled[key] ~= true
                    or (PT.VisualPhysicsState.dirty and PT.VisualPhysicsState.dirty[key] ~= nil)
                    or (PT.IsVisualPropPlayerMoved and PT.IsVisualPropPlayerMoved(prop))
                    or (PT.IsVisualPropBeingManipulated and PT.IsVisualPropBeingManipulated(prop))) then
                hasActivePhysics = true
                break
            elseif not key then
                hasActivePhysics = true
                break
            end
        end
        if not hasActivePhysics then
            local sleepStepMs = tonumber(cfg.sleepingInventoryStepMs) or 360
            if (nowMs - (PT.VisualPhysicsState.lastSleepingStepAt or 0)) < sleepStepMs then
                PT.VisualPhysicsState.lastStepAt = nowMs
                return
            end
            PT.VisualPhysicsState.lastSleepingStepAt = nowMs
        end
    end
    PT.VisualPhysicsState.lastStepAt = nowMs

    local pctx = buildVehiclePlacementContext(State.vehicle)
    local floorZ = getPivotBaseZForCurrentVehicle() + (tonumber(cfg.groundPadding) or 0.006)
    local gravity = tonumber(cfg.gravity) or 0.010
    local maxFallVelocity = math.abs(tonumber(cfg.maxFallVelocity) or 0.035)
    local damping = tonumber(cfg.verticalDamping) or 0.42
    local angularDamping = tonumber(cfg.angularDamping) or 0.65
    local impactAngularDamping = tonumber(cfg.impactAngularDamping) or 0.86
    local fallAngularTorque = tonumber(cfg.fallAngularTorque) or 0.0
    local floorFrictionAngularDamping = tonumber(cfg.floorFrictionAngularDamping) or 0.5
    local impactTorque = tonumber(cfg.impactTorque) or 2.8
    local minImpactVelocity = tonumber(cfg.minImpactVelocity) or 0.006
    local yawImpulse = tonumber(cfg.collisionYawImpulse) or 2.2
    local pitchImpulse = tonumber(cfg.collisionPitchImpulse) or 1.1
    local rollImpulse = tonumber(cfg.collisionRollImpulse) or 1.1
    local rotationSettle = tonumber(cfg.rotationSettle) or tonumber(cfg.floorPitchSettle) or 0.18
    local safeGap = tonumber(cfg.safeGap) or 0.014
    local stackSupportPadding = tonumber(cfg.stackSupportPadding) or 0.040
    local stackOriginTopMargin = tonumber(cfg.stackOriginTopMargin) or 0.018
    local stackVerticalReach = tonumber(cfg.stackVerticalReach) or 0.120
    local stackDropVerticalReach = tonumber(cfg.stackDropVerticalReach) or math.max(stackVerticalReach, 0.180)
    local settledSleepZTolerance = tonumber(cfg.settledSleepZTolerance) or 0.006
    PT.VisualPhysicsState.stackSupports = PT.VisualPhysicsState.stackSupports or {}
    local records = {}

    for _, prop in ipairs(props) do
        local rec = PT.BuildVisualPhysicsRecord(prop, pctx, floorZ, cfg)
        if rec then
            records[#records + 1] = rec
        end
    end

    for _, rec in ipairs(records) do
        if rec.movable then
            local velocity = tonumber(PT.VisualPhysicsState.velocities[rec.key]) or 0.0
            local angular = PT.VisualPhysicsState.angular[rec.key] or { yaw = 0.0, pitch = 0.0, roll = 0.0 }
            PT.VisualPhysicsState.angular[rec.key] = angular
            local recFloorZ = tonumber(rec.floorZ) or floorZ
            local previousSupportKey = PT.VisualPhysicsState.stackSupports[rec.key]
            local activeSupportKey = nil
            local recPlayerMoved = PT.IsVisualPropPlayerMoved(rec.prop)
            for _, support in ipairs(records) do
                if support ~= rec then
                    local supportTop = (tonumber(support.z) or 0.0) + (tonumber(support.topRelZ) or 0.0)
                    local recBottom = (tonumber(rec.z) or 0.0) + (tonumber(rec.bottomRelZ) or 0.0)
                    -- Only use this support if rec is actually above it (box bottom above support top - margin),
                    -- the support top is reachable from below, and footprints overlap.
                    local recIsAbove = recBottom >= (supportTop - stackOriginTopMargin)
                    local supportReachable = supportTop <= recBottom + stackVerticalReach
                    local dropReachable = supportTop <= recBottom + stackDropVerticalReach
                    local supportUnavailable = PT.IsVisualPropSupportDisabled(support.prop) or PT.IsVisualPropPlayerMoved(support.prop)
                    local supportOverlaps = false
                    local supportReachRadius = (((tonumber(rec.radius) or 0.0) + (tonumber(support.radius) or 0.0)) * 2.35) + stackSupportPadding + 0.055
                    local supportDx = (tonumber(support.x) or 0.0) - (tonumber(rec.x) or 0.0)
                    local supportDy = (tonumber(support.y) or 0.0) - (tonumber(rec.y) or 0.0)
                    if ((supportDx * supportDx) + (supportDy * supportDy)) <= (supportReachRadius * supportReachRadius) then
                        supportOverlaps = PT.FootprintsOverlapRelaxed(rec, support, stackSupportPadding)
                    end
                    local recBottomNearSupport = recBottom >= (supportTop - stackOriginTopMargin)
                        and recBottom <= (supportTop + stackVerticalReach)
                    local placeMovedItemOnStaticSupport = recPlayerMoved
                        and not supportUnavailable
                        and dropReachable
                        and supportOverlaps
                    local keepMovedBaseSupport = supportUnavailable
                        and previousSupportKey ~= nil
                        and previousSupportKey == support.key
                        and recIsAbove
                        and recBottomNearSupport
                        and supportOverlaps
                    local canUseSupport = ((not supportUnavailable and recIsAbove and supportReachable)
                        or placeMovedItemOnStaticSupport
                        or keepMovedBaseSupport)
                    if canUseSupport and supportOverlaps then
                        -- stackTopPad do SUPORTE: eleva o item empilhado pela folga entre
                        -- a malha visual e o physics bounds do prop de baixo (sem inflar o
                        -- extent usado no portao recIsAbove acima).
                        local supportPad = tonumber(support.stackTopPad) or 0.0
                        local candidateFloor = supportTop - (tonumber(rec.supportBottomRelZ) or tonumber(rec.bottomRelZ) or 0.0) + 0.006 + supportPad
                        if candidateFloor > recFloorZ then
                            recFloorZ = candidateFloor
                            activeSupportKey = support.key
                        end
                    end
                end
            end
            if activeSupportKey then
                PT.VisualPhysicsState.stackSupports[rec.key] = activeSupportKey
            elseif recFloorZ <= ((tonumber(rec.floorZ) or floorZ) + 0.001) then
                PT.VisualPhysicsState.stackSupports[rec.key] = nil
            end
            local settledSleeping = PT.VisualPhysicsState.settled[rec.key] == true
                and rec.needsSettleWobble ~= true
                and math.abs((tonumber(rec.z) or recFloorZ) - recFloorZ) <= settledSleepZTolerance
            -- d11_ptrunk: assentado mas fora de uma face = ainda tombando; acorda e a estabilidade continua o giro.
            if settledSleeping and not restingOnFace(rec, cfg) then
                settledSleeping = false
                PT.VisualPhysicsState.settled[rec.key] = nil
                PT.ApplyVisualPropStability(rec, cfg)
            end
            if settledSleeping then
                rec.sleeping = true
                rec.z = recFloorZ
                velocity = 0.0
                angular.yaw = 0.0
                angular.pitch = 0.0
                angular.roll = 0.0
            elseif rec.z > recFloorZ + 0.001 then
                local impactVelocity = velocity - gravity
                velocity = velocity - gravity
                if maxFallVelocity > 0.0 and velocity < -maxFallVelocity then
                    velocity = -maxFallVelocity
                end
                if fallAngularTorque > 0.0 then
                    local yawRad = math.rad((tonumber(rec.yaw) or 0.0) + ((tonumber(rec.x) or 0.0) * 47.0) + ((tonumber(rec.y) or 0.0) * 31.0))
                    local fallEnergy = math.min(1.0, math.abs(velocity) / math.max(gravity * 8.0, 0.001))
                    angular.yaw = (tonumber(angular.yaw) or 0.0) + (math.sin(yawRad * 0.67) * fallAngularTorque * 0.38 * fallEnergy)
                    angular.pitch = (tonumber(angular.pitch) or 0.0) + (math.sin(yawRad) * fallAngularTorque * fallEnergy)
                    angular.roll = (tonumber(angular.roll) or 0.0) + (math.cos(yawRad * 1.21) * fallAngularTorque * fallEnergy)
                    angular.yaw = (tonumber(angular.yaw) or 0.0) * angularDamping
                    angular.pitch = (tonumber(angular.pitch) or 0.0) * angularDamping
                    angular.roll = (tonumber(angular.roll) or 0.0) * angularDamping
                end
                rec.z = math.max(recFloorZ, rec.z + velocity)
                if rec.z <= recFloorZ + 0.001 then
                    rec.z = recFloorZ
                    if math.abs(impactVelocity) >= minImpactVelocity then
                        local yawRad = math.rad((tonumber(rec.yaw) or 0.0) + ((tonumber(rec.x) or 0.0) * 41.0) + ((tonumber(rec.y) or 0.0) * 29.0))
                        local impactEnergy = math.min(1.0, math.abs(impactVelocity) / math.max(maxFallVelocity, minImpactVelocity, 0.001))
                        angular.yaw = (tonumber(angular.yaw) or 0.0) + (math.sin(yawRad * 0.61) * impactTorque * 0.55 * impactEnergy)
                        angular.pitch = (tonumber(angular.pitch) or 0.0) + (math.sin(yawRad) * impactTorque * impactEnergy)
                        angular.roll = (tonumber(angular.roll) or 0.0) + (math.cos(yawRad) * impactTorque * impactEnergy)
                    end
                    PT.ApplyVisualPropSettleWobble(rec, cfg, true)
                    PT.ApplyVisualPropStability(rec, cfg)
                    velocity = math.abs(velocity) * damping
                    if velocity < 0.004 then velocity = 0.0 end
                end
                rec.dirty = true
            elseif rec.z < recFloorZ - 0.001 then
                rec.z = recFloorZ
                velocity = 0.0
                rec.dirty = true
                PT.ApplyVisualPropStability(rec, cfg)
            else
                rec.z = recFloorZ
                velocity = 0.0
                PT.ApplyVisualPropSettleWobble(rec, cfg, false)
                PT.ApplyVisualPropStability(rec, cfg)
                angular.yaw = (tonumber(angular.yaw) or 0.0) * floorFrictionAngularDamping
                angular.pitch = (tonumber(angular.pitch) or 0.0) * floorFrictionAngularDamping
                angular.roll = (tonumber(angular.roll) or 0.0) * floorFrictionAngularDamping
            end
            if math.abs(tonumber(angular.yaw) or 0.0) > 0.01 or math.abs(tonumber(angular.pitch) or 0.0) > 0.01 or math.abs(tonumber(angular.roll) or 0.0) > 0.01 then
                rec.yaw = normalizeAngle180((tonumber(rec.yaw) or 0.0) + (tonumber(angular.yaw) or 0.0))
                rec.pitch = normalizeAngle180((tonumber(rec.pitch) or 0.0) + (tonumber(angular.pitch) or 0.0))
                rec.roll = normalizeAngle180((tonumber(rec.roll) or 0.0) + (tonumber(angular.roll) or 0.0))
                angular.yaw = (tonumber(angular.yaw) or 0.0) * impactAngularDamping
                angular.pitch = (tonumber(angular.pitch) or 0.0) * impactAngularDamping
                angular.roll = (tonumber(angular.roll) or 0.0) * impactAngularDamping
                if math.abs(tonumber(angular.yaw) or 0.0) < 0.01 then angular.yaw = 0.0 end
                if math.abs(tonumber(angular.pitch) or 0.0) < 0.01 then angular.pitch = 0.0 end
                if math.abs(tonumber(angular.roll) or 0.0) < 0.01 then angular.roll = 0.0 end
                rec.floorZ = PT.GetVisualPropFloorOriginZ(rec.prop, floorZ, rec.pitch, rec.roll, rec.yaw)
                rec.z = math.max(tonumber(rec.floorZ) or recFloorZ, rec.z)
                rec.bottomRelZ, rec.topRelZ = PT.GetVisualPropVerticalExtents(rec.prop, rec.pitch, rec.roll, rec.yaw)
                refreshRecordSupportExtents(rec)
                rec.footprint = PT.GetVisualPropFootprintPoints(rec.prop, rec.x, rec.y, rec.yaw, rec.pitch, rec.roll)
                rec.dirty = true
            end
            if rotationSettle > 0.0 and rec.z <= recFloorZ + 0.001 then
                local pitchDelta = normalizeAngle180((tonumber(rec.restPitch) or 0.0) - (tonumber(rec.pitch) or 0.0))
                if math.abs(pitchDelta) > 0.05 then
                    rec.pitch = normalizeAngle180((tonumber(rec.pitch) or 0.0) + (pitchDelta * rotationSettle))
                    if math.abs(normalizeAngle180((tonumber(rec.restPitch) or 0.0) - rec.pitch)) < 0.08 then
                        rec.pitch = normalizeAngle180(tonumber(rec.restPitch) or rec.pitch)
                    end
                    rec.floorZ = PT.GetVisualPropFloorOriginZ(rec.prop, floorZ, rec.pitch, rec.roll, rec.yaw)
                    rec.z = math.max(tonumber(rec.floorZ) or recFloorZ, rec.z)
                    rec.bottomRelZ, rec.topRelZ = PT.GetVisualPropVerticalExtents(rec.prop, rec.pitch, rec.roll, rec.yaw)
                    refreshRecordSupportExtents(rec)
                    rec.footprint = PT.GetVisualPropFootprintPoints(rec.prop, rec.x, rec.y, rec.yaw, rec.pitch, rec.roll)
                    rec.dirty = true
                end
            end
            rec.footprint = PT.GetVisualPropFootprintPoints(rec.prop, rec.x, rec.y, rec.yaw, rec.pitch, rec.roll)
            PT.VisualPhysicsState.velocities[rec.key] = velocity
            PT.VisualPhysicsState.angular[rec.key] = angular
        else
            PT.VisualPhysicsState.velocities[rec.key] = 0.0
            PT.VisualPhysicsState.angular[rec.key] = { yaw = 0.0, pitch = 0.0, roll = 0.0 }
        end
    end

    local iterations = math.max(1, math.min(8, tonumber(cfg.collisionIterations) or 4))
    if propCount >= 24 then
        iterations = math.min(iterations, tonumber(cfg.largeInventoryCollisionIterations) or 2)
    elseif propCount >= 14 then
        iterations = math.min(iterations, tonumber(cfg.mediumInventoryCollisionIterations) or 3)
    end
    for _ = 1, iterations do
        for i = 1, #records - 1 do
            local a = records[i]
            for j = i + 1, #records do
                local b = records[j]
                local aMinZ = (tonumber(a.z) or 0.0) + (tonumber(a.supportBottomRelZ) or tonumber(a.bottomRelZ) or 0.0)
                local aMaxZ = (tonumber(a.z) or 0.0) + (tonumber(a.supportTopRelZ) or tonumber(a.topRelZ) or 0.0)
                local bMinZ = (tonumber(b.z) or 0.0) + (tonumber(b.supportBottomRelZ) or tonumber(b.bottomRelZ) or 0.0)
                local bMaxZ = (tonumber(b.z) or 0.0) + (tonumber(b.supportTopRelZ) or tonumber(b.topRelZ) or 0.0)
                local verticalOverlap = aMinZ <= (bMaxZ + 0.008) and bMinZ <= (aMaxZ + 0.008)
                local broadphaseRadius = (((tonumber(a.radius) or 0.0) + (tonumber(b.radius) or 0.0)) * 2.35) + stackSupportPadding + safeGap + 0.055
                local broadphaseDx = (tonumber(b.x) or 0.0) - (tonumber(a.x) or 0.0)
                local broadphaseDy = (tonumber(b.y) or 0.0) - (tonumber(a.y) or 0.0)
                local broadphaseOverlap = ((broadphaseDx * broadphaseDx) + (broadphaseDy * broadphaseDy)) <= (broadphaseRadius * broadphaseRadius)
                local stackingFootprint = broadphaseOverlap and PT.FootprintsOverlapRelaxed(a, b, stackSupportPadding) or false
                local isStacking = stackingFootprint and (
                    bMinZ > (aMaxZ - stackOriginTopMargin)
                    or aMinZ > (bMaxZ - stackOriginTopMargin)
                )
                local collisionEnabled = not a.manipulating and not b.manipulating and not (a.sleeping == true and b.sleeping == true)
                if collisionEnabled and verticalOverlap and broadphaseOverlap and not isStacking then
                    local sep = PT.GetFootprintSeparation(a, b)
                    if sep then
                        local pushDepth = sep.depth + safeGap
                        local nx, ny = sep.nx, sep.ny
                        local aShare, bShare = 0.5, 0.5
                        local aPlayerMoved = PT.IsVisualPropPlayerMoved(a.prop)
                        local bPlayerMoved = PT.IsVisualPropPlayerMoved(b.prop)
                        if aPlayerMoved and not bPlayerMoved then
                            aShare, bShare = 0.0, 1.0
                        elseif bPlayerMoved and not aPlayerMoved then
                            aShare, bShare = 1.0, 0.0
                        elseif a.sleeping == true and b.sleeping ~= true then
                            aShare, bShare = 0.0, 1.0
                        elseif b.sleeping == true and a.sleeping ~= true then
                            aShare, bShare = 1.0, 0.0
                        end
                        local ax = nx * pushDepth
                        local ay = ny * pushDepth
                        if a.movable and (a.sleeping ~= true or aPlayerMoved or bPlayerMoved) and aShare > 0.0 then
                            a.x = a.x - (ax * aShare)
                            a.y = a.y - (ay * aShare)
                            a.yaw   = normalizeAngle180((a.yaw   or 0.0) - (yawImpulse   * angularDamping))
                            a.pitch = normalizeAngle180((a.pitch or 0.0) - (ny * pitchImpulse * angularDamping))
                            a.roll  = normalizeAngle180((a.roll  or 0.0) + (nx * rollImpulse  * angularDamping))
                            local angularA = PT.VisualPhysicsState.angular[a.key] or { yaw = 0.0, pitch = 0.0, roll = 0.0 }
                            angularA.yaw   = (tonumber(angularA.yaw)   or 0.0) - (yawImpulse   * 0.18)
                            angularA.pitch = (tonumber(angularA.pitch) or 0.0) - (ny * pitchImpulse * 0.18)
                            angularA.roll  = (tonumber(angularA.roll)  or 0.0) + (nx * rollImpulse  * 0.18)
                            PT.VisualPhysicsState.angular[a.key] = angularA
                            a.x, a.y = PT.ClampPropInsidePhysicsWalls(pctx, a.x, a.y, a.radius, a.prop, a.yaw, a.pitch, a.roll)
                            a.footprint = PT.GetVisualPropFootprintPoints(a.prop, a.x, a.y, a.yaw, a.pitch, a.roll)
                            refreshRecordSupportExtents(a)
                            a.dirty = true
                        end
                        if b.movable and (b.sleeping ~= true or bPlayerMoved or aPlayerMoved) and bShare > 0.0 then
                            b.x = b.x + (ax * bShare)
                            b.y = b.y + (ay * bShare)
                            b.yaw   = normalizeAngle180((b.yaw   or 0.0) + (yawImpulse   * angularDamping))
                            b.pitch = normalizeAngle180((b.pitch or 0.0) + (ny * pitchImpulse * angularDamping))
                            b.roll  = normalizeAngle180((b.roll  or 0.0) - (nx * rollImpulse  * angularDamping))
                            local angularB = PT.VisualPhysicsState.angular[b.key] or { yaw = 0.0, pitch = 0.0, roll = 0.0 }
                            angularB.yaw   = (tonumber(angularB.yaw)   or 0.0) + (yawImpulse   * 0.18)
                            angularB.pitch = (tonumber(angularB.pitch) or 0.0) + (ny * pitchImpulse * 0.18)
                            angularB.roll  = (tonumber(angularB.roll)  or 0.0) - (nx * rollImpulse  * 0.18)
                            PT.VisualPhysicsState.angular[b.key] = angularB
                            b.x, b.y = PT.ClampPropInsidePhysicsWalls(pctx, b.x, b.y, b.radius, b.prop, b.yaw, b.pitch, b.roll)
                            b.footprint = PT.GetVisualPropFootprintPoints(b.prop, b.x, b.y, b.yaw, b.pitch, b.roll)
                            refreshRecordSupportExtents(b)
                            b.dirty = true
                        end
                    end
                end
            end
        end
    end

    for _, rec in ipairs(records) do
        if not rec.manipulating then
            PT.SetPropPhysicsLocal(
                rec.prop,
                rec.x,
                rec.y,
                rec.z,
                tonumber(rec.yaw) or 0.0,
                tonumber(rec.pitch) or 0.0,
                tonumber(rec.roll) or 0.0,
                pctx
            )
            if rec.dirty then
                PT.MarkVisualPhysicsDirty(rec.prop)
            end
        end
    end

    PT.FlushSettledVisualPhysics()
end

-- ------------------------------------------------------------------ d11_ptrunk
-- O attach do motor (pivo do propbrowser, colisao conforme a fisica), usado tambem pelo arraste e pelo teclado.
PT.ApplyPropLocalTransform = applyPropLocalTransform
