Config = {}

-- Opcao do menu (clique direito) nas armas do gunny que aceitam acessorio.
Config.MenuAction = 'd11_attachments:open'   -- ate 32 caracteres (whip_core)
Config.MenuLabel = 'Acessórios'

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
    { id = 'scope',      label = 'Mira',        category = 'scope',      bones = { 'WAPScop', 'WAPScop_2' },                    offset = vec3(0.0, 0.05, 0.08) },
    { id = 'muzzle',     label = 'Bocal',       category = 'muzzle',     bones = { 'WAPSupp', 'WAPSupp_2' },                    offset = vec3(0.0, 0.45, 0.02) },
    { id = 'barrel',     label = 'Cano',        category = 'barrel',     bones = { 'gun_muzzle' },                              offset = vec3(0.0, 0.35, 0.0) },
    { id = 'grip',       label = 'Empunhadura', category = 'grip',       bones = { 'WAPGrip', 'WAPGrip_2' },                    offset = vec3(0.0, 0.2, -0.05) },
    { id = 'flashlight', label = 'Lanterna',    category = 'flashlight', bones = { 'WAPFlshLasr', 'WAPFlshLasr_2', 'WAPFlsh' }, offset = vec3(0.03, 0.25, 0.0) },
    { id = 'magazine',   label = 'Carregador',  magazine = true,         bones = { 'WAPClip', 'WAPClip_2' },                    offset = vec3(0.0, 0.05, -0.1) },
}

Config.Text = {
    title = 'INSPEÇÃO',
    hint = 'Passe o mouse num ponto de encaixe  ·  ESC sai',
    empty = 'Vazio',
    detach = 'Remover %s',
    attach = 'Acoplar %s',
    attachBlocked = 'Remova %s primeiro',
    noMagazine = 'Sem carregador',
    magazineHint = 'Troque o carregador com R',
    cameraFirst = '1ª pessoa',
    cameraScripted = 'Externa',
    cameraButton = 'Câmera: %s',
    drawFail = 'Não foi possível sacar a arma.',
    inVehicle = 'Não dá para mexer na arma dentro de um veículo.',
    noAttachments = 'Esta arma não aceita acessórios.',
    failed = 'Não foi possível concluir.',
    -- Card
    kindWeapon = 'Arma', serial = 'Série', ammo = 'Munição', magazine = 'Carregador',
    parts = 'Acessórios', noParts = 'Nenhum acessório',
}

-- Icones dos itens: o whip_core procura o icone no resource que registrou o item (html/img/items/<item>.webp|png).
-- Armas, pentes e acessorios sao todos do gunny.
Config.IconBase = 'https://cfx-nui-whip_gunny/html/img/items/'
