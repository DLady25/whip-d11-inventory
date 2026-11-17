-- d11_ptrunk: porta-malas fisico (porte do velocity-physicaltrunk da D12).
-- Idioma: setr d11_locale en | pt-BR no server.cfg (padrao en). L(ingles, portugues).
local PT_BR = GetConvar('d11_locale', 'en') == 'pt-BR'
local function L(en, pt) return PT_BR and pt or en end

Config = {}

-- Liga/desliga: D11Inventory_World no config.lua do d11_inventory (Trunk, Ground, Camera), que o d11_inventory publica
-- como convars ao subir (ele sobe antes deste). Padrao: tudo ligado.
Config.PhysicalTrunk = GetConvarInt('d11_inventory_trunk', 1) ~= 0
Config.PhysicalGround = GetConvarInt('d11_inventory_ground', 1) ~= 0
Config.GroundCamera = GetConvarInt('d11_inventory_camera', 1) ~= 0

-- Perfis dos carros (a area util, a camera e a luz de cada modelo), em arquivos por pack de carros. Na ordem: o de
-- baixo vence o de cima, e o que o wizard grava no banco vence todos. resource = o pack so vale com um resource
-- rodando que tenha esse texto no nome. Carro sem area em nenhum deles abre o porta-malas normal do WHIP.
-- Seus carros: crie um arquivo no formato de data/profiles/base.lua (ou gere com /ptrunkexport) e ponha aqui.
Config.ProfilePacks = {
    { file = 'data/profiles/base.lua' },                           -- GTA V (e as classes)
    { file = 'data/profiles/onx.lua' },                            -- ONX (onx-cvp / onx-evp)
    { file = 'data/profiles/nopixel.lua', resource = 'nopixel' },  -- NoPixel 4: substitui carros base, so com o pack
    -- { file = 'data/profiles/my_server.lua' },
}

-- Camera padrao. O perfil do modelo (data/profiles, camera) e o da classe (class) vencem estes valores.
Config.Camera = {
    fov = 52.0,
    transitionMs = 450,
    rearDistance = 0.55,
    rearHeight = 1.0,
    lookHeight = 0.72,
    sideOffset = 0.0,
}

-- Camera do modo fisico: orbital, presa ao porta-malas (pedido de 2026-11-16, no lugar da camera fechada do perfil).
-- Comeca na direcao da camera calibrada do perfil, startScale vezes mais longe. Botao direito arrastando no meio da
-- tela gira (ate yawLimit graus para os lados, pitchMin..pitchMax para baixo/cima); a roda aproxima e afasta.
Config.Orbit = {
    startScale = 1.6,      -- quanto mais longe que a camera do perfil comeca
    minScale = 0.9,        -- o mais perto (roda)
    maxScale = 2.6,        -- o mais longe (roda)
    zoomStep = 0.12,
    yawLimit = 70.0,
    pitchMin = -20.0,
    pitchMax = 35.0,
    sensitivity = 160.0,   -- graus por tela inteira de mouse
    smooth = 0.25,         -- 1 = sem suavizar
    extraFov = 6.0,        -- fov a mais que o do perfil, para ficar mais aberto
    maxFov = 75.0,
    -- Ponto de foco (pedido de 2026-11-16): botao do meio arrastando (ou Shift + botao direito) leva o ponto para onde
    -- a camera mira pelo chao do carro, ate panLimit metros do centro do porta-malas; clique do meio volta ao centro.
    panLimit = 1.6,
    panSpeed = 1.2,        -- metros por tela inteira de mouse, por metro de distancia da camera
}

-- Itens no chao a ate quantos metros do carro aparecem para pegar com o mouse e guardar no porta-malas.
Config.GroundReach = 6.5

-- No modo porta-malas, largar com o cursor no chao poe o item no ponto do cursor, em qualquer chao ate GroundReach do
-- carro (sem area nem grade desde 2026-11-16). Largar sem cursor no chao (menu, painel) usa estes pontos de reserva
-- invisiveis na frente do porta-malas: size x size metros, a `gap` metros do para-choque, de `cell` em `cell` metros,
-- o primeiro livre de perto do carro para longe.
Config.GroundArea = {
    size = 3.0,
    gap = 0.25,
    cell = 0.30,
}

