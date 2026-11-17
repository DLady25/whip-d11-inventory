-- d11_ptrunk (cliente): mexer nos objetos do porta-malas no modo fisico (fases 2 e 3).
-- Porte da interacao do velocity-physicaltrunk (D12): o mouse vem do renderer d11_inventory (a pagina do WHIP tem o
-- foco), o raio sai da camera do porta-malas e encontra o plano do objeto no espaco do carro.
--   passar o mouse: contorno + a dica do item (a mesma do card)
--   clicar e arrastar: move no plano, suave (DRAG_FLOW_GUARDRAIL.md da D12); Q/E giram durante o arraste. Ao soltar,
--   a fisica assume (o objeto cai, assenta, empurra os outros) e grava onde parou
--   clicar: seleciona (MoveMode da D12): o objeto fica onde esta, a fisica nao mexe nele, e o teclado manda: WASD move
--   (Ctrl fino, Shift rapido), R/F sobe/desce, Q/E giram (yaw; Shift pitch; Ctrl roll). Clicar fora solta: ele cai
--   soltar no painel do jogador: retira (o renderer faz o movimento nativo)
--   botao direito: Retirar, Inspecionar, Posicionar com teclado, Endireitar
--   inspecionar: o item na frente da camera, Q/E e R/F giram; clique, botao direito ou Backspace saem
local MoveMode, Drag = PT.PhysMoveMode, PT.PhysDrag

local W = exports.whip_core

local E = {
    scene = nil, vehicleId = nil, front = false,
    ground = {}, groundAt = 0, groundHover = nil, gdrag = nil, groundBusy = false,
    cursor = { x = 0.5, y = 0.5 }, free = false, moved = true,
    hover = nil, selected = nil, drag = nil, inspect = nil,
    keys = {}, outlined = {}, moveChangedAt = 0,
    highlights = false, grid = false, light = true, gizmo = false, gz = nil, gzHover = nil,
    lastPick = 0,
}

local COMMIT_DELAY = 650     -- ms parado antes de gravar o teclado (commitMoveModeTransform da D12)
local MOVED_TTL = 1800       -- ms em que o objeto mexido vence a fisica dos outros (MarkVisualPropPlayerMoved)

local function wrap(a)
    a = (tonumber(a) or 0.0) % 360.0
    if a > 180.0 then a = a - 360.0 end
    return a
end

local function key(name) return E.keys[name] == true end

-- ------------------------------------------------------------------ poses
--- Grava a pose do objeto (a altura vai como "acima do fundo").
function PT.SavePose(rec)
    if not E.vehicleId or not E.scene or not rec or not rec.key or not rec.entity then return end
    local it = rec.item
    rec.posed = true
    TriggerServerEvent('d11_ptrunk:server:pose', E.vehicleId, rec.key, it.visualX, it.visualY, PT.LiftOf(E.scene, rec),
        wrap(it.visualYaw), wrap(it.visualPitch), wrap(it.visualRoll))
end

--- O motor da D12 assentou um objeto: grava onde ele parou.
function PT.PhysicsPersist(_, data)
    local rec = E.scene and data and E.scene.props[data.instanceId]
    if rec then PT.SavePose(rec) end
end

-- ------------------------------------------------------------------ cursor -> mundo
local function cursorRay()
    local cam = PT.ActiveCamera()
    if not cam then return nil end
    local right, forward, up, origin = GetCamMatrix(cam)
    local half = math.tan(math.rad(GetCamFov(cam)) * 0.5)
    local nx = (E.cursor.x - 0.5) * 2.0 * half * GetAspectRatio(false)
    local ny = (0.5 - E.cursor.y) * 2.0 * half
    local d = forward + right * nx + up * ny
    return origin, d / #d
end

--- Onde o cursor encontra o plano horizontal do porta-malas a `z` (espaco do carro); devolve x, y locais.
local function planeHit(z)
    local o, d = cursorRay()
    if not o or not E.scene then return nil end
    local veh = E.scene.vehicle
    local _, _, up = GetEntityMatrix(veh)
    local p = GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, z)
    local denom = d.x * up.x + d.y * up.y + d.z * up.z
    if math.abs(denom) < 0.00001 then return nil end
    local t = ((p.x - o.x) * up.x + (p.y - o.y) * up.y + (p.z - o.z) * up.z) / denom
    if t <= 0.0 then return nil end
    local hit = o + d * t
    local l = GetOffsetFromEntityGivenWorldCoords(veh, hit.x, hit.y, hit.z)
    return l.x, l.y
end

local function planeZ(rec)
    if rec and tonumber(rec.item.visualZ) then return rec.item.visualZ end
    return E.scene.area.z or 0.3
end

local function apply(rec)
    local it = rec.item
    PT.ApplyPropLocalTransform(rec, it.visualX, it.visualY, it.visualZ, it.visualYaw, it.visualPitch, it.visualRoll)
end

-- ------------------------------------------------------------------ escolher o objeto sob o cursor
local function screenBounds(rec)
    local mn, mx = GetModelDimensions(rec.model)
    local b = { x0 = math.huge, y0 = math.huge, x1 = -math.huge, y1 = -math.huge }
    local seen = false
    for _, x in ipairs({ mn.x, mx.x }) do
        for _, y in ipairs({ mn.y, mx.y }) do
            for _, z in ipairs({ mn.z, mx.z }) do
                local w = GetOffsetFromEntityInWorldCoords(rec.entity, x, y, z)
                local on, sx, sy = GetScreenCoordFromWorldCoord(w.x, w.y, w.z)
                if on then
                    seen = true
                    b.x0, b.y0 = math.min(b.x0, sx), math.min(b.y0, sy)
                    b.x1, b.y1 = math.max(b.x1, sx), math.max(b.y1, sy)
                end
            end
        end
    end
    return seen and b or nil
