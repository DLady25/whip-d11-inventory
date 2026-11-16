Config = {}

-- Idioma: setr d11_locale en | pt-BR no server.cfg (padrao en). L(ingles, portugues).
local PT = GetConvar('d11_locale', 'en') == 'pt-BR'
local function L(en, pt) return PT and pt or en end


-- Opcao do menu (clique direito) nas armas do gunny que aceitam acessorio.
Config.MenuAction = 'd11_attachments:open'   -- ate 32 caracteres (whip_core)
Config.MenuLabel = L('Attachments', 'Acessórios')

-- Pose de inspecao do D12: o ped levanta a arma na frente do corpo; a anim toca ate `freezeAt` e congela ali
-- (a original fica girando a arma). Os outros jogadores veem a mesma pose congelada (state bag).
Config.Anim = {
    default = { dict = 'weapons@first_person@aim_idle@p_m_zero@pistol@shared@fidgets@c', anim = 'fidget_med_loop' },
    byGroup = {},
    flag = 49,
    freezeAt = 0.35,
}

-- 'scripted' (padrao): camera parada a frente e a direita do ped, mirando onde a arma fica na pose.
-- 'firstperson': a 1a pessoa do jogo (o botao na tela alterna entre as duas).
Config.Camera = {
    mode = 'scripted',
    byGroup = {},                      -- [`GROUP_PISTOL`] = 'firstperson'
    offset = vec3(0.75, 1.30, 0.62),   -- x direita, y frente, z cima (a partir do ped)
    fov = 46.0,
    interp = 350,
}

-- Pontos de encaixe. `category` e a categoria do gunny (items/attachments.lua). O ponto so aparece se a arma
-- tiver a categoria. `magazine` e so informativo: no gunny o pente estendido e um carregador trocado com o R.
Config.Slots = {
    { id = 'scope',      label = L('Sight', 'Mira'),                 category = 'scope',      bones = { 'WAPScop', 'WAPScop_2' },                    offset = vec3(0.0, 0.05, 0.08) },
    { id = 'muzzle',     label = L('Muzzle', 'Bocal'),               category = 'muzzle',     bones = { 'WAPSupp', 'WAPSupp_2' },                    offset = vec3(0.0, 0.45, 0.02) },
    { id = 'barrel',     label = L('Barrel', 'Cano'),                category = 'barrel',     bones = { 'gun_muzzle' },                              offset = vec3(0.0, 0.35, 0.0) },
    { id = 'grip',       label = L('Grip', 'Empunhadura'),           category = 'grip',       bones = { 'WAPGrip', 'WAPGrip_2' },                    offset = vec3(0.0, 0.2, -0.05) },
    { id = 'flashlight', label = L('Flashlight', 'Lanterna'),        category = 'flashlight', bones = { 'WAPFlshLasr', 'WAPFlshLasr_2', 'WAPFlsh' }, offset = vec3(0.03, 0.25, 0.0) },
    { id = 'magazine',   label = L('Magazine', 'Carregador'),        magazine = true,         bones = { 'WAPClip', 'WAPClip_2' },                    offset = vec3(0.0, 0.05, -0.1) },
}

Config.Text = {
    title = L('INSPECTION', 'INSPEÇÃO'),
    hint = L('Hover a mount point  ·  ESC to exit', 'Passe o mouse num ponto de encaixe  ·  ESC sai'),
    empty = L('Empty', 'Vazio'),
    detach = L('Remove %s', 'Remover %s'),
    attach = L('Attach %s', 'Acoplar %s'),
    attachBlocked = L('Remove %s first', 'Remova %s primeiro'),
    noMagazine = L('No magazine', 'Sem carregador'),
    magazineHint = L('Swap the magazine with R', 'Troque o carregador com R'),
    cameraFirst = L('1st person', '1ª pessoa'),
    cameraScripted = L('External', 'Externa'),
    cameraButton = L('Camera: %s', 'Câmera: %s'),
    drawFail = L('Could not draw the weapon.', 'Não foi possível sacar a arma.'),
    inVehicle = L('You cannot work on a weapon inside a vehicle.', 'Não dá para mexer na arma dentro de um veículo.'),
    noAttachments = L('This weapon takes no attachments.', 'Esta arma não aceita acessórios.'),
    failed = L('Could not finish that.', 'Não foi possível concluir.'),
    -- servidor
    wrongAttachment = L('This weapon does not take that attachment.', 'Esta arma não aceita esse acessório.'),
    slotTaken = L('That mount point is already taken.', 'Esse encaixe já está ocupado.'),
    takeFailed = L('Could not take the attachment.', 'Não foi possível pegar o acessório.'),
    saveFailed = L('Could not save the weapon.', 'Não foi possível salvar a arma.'),
    nothingThere = L('Nothing attached there.', 'Nada acoplado aí.'),
    noRoom = L('No room for the attachment.', 'Sem espaço para o acessório.'),
    -- Card
    kindWeapon = L('Weapon', 'Arma'), serial = L('Serial', 'Série'), ammo = L('Ammo', 'Munição'),
    magazine = L('Magazine', 'Carregador'), parts = L('Attachments', 'Acessórios'), noParts = L('No attachments', 'Nenhum acessório'),
}

-- Icones dos itens: o whip_core procura o icone no resource que registrou o item (html/img/items/<item>.webp|png).
-- Armas, pentes e acessorios sao todos do gunny.
Config.IconBase = 'https://cfx-nui-whip_gunny/html/img/items/'
