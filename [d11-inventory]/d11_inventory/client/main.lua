-- Largar no chao com animacao e fisica: client/drop.lua.

-- Abas de painel (bolsa, carteira): o "x" do renderer fecha uma so; "Abrir" numa pilha do chao abre a bolsa ali
-- (com docs/patches/whip_core-ground-panel-d11.patch; sem ele responde fallback e o renderer pega e abre nos bolsos). O fechar passa pelo ClosePanel do servidor, que avisa o whip_core
-- do cliente e a NUI.
RegisterNUICallback('closePanel', function(data, cb)
    if type(data) == 'table' and data.id ~= nil then TriggerServerEvent('d11_inventory:closePanel', tostring(data.id)) end
    cb({ ok = true })
end)

RegisterNUICallback('openGround', function(data, cb)
    if not GlobalState.d11GroundPanel then return cb({ fallback = true }) end
    local id = type(data) == 'table' and tonumber(data.id)
    if id then TriggerServerEvent('whip_core:server:openGroundPanel', math.floor(id)) end
    cb({ ok = true })
end)
