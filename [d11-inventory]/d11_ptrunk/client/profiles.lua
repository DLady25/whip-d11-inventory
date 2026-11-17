-- d11_ptrunk (cliente): perfis por modelo, lado de acesso, camera e luz.
-- Porte de client/trunk.lua e client/camera.lua do velocity-physicaltrunk (D12), com os perfis em data/profiles.
PT = PT or {}

-- Os perfis vem dos arquivos de Config.ProfilePacks, na ordem (o de baixo vence); a tabela do servidor vale por cima.
-- Em cada arquivo, vehicles = { <modelo ou hash> = { spawn, camera, light } }; class e backEngine somam.
local Profiles = { spawn = {}, camera = {}, light = {}, class = {}, backEngine = {} }
PT.Profiles = Profiles

--- Um pack com `resource` so vale se algum resource rodando tem esse texto no nome (ex.: os carros do NoPixel).
local function packOn(pack)
    if not pack.resource then return true end
    local want = pack.resource:lower()
    for i = 0, GetNumResources() - 1 do
        local r = GetResourceByFindIndex(i)
        if r and r:lower():find(want, 1, true) and GetResourceState(r) == 'started' then return true end
    end
    return false
end

local backEngine = {}

--- Le os packs de novo (na entrada e quando o servidor manda os perfis: os carros do pack ja estao rodando ai).
local function loadPacks()
    for _, t in pairs(Profiles) do for k in pairs(t) do t[k] = nil end end
    for k in pairs(backEngine) do backEngine[k] = nil end
    for _, pack in ipairs(Config.ProfilePacks or {}) do
        local src = pack.file and LoadResourceFile(GetCurrentResourceName(), pack.file)
        local fn = src and load(src, '@' .. pack.file)
        local ok, data = false, nil
        if fn then ok, data = pcall(fn) end
        if not ok or type(data) ~= 'table' then
            print(('^3[d11_ptrunk] perfis: %s nao carregou (%s)^7'):format(tostring(pack.file), tostring(data or 'arquivo nao encontrado')))
        elseif packOn(pack) then
            for key, v in pairs(data.vehicles or {}) do
                local hash = type(key) == 'string' and joaat(key) or math.tointeger(key)
                if hash and type(v) == 'table' then
                    for _, kind in ipairs({ 'spawn', 'camera', 'light' }) do
                        if type(v[kind]) == 'table' then Profiles[kind][hash] = v[kind] end
                    end
                end
            end
            for cls, v in pairs(data.class or {}) do Profiles.class[cls] = v end
            for _, name in ipairs(data.backEngine or {}) do Profiles.backEngine[#Profiles.backEngine + 1] = name end
        end
    end
    for _, name in ipairs(Profiles.backEngine) do backEngine[joaat(name)] = true end
end
loadPacks()


local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- ------------------------------------------------------------------ perfis
--- Perfil resolvido: o da classe com o do modelo por cima (camera, lado, ponto de pe).
function PT.ResolvedProfile(vehicle)
    local model = GetEntityModel(vehicle)
    local out = {}
    for k, v in pairs(Profiles.class[GetVehicleClass(vehicle)] or {}) do out[k] = v end
    for k, v in pairs(Profiles.camera[model] or {}) do out[k] = v end
    return out, model
end

--- Troca um perfil na hora (wizard, servidor). kind = 'camera' | 'spawn' | 'light'.
function PT.SetProfile(kind, hash, data)
    if Profiles[kind] and math.tointeger(hash) then Profiles[kind][math.tointeger(hash)] = data end
end

--- O que o servidor tem na tabela d11_ptrunk_profiles (wizard, /ptrunkimport) vale por cima do data/profiles.
local function applyServer(set)
    for kind in pairs({ camera = true, spawn = true, light = true }) do
        for hash, data in pairs(type(set) == 'table' and set[kind] or {}) do
            if type(data) == 'table' then PT.SetProfile(kind, tonumber(hash), data) end
        end
    end
end

local function fetchServerProfiles()
    CreateThread(function()
        local set = exports.whip_core:Callback('d11_ptrunk:profiles')
        loadPacks()
        applyServer(set)
    end)
end

Whip.register(fetchServerProfiles)
RegisterNetEvent('d11_ptrunk:client:profilesReload', fetchServerProfiles)

-- Um modelo recalibrado por alguem: { modelHash, camera?, spawn?, light? }.
RegisterNetEvent('d11_ptrunk:client:profiles', function(saved)
    if type(saved) ~= 'table' then return end
    for kind in pairs({ camera = true, spawn = true, light = true }) do
        if type(saved[kind]) == 'table' then PT.SetProfile(kind, tonumber(saved.modelHash), saved[kind]) end
    end
end)

function PT.SpawnProfile(vehicle) return Profiles.spawn[GetEntityModel(vehicle)] end
function PT.LightProfile(vehicle) return Profiles.light[GetEntityModel(vehicle)] end

--- Modo fisico so com a area util do modelo calibrada (decisao de 2026-11-17): sem ela, o porta-malas normal do WHIP.
--- Camera e luz sao opcionais: sem a do modelo, a camera vem da classe e o porta-malas fica sem luz propria.
function PT.HasFullProfile(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    return Profiles.spawn[GetEntityModel(vehicle)] ~= nil
end

-- ------------------------------------------------------------------ acesso (client/trunk.lua da D12)
local function accessSide(vehicle)
    local p, model = PT.ResolvedProfile(vehicle)
    if p.access then return p.access end
    return backEngine[model] and 'front' or 'rear'
end

function PT.AccessY(vehicle)
    local mn, mx = GetModelDimensions(GetEntityModel(vehicle))
    return accessSide(vehicle) == 'front' and mx.y or mn.y
end

local function triggerRadius(vehicle)
    local p = PT.ResolvedProfile(vehicle)
    if p.triggerRadius then return p.triggerRadius end
    local mn, mx = GetModelDimensions(GetEntityModel(vehicle))
    local width, length = math.abs(mx.x - mn.x), math.abs(mx.y - mn.y)
    return math.max(Config.TrunkInteractDistance, math.min(3.0, 1.35 + width * 0.35 + length * 0.12))
end

function PT.AccessData(vehicle)
    return {
        access = accessSide(vehicle),
        coords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, PT.AccessY(vehicle), 0.0),
        triggerRadius = triggerRadius(vehicle),
    }
end

--- O jogador esta na area de carga (traseira, ou frente no motor traseiro)?
function PT.IsAtTrunk(vehicle)
    local a = PT.AccessData(vehicle)
    local pos = GetEntityCoords(PlayerPedId())
    return #(vector2(pos.x, pos.y) - vector2(a.coords.x, a.coords.y)) <= a.triggerRadius
end

-- ------------------------------------------------------------------ camera (client/camera.lua da D12)
local cam = nil

local function cameraParams(vehicle)
    local p = PT.ResolvedProfile(vehicle)
    local C = Config.Camera
    local mn, mx = GetModelDimensions(GetEntityModel(vehicle))
    local params = {
        access = accessSide(vehicle),
        fov = p.fov or C.fov,
        camLocalX = p.camLocalX, camLocalY = p.camLocalY, camLocalZ = p.camLocalZ,
        lookLocalX = p.lookLocalX, lookLocalY = p.lookLocalY, lookLocalZ = p.lookLocalZ,
        sideOffset = p.sideOffset or C.sideOffset,
        rearDistance = p.rearDistance or C.rearDistance,
        rearHeight = p.rearHeight or C.rearHeight,
        lookHeight = p.lookHeight or C.lookHeight,
    }
    local heightBias = clamp((math.abs(mx.z - mn.z) - 1.35) * 0.16, -0.12, 0.16)
    params.rearHeight = clamp(params.rearHeight + heightBias, 0.45, 1.15)
    params.lookHeight = clamp(params.lookHeight + heightBias * 0.65, 0.12, 0.82)
    params.rearDistance = clamp(params.rearDistance, -0.15, 1.2)
    params.sideOffset = clamp(params.sideOffset, -0.8, 0.8)
    params.fov = clamp(params.fov, 35.0, 90.0)
    return params
end

local function cameraPlacement(vehicle, params)
    if params.camLocalX and params.camLocalY and params.camLocalZ
        and params.lookLocalX and params.lookLocalY and params.lookLocalZ then
        return GetOffsetFromEntityInWorldCoords(vehicle, params.camLocalX, params.camLocalY, params.camLocalZ),
            GetOffsetFromEntityInWorldCoords(vehicle, params.lookLocalX, params.lookLocalY, params.lookLocalZ)
    end
    local dir = params.access == 'front' and 1.0 or -1.0
    local y = PT.AccessY(vehicle)
    return GetOffsetFromEntityInWorldCoords(vehicle, params.sideOffset, y + dir * params.rearDistance, params.rearHeight),
        GetOffsetFromEntityInWorldCoords(vehicle, 0.0, y, params.lookHeight)
end

function PT.CreateTrunkCamera(vehicle)
    PT.DestroyTrunkCamera(true)
    local params = cameraParams(vehicle)
    local from, look = cameraPlacement(vehicle, params)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, from.x, from.y, from.z)
    PointCamAtCoord(cam, look.x, look.y, look.z)
    SetCamFov(cam, params.fov)
    SetCamNearClip(cam, 0.02)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, Config.Camera.transitionMs, true, true)
    return cam
