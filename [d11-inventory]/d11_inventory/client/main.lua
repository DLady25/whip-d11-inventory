-- Largar no chao com animacao e fisica: client/drop.lua.

-- Idioma do renderer: setr d11_locale en | pt-BR (server.cfg). Padrao en.
RegisterNUICallback('locale', function(_, cb)
    -- craft: o botao Crafting so aparece com o d11_craft rodando (ele nao vem neste pacote).
    cb({ lang = GetConvar('d11_locale', 'en'), craft = GetResourceState('d11_craft') == 'started' })
end)

-- Abas de painel (bolsa, carteira): o "x" do renderer fecha uma so; "Abrir" numa pilha do chao abre a bolsa ali
-- (com docs/patches/whip_core-ground-panel-d11.patch; sem ele responde fallback e o renderer pega e abre nos bolsos). O fechar passa pelo ClosePanel do servidor, que avisa o whip_core
-- do cliente e a NUI.
RegisterNUICallback('closePanel', function(data, cb)
    if type(data) == 'table' and data.id ~= nil then TriggerServerEvent('d11_inventory:closePanel', tostring(data.id)) end
    cb({ ok = true })
end)

-- "Abrir" numa bolsa dentro do porta-malas ou de uma stash aberta: { store = 'vehicle:<id>:trunk' | 'container:<id>', slot }.
-- Com docs/patches/whip_core-store-panel-d11.patch abre ali mesmo; sem ele responde fallback (o renderer pega e abre).
RegisterNUICallback('openStore', function(data, cb)
    if not GlobalState.d11StorePanel then return cb({ fallback = true }) end
    local store, slot = type(data) == 'table' and data.store, type(data) == 'table' and tonumber(data.slot)
    if type(store) == 'string' and #store <= 64 and slot then
        TriggerServerEvent('whip_core:server:openStorePanel', store, math.floor(slot))
    end
    cb({ ok = true })
end)

RegisterNUICallback('openGround', function(data, cb)
    if not GlobalState.d11GroundPanel then return cb({ fallback = true }) end
    local id = type(data) == 'table' and tonumber(data.id)
    if id then TriggerServerEvent('whip_core:server:openGroundPanel', math.floor(id)) end
    cb({ ok = true })
end)
