-- d11_ptrunk (cliente): os itens do porta-malas como objetos locais presos ao carro.
-- Uma cena por carro. Cada item (chave: uid do item, ou 'slot:<n>:<item>' sem uid) vira um objeto no formato do motor
-- de fisica da D12 (client/physics.lua): { entity, model, scale, item = { slot, instanceId, visualX, visualY,
-- visualZ (altura da origem no espaco do carro), visualYaw, visualPitch, visualRoll, propPivot } }.
-- No banco a pose guarda a altura ACIMA DO FUNDO (z); aqui ela vira a altura da origem do modelo girado.
-- Item com pose salva fica onde estava; item sem pose cai na grade automatica, no primeiro ponto livre da area util
-- ("como cabe"); com a fisica ligada ele nasce um pouco acima (spawnLift) e assenta.
local P = Config.Props

-- ------------------------------------------------------------------ area util
function PT.InsidePolygon(poly, x, y)
    local hit, j = false, #poly
    for i = 1, #poly do
        local a, b = poly[i], poly[j]
        if ((a.y > y) ~= (b.y > y)) and (x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) then hit = not hit end
        j = i
    end
    return hit
end

--- O ponto mais perto dentro da area (clampPointToPolygon da D12).
function PT.ClampToArea(poly, x, y)
    if not poly or #poly < 3 or PT.InsidePolygon(poly, x, y) then return x, y end
    local bx, by, best = x, y, math.huge
    for i = 1, #poly do
        local a, b = poly[i], poly[(i % #poly) + 1]
        local abx, aby = b.x - a.x, b.y - a.y
        local len2 = abx * abx + aby * aby
        local t = len2 > 0.000001 and math.max(0.0, math.min(1.0, ((x - a.x) * abx + (y - a.y) * aby) / len2)) or 0.0
        local cx, cy = a.x + abx * t, a.y + aby * t
        local d2 = (x - cx) ^ 2 + (y - cy) ^ 2
        if d2 < best then best, bx, by = d2, cx, cy end
    end
    return bx, by
end

--- Area do modelo, ou um retangulo junto ao acesso, pela caixa do carro.
function PT.AreaOf(vehicle)
    local p = PT.SpawnProfile(vehicle)
    if p and p.areaPoints and #p.areaPoints >= 3 then return p end
    local y = PT.AccessY(vehicle)
    y = y + (y < 0 and 0.85 or -0.85)
    return { x = 0.0, y = y, z = 0.30,
        areaPoints = { { x = -0.5, y = y + 0.35 }, { x = 0.5, y = y + 0.35 }, { x = 0.5, y = y - 0.35 }, { x = -0.5, y = y - 0.35 } } }
end

--- Pontos da grade dentro da area, do fundo do porta-malas (mais perto do centro do carro) para a borda.
local function gridPoints(area)
    local poly = area.areaPoints
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(poly) do
        minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
        minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
    end
    local out, step = {}, P.spacing
    local fromY, toY, dy = maxY - step / 2, minY, -step
    if math.abs(minY) < math.abs(maxY) then fromY, toY, dy = minY + step / 2, maxY, step end
    local y = fromY
    while (dy < 0 and y >= toY) or (dy > 0 and y <= toY) do
        local x = minX + step / 2
        while x <= maxX do
            if PT.InsidePolygon(poly, x, y) then out[#out + 1] = { x = x, y = y } end
            x = x + step
        end
        y = y + dy
    end
    return out
end

--- Primeiro ponto da grade sem objeto perto; com a grade cheia, o ponto menos ocupado.
local function freeSpot(scene, n)
    local pts = scene.grid
    if #pts == 0 then return scene.area.x or 0.0, scene.area.y or -1.5 end
    local bestPt, bestGap = pts[((n - 1) % #pts) + 1], -1
    for _, pt in ipairs(pts) do
        local gap = math.huge
        for _, rec in pairs(scene.props) do
            local it = rec.item
            if it.visualX then gap = math.min(gap, (it.visualX - pt.x) ^ 2 + (it.visualY - pt.y) ^ 2) end
        end
        if gap >= (P.spacing * 0.75) ^ 2 then return pt.x, pt.y end
        if gap > bestGap then bestGap, bestPt = gap, pt end
    end
    return bestPt.x, bestPt.y
end

-- ------------------------------------------------------------------ altura
--- Altura do fundo do porta-malas com a folga do motor.
local function floorZ(scene)
    return (scene.area.z or 0.3) + (tonumber(Config.VisualPropPhysics.groundPadding) or 0.006)
end

--- Altura da origem com o objeto apoiado no fundo, na rotacao atual (GetVisualPropFloorOriginZ da D12).
function PT.RestZ(scene, rec)
    local it = rec.item
    return PT.GetVisualPropFloorOriginZ(rec, floorZ(scene), it.visualPitch, it.visualRoll, it.visualYaw)
end

--- Altura acima do fundo (o que vai para o banco).
function PT.LiftOf(scene, rec)
    return (tonumber(rec.item.visualZ) or PT.RestZ(scene, rec)) - PT.RestZ(scene, rec)
end

-- ------------------------------------------------------------------ objetos
local function loadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
    return HasModelLoaded(model)
end

--- Pitch exatamente em +-90 (o motor da D12 deita assim itens como armas e calcados) trava a rotacao do attach
--- (gimbal lock): a matriz do objeto vira NaN e o GTA nao o desenha. Afasta 0,05 grau, o que nao se ve.
function PT.SafePitch(p)
    p = tonumber(p) or 0.0
    if math.abs(math.abs(p) - 90.0) < 0.05 then return p < 0 and -89.95 or 89.95 end
    return p
end

--- Prende o objeto na pose do item. No modo fisico pelo attach do motor (colisao conforme a fisica); nos outros
--- carros, so visual, sem colisao.
function PT.ApplyPose(scene, rec)
    if not rec.entity or not DoesEntityExist(rec.entity) or not DoesEntityExist(scene.vehicle) then return end
    local it = rec.item
    if scene.physical then
        PT.ApplyPropLocalTransform(rec, it.visualX, it.visualY, it.visualZ, it.visualYaw, it.visualPitch, it.visualRoll)
        return
    end
    local x, y, z = PT.ApplyPropBrowserPivotOffset(it, rec.scale, it.visualX, it.visualY, it.visualZ,
        it.visualYaw, it.visualPitch, it.visualRoll)
    AttachEntityToEntity(rec.entity, scene.vehicle, 0, x, y, z, PT.SafePitch(it.visualPitch), it.visualRoll, it.visualYaw,
        false, false, false, false, 2, true)
    FreezeEntityPosition(rec.entity, true)
    SetEntityHasGravity(rec.entity, false)
    SetEntityCollision(rec.entity, false, false)
end

local function spawn(scene, rec)
    if not loadModel(rec.model) or not DoesEntityExist(scene.vehicle) then return false end
    PT.LoadItemAssets(rec.visual)   -- arma: o asset, senao o objeto fica invisivel
    local obj = CreateObjectNoOffset(rec.model, 0.0, 0.0, -100.0, false, false, false)
    SetModelAsNoLongerNeeded(rec.model)
    if obj == 0 then return false end
    SetEntityCollision(obj, false, false)
    rec.entity = obj
    rec.scale = PT.AutoScale(rec.scale, rec.model)
    return true
end

local function deleteRec(rec)
    if rec.entity and DoesEntityExist(rec.entity) then DeleteEntity(rec.entity) end
    rec.entity = nil
end

--- physical: a cena do modo fisico (o motor mexe nela); senao, so para ver.
function PT.NewScene(vehicle, physical)
    local area = PT.AreaOf(vehicle)
    return { vehicle = vehicle, area = area, grid = gridPoints(area), props = {}, pending = {}, physical = physical == true }
end

function PT.ClearScene(scene)
    if not scene then return end
    for _, rec in pairs(scene.props) do deleteRec(rec) end
    scene.props = {}
end

function PT.KeyOf(it)
    if it.key then return it.key end
    if it.uid ~= nil then return tostring(it.uid) end
    return ('slot:%d:%s'):format(it.slot, it.item)
end

local function newRec(key, it)
    local v = PT.ItemVisual(it.item, it.amount)
    return {
        key = key, model = v.model, scale = v.scale, category = v.category, itemName = it.item, visual = v,
        item = { slot = it.slot, instanceId = key, name = v.name, id = v.name, category = v.category, propPivot = v.pivot,
            visualYaw = 0.0, visualPitch = 0.0, visualRoll = 0.0 },
    }
end

--- Acerta a cena com a lista de itens ({ slot, item, uid, key?, pose? }). Objetos de itens que sairam somem, os que
--- entraram aparecem (na pose salva, no ponto onde foram soltos ou na grade) e os que ganharam uid trocam de chave.
--- Devolve os registros cuja pose precisa ser salva (soltos num ponto, ou que trocaram de chave ja posicionados) e
--- quantos itens ficaram sem objeto (modelo que nao carregou a tempo: quem chama tenta de novo).
function PT.SyncScene(scene, items)
    local toSave = {}
    local wanted, order = {}, {}
    for i = 1, math.min(#items, P.max) do
        local it = items[i]
        local key = PT.KeyOf(it)
        if not wanted[key] then
            wanted[key] = it
            order[#order + 1] = key
        end
    end
    -- Item que ganhou uid: o registro 'slot:<n>:<item>' do mesmo slot e item passa para a chave nova.
    for key, it in pairs(wanted) do
        if not scene.props[key] then
            for oldKey, rec in pairs(scene.props) do
                if not wanted[oldKey] and oldKey:sub(1, 5) == 'slot:' and rec.item.slot == it.slot and rec.itemName == it.item then
                    scene.props[oldKey] = nil
                    rec.key, rec.item.instanceId = key, key
                    scene.props[key] = rec
                    if rec.posed then toSave[#toSave + 1] = rec end
                    break
                end
            end
        end
    end
    for key, rec in pairs(scene.props) do
        if not wanted[key] then
            deleteRec(rec)
            scene.props[key] = nil
        end
    end
    local now = GetGameTimer()
    local lift = scene.physical and PT.VisualPhysicsEnabled() and (tonumber(Config.VisualPropPhysics.spawnLift) or 0.065) or 0.0
    for n, key in ipairs(order) do
        local it = wanted[key]
        local rec = scene.props[key]
        if rec then
            rec.item.slot = it.slot
            -- A quantidade mudou de faixa (Config.ItemModelsByAmount): o objeto troca de modelo no mesmo lugar e
            -- assenta de novo (outro tamanho).
            local v = PT.ItemVisual(it.item, it.amount)
            if v.model ~= rec.model and rec.entity then
                local old, oldModel, oldScale, oldVisual = rec.entity, rec.model, rec.scale, rec.visual
                rec.model, rec.scale, rec.visual = v.model, v.scale, v
                if spawn(scene, rec) then
                    if DoesEntityExist(old) then DeleteEntity(old) end
                    rec.item.visualZ = PT.RestZ(scene, rec) + lift
                    rec.item._ptPhysicsRuntimeZ = rec.item.visualZ
                    if scene.physical and PT.VisualPhysicsEnabled() then PT.PhysicsSpawned(rec, false) end
                    PT.ApplyPose(scene, rec)
                    if rec.posed then toSave[#toSave + 1] = rec end
                else
                    rec.entity, rec.model, rec.scale, rec.visual = old, oldModel, oldScale, oldVisual
                end
            end
        else
            rec = newRec(key, it)
            local item = rec.item
            local pose, drop = it.pose, scene.pending[it.slot]
            -- Do chao o servidor escolhe o slot: o ponto vale para o primeiro item novo com o mesmo nome.
            if not drop and scene.pendingItem and scene.pendingItem.item == it.item then
                drop = scene.pendingItem
                scene.pendingItem = nil
            end
            local z = lift
            if pose then
                -- A pose salva passa pela mesma trava da area que o arraste usa: uma pose fora dela (area recalibrada,
                -- pose de outro modelo) deixava o objeto dentro da lataria, invisivel ate ser arrastado. Corrigida, e
                -- gravada de novo.
                item.visualX, item.visualY = PT.ClampToArea(scene.area.areaPoints, pose.x, pose.y)
                if math.abs(item.visualX - pose.x) > 0.001 or math.abs(item.visualY - pose.y) > 0.001 then
                    toSave[#toSave + 1] = rec
                end
                item.visualYaw, item.visualPitch, item.visualRoll = pose.yaw, pose.pitch, pose.roll
                z = pose.z
                rec.posed = true
            elseif drop and now - drop.at < 6000 then
                scene.pending[it.slot] = nil
                item.visualX, item.visualY = PT.ClampToArea(scene.area.areaPoints, drop.x, drop.y)
                item.visualYaw = ((n * 37) % 30) - 15.0
                rec.posed = true
                toSave[#toSave + 1] = rec
            else
                item.visualX, item.visualY = freeSpot(scene, n)
                item.visualYaw = ((n * 37) % 30) - 15.0
            end
            if spawn(scene, rec) then
                item.visualZ = PT.RestZ(scene, rec) + z
                item._ptPhysicsRuntimeZ = item.visualZ
                scene.props[key] = rec
                if scene.physical and PT.VisualPhysicsEnabled() then PT.PhysicsSpawned(rec, pose ~= nil) end
                PT.ApplyPose(scene, rec)
            end
        end
    end
    local missing = 0
    for _, key in ipairs(order) do
        if not scene.props[key] then missing = missing + 1 end
    end
    return toSave, missing
end

--- Assinatura de uma lista de itens com pose (cena de outro carro): so remonta quando muda.
function PT.Signature(items)
    local parts = {}
    for _, it in ipairs(items) do
        local p = it.pose
        parts[#parts + 1] = ('%s:%s:%s'):format(it.slot, PT.KeyOf(it),
            p and ('%.3f,%.3f,%.3f,%.1f,%.1f,%.1f'):format(p.x, p.y, p.z, p.yaw, p.pitch, p.roll) or '')
    end
    return table.concat(parts, ',')
end
