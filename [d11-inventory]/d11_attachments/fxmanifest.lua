fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'd11_attachments'
author 'D11'
description 'Acessorios na arma em maos (inspecao de armas D11 sobre o whip_gunny)'
version '1.0.0'

-- Fonte D12 (so leitura): resources/[d12-local]/d12-item-inspect (client/weapon.lua, client/main.lua, html/).
-- Os acessorios sao os do whip_gunny (items/attachments.lua, lido em runtime) e o estado fica no mesmo
-- metadata.attachments da bancada do gunny; aqui so nao precisa estar na bancada.
dependencies {
    'whip_core',
    'whip_gunny',
}

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'config.lua',
    'shared/catalog.lua',
}

client_script 'client.lua'
server_script 'server.lua'

ui_page 'web/index.html'
files {
    'web/index.html',
    'web/app.js',
    'web/style.css',
}

whip_requires '1.0'
