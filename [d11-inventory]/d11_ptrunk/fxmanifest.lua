fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'd11_ptrunk'
author 'D11'
description 'D11 Physical Trunk for WHIP: the boot seen from behind the car, its items as props, inside the WHIP inventory'
version '1.0.0'
license 'MIT'

-- Port of velocity-physicaltrunk (D12) to WHIP. Plan and phases: docs/PLANO-PHYSICALTRUNK-WHIP.md.
-- Opened through the boot's own "View trunk" prompt: whip_core patch docs/patches/whip_core-trunk-opener-d11.patch
-- plus `setr whip_trunk_opener d11_ptrunk` in server.cfg. The screen is the d11_inventory renderer, in trunk mode.

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'config.lua',
}

client_scripts {
    'client/profiles.lua',
    'client/visuals.lua',
    'client/world.lua',
    'client/groundphys.lua',
    'client/props.lua',
    'client/physics.lua',
    'client/edit.lua',
    'client/wizard.lua',
    'client/ground.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

-- Painel do wizard de calibracao (client/wizard.lua): so mostra, sem foco; as teclas ficam no jogo.
ui_page 'html/wizard.html'

files { 'data/profiles/*.lua', 'data/item_visuals.lua', 'html/wizard.html', 'html/wizard.css', 'html/wizard.js', 'html/fonts/*' }

dependencies { 'whip_core', 'oxmysql' }

whip_requires '1.0'
