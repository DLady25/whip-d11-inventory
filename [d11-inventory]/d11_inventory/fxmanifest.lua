fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'd11_inventory'
description 'Inventario D11 do WHIP (renderer: so desenha; estado, regras e servidor seguem no whip_core).'
author 'D11'
version '1.2.1'

-- Ativar: setr whip_inventory_renderer d11_inventory (server.cfg) ou Config.InventoryRenderer.
-- whip_core importa https://cfx-nui-d11_inventory/renderer.js (docs/nui-inventory.md).
dependency 'whip_core'

-- animacao de largar no chao, pedida pelo renderer (client/main.lua)
client_scripts { 'config.lua', 'client/gestures.lua', 'client/main.lua', 'client/drop.lua', 'client/body.lua' }
server_scripts { 'config.lua', 'server.lua' }

files {
    'renderer.js',
    'locales.js',
    'style.css',
    'fonts/*',
}