end

--- O objeto sob o cursor: dentro da caixa projetada (com uma folga e um tamanho minimo), o mais perto do centro e da
--- camera vence (PT.GetSelectedVisualProp da D12, sem o atraso).
local function pick()
    if not E.scene or not E.free then return nil end
    local cam = PT.ActiveCamera()
    local camPos = cam and GetCamCoord(cam)
    local cx, cy = E.cursor.x, E.cursor.y
    local best, bestScore = nil, math.huge
    for _, rec in pairs(E.scene.props) do
        if rec.entity and DoesEntityExist(rec.entity) then
            local b = screenBounds(rec)
            if b then
                local w = math.max(b.x1 - b.x0, 0.018)
                local h = math.max(b.y1 - b.y0, 0.018)
                local mx, my = (b.x0 + b.x1) * 0.5, (b.y0 + b.y1) * 0.5
                local ndx, ndy = (cx - mx) / (w * 0.5 + 0.006), (cy - my) / (h * 0.5 + 0.006)
                if math.abs(ndx) <= 1.0 and math.abs(ndy) <= 1.0 then
                    local dist = camPos and #(camPos - GetEntityCoords(rec.entity)) or 0.0
                    local score = ndx * ndx + ndy * ndy + dist * 0.15
                    if score < bestScore then best, bestScore = rec, score end
                end
            end
        end
    end
    return best
end

-- ------------------------------------------------------------------ itens no chao (pegar e guardar no porta-malas)
local function refreshGround()
    if E.groundBusy or not E.vehicleId or GetGameTimer() - E.groundAt < 1000 then return end
    E.groundBusy, E.groundAt = true, GetGameTimer()
    local vid = E.vehicleId
    CreateThread(function()
        local list = W:Callback('d11_ptrunk:groundNear', vid)
        if E.vehicleId == vid then
            E.ground = type(list) == 'table' and list or {}
            PT.GSSync(E.ground)
        end
        E.groundBusy = false
    end)
end

--- O objeto do chao sob o cursor (client/groundphys.lua: os itens do chao sao objetos com fisica nesta sessao).
local function pickGround()
    if not E.scene or not E.free then return nil end
    return PT.GSPick(E.cursor.x, E.cursor.y)
end

-- ------------------------------------------------------------------ chao (todo o chao ate Config.GroundReach)
--- Pontos de reserva perto do porta-malas (Config.GroundArea), no espaco do carro, de perto para longe: so para largar
--- sem cursor no chao (menu, painel). Nada disso e desenhado; com o cursor no chao, o item vai para o ponto dele.
local function groundCells()
    local veh = E.scene.vehicle
    local G = Config.GroundArea
    local dir = PT.AccessData(veh).access == 'front' and 1.0 or -1.0
    local near = PT.AccessY(veh) + dir * G.gap
    local half = G.size * 0.5
    local cells = {}
    local n = math.max(1, math.floor(G.size / G.cell + 0.5))
    for row = 0, n - 1 do
        for col = 0, n - 1 do
            cells[#cells + 1] = { x = -half + G.cell * (col + 0.5), y = near + dir * G.cell * (row + 0.5) }
        end
    end
    return cells
end

--- Ponto do chao de verdade (z do terreno) para um ponto no espaco do carro.
local function groundWorld(x, y)
    local w = GetOffsetFromEntityInWorldCoords(E.scene.vehicle, x, y, 0.0)
    local found, z = GetGroundZFor_3dCoord(w.x, w.y, w.z + 1.0, false)
    return vector3(w.x, w.y, found and z or (w.z - 0.5))
end

local overTrunk

--- O chao sob o cursor (mapa ou objeto, superficie mais deitada que de pe), ate Config.GroundReach do carro e fora do
--- porta-malas e do proprio carro; devolve o ponto no mundo, ou nil.
local function cursorOnGround()
    if not E.scene or overTrunk() then return nil end
    local o, d = cursorRay()
    if not o then return nil end
    local to = o + d * 30.0
    local h = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, to.x, to.y, to.z, 1 | 2 | 16, PlayerPedId(), 7)
    local _, hit, at, normal, ent = GetShapeTestResult(h)
    if hit ~= 1 or normal.z < 0.55 then return nil end
    if ent and ent ~= 0 and (ent == E.scene.vehicle or IsEntityAVehicle(ent)) then return nil end
    if #(at - GetEntityCoords(E.scene.vehicle)) > Config.GroundReach then return nil end
    return at
end

E.reserved = {}   -- [ponto] = ate quando: ponto escolhido, esperando o item aparecer na lista do chao

--- O proximo ponto de reserva livre (sem item do chao a menos de meia celula, nem reservado ha pouco), no mundo.
local function freeCell()
    local cells = groundCells()
    local veh = E.scene.vehicle
    local now = GetGameTimer()
    local r2 = (Config.GroundArea.cell * 0.5) ^ 2
    for i, c in ipairs(cells) do
        if (E.reserved[i] or 0) < now then
            local busy = false
            for _, g in ipairs(E.ground) do
                local l = GetOffsetFromEntityGivenWorldCoords(veh, g.x, g.y, g.z)
                if (l.x - c.x) ^ 2 + (l.y - c.y) ^ 2 < r2 then busy = true break end
            end
            if not busy then
                E.reserved[i] = now + 2500
                return groundWorld(c.x, c.y)
            end
        end
    end
    return groundWorld(cells[1].x, cells[1].y)