end

-- ------------------------------------------------------------------ camera orbital do modo fisico (2026-11-16)
-- Pedido do usuario: em vez da camera fechada do perfil, uma camera mais aberta presa ao porta-malas, que o jogador
-- gira (botao direito arrastando) e aproxima/afasta (roda), dentro de limites. A direcao inicial e a da camera
-- calibrada do perfil, afastada por Config.Orbit.startScale; o alvo e o centro da area util.
local orbit = nil

function PT.CreateOrbitCamera(vehicle, area)
    PT.DestroyTrunkCamera(true)
    local O = Config.Orbit
    local params = cameraParams(vehicle)
    local from = cameraPlacement(vehicle, params)
    local t = vector3(area.x or 0.0, area.y or PT.AccessY(vehicle), area.z or 0.3)
    local d = GetOffsetFromEntityGivenWorldCoords(vehicle, from.x, from.y, from.z) - t
    local dist = math.max(0.5, #d)
    orbit = {
        vehicle = vehicle, target = t, dist = dist,
        baseYaw = math.deg(math.atan(d.x, d.y)), basePitch = math.deg(math.asin(clamp(d.z / dist, -1.0, 1.0))),
        want = { yaw = 0.0, pitch = 0.0, scale = O.startScale, px = 0.0, py = 0.0 },
        cur = { yaw = 0.0, pitch = 0.0, scale = O.startScale, px = 0.0, py = 0.0 },
    }
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, math.min(O.maxFov, params.fov + O.extraFov))
    SetCamNearClip(cam, 0.02)
    PT.OrbitTick(true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, Config.Camera.transitionMs, true, true)
    return cam
