-- Abrir bolsa no chao: so com docs/patches/whip_core-ground-panel-d11.patch no whip_core (ele cria o evento
-- whip_core:server:openGroundPanel). Sem o patch, "Abrir" numa bolsa no chao pega ela para os bolsos e abre ali
-- (renderer.js, pickUpAndOpen). Lido do arquivo do whip_core, entao nada a configurar.
-- Teste do caminho sem patch: set d11_inventory_ground_panel 0 (no server.cfg ou no console, depois ensure d11_inventory).
GlobalState.d11GroundPanel = GetConvar('d11_inventory_ground_panel', '1') ~= '0'
    and (LoadResourceFile('whip_core', 'server/panels.lua') or ''):find('openGroundPanel', 1, true) ~= nil

-- Fecha um painel do proprio jogador (o "x" da aba no renderer). So o que ele tem aberto: ClosePanel e por source.
RegisterNetEvent('d11_inventory:closePanel', function(id)
    if type(id) ~= 'string' or #id > 80 then return end
    exports.whip_core:ClosePanel(source, id)
end)