end

--- O cursor esta em cima da area do porta-malas?
function overTrunk()
    if not E.scene then return false end
    local x, y = planeHit(E.scene.area.z or 0.3)
    return x ~= nil and PT.InsidePolygon(E.scene.area.areaPoints, x, y)
end

-- ------------------------------------------------------------------ desenho
local OUTLINE = { hover = { 255, 214, 110, 145 }, selected = { 70, 210, 255, 180 } }

local function setOutlines()
    local want = {}
    if E.highlights then
        for _, rec in pairs(E.scene.props) do if rec.entity then want[rec.entity] = true end end
    end
    if E.selected and E.selected.entity then want[E.selected.entity] = true end
    if E.hover and E.hover.entity then want[E.hover.entity] = true end
    for ent in pairs(E.outlined) do
        if not want[ent] and DoesEntityExist(ent) then SetEntityDrawOutline(ent, false) end
    end
    local c = (E.hover and E.hover ~= E.selected) and OUTLINE.hover or OUTLINE.selected
    SetEntityDrawOutlineColor(c[1], c[2], c[3], c[4])
    for ent in pairs(want) do
        if DoesEntityExist(ent) then SetEntityDrawOutline(ent, true) end
    end
    E.outlined = want
end

local function clearOutlines()
    for ent in pairs(E.outlined) do
        if DoesEntityExist(ent) then SetEntityDrawOutline(ent, false) end
    end
    E.outlined = {}
end

--- Caixa do objeto selecionado (as 12 arestas), para separar do contorno de passar o mouse.
local function drawBox(rec)
    local mn, mx = GetModelDimensions(rec.model)
    local c = {}
    for i, v in ipairs({
        { mn.x, mn.y, mn.z }, { mx.x, mn.y, mn.z }, { mx.x, mx.y, mn.z }, { mn.x, mx.y, mn.z },
        { mn.x, mn.y, mx.z }, { mx.x, mn.y, mx.z }, { mx.x, mx.y, mx.z }, { mn.x, mx.y, mx.z },
    }) do
        c[i] = GetOffsetFromEntityInWorldCoords(rec.entity, v[1], v[2], v[3])
    end
    for _, e in ipairs({ { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 }, { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
        { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 } }) do
        local a, b = c[e[1]], c[e[2]]
        DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 70, 210, 255, 200)
    end
end