end

--- Gira (dx, dy na fracao da tela que o mouse andou).
function PT.OrbitInput(dx, dy)
    if not orbit then return end
    local O = Config.Orbit
    local w = orbit.want
    w.yaw = clamp(w.yaw - dx * O.sensitivity, -O.yawLimit, O.yawLimit)
    w.pitch = clamp(w.pitch + dy * O.sensitivity * 0.6, O.pitchMin, O.pitchMax)
end

--- Move o ponto de foco (dx, dy na fracao da tela) pelo chao do carro, como arrastar um mapa: o que esta sob o cursor
--- vai junto com ele.
function PT.OrbitPan(dx, dy)
    if not orbit then return end
    local O = Config.Orbit
    local c, w = orbit.cur, orbit.want
    local yaw = math.rad(orbit.baseYaw + c.yaw)
    local fx, fy = -math.sin(yaw), -math.cos(yaw)   -- para onde a camera olha, no plano do carro
    local rx, ry = fy, -fx                           -- a direita da camera
    local k = O.panSpeed * orbit.dist * c.scale
    local px = w.px - rx * dx * k + fx * dy * k
    local py = w.py - ry * dx * k + fy * dy * k
    local len = math.sqrt(px * px + py * py)
    if len > O.panLimit then px, py = px / len * O.panLimit, py / len * O.panLimit end
    w.px, w.py = px, py
end

--- Volta o foco para o centro do porta-malas.
function PT.OrbitRecenter()
    if orbit then orbit.want.px, orbit.want.py = 0.0, 0.0 end
end

--- A vista inicial: sem giro, zoom de partida e foco no centro (suave, como o resto da orbita).
function PT.OrbitReset()
    if not orbit then return end
    local w = orbit.want
    w.yaw, w.pitch, w.scale, w.px, w.py = 0.0, 0.0, Config.Orbit.startScale, 0.0, 0.0
end

--- Roda do mouse: >0 afasta, <0 aproxima.
function PT.OrbitZoom(delta)
    if not orbit then return end
    local O = Config.Orbit
    orbit.want.scale = clamp(orbit.want.scale + (delta > 0 and O.zoomStep or -O.zoomStep), O.minScale, O.maxScale)
