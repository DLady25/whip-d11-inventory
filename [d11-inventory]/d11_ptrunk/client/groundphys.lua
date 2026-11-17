-- d11_ptrunk (cliente): os itens do chao como objetos com fisica (pedido de 2026-11-16: "a mesma dinamica do
-- porta-malas, fisica, empilhamento"). No chao a fisica e a do proprio GTA, porque ha chao de verdade para colidir
-- (no porta-malas a D12 precisava do motor proprio: os objetos ficavam presos ao carro, sem chao). Enquanto a sessao
-- dura, o whip_core nao desenha esses itens (patch HoldGroundProp) e cada um vira um objeto local deste jogo:
--   arrastar: o proprio objeto segue o cursor pelo mundo, sem colidir. Q/E giram (Shift: pitch, Ctrl: roll), R/F
--     sobem/descem (pedido de 2026-11-16: passar por cima e apoiar em mesa ou em outro objeto)
--   soltar: volta a colidir e cai; empilha, tomba e empurra os vizinhos com a fisica do jogo
--   assentou: a pose (posicao e inclinacao) vai para o servidor (MoveGroundItem, mesmo id) e todo mundo ve igual
-- Fim da sessao (inventario fechou, saiu do porta-malas): o que se mexeu e gravado, os objetos somem e o whip_core
-- volta a desenhar os itens na pose nova.
-- Os itens seguem os eventos do whip_core (criado, apagado, assentado, quantidade) na hora; a lista do servidor
-- (owner da sessao, a cada segundo) so traz o que entrou no alcance andando. Trocar o prop do whip_core pelo objeto
-- daqui e o contrario acontece no mesmo quadro: nunca dois objetos, nunca um buraco.
local W = exports.whip_core

local S = { active = false, recs = {}, holding = nil, hover = nil, outlined = nil }

local SETTLE_FRAMES = 18     -- quadros parado para contar como assentado
local WAKE_RADIUS = 0.7      -- ao soltar, vizinhos a ate isso acordam (podem ser empurrados ou servir de apoio)

local function poseOf(e)
    local c = GetEntityCoords(e)
    local r = GetEntityRotation(e, 2)
    return { x = c.x, y = c.y, z = c.z, rx = r.x, ry = r.y, heading = r.z }
end

local function changed(a, b)
    if not a or not b then return true end
    local function ang(x, y) local d = ((x - y + 180.0) % 360.0) - 180.0 return math.abs(d) end
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2) > 0.02
        or ang(a.heading, b.heading) > 3.0 or ang(a.rx, b.rx) > 3.0 or ang(a.ry, b.ry) > 3.0
end

local function persist(rec)
    if not rec.entity or not DoesEntityExist(rec.entity) then return end
    local p = poseOf(rec.entity)
    if not changed(p, rec.saved) then return end
    rec.saved = p
    rec.pending = true   -- ate o eco (groundItemSettled)
    TriggerServerEvent('d11_ptrunk:server:groundPose', rec.id, p.x, p.y, p.z, p.heading, p.rx, p.ry)
end

local function freeze(rec, frozen)
    if not DoesEntityExist(rec.entity) then return end
    FreezeEntityPosition(rec.entity, frozen)
    if not frozen then
        SetEntityDynamic(rec.entity, true)
        ActivatePhysics(rec.entity)
    end
end