--- Borda da area util e linhas a cada 10 cm dentro dela (drawAreaGridOverlay da D12).
--- A grade da area util (botao Grade), como a drawAreaGridOverlay da D12: 18 mm acima do piso (rente ao piso o
--- forro do porta-malas cobria as linhas), passo de um quinto da area (entre 14 e 30 cm), mais forte arrastando.
local function drawGrid()
    local scene = E.scene
    local poly = scene.area.areaPoints
    if not poly or #poly < 3 then return end
    local veh, z = scene.vehicle, (scene.area.z or 0.3) + 0.018
    local strong = E.drag ~= nil or MoveMode.active
    local edgeA, gridA = strong and 190 or 130, strong and 110 or 70
    local function line(x1, y1, x2, y2, r, g, b, a)
        local p = GetOffsetFromEntityInWorldCoords(veh, x1, y1, z)
        local q = GetOffsetFromEntityInWorldCoords(veh, x2, y2, z)
        DrawLine(p.x, p.y, p.z, q.x, q.y, q.z, r, g, b, a)
    end
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    for i, p in ipairs(poly) do
        local q = poly[(i % #poly) + 1]
        line(p.x, p.y, q.x, q.y, 70, 190, 255, edgeA)
        minX, maxX = math.min(minX, p.x), math.max(maxX, p.x)
        minY, maxY = math.min(minY, p.y), math.max(maxY, p.y)
    end
    -- Cada linha cortada pela area: as intersecoes com as bordas, em pares.
    local function cut(horizontal, k)
        local xs = {}
        for i, p in ipairs(poly) do
            local q = poly[(i % #poly) + 1]
            local a, b = horizontal and p.y or p.x, horizontal and q.y or q.x
            if (a <= k and b > k) or (b <= k and a > k) then
                local t = (k - a) / (b - a)
                xs[#xs + 1] = horizontal and (p.x + (q.x - p.x) * t) or (p.y + (q.y - p.y) * t)
            end
        end
        table.sort(xs)
        for i = 1, #xs - 1, 2 do
            if math.abs(xs[i + 1] - xs[i]) > 0.01 then
                if horizontal then line(xs[i], k, xs[i + 1], k, 90, 210, 255, gridA)
                else line(k, xs[i], k, xs[i + 1], 90, 210, 255, gridA) end
            end
        end
    end
    local stepX = math.max(0.14, math.min(0.30, (maxX - minX) / 5.0))
    local stepY = math.max(0.14, math.min(0.30, (maxY - minY) / 5.0))
    for x = minX + stepX, maxX - 0.02, stepX do cut(false, x) end
    for y = minY + stepY, maxY - 0.02, stepY do cut(true, y) end
end

-- ------------------------------------------------------------------ inspecionar
local function stopInspect()
    local ins = E.inspect
    if not ins then return end
    E.inspect = nil
    if DoesEntityExist(ins.entity) then DeleteEntity(ins.entity) end
    if ins.rec.entity and DoesEntityExist(ins.rec.entity) then ResetEntityAlpha(ins.rec.entity) end
end

local function startInspect(rec)
    stopInspect()
    if not rec or not rec.entity or not IsModelInCdimage(rec.model) then return end
    RequestModel(rec.model)
    local deadline = GetGameTimer() + 1500
    while not HasModelLoaded(rec.model) and GetGameTimer() < deadline do Wait(0) end
    local obj = CreateObjectNoOffset(rec.model, 0.0, 0.0, -100.0, false, false, false)
    SetModelAsNoLongerNeeded(rec.model)
    if obj == 0 then return end
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityAlpha(rec.entity, 90, false)
    local mn, mx = GetModelDimensions(rec.model)
    E.inspect = { rec = rec, entity = obj, yaw = 0.0, pitch = 0.0,
        dist = math.max(0.35, 0.25 + math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z) * 1.2) }
    E.hover, E.drag = nil, nil
end

local function tickInspect()
    local ins = E.inspect
    local cam = PT.ActiveCamera()
    if not cam or not DoesEntityExist(ins.entity) or not ins.rec.entity or not DoesEntityExist(ins.rec.entity) then
        stopInspect()
        return
    end
    if key('backspace') then stopInspect() return end
    local step = key('shift') and 3.0 or 1.2
    if key('e') then ins.yaw = ins.yaw + step end
    if key('q') then ins.yaw = ins.yaw - step end
    if key('r') then ins.pitch = ins.pitch + step end
    if key('f') then ins.pitch = ins.pitch - step end
    local _, forward, _, origin = GetCamMatrix(cam)
    local pos = origin + forward * ins.dist
    local rot = GetCamRot(cam, 2)
    SetEntityCoordsNoOffset(ins.entity, pos.x, pos.y, pos.z, false, false, false)
    SetEntityRotation(ins.entity, rot.x + ins.pitch, 0.0, rot.z + ins.yaw, 2, false)
end

-- ------------------------------------------------------------------ selecionar (MoveMode da D12)
local function selectRec(rec)
    if E.selected == rec then return end
    if E.selected then
        -- Soltar a selecao devolve o objeto a fisica (stopMoveMode + FinalizeOtherVisualPropMoves da D12).
        if MoveMode.dirty then PT.SavePose(E.selected) end
        PT.MarkVisualPropPlayerMoved(E.selected, MOVED_TTL)
    end
    E.selected = rec
    MoveMode.active = rec ~= nil
    MoveMode.slot = rec and rec.item.slot or nil
    MoveMode.instanceId = rec and rec.item.instanceId or nil
    MoveMode.dirty, MoveMode.inFlight, MoveMode.dragging = false, false, false
    if rec then PT.FinalizeOtherVisualPropMoves(rec) end
end

-- ------------------------------------------------------------------ gizmo (pedido de 2026-11-16, liga no botao Gizmo)
-- Com um objeto selecionado: setas X (vermelha), Y (verde), Z (azul) movem so naquele eixo do carro; aneis giram
-- (X = pitch, Y = roll, Z = yaw). O objeto fica com o jogador (MoveMode) enquanto isso; grava ao soltar.
local GZ = { len = 0.22, ring = 0.15, pick = 0.014, segs = 28 }
local AXES = { x = vector3(1.0, 0.0, 0.0), y = vector3(0.0, 1.0, 0.0), z = vector3(0.0, 0.0, 1.0) }
local ROT = { x = 'visualPitch', y = 'visualRoll', z = 'visualYaw' }
local COLOR = { x = { 235, 70, 70 }, y = { 80, 220, 110 }, z = { 70, 140, 255 } }
local PLANE = { x = { 'y', 'z' }, y = { 'x', 'z' }, z = { 'x', 'y' } }

--- Centro do objeto no mundo e os eixos do carro no mundo.
local function gizmoBasis(rec)
    local veh = E.scene.vehicle
    local mn, mx = GetModelDimensions(rec.model)
    local c = GetOffsetFromEntityInWorldCoords(rec.entity, (mn.x + mx.x) * 0.5, (mn.y + mx.y) * 0.5, (mn.z + mx.z) * 0.5)
    local o = GetOffsetFromEntityInWorldCoords(veh, 0.0, 0.0, 0.0)
    local dirs = {}
    for k, a in pairs(AXES) do dirs[k] = GetOffsetFromEntityInWorldCoords(veh, a.x, a.y, a.z) - o end
    return c, dirs
end

local function toScreen(v)
    local on, x, y = GetScreenCoordFromWorldCoord(v.x, v.y, v.z)
    if not on then return nil end
    return x, y
end

local function segDist(px, py, ax, ay, bx, by)
    local aspect = GetAspectRatio(false)
    px, ax, bx = px * aspect, ax * aspect, bx * aspect
    local vx, vy = bx - ax, by - ay
    local len2 = vx * vx + vy * vy
    local t = len2 > 0 and math.max(0.0, math.min(1.0, ((px - ax) * vx + (py - ay) * vy) / len2)) or 0.0
    return math.sqrt((px - ax - vx * t) ^ 2 + (py - ay - vy * t) ^ 2)
end

local function ringPoint(c, dirs, k, i)
    local p = PLANE[k]
    local a = (i / GZ.segs) * math.pi * 2.0
    return c + dirs[p[1]] * (math.cos(a) * GZ.ring) + dirs[p[2]] * (math.sin(a) * GZ.ring)
end

--- O pedaco do gizmo sob o cursor: { kind = 'move' | 'rotate', axis }.
local function gizmoPick(rec)
    local c, dirs = gizmoBasis(rec)
    local cx, cy = E.cursor.x, E.cursor.y
    local best, bestD = nil, GZ.pick
    for k in pairs(AXES) do
        local ax, ay = toScreen(c)
        local bx, by = toScreen(c + dirs[k] * GZ.len)
        if ax and bx then
            local d = segDist(cx, cy, ax, ay, bx, by)
            if d < bestD then best, bestD = { kind = 'move', axis = k }, d end
        end
        local px, py = toScreen(ringPoint(c, dirs, k, 0))
        for i = 1, GZ.segs do
            local qx, qy = toScreen(ringPoint(c, dirs, k, i))
            if px and qx then
                local d = segDist(cx, cy, px, py, qx, qy)
                if d < bestD then best, bestD = { kind = 'rotate', axis = k }, d end
            end
            px, py = qx, qy
        end
    end
    return best
end

local function drawGizmo(rec)
    local c, dirs = gizmoBasis(rec)
    local active = E.gz or E.gzHover
    for k in pairs(AXES) do
        local col = COLOR[k]
        local hotMove = active and active.kind == 'move' and active.axis == k
        local hotRot = active and active.kind == 'rotate' and active.axis == k
        local tip = c + dirs[k] * GZ.len
        local r, g, b = table.unpack(hotMove and { 255, 230, 90 } or col)
        DrawLine(c.x, c.y, c.z, tip.x, tip.y, tip.z, r, g, b, 255)
        DrawMarker(28, tip.x, tip.y, tip.z, 0, 0, 0, 0, 0, 0, 0.018, 0.018, 0.018, r, g, b, 230, false, false, 2, false, nil, nil, false)
        r, g, b = table.unpack(hotRot and { 255, 230, 90 } or col)
        local prev = ringPoint(c, dirs, k, 0)
        for i = 1, GZ.segs do
            local p = ringPoint(c, dirs, k, i)
            DrawLine(prev.x, prev.y, prev.z, p.x, p.y, p.z, r, g, b, hotRot and 255 or 150)
            prev = p
        end
    end
end

local function screenAngle(ox, oy)
    return math.atan(-(E.cursor.y - oy), (E.cursor.x - ox) * GetAspectRatio(false))
end

local function startGizmo(rec, part)
    local c, dirs = gizmoBasis(rec)
    local it = rec.item
    local gz = { rec = rec, kind = part.kind, axis = part.axis, cx = E.cursor.x, cy = E.cursor.y,
        x = it.visualX, y = it.visualY, z = it.visualZ, rot = it[ROT[part.axis]] or 0.0 }
    local ax, ay = toScreen(c)
    if part.kind == 'move' then
        local bx, by = toScreen(c + dirs[part.axis] * GZ.len)
        if not (ax and bx) then return false end
        gz.sx, gz.sy = bx - ax, by - ay
    else
        if not ax then return false end
        gz.ox, gz.oy = ax, ay
        gz.a0 = screenAngle(ax, ay)
        -- Eixo apontando para a camera: anti-horario na tela = giro positivo.
        local cam = PT.ActiveCamera()
        local toCam = cam and (GetCamCoord(cam) - c) or vector3(0.0, 0.0, 1.0)
        local d = dirs[part.axis]
        gz.sign = (d.x * toCam.x + d.y * toCam.y + d.z * toCam.z) >= 0 and 1.0 or -1.0
    end
    E.gz = gz
    MoveMode.dragging = true
    return true
end

local function tickGizmo()
    local gz = E.gz
    local rec = gz.rec
    if not rec.entity or not DoesEntityExist(rec.entity) then E.gz = nil return end
    local it = rec.item
    if gz.kind == 'move' then
        local s2 = gz.sx * gz.sx + gz.sy * gz.sy
        if s2 < 0.0000001 then return end
        local t = ((E.cursor.x - gz.cx) * gz.sx + (E.cursor.y - gz.cy) * gz.sy) / s2 * GZ.len
        local a = AXES[gz.axis]
        local x, y, z = gz.x + a.x * t, gz.y + a.y * t, gz.z + a.z * t
        x, y = PT.ClampToArea(E.scene.area.areaPoints, x, y)
        local baseZ = E.scene.area.z or 0.3
        local minZ = PT.RestZ(E.scene, rec)
        z = math.max(minZ, math.min(math.max(baseZ + 0.35, minZ + 0.12), z))
        it.visualX, it.visualY, it.visualZ, it._ptPhysicsRuntimeZ = x, y, z, z
    else
        local d = screenAngle(gz.ox, gz.oy) - gz.a0
        it[ROT[gz.axis]] = wrap(gz.rot + math.deg(d) * gz.sign)
    end
    PT.MarkVisualPropPlayerMoved(rec, MOVED_TTL)
    apply(rec)
    SetEntityCollision(rec.entity, false, false)
end

-- ------------------------------------------------------------------ arrastar e teclado
local function startDrag(rec)
    selectRec(rec)
    local hx, hy = planeHit(planeZ(rec))
    local it = rec.item
    E.drag = {
        rec = rec, sx = it.visualX, sy = it.visualY, tx = it.visualX, ty = it.visualY, smx = it.visualX, smy = it.visualY,
        ox = hx and it.visualX - hx or 0.0, oy = hy and it.visualY - hy or 0.0, moved = false,
    }
    Drag.active, Drag.slot, Drag.instanceId, Drag.moved = true, it.slot, it.instanceId, false
    MoveMode.dragging = true
end

local function endDrag()
    E.drag = nil
    Drag.active, Drag.moved = false, false
    MoveMode.dragging = false
end

--- Q/E giram o eixo da vez: Ctrl = roll, Shift = pitch, senao yaw (rotationAxisModifier da D12).
local function rotateKeys(it)
    local d = (key('e') and 1.5 or 0.0) - (key('q') and 1.5 or 0.0)
    if d == 0.0 then return false end
    local axis = key('control') and 'visualRoll' or key('shift') and 'visualPitch' or 'visualYaw'
    it[axis] = wrap(it[axis] + d)
    return true
end

local function tickDrag()
    local d = E.drag
    local rec = d.rec
    if not rec.entity or not DoesEntityExist(rec.entity) then endDrag() return end
    local it = rec.item
    if E.moved then
        local hx, hy = planeHit(planeZ(rec))
        d.outside = not hx or not PT.InsidePolygon(E.scene.area.areaPoints, hx, hy)
        if hx then
            local tx, ty = PT.ClampToArea(E.scene.area.areaPoints, hx + d.ox, hy + d.oy)
            d.tx, d.ty = tx, ty
            if math.abs(tx - d.sx) + math.abs(ty - d.sy) > 0.003 then d.moved = true end
        end
    end
    -- Guardrail: o objeto segue o alvo suavizado; ao soltar, vale o alvo (Drag.smooth* / targetX da D12).
    local dx, dy = d.tx - d.smx, d.ty - d.smy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0.0012 then
        d.smx, d.smy = d.tx, d.ty
    else
        local alpha = dist > 0.18 and 1.0 or 0.42
        d.smx, d.smy = d.smx + dx * alpha, d.smy + dy * alpha
    end
    if rotateKeys(it) then d.moved = true end
    if d.moved then
        Drag.moved = true
        PT.MarkVisualPropPlayerMoved(rec, MOVED_TTL)
        it.visualX, it.visualY = d.smx, d.smy
        apply(rec)
        SetEntityCollision(rec.entity, false, false)
    end
end

local function tickKeyboard(rec)
    local it = rec.item
    local placement = Config.VisualPlacement or {}
    local baseZ = E.scene.area.z or 0.3
    local minZ = math.max(baseZ + (tonumber(placement.minZOffset) or 0.0), PT.RestZ(E.scene, rec))
    local maxZ = math.max(baseZ + (tonumber(placement.maxZOffset) or 0.35), minZ + 0.12)
    local sign = E.front and -1.0 or 1.0
    local stepXY = key('control') and 0.003 or (key('shift') and 0.020 or 0.008)
    local stepZ = key('shift') and 0.02 or 0.008
    local x, y = it.visualX, it.visualY
    local z = tonumber(it.visualZ) or minZ
    if key('a') then x = x - stepXY * sign end
    if key('d') then x = x + stepXY * sign end
    if key('w') then y = y + stepXY * sign end
    if key('s') then y = y - stepXY * sign end
    if key('r') then z = z + stepZ end
    if key('f') then z = z - stepZ end
    x, y = PT.ClampToArea(E.scene.area.areaPoints, x, y)
    z = math.max(minZ, math.min(maxZ, z))
    local changed = rotateKeys(it) or x ~= it.visualX or y ~= it.visualY or z ~= it.visualZ
    if changed then
        it.visualX, it.visualY, it.visualZ, it._ptPhysicsRuntimeZ = x, y, z, z
        PT.MarkVisualPropPlayerMoved(rec, MOVED_TTL)
        apply(rec)
        SetEntityCollision(rec.entity, false, false)
        MoveMode.dirty = true
        E.moveChangedAt = GetGameTimer()
    elseif MoveMode.dirty and GetGameTimer() - E.moveChangedAt >= COMMIT_DELAY then
        MoveMode.dirty = false
        PT.SavePose(rec)
    end
end

-- ------------------------------------------------------------------ ciclo
function PT.EditBegin(scene, vehicleId, front)
    E.scene, E.vehicleId, E.front = scene, vehicleId, front == true
    E.hover, E.selected, E.drag, E.keys = nil, nil, nil, {}
    E.free, E.moved = false, true
    -- Como na D12: cada abertura comeca com a luz acesa, sem grade e sem destaques; as abas visiveis (Ocultar HUD no
    -- cabecalho do porta-malas deixa elas 98% transparentes, no renderer).
    E.light, E.grid, E.highlights, E.hud = true, false, false, false
    E.groundAt = 0
    local veh = scene.vehicle
    PT.GSStart(function(g)
        return DoesEntityExist(veh) and #(vector3(g.x, g.y, g.z) - GetEntityCoords(veh)) <= Config.GroundReach
    end)
end

function PT.EditEnd()
    if E.selected and MoveMode.dirty then PT.SavePose(E.selected) end
    endDrag()
    selectRec(nil)
    stopInspect()
    clearOutlines()
    E.scene, E.vehicleId, E.hover, E.keys = nil, nil, nil, {}
    E.ground, E.groundHover, E.gdrag = {}, nil, nil
    E.gz, E.gzHover = nil, nil
    PT.GSHover(nil)
    PT.GSStop()
end

function PT.EditLightOn() return E.light end

--- Um objeto selecionado para o teclado (WASD move o objeto; o personagem fica parado).
function PT.EditSelecting() return E.selected ~= nil end

function PT.EditTick()
    if not E.scene then return end
    HideHudAndRadarThisFrame()   -- HUD e radar do GTA fora enquanto o modo dura
    -- O objeto escolhido pode ter sumido (o item saiu do porta-malas por um painel).
    if E.drag and E.scene.props[E.drag.rec.key] ~= E.drag.rec then endDrag() end
    if E.selected and E.scene.props[E.selected.key] ~= E.selected then
        E.selected = nil
        MoveMode.active = false
    end
    if E.inspect then
        tickInspect()
    elseif E.gz then
        tickGizmo()
    elseif E.drag then
        tickDrag()
    else
        local now = GetGameTimer()
        if E.moved or now - E.lastPick > 150 then
            E.hover = pick()
            E.groundHover = (not E.hover and not E.gdrag) and pickGround() or nil
            E.lastPick = now
        end
        refreshGround()
        -- O objeto do chao na mao segue o cursor pelo mundo, ate GroundReach do carro (client/groundphys.lua).
        if E.gdrag then
            local veh = E.scene.vehicle
            PT.GSDragTick(E.cursor.x, E.cursor.y, { q = key('q'), e = key('e'), r = key('r'), f = key('f'),
                shift = key('shift'), control = key('control') }, function(at)
                return #(at - GetEntityCoords(veh)) <= Config.GroundReach
            end)
        end
        PT.GSHover(E.gdrag or E.groundHover)
        local spot = (E.drag or E.carrying) and cursorOnGround() or nil
        if spot then PT.DrawGroundSpot(spot, true) end
        if E.selected and not E.gdrag then tickKeyboard(E.selected) end
        E.gzHover = E.gizmo and E.selected and E.selected.entity and E.free and gizmoPick(E.selected) or nil
    end
    E.moved = false
    if not E.inspect then setOutlines() else clearOutlines() end
    if E.selected and E.selected.entity and not E.inspect then
        if E.gizmo then drawGizmo(E.selected) else drawBox(E.selected) end
    end
    if E.grid then drawGrid() end
end

-- ------------------------------------------------------------------ o renderer
local function setCursor(data)
    if type(data) ~= 'table' then return end
    local x, y = tonumber(data.x), tonumber(data.y)
    if x and y then
        E.cursor.x, E.cursor.y = math.max(0.0, math.min(1.0, x)), math.max(0.0, math.min(1.0, y))
        E.moved = true
    end
    if data.free ~= nil then E.free = data.free == true end
end

local function recOf(data)
    local k = type(data) == 'table' and data.key
    return E.scene and k and E.scene.props[k] or nil
end

--- Liga/desliga luz, grade ou destaques do modo fisico; devolve o estado novo.
local TOGGLES = { light = true, grid = true, highlights = true, gizmo = true, hud = true }
function PT.EditToggle(what)
    if TOGGLES[what] then E[what] = not E[what] end
    return E[what]
end

function PT.EditState()
    return { light = E.light, grid = E.grid, highlights = E.highlights, gizmo = E.gizmo, hud = E.hud }
end

-- Mouse no meio da tela: { x, y (0-1), free (fora das janelas) }. Responde o objeto sob o cursor, para a dica.
RegisterNUICallback('pointer', function(data, cb)
    setCursor(data)
    local h = E.scene and not E.drag and not E.inspect and E.free and E.hover or nil
    local g = E.scene and not E.drag and not E.gdrag and E.groundHover or nil
    E.carrying = type(data) == 'table' and data.carrying == true
    cb({ hover = h and h.item.slot or nil, drag = E.drag ~= nil, overTrunk = overTrunk(),
        overGround = cursorOnGround() ~= nil, ground = g and PT.GSLabel(g) or nil })
end)

RegisterNUICallback('down', function(data, cb)
    if not E.scene then return cb({}) end
    if E.inspect then stopInspect() return cb({}) end
    setCursor(data)
    E.free = true
    if E.gizmo and E.selected and E.selected.entity then
        local part = gizmoPick(E.selected)
        if part and startGizmo(E.selected, part) then return cb({ gizmo = true }) end
    end
    local rec = pick()
    if not rec then
        local g = pickGround()
        if g and PT.GSGrab(g) then
            E.gdrag, E.groundHover = g, nil
            return cb({ grabGround = { id = g.id, label = PT.GSLabel(g) } })
        end
        selectRec(nil)
        return cb({})
    end
    startDrag(rec)
    cb({ grab = { slot = rec.item.slot, key = rec.key } })
end)

-- { cancel = true }: o objeto foi solto no painel do jogador (o renderer retira o item); senao, fica onde parou e a
-- fisica assume dali.
RegisterNUICallback('up', function(data, cb)
    if E.gz then
        local rec = E.gz.rec
        E.gz = nil
        MoveMode.dragging = false
        if rec.entity then PT.SavePose(rec) end
        return cb({})
    end
    local g = E.gdrag
    if g then
        E.gdrag = nil
        setCursor(data)
        if type(data) == 'table' and data.cancel then
            -- No painel do jogador: guarda nos bolsos (o servidor confere e devolve ao chao se nao couber).
            TriggerServerEvent('d11_ptrunk:server:groundTake', g.id, 'player', 0)
            PT.GSDiscard(g)
            return cb({})
        end
        -- Numa bolsa ou caixa aberta ({ to = 'panel:<id>', slot }): guarda nela (mesmo caminho do chao livre).
        if type(data) == 'table' and type(data.to) == 'string' and data.to:find('^panel:') then
            TriggerServerEvent('d11_ptrunk:server:groundTake', g.id, data.to, math.floor(tonumber(data.slot) or 0))
            PT.GSDiscard(g)
            return cb({})
        end
        -- Bolsa cheia: volta para onde estava.
        if type(data) == 'table' and data.back then
            PT.GSCancel()
            return cb({})
        end
        local x, y = planeHit(E.scene.area.z or 0.3)
        if x and PT.InsidePolygon(E.scene.area.areaPoints, x, y) then
            -- Em cima do porta-malas: guarda (o objeto do chao some; o do porta-malas nasce onde soltou).
            E.scene.pendingItem = { item = g.item, x = x, y = y, at = GetGameTimer() }
            TriggerServerEvent('d11_ptrunk:server:fromGround', E.vehicleId, g.id)
            PT.GSDiscard(g)
        else
            -- No mundo: cai com a fisica do jogo e grava onde assentar.
            PT.GSDrop()
        end
        E.groundAt = 0
        return cb({})
    end
    local d = E.drag
    if not d then return cb({}) end
    local rec = d.rec
    local it = rec.item
    endDrag()
    if type(data) == 'table' and data.cancel then
        it.visualX, it.visualY = d.sx, d.sy
        apply(rec)
        return cb({})
    end
    -- Solto fora do porta-malas (no meio da tela): o objeto volta e o renderer larga o item no chao.
    if d.moved and d.outside then
        it.visualX, it.visualY = d.sx, d.sy
        apply(rec)
        return cb({ ground = true, slot = it.slot })
    end
    cb({})
    if d.moved then
        it.visualX, it.visualY = d.tx, d.ty
        PT.MarkVisualPropPlayerMoved(rec, MOVED_TTL)
        apply(rec)
        PT.SavePose(rec)
    else
        apply(rec)
    end
end)

local KEYS = { w = true, a = true, s = true, d = true, q = true, e = true, r = true, f = true,
    shift = true, control = true, backspace = true }
RegisterNUICallback('key', function(data, cb)
    cb({})
    if type(data) == 'table' and KEYS[data.key] then E.keys[data.key] = data.down == true end
end)

RegisterNUICallback('ctx', function(data, cb)
    if not E.scene then return cb({}) end
    if E.inspect then stopInspect() return cb({}) end
    setCursor(data)
    E.free = true
    local rec = pick()
    if not rec then return cb({}) end
    cb({ slot = rec.item.slot, key = rec.key })
end)

-- { what = 'inspect' | 'select' | 'reset', key }
RegisterNUICallback('action', function(data, cb)
    cb({})
    local rec = recOf(data)
    if not rec then return end
    local what = data.what
    if what == 'inspect' then
        CreateThread(function() startInspect(rec) end)
    elseif what == 'select' then
        selectRec(rec)
    elseif what == 'reset' then
        -- Endireitar: de pe e apoiado no fundo, so o yaw fica (resetVisualBase da D12).
        local it = rec.item
        it.visualPitch, it.visualRoll = 0.0, 0.0
        it.visualZ = PT.RestZ(E.scene, rec)
        it._ptPhysicsRuntimeZ = it.visualZ
        PT.MarkVisualPropPlayerMoved(rec, MOVED_TTL)
        apply(rec)
        PT.SavePose(rec)
    end
end)

-- Largar no chao o item de `slot` do porta-malas: aos pes do jogador, no chao de verdade. Quem tira do porta-malas e
-- cria o item no chao e o servidor (o WHIP so larga dos bolsos).
RegisterNUICallback('toGround', function(data, cb)
    cb({})
    if not E.scene or type(data) ~= 'table' or not tonumber(data.slot) then return end
    local from = data.from == 'container' and 'trunk' or data.from
    local panel = type(from) == 'string' and from:match('^panel:(.+)$')   -- bolsa ou caixa aberta (aba do painel)
    if not panel and from ~= 'trunk' and from ~= 'player' and from ~= 'accessory' then return end
    local w
    if data.x and data.y then
        setCursor(data)
        w = cursorOnGround()
    end
    w = w or freeCell()
    if panel then
        TriggerServerEvent('d11_ptrunk:server:panelToGround', E.vehicleId, panel, tonumber(data.slot), w.x, w.y, w.z,
            GetEntityHeading(E.scene.vehicle))
    else
        TriggerServerEvent('d11_ptrunk:server:toGround', E.vehicleId, from, tonumber(data.slot), w.x, w.y, w.z,
            GetEntityHeading(E.scene.vehicle))
    end
    E.groundAt = 0
end)

-- Camera orbital: { dx, dy } (fracao da tela) com o botao direito arrastando; { delta } da roda.
RegisterNUICallback('orbit', function(data, cb)
    cb({})
    if type(data) == 'table' then PT.OrbitInput(tonumber(data.dx) or 0.0, tonumber(data.dy) or 0.0) end
end)

-- Ponto de foco: { dx, dy } com o botao do meio (ou Shift + direito) arrastando; 'recenter' no clique do meio.
RegisterNUICallback('pan', function(data, cb)
    cb({})
    if type(data) == 'table' then PT.OrbitPan(tonumber(data.dx) or 0.0, tonumber(data.dy) or 0.0) end
end)

RegisterNUICallback('recenter', function(_, cb)
    cb({})
    PT.OrbitRecenter()
end)

-- Botao Camera do cabecalho: volta giro, zoom e foco para a vista inicial.
RegisterNUICallback('camreset', function(_, cb)
    cb({})
    PT.OrbitReset()
end)

RegisterNUICallback('zoom', function(data, cb)
    cb({})
    if type(data) == 'table' and tonumber(data.delta) then PT.OrbitZoom(tonumber(data.delta)) end
end)

RegisterNUICallback('toggle', function(data, cb)
    local what = type(data) == 'table' and data.what
    if TOGGLES[what] then E[what] = not E[what] end
    if what == 'gizmo' then E.gz, E.gzHover = nil, nil end
    cb(PT.EditState())
end)

-- Um item dos bolsos solto no meio da tela vai para `slot`: o objeto nasce onde o mouse soltou.
RegisterNUICallback('place', function(data, cb)
    cb({})
    if not E.scene or type(data) ~= 'table' or not tonumber(data.slot) then return end
    setCursor(data)
    local x, y = planeHit(planeZ(nil))
    if x then E.scene.pending[tonumber(data.slot)] = { x = x, y = y, at = GetGameTimer() } end
end)

function PT.EditInspecting() return E.inspect ~= nil end