end

function PT.OrbitTick(instant)
    if not orbit or not cam or not DoesEntityExist(orbit.vehicle) then return end
    local a = instant and 1.0 or Config.Orbit.smooth
    local c, w = orbit.cur, orbit.want
    c.yaw = c.yaw + (w.yaw - c.yaw) * a
    c.pitch = c.pitch + (w.pitch - c.pitch) * a
    c.scale = c.scale + (w.scale - c.scale) * a
    c.px = c.px + (w.px - c.px) * a
    c.py = c.py + (w.py - c.py) * a
    local yaw = math.rad(orbit.baseYaw + c.yaw)
    local pitch = math.rad(clamp(orbit.basePitch + c.pitch, -5.0, 80.0))
    local dist = orbit.dist * c.scale
    local t = orbit.target + vector3(c.px, c.py, 0.0)
    local p = GetOffsetFromEntityInWorldCoords(orbit.vehicle,
        t.x + math.sin(yaw) * math.cos(pitch) * dist, t.y + math.cos(yaw) * math.cos(pitch) * dist, t.z + math.sin(pitch) * dist)
    local look = GetOffsetFromEntityInWorldCoords(orbit.vehicle, t.x, t.y, t.z)
    SetCamCoord(cam, p.x, p.y, p.z)
    PointCamAtCoord(cam, look.x, look.y, look.z)
end

-- ------------------------------------------------------------------ camera orbital do jogador (chao livre)
-- Com o inventario aberto fora do porta-malas (pedido de 2026-11-16): girar (botao direito/meio) e afastar (roda).
-- A camera do jogo nao serve: o WHIP segura o "olhar" com o inventario aberto e ela trava ou desce sozinha. Esta nasce
-- exatamente onde a do jogo esta (sem pulo), segue o jogador, nao atravessa parede, e mantem a direcao do andar
-- (a camera do jogo, invisivel, acompanha o giro).
local porbit = nil

local function playerTarget()
    return GetEntityCoords(PlayerPedId()) + vector3(0.0, 0.0, Config.GroundFree.camera.height)
end

