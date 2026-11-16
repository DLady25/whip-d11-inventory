fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'd11_bags'
author 'D11'
description 'Bolsas D11 no WHIP: mochilas e saco de papel como painel do inventario'
version '1.0.0'

dependency 'whip_core'

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'config.lua',
}

server_script 'server.lua'

files { 'html/img/items/*.png' }

whip_requires '1.0'
