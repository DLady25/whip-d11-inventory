-- Bolsas D11 no WHIP (d11_bag_t1/t2/t3 e paperbag).
-- Regra de peso do WHIP (decisao 2026-11-15): a bolsa pesa pouco e o conteudo soma no peso de quem carrega
-- (bolsos 80 kg). maxWeight e o limite interno da bolsa, checado no onValidate (RegisterPanelItem nao tem maxWeight).
-- Sem limite de bolsas por jogador e aninhamento pela regra do WHIP (ate 4 niveis).
-- prop: modelo no chao. A bolsa nao aparece no jogador (so inventario).
-- Idioma: setr d11_locale en | pt-BR no server.cfg (padrao en). L(ingles, portugues).
local PT = GetConvar('d11_locale', 'en') == 'pt-BR'
local function L(en, pt) return PT and pt or en end

D11Bags = {
    d11_bag_t1 = {
        name = L('Small Backpack', 'Bolsa'),
        desc = L('A small backpack for discreet loads. 15 slots, up to 15 kg.', 'Mochila pequena para carga discreta. 15 espaços, até 15 kg.'),
        weight = 1.0, slots = 15, maxWeight = 15.0,
        prop = 'sf_prop_sf_backpack_03a',
    },
    d11_bag_t2 = {
        name = L('Medium Backpack', 'Bolsa Média'),
        desc = L('A medium backpack for street work. 20 slots, up to 25 kg.', 'Mochila média para operações de rua. 20 espaços, até 25 kg.'),
        weight = 1.5, slots = 20, maxWeight = 25.0,
        prop = 'xm3_prop_xm3_backpack_01a',
    },
    d11_bag_t3 = {
        name = L('Large Backpack', 'Bolsa Grande'),
        desc = L('A large backpack for heavy loads. 25 slots, up to 40 kg.', 'Mochila grande para carga pesada. 25 espaços, até 40 kg.'),
        weight = 2.0, slots = 25, maxWeight = 40.0,
        prop = 'ch_p_m_bag_var02_arm_s',
    },
    paperbag = {
        name = L('Paper Bag', 'Saco de Papel'),
        desc = L('A lunch bag. 5 slots, up to 1 kg.', 'Saco de lanche. 5 espaços, até 1 kg.'),
        weight = 0.01, slots = 5, maxWeight = 1.0,
        prop = 'prop_paper_bag_small',
    },
}

D11BagsAction = 'd11_bags:open'
D11BagsText = {
    open = L('Open', 'Abrir'),
    tooHeavy = L("It doesn't fit: the %s holds %g kg", 'Não cabe: a %s aguenta %g kg'),
}