local function ensurePlayerOrbit()
    if porbit then return true end
    if cam then return false end   -- porta-malas ou calibracao com a camera
    local from = GetFinalRenderedCamCoord()
    local d = from - playerTarget()
    local P = Config.GroundFree.camera
    local dist = clamp(#d, P.minDist, P.maxDist)
    local yaw = math.deg(math.atan(d.x, d.y))
    local pitch = clamp(math.deg(math.asin(clamp(d.z / math.max(#d, 0.01), -1.0, 1.0))), P.pitchMin, P.pitchMax)
    porbit = { want = { yaw = yaw, pitch = pitch, dist = dist }, cur = { yaw = yaw, pitch = pitch, dist = dist } }
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(cam, GetFinalRenderedCamFov())
    SetCamNearClip(cam, 0.02)
    PT.PlayerOrbitTick(true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    return true
end

--- Gira (dx, dy: fracao da tela que o mouse andou com o botao segurado).
function PT.PlayerOrbitInput(dx, dy)
    if not ensurePlayerOrbit() then return end
    local P = Config.GroundFree.camera
    local w = porbit.want
    w.yaw = w.yaw - dx * P.sensitivity
    w.pitch = clamp(w.pitch + dy * P.sensitivity * 0.6, P.pitchMin, P.pitchMax)
end

--- Roda do mouse: > 0 afasta, < 0 aproxima.
function PT.PlayerOrbitZoom(delta)
    if not ensurePlayerOrbit() then return end
    local P = Config.GroundFree.camera
    porbit.want.dist = clamp(porbit.want.dist + (delta > 0 and P.zoomStep or -P.zoomStep), P.minDist, P.maxDist)
end

function PT.PlayerOrbitTick(instant)
    if not porbit or not cam then return end
    local a = instant and 1.0 or Config.GroundFree.camera.smooth
    local c, w = porbit.cur, porbit.want
    c.yaw = c.yaw + (w.yaw - c.yaw) * a
    c.pitch = c.pitch + (w.pitch - c.pitch) * a
    c.dist = c.dist + (w.dist - c.dist) * a
    local t = playerTarget()
    local yaw, pitch = math.rad(c.yaw), math.rad(c.pitch)
    local dir = vector3(math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local dist = c.dist
    -- Sem atravessar parede: encosta um pouco antes do que estiver entre o jogador e a camera.
    local far = t + dir * dist
    local h = StartExpensiveSynchronousShapeTestLosProbe(t.x, t.y, t.z, far.x, far.y, far.z, 1 | 16, PlayerPedId(), 7)
    local _, hit, at = GetShapeTestResult(h)
    if hit == 1 then dist = math.max(0.3, #(at - t) - 0.2) end
    local p = t + dir * dist
    SetCamCoord(cam, p.x, p.y, p.z)
    PointCamAtCoord(cam, t.x, t.y, t.z)
    -- A camera do jogo olha para o mesmo lado: WASD anda para onde se ve, e a volta ao fechar nao pula.
    local heading = (180.0 - c.yaw) - GetEntityHeading(PlayerPedId())
    SetGameplayCamRelativeHeading((heading + 540.0) % 360.0 - 180.0)
end

--- Volta para a camera do jogo (fechar o inventario, entrar no porta-malas); instant: sem transicao (parar o resource).
function PT.DestroyPlayerOrbit(instant)
    if not porbit then return end
    porbit = nil
    if not cam then return end
    RenderScriptCams(false, not instant, instant and 0 or Config.GroundFree.camera.exitMs, true, true)
    DestroyCam(cam, false)
    cam = nil
end

--- instant: sem a transicao de volta (trocar de camera, parar o resource).
function PT.DestroyTrunkCamera(instant)
    orbit = nil
    porbit = nil
    if not cam then return end
    RenderScriptCams(false, not instant, instant and 0 or Config.Camera.transitionMs, true, true)
    DestroyCam(cam, false)
    cam = nil
end

function PT.ActiveCamera() return cam end

-- ------------------------------------------------------------------ calibracao (camera livre, client/camera.lua da D12)
function PT.RotationToDirection(rot)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    return vector3(-math.sin(z) * math.abs(math.cos(x)), math.cos(z) * math.abs(math.cos(x)), math.sin(x))
end

function PT.RotationFromPoints(from, to)
    local d = to - from
    local flat = math.sqrt(d.x * d.x + d.y * d.y)
    return vector3(-math.deg(math.atan(d.z, flat)), 0.0, math.deg(math.atan(d.x, d.y)))
end

--- Camera e alvo do perfil atual (no mundo) e o fov: ponto de partida da camera livre da calibracao.
function PT.CameraPlacement(vehicle)
    local params = cameraParams(vehicle)
    local from, look = cameraPlacement(vehicle, params)
    return from, look, params.fov
end

function PT.CreateFreeCamera(pos, rot, fov)
    PT.DestroyTrunkCamera(true)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamRot(cam, rot.x, rot.y, rot.z, 2)
    SetCamFov(cam, fov or Config.Camera.fov)
    SetCamNearClip(cam, 0.02)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, Config.Camera.transitionMs, true, true)
    return cam
end

function PT.SetFreeCameraTransform(pos, rot, fov)
    if not cam then return end
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamRot(cam, rot.x, rot.y, rot.z, 2)
    SetCamFov(cam, fov or Config.Camera.fov)
end

--- Distancia do ponto de pe ate o acesso (getStandOffset da D12).
function PT.StandOffset(vehicle)
    local p = PT.ResolvedProfile(vehicle)
    if p.standOffset then return p.standOffset end
    local mn, mx = GetModelDimensions(GetEntityModel(vehicle))
    return math.max(1.35, math.min(2.0, 1.15 + math.abs(mx.y - mn.y) * 0.12))
end

-- ------------------------------------------------------------------ luz
function PT.DrawTrunkLight(vehicle)
    local profile = PT.LightProfile(vehicle)
    if not profile or not profile.spots then return end
    local D = Config.TrunkLight
    for _, s in ipairs(profile.spots) do
        local pos = GetOffsetFromEntityInWorldCoords(vehicle, s.pos.x, s.pos.y, s.pos.z)
        local look = GetOffsetFromEntityInWorldCoords(vehicle, s.look.x, s.look.y, s.look.z)
        local d = look - pos
        local len = #d
        if len > 0.0001 then
            local n = d / len
            local c = s.color or { r = 255, g = 235, b = 190 }
            DrawSpotLight(pos.x, pos.y, pos.z, n.x, n.y, n.z, c.r or 255, c.g or 235, c.b or 190,
                s.distance or D.distance, s.brightness or D.brightness, s.roundness or D.roundness,
                s.spotFov or s.radius or D.radius, s.falloff or D.falloff)
        end
    end
end
