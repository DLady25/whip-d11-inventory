-- Catalogo de acessorios do whip_gunny, lido do arquivo dele (items/attachments.lua) como o whip_d12_hud le os
-- pentes: as tabelas Config.Attachments / Config.WeaponAttachments nao sao exportadas. Armas de packs
-- (RegisterWeapon com `attachments`) nao aparecem aqui.

Catalog = { attachments = {}, weapons = {} }

function Catalog.load()
    local code = LoadResourceFile('whip_gunny', 'items/attachments.lua')
    local env = setmetatable({ Config = {} }, { __index = _G })
    local chunk = code and load(code, '@whip_gunny/items/attachments.lua', 't', env)
    if not (chunk and pcall(chunk)) then
        print('[d11_attachments] nao consegui ler whip_gunny/items/attachments.lua')
        return
    end
    Catalog.attachments = env.Config.Attachments or {}
    Catalog.weapons = env.Config.WeaponAttachments or {}
end

--- O componente GTA de um acessorio (item) nesta arma, ou nil.
function Catalog.component(weaponItem, attachmentItem)
    local att = Catalog.attachments[attachmentItem]
    local kinds = att and (Catalog.weapons[weaponItem] or {})[att.category]
    return kinds and kinds[att.tier] or nil, att
end

Catalog.load()
local function reload(name) if name == 'whip_gunny' then Catalog.load() end end
AddEventHandler(IsDuplicityVersion() and 'onResourceStart' or 'onClientResourceStart', reload)
