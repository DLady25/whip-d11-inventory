-- Abrir bolsa no chao: so com docs/patches/whip_core-ground-panel-d11.patch no whip_core (ele cria o evento
-- whip_core:server:openGroundPanel). Sem o patch, "Abrir" numa bolsa no chao pega ela para os bolsos e abre ali
-- (renderer.js, pickUpAndOpen). Lido do arquivo do whip_core, entao nada a configurar.
-- Teste do caminho sem patch: set d11_inventory_ground_panel 0 (no server.cfg ou no console, depois ensure d11_inventory).
GlobalState.d11GroundPanel = GetConvar('d11_inventory_ground_panel', '1') ~= '0'
    and (LoadResourceFile('whip_core', 'server/panels.lua') or ''):find('openGroundPanel', 1, true) ~= nil
-- Abrir bolsa dentro de um porta-malas ou stash: so com docs/patches/whip_core-store-panel-d11.patch (evento
-- whip_core:server:openStorePanel). Sem ele, "Abrir" pega a bolsa para os bolsos e abre ali, como no chao.
GlobalState.d11StorePanel = (LoadResourceFile('whip_core', 'server/panels.lua') or ''):find('openStorePanel', 1, true) ~= nil

-- Fecha um painel do proprio jogador (o "x" da aba no renderer). So o que ele tem aberto: ClosePanel e por source.
RegisterNetEvent('d11_inventory:closePanel', function(id)
    if type(id) ~= 'string' or #id > 80 then return end
    exports.whip_core:ClosePanel(source, id)
end)

-- O bloco World do config.lua vira convars replicadas: o whip_core (patches noblur e drive) e o d11_ptrunk leem.
do
    local W = D11Inventory_World or {}
    local function set(name, on) SetConvarReplicated(name, on and '1' or '0') end
    set('d11_inventory_blur', W.Blur == true)
    set('d11_inventory_move', W.Move ~= false)
    set('d11_inventory_move_look', W.MoveLook == true)
    set('d11_inventory_trunk', W.Trunk ~= false)
    set('d11_inventory_ground', W.Ground ~= false)
    set('d11_inventory_camera', W.Camera ~= false)
end

-- Encaixes de equipamento (D11Inventory.GearSlots): a faixa do whip_core recusa o item errado no servidor.
for _, def in ipairs(D11Inventory.GearSlots or {}) do
    local ok, why = exports.whip_core:RegisterAccessorySlot(def)
    if not ok then print(('[d11_inventory] slot de equipamento %s (%s) recusado: %s'):format(def.slot, def.label, tostring(why))) end
end
