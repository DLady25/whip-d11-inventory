-- d11_ptrunk (cliente): os itens do chao com o mouse sempre que o inventario esta aberto (fora do porta-malas fisico,
-- que trata o chao do jeito dele). Pedido de 2026-11-16 (sessao de migracao): reposicionar livremente no mundo e arrastar
-- para os bolsos, um stash ou uma bolsa aberta, como no porta-malas.
--   passar o mouse num item do chao: contorno e o nome
--   arrastar: o proprio objeto segue o cursor (Q/E giram); soltar no mundo cai com a fisica do jogo, empilha e
--     assenta, ate Config.GroundFree.moveReach do jogador (client/groundphys.lua); soltar no painel do jogador, num
--     stash ou numa bolsa pega o item ali
-- O renderer d11_inventory manda o mouse (gmode, gpointer, gdown, gup, gkey, gclosed); quem move e o servidor.
local W = exports.whip_core

local G = { on = false, list = {}, at = 0, busy = false, cursor = { x = 0.5, y = 0.5 }, free = false,
    hover = nil, drag = nil, keys = {} }

local function refresh()
    if G.busy or GetGameTimer() - G.at < 1000 then return end
    G.busy, G.at = true, GetGameTimer()
    CreateThread(function()
        local list = W:Callback('d11_ptrunk:groundAround')
        G.list = type(list) == 'table' and list or {}
        if G.on then PT.GSSync(G.list) end
        G.busy = false
    end)
end

local function stop()
    G.on, G.hover, G.drag, G.keys = false, nil, nil, {}
    PT.DestroyPlayerOrbit()
    PT.GSHover(nil)
    PT.GSStop()
end

CreateThread(function()
    while true do
        if not G.on then
            Wait(250)
        elseif PT.ModeActive() or not W:IsInventoryOpen() then
            stop()
        else
            refresh()
            if G.drag then
                local me = GetEntityCoords(PlayerPedId())
                PT.GSDragTick(G.cursor.x, G.cursor.y, G.keys, function(at)
                    return #(at - me) <= Config.GroundFree.moveReach
                end)
            end
            PT.GSHover(G.drag or G.hover)
            PT.PlayerOrbitTick()
            Wait(0)
        end
    end
end)

local function setCursor(data)
    if type(data) ~= 'table' then return end
    local x, y = tonumber(data.x), tonumber(data.y)
    if x and y then G.cursor.x, G.cursor.y = math.max(0.0, math.min(1.0, x)), math.max(0.0, math.min(1.0, y)) end
    if data.free ~= nil then G.free = data.free == true end
end

-- O inventario abriu: { active } diz se este modo vale (fora do porta-malas fisico).
RegisterNUICallback('gmode', function(_, cb)
    G.on = Config.PhysicalGround and not PT.ModeActive()
    G.at = 0
    if G.on then
        PT.GSStart(function(g)
            return #(vector3(g.x, g.y, g.z) - GetEntityCoords(PlayerPedId())) <= Config.GroundFree.reach
        end)
    end
    cb({ active = G.on })
end)

RegisterNUICallback('gclosed', function(_, cb)
    cb({})
    stop()
end)

RegisterNUICallback('gpointer', function(data, cb)
    setCursor(data)
    if not G.on then return cb({}) end
    G.hover = (not G.drag and G.free) and PT.GSPick(G.cursor.x, G.cursor.y) or nil
    cb({ ground = G.hover and PT.GSLabel(G.hover) or nil, holding = G.drag ~= nil })
end)

RegisterNUICallback('gdown', function(data, cb)
    setCursor(data)
    G.free = true
    if not G.on then return cb({}) end
    local rec = PT.GSPick(G.cursor.x, G.cursor.y)
    if not rec or not PT.GSGrab(rec) then return cb({}) end
    G.drag, G.hover = rec, nil
    cb({ grab = { id = rec.id, label = PT.GSLabel(rec) } })
end)

-- { x, y, to?, slot? }: to = 'player' | storeId do stash ('container:N', 'vehicle:N:trunk') | 'panel:<id>' (bolsa) |
-- 'cancel' (painel que nao aceita: volta); sem `to`, cai no mundo com a fisica do jogo.
RegisterNUICallback('gup', function(data, cb)
    cb({})
    local rec = G.drag
    G.drag = nil
    if not rec or type(data) ~= 'table' then return end
    setCursor(data)
    if data.to == 'cancel' then
        PT.GSCancel()
    elseif type(data.to) == 'string' and data.to ~= '' then
        TriggerServerEvent('d11_ptrunk:server:groundTake', rec.id, data.to, math.floor(tonumber(data.slot) or 0))
        PT.GSDiscard(rec)
    else
        PT.GSDrop()
    end
    G.at = 0
end)

local GKEYS = { q = true, e = true, r = true, f = true, shift = true, control = true }

-- Camera orbital em volta do jogador (client/profiles.lua): a roda afasta ({ delta } do navegador; > 0 afasta) e o
-- botao direito ou do meio arrastando gira ({ dx, dy } na fracao da tela). Fica ate fechar o inventario.
RegisterNUICallback('gzoom', function(data, cb)
    cb({})
    if G.on and Config.GroundCamera and type(data) == 'table' and tonumber(data.delta) then PT.PlayerOrbitZoom(tonumber(data.delta)) end
end)

RegisterNUICallback('gcam', function(data, cb)
    cb({})
    if G.on and Config.GroundCamera and type(data) == 'table' then PT.PlayerOrbitInput(tonumber(data.dx) or 0.0, tonumber(data.dy) or 0.0) end
end)
RegisterNUICallback('gkey', function(data, cb)
    cb({})
    if type(data) == 'table' and GKEYS[data.key] then G.keys[data.key] = data.down == true end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then PT.DestroyPlayerOrbit(true) end
end)