-- Itens do chao com o mouse fora do porta-malas, com o inventario aberto (client/ground.lua): de quantos metros do
-- jogador eles aparecem, e ate quantos metros dele da para mudar um de lugar.
Config.GroundFree = {
    reach = 3.5,
    moveReach = 3.0,
    -- Camera orbital em volta do jogador (client/profiles.lua, PT.PlayerOrbit*): nasce onde a camera do jogo esta no
    -- primeiro giro (botao direito/meio) ou roda, segue o jogador e volta para a do jogo ao fechar o inventario.
    camera = {
        height = 0.55,         -- alvo: metros acima do centro do personagem
        minDist = 1.2, maxDist = 8.0, zoomStep = 0.4,
        sensitivity = 200.0,   -- graus por tela inteira de mouse
        pitchMin = -15.0, pitchMax = 75.0,
        smooth = 0.25,         -- 1 = sem suavizar
        exitMs = 350,
    },
}

-- Distancia minima do ponto de acesso (traseira, ou frente no motor traseiro) para o modo fisico.
Config.TrunkInteractDistance = 2.6

-- Objetos dos itens.
Config.Props = {
    max = 30,              -- objetos no maximo (VisualItemLimit da D12)
    spacing = 0.32,        -- distancia entre objetos na grade (m)
    maxModelSize = 0.9,    -- modelo de item maior que isso (m) vira a caixa da categoria
}

-- Fisica dos objetos (fase 3): o motor e os parametros sao os da D12 (data/item_visuals.lua, d12.physics). Para mudar
-- um parametro, ponha aqui (ex.: { gravity = 0.002 }), sem editar o motor. Liga/desliga para todos: /ptrunkphysics.
Config.PhysicsOverrides = {}

-- Itens do WHIP com nome diferente do da D12 (os modelos, pivos e footprints calibrados la sao pelo nome da D12).
-- Nome no WHIP = nome na D12.
Config.ItemAliases = {
    d11_bags_t1 = 'ptrunk_bag_t1',
    d11_bags_t2 = 'ptrunk_bag_t2',
    d11_bags_t3 = 'ptrunk_bag_t3',
    d11_bags_box_t1 = 'ptrunk_box_t1',
    d11_bags_box_t2 = 'ptrunk_box_t2',
    d11_bags_box_t3 = 'ptrunk_box_t3',
}

-- Modelo de itens do WHIP que nao existiam na D12 (sem propbrowser, sem modelo da D12 e sem `prop` no catalogo): sem
-- isto eles viram o modelo da categoria (o saco de papel pequeno). Vale antes das tabelas da D12, no porta-malas, no
-- chao e na mao (o WHIP pergunta pelo export ItemPropModel). Um modelo que nao existe no jogo e ignorado (cai na
-- categoria); /ptrunkmodels lista quais do mapa nao existem.
Config.ItemModels = {
    -- my_item = 'prop_cs_box_clothes',
    -- cash_stack = 'prop_cash_pile_02',
}

-- Modelo pela quantidade na pilha, como o `images` do WHIP faz com o icone (o dinheiro do whip_core): a primeira
-- entrada que serve e o modelo (below / above / atLeast / atMost; sem teste, serve sempre). Vale antes do
-- Config.ItemModels; um modelo que nao existe no jogo e pulado. No porta-malas, no chao e na mao.
Config.ItemModelsByAmount = {
    -- my_cash = {
    --     { below = 100, model = 'prop_anim_cash_note' },
    --     { below = 1000, model = 'ex_cash_roll_01' },
    --     { model = 'prop_cash_pile_02' },
    -- },
}

-- Comandos de admin (ACE). Sem a ACE o comando nao faz nada.
Config.AdminAce = 'whip.devtools'

-- Porta-malas aberto de outro carro: de quantos metros os objetos e a luz aparecem, e de quanto em quanto tempo o
-- jogo confere o conteudo.
Config.Ambient = {
    range = 12.0,
    refreshMs = 3000,
}

-- "Abrir porta-malas": quanto a tampa espera (ms) para os objetos ja estarem no lugar quando ela sobe (patch
-- whip_trunk_opener, BeforeTrunkLid). Pedido de 2026-11-16: melhor do que ver os objetos aparecendo.
Config.LidDelayMs = 500

-- Luz quando o modelo nao tem perfil de luz (Config.TrunkLight da D12).
Config.TrunkLight = {
    distance = 2.2,
    brightness = 6.0,
    roundness = 0.2,
    radius = 12.0,
    falloff = 18.0,
}

-- Quantos segundos o modo fisico fica com um jogador depois que ele some do store (queda, crash) antes de liberar.
Config.LockGraceSeconds = 3

Config.Text = {
    busy = L('Someone else is working this trunk: opening it the plain way.',
        'Outra pessoa está mexendo neste porta-malas: abrindo do jeito normal.'),
    notFound = L('Vehicle not found.', 'Veículo não encontrado.'),
    tooFar = L('Get closer to the trunk.', 'Chegue mais perto do porta-malas.'),
}