local function spawnRec(g)
    local visual = PT.ItemVisual(g.item, g.amount)
    local model = visual.model
    if not IsModelInCdimage(model) then return nil end
    RequestModel(model)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(model) then return nil end
    PT.LoadItemAssets(visual)   -- arma: o asset, senao o objeto fica invisivel
    local obj = CreateObjectNoOffset(model, g.x, g.y, g.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if obj == 0 then return nil end
    -- Como o whip_core desenha: pose exata se ja foi colocado (placed), senao em pe no chao.
    if g.placed then
        SetEntityCoordsNoOffset(obj, g.x, g.y, g.z, false, false, false)
        SetEntityRotation(obj, g.rx or 0.0, g.ry or 0.0, g.heading or 0.0, 2, true)
    else
        SetEntityHeading(obj, g.heading or 0.0)
        PlaceObjectOnGroundProperly(obj)
    end
    SetEntityCollision(obj, true, true)
    FreezeEntityPosition(obj, true)   -- parado ate alguem mexer nele ou perto dele
    -- So agora o whip_core tira o prop dele: os dois trocam no mesmo quadro.
    W:HoldGroundProp(g.id, true)
    local rec = { id = g.id, item = g.item, amount = g.amount, model = model, entity = obj, watch = false, still = 0 }
    rec.saved = poseOf(obj)
    return rec
end

local function deleteObject(rec)
    if rec.entity and DoesEntityExist(rec.entity) then DeleteEntity(rec.entity) end
    rec.entity = nil
end

--- Devolve o item ao whip_core: ele desenha o prop dele (o modelo ja esta carregado) e o daqui some no mesmo quadro.
local function handOver(rec)
    W:HoldGroundProp(rec.id, false)
    deleteObject(rec)
end

-- Depois do fim da sessao ou de pegar um item, o que ainda espera o servidor:
local leaving = {}   -- [id] = rec: pose nova enviada; o whip_core so desenha depois do eco (senao, na pose antiga)
local gone = {}      -- [id] = ate quando: pego (bolsos, stash, porta-malas); segura o prop do whip_core ate o
                     -- servidor apagar (senao ele reaparece no meio); se o servidor recusar, volta a aparecer

-- ------------------------------------------------------------------ sessao
function PT.GSActive() return S.active end

--- inReach(g): se um item ({ x, y, z }) esta no alcance de quem abriu a sessao (jogador ou carro).
function PT.GSStart(inReach)
    if not Config.PhysicalGround then return end   -- chao fisico desligado: os itens ficam com o whip_core
    S.active, S.inReach = true, inReach
end

--- Um item do chao vira objeto daqui (se a sessao esta aberta, esta no alcance e nao esta voando).
local function adopt(g)
    if not S.active or not g or not g.id or g.flight or S.recs[g.id] ~= nil or gone[g.id] then return end
    if S.inReach and not S.inReach(g) then return end
    local back = leaving[g.id]
    if back then   -- a sessao reabriu antes do eco: o mesmo objeto continua
        leaving[g.id] = nil
        S.recs[g.id] = back
        return
    end
    local id = g.id
    S.recs[id] = false   -- carregando
    CreateThread(function()
        local rec = spawnRec(g)
        if rec and S.active and S.recs[id] == false then
            S.recs[id] = rec
        else
            if S.recs[id] == false then S.recs[id] = nil end
            if rec then handOver(rec) end
        end
    end)
end

--- A lista do servidor ({ id, item, amount, x, y, z, heading, placed, rx, ry, flight }): adota o que entrou no
--- alcance; o que saiu do alcance volta para o whip_core. Sumir da lista nao apaga nada: quem apaga e o evento
--- (uma resposta atrasada nao pode tirar um item recem-criado).
function PT.GSSync(list)
    if not S.active then return end
    for _, g in ipairs(list or {}) do adopt(g) end
    if not S.inReach then return end
    for id, rec in pairs(S.recs) do
        if rec and rec.entity and not rec.watch and not (S.holding and S.holding.rec == rec) then
            local c = GetEntityCoords(rec.entity)
            if not S.inReach({ x = c.x, y = c.y, z = c.z }) then
                persist(rec)
                S.recs[id] = nil
                if rec.pending then
                    rec.leaveBy = GetGameTimer() + 2500
                    leaving[id] = rec
                else
                    handOver(rec)
                end
            end
        end
    end
end

--- Fim: grava o que se mexeu e devolve os itens ao whip_core (o que mudou de pose, so depois do eco do servidor).
function PT.GSStop()
    if not S.active then return end
    S.active, S.inReach = false, nil
    S.holding, S.hover = nil, nil
    for id, rec in pairs(S.recs) do
        if rec then
            persist(rec)
            if rec.watch then FreezeEntityPosition(rec.entity, true) end
            if rec.pending then
                rec.leaveBy = GetGameTimer() + 2500
                leaving[id] = rec
            else
                handOver(rec)
            end
        end
        S.recs[id] = nil
    end
end

-- ------------------------------------------------------------------ eventos do whip_core (todos os clientes recebem)
RegisterNetEvent('whip_core:client:groundItemCreated', function(data)
    if type(data) == 'table' then adopt(data) end
end)

-- Pousou (arremesso) ou mudou de pose (MoveGroundItem: nosso eco ou outro jogador).
RegisterNetEvent('whip_core:client:groundItemSettled', function(data)
    if type(data) ~= 'table' or not data.id then return end
    local id = data.id
    local rec = S.recs[id] or leaving[id]
    if not rec then return adopt(data) end
    local p = { x = data.x, y = data.y, z = data.z, rx = data.rx or 0.0, ry = data.ry or 0.0, heading = data.heading or 0.0 }
    if rec.pending then
        -- Esperando o eco do que gravamos: o eco da ultima pose libera; um eco mais antigo nao mexe em nada.
        if not changed(p, rec.saved) then rec.pending = nil end
    elseif rec.entity and not rec.watch and not (S.holding and S.holding.rec == rec) then
        -- Outro jogador mexeu: o objeto daqui vai para a pose nova.
        SetEntityCoordsNoOffset(rec.entity, p.x, p.y, p.z, false, false, false)
        SetEntityRotation(rec.entity, p.rx, p.ry, p.heading, 2, true)
        rec.saved = p
    end
    if leaving[id] == rec and not rec.pending then
        leaving[id] = nil
        -- Depois dos outros handlers deste evento: o whip_core ja tem a pose nova quando voltar a desenhar.
        SetTimeout(0, function() handOver(rec) end)
    end
end)

RegisterNetEvent('whip_core:client:groundItemDeleted', function(id)
    id = tonumber(id)
    if not id then return end
    local rec = S.recs[id] or leaving[id]
    if S.holding and S.holding.rec == rec then S.holding = nil end
    if rec then deleteObject(rec) end
    if S.recs[id] ~= nil then S.recs[id] = nil end
    leaving[id] = nil
    if rec or gone[id] then W:HoldGroundProp(id, false) end
    gone[id] = nil
end)

RegisterNetEvent('whip_core:client:groundItemUpdated', function(id, amount)
    local rec = S.recs[tonumber(id) or -1]
    if rec and type(amount) == 'number' then rec.amount = amount end
end)

-- ------------------------------------------------------------------ escolher e arrastar
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

--- O objeto do chao sob o cursor (caixa projetada, o mais perto do centro e da camera).
function PT.GSPick(cx, cy)
    if not S.active then return nil end
    local camPos = GetFinalRenderedCamCoord()
    local best, bestScore = nil, math.huge
    for _, rec in pairs(S.recs) do
        if rec and rec.entity and DoesEntityExist(rec.entity) then
            local b = screenBounds(rec)
            if b then
                local w, h = math.max(b.x1 - b.x0, 0.02), math.max(b.y1 - b.y0, 0.02)
                local ndx, ndy = (cx - (b.x0 + b.x1) * 0.5) / (w * 0.5 + 0.006), (cy - (b.y0 + b.y1) * 0.5) / (h * 0.5 + 0.006)
                if math.abs(ndx) <= 1.0 and math.abs(ndy) <= 1.0 then
                    local score = ndx * ndx + ndy * ndy + #(camPos - GetEntityCoords(rec.entity)) * 0.1
                    if score < bestScore then best, bestScore = rec, score end
                end
            end
        end
    end
    return best
end

function PT.GSLabel(rec)
    return PT.GroundLabel({ item = rec.item, amount = rec.amount })
end

--- Contorno no objeto sob o cursor ou na mao.
function PT.GSHover(rec)
    if S.outlined and S.outlined ~= (rec and rec.entity) and DoesEntityExist(S.outlined) then
        SetEntityDrawOutline(S.outlined, false)
    end
    S.outlined = rec and rec.entity or nil
    if S.outlined then
        SetEntityDrawOutlineColor(255, 214, 110, 160)
        SetEntityDrawOutline(S.outlined, true)
    end
end

function PT.GSGrab(rec)
    if not rec or not rec.entity then return false end
    local r = GetEntityRotation(rec.entity, 2)
    S.holding = { rec = rec, heading = r.z, pitch = 0.0, roll = 0.0, lift = 0.0 }
    rec.watch = false
    FreezeEntityPosition(rec.entity, true)
    SetEntityCollision(rec.entity, false, false)
    return true
end

function PT.GSHolding() return S.holding and S.holding.rec or nil end

--- O objeto na mao segue o cursor: o ponto onde o raio bate no mundo (chao ou outro objeto), um pouco acima.
--- ok(at) diz se o ponto vale (distancia); fora, o objeto fica onde estava.
local LIFT_MAX = 1.5
local HOVER = 0.08   -- acima do ponto de apoio enquanto esta na mao (sem altura pedida)

local function wrap(a)
    a = (a + 180.0) % 360.0 - 180.0
    return a
end

function PT.GSDragTick(cx, cy, keys, ok)
    local h = S.holding
    if not h or not h.rec.entity or not DoesEntityExist(h.rec.entity) then S.holding = nil return end
    local e = h.rec.entity
    -- Q/E giram o eixo da vez (Ctrl = roll, Shift = pitch, senao heading); R/F sobem e descem.
    local d = (keys.e and 2.0 or 0.0) - (keys.q and 2.0 or 0.0)
    if d ~= 0.0 then
        if keys.control then h.roll = wrap(h.roll + d)
        elseif keys.shift then h.pitch = wrap(h.pitch + d)
        else h.heading = wrap(h.heading + d) end
    end
    if keys.r then h.lift = math.min(LIFT_MAX, h.lift + 0.01) end
    if keys.f then h.lift = math.max(0.0, h.lift - 0.01) end
    local o, dir = PT.CursorRay(cx, cy)
    local to = o + dir * 15.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, to.x, to.y, to.z, 1 + 16, e, 7)
    local _, hit, at = GetShapeTestResult(ray)
    if hit == 1 and (not ok or ok(at)) then h.at = at end
    if not h.at then return end
    -- Gira primeiro e mede o canto mais baixo: o objeto fica apoiado no ponto (mais a altura), em qualquer inclinacao.
    SetEntityRotation(e, PT.SafePitch(h.pitch), h.roll, h.heading, 2, true)   -- +-90 exato: matriz NaN
    SetEntityCoordsNoOffset(e, h.at.x, h.at.y, h.at.z + 1.0, false, false, false)
    local mn, mx = GetModelDimensions(h.rec.model)
    local low = math.huge
    for _, x in ipairs({ mn.x, mx.x }) do
        for _, y in ipairs({ mn.y, mx.y }) do
            for _, z in ipairs({ mn.z, mx.z }) do
                low = math.min(low, GetOffsetFromEntityInWorldCoords(e, x, y, z).z)
            end
        end
    end
    local lift = h.lift > 0.0 and h.lift or HOVER
    SetEntityCoordsNoOffset(e, h.at.x, h.at.y, h.at.z + 1.0 - (low - h.at.z) + lift, false, false, false)
