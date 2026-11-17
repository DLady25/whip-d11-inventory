-- d11_ptrunk (cliente): o comum entre o porta-malas fisico e os itens do chao com o inventario aberto.
-- O raio do cursor (da camera do porta-malas, ou da camera do jogo quando nao ha camera de script), acertar o mundo com
-- ele, e os itens do chao do WHIP: escolher o que esta sob o cursor, o nome e o marcador.
local W = exports.whip_core

local function camRay(cx, cy)
    local cam = PT.ActiveCamera()
    if cam then
        local right, forward, up, origin = GetCamMatrix(cam)
        return origin, right, forward, up, GetCamFov(cam)
    end
    -- Camera do jogo: a direcao pela rotacao (ordem 2), a direita e o alto a partir dela.
    local origin = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local forward = vector3(-math.sin(z) * math.cos(x), math.cos(z) * math.cos(x), math.sin(x))
    local right = vector3(math.cos(z), math.sin(z), 0.0)
    local up = vector3(right.y * forward.z - right.z * forward.y, right.z * forward.x - right.x * forward.z,
        right.x * forward.y - right.y * forward.x)
    return origin, right, forward, up, GetFinalRenderedCamFov()
end

--- Origem e direcao (normalizada) do raio que passa pelo cursor (cx, cy de 0 a 1).
function PT.CursorRay(cx, cy)
    local origin, right, forward, up, fov = camRay(cx, cy)
    local half = math.tan(math.rad(fov) * 0.5)
    local nx = (cx - 0.5) * 2.0 * half * GetAspectRatio(false)
    local ny = (0.5 - cy) * 2.0 * half
    local d = forward + right * nx + up * ny
    return origin, d / #d
end

--- Onde o raio do cursor bate no mundo (chao, predio), ate maxDist metros; ignora o proprio personagem.
function PT.WorldHit(cx, cy, maxDist)
    local o, d = PT.CursorRay(cx, cy)
    local to = o + d * (maxDist or 15.0)
    local h = StartExpensiveSynchronousShapeTestLosProbe(o.x, o.y, o.z, to.x, to.y, to.z, 1, PlayerPedId(), 7)
    local _, hit, at = GetShapeTestResult(h)
    if hit == 1 then return at end
    return nil
end

--- O item do chao (lista { id, item, amount, x, y, z }) mais perto do cursor na tela, ate ~3,5% dela.
function PT.PickGround(list, cx, cy)
    local best, bestD = nil, 0.035
    for _, g in ipairs(list or {}) do
        local on, sx, sy = GetScreenCoordFromWorldCoord(g.x, g.y, g.z + 0.05)
        if on then
            local dist = math.sqrt((sx - cx) ^ 2 + (sy - cy) ^ 2)
            if dist < bestD then best, bestD = g, dist end
        end
    end
    return best
end

function PT.GroundLabel(g)
    local def = W:GetItemDef(g.item)
    local name = def and def.name or g.item
    return (g.amount or 1) > 1 and ('%s x%d'):format(name, g.amount) or name
end

--- Seta em cima do item do chao: amarela sob o cursor, azul na mao.
function PT.DrawGroundMarker(g, held)
    DrawMarker(2, g.x, g.y, g.z + 0.30, 0, 0, 0, 180.0, 0, 0, 0.12, 0.12, 0.12,
        held and 70 or 255, held and 210 or 214, held and 255 or 110, 210, true, true, 2, false, nil, nil, false)
end

--- Disco no chao onde o item vai ficar.
function PT.DrawGroundSpot(at, ok)
    DrawMarker(25, at.x, at.y, at.z + 0.03, 0, 0, 0, 0, 0, 0, 0.22, 0.22, 0.22,
        ok and 255 or 235, ok and 214 or 70, ok and 110 or 70, 160, false, false, 2, false, nil, nil, false)
end