end

--- Soltar no mundo: volta a colidir e cai com a fisica do jogo; os vizinhos acordam.
function PT.GSDrop()
    local h = S.holding
    S.holding = nil
    if not h or not h.rec.entity or not DoesEntityExist(h.rec.entity) then return end
    local rec = h.rec
    SetEntityCollision(rec.entity, true, true)
    freeze(rec, false)
    rec.watch, rec.still = true, 0
    local c = GetEntityCoords(rec.entity)
    for _, other in pairs(S.recs) do
        if other and other ~= rec and other.entity and DoesEntityExist(other.entity)
            and #(GetEntityCoords(other.entity) - c) <= WAKE_RADIUS then
            freeze(other, false)
            other.watch, other.still = true, 0
        end
    end
end

--- O item saiu do chao (bolsos, stash, porta-malas): o objeto some ja; o servidor apaga o item.
function PT.GSDiscard(rec)
    if S.holding and S.holding.rec == rec then S.holding = nil end
    if rec and S.recs[rec.id] == rec then
        deleteObject(rec)
        S.recs[rec.id] = nil
        gone[rec.id] = GetGameTimer() + 3000
    end
end

--- Soltou em lugar nenhum (painel que nao aceita): volta para onde estava.
function PT.GSCancel()
    local h = S.holding
    S.holding = nil
    if not h or not h.rec.entity then return end
    local p = h.rec.saved
    SetEntityCoordsNoOffset(h.rec.entity, p.x, p.y, p.z, false, false, false)
    SetEntityRotation(h.rec.entity, p.rx, p.ry, p.heading, 2, true)
    SetEntityCollision(h.rec.entity, true, true)
end

-- ------------------------------------------------------------------ assentar
CreateThread(function()
    while true do
        local now = GetGameTimer()
        for id, rec in pairs(leaving) do
            if now > rec.leaveBy then leaving[id] = nil; handOver(rec) end   -- sem eco: o whip_core desenha o que sabe
        end
        for id, untilAt in pairs(gone) do
            if now > untilAt then gone[id] = nil; W:HoldGroundProp(id, false) end   -- o servidor recusou: volta
        end
        if not S.active then
            Wait(300)
        else
            for _, rec in pairs(S.recs) do
                if rec and rec.watch and rec.entity and DoesEntityExist(rec.entity) then
                    local v = GetEntityVelocity(rec.entity)
                    local r = GetEntityRotationVelocity(rec.entity)
                    if #v < 0.03 and #r < 0.05 then
                        rec.still = rec.still + 1
                        if rec.still >= SETTLE_FRAMES then
                            rec.watch = false
                            FreezeEntityPosition(rec.entity, true)
                            persist(rec)
                        end
                    else
                        rec.still = 0
                    end
                end
            end
            Wait(0)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, rec in pairs(S.recs) do if rec then deleteObject(rec) end end
    for _, rec in pairs(leaving) do deleteObject(rec) end
end)
