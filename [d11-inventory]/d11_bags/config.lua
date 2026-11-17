-- Bolsas D11 no WHIP (d11_bags_t1/t2/t3 e d11_bags_paper) e caixas (d11_bags_box_t1/t2/t3, porte das
-- ptrunk_box_t1-3 do porta-malas fisico da D12: slots, limite e peso da D12; modelo do propbrowser da D12).
-- Regra de peso do WHIP (decisao 2026-11-15): a bolsa pesa pouco e o conteudo soma no peso de quem carrega
-- (bolsos 80 kg). maxWeight e o limite interno da bolsa, checado no onValidate (RegisterPanelItem nao tem maxWeight).
-- Sem limite de bolsas por jogador e aninhamento pela regra do WHIP (ate 4 niveis).
-- prop: modelo no chao. Nas costas quem desenha e o d11_onback (porte do d12-weapons-on-back, /d12attachment).
-- Idioma: setr d11_locale en | pt-BR no server.cfg (padrao en). L(ingles, portugues).
local PT = GetConvar('d11_locale', 'en') == 'pt-BR'
local function L(en, pt) return PT and pt or en end

D11Bags = {
    d11_bags_t1 = {
        name = L('Small Backpack', 'Bolsa'),
        desc = L('A small backpack for discreet loads. 15 slots, up to 15 kg.', 'Mochila pequena para carga discreta. 15 espaços, até 15 kg.'),
        weight = 1.0, slots = 15, maxWeight = 15.0,
        prop = 'sf_prop_sf_backpack_03a',
    },
    d11_bags_t2 = {
        name = L('Medium Backpack', 'Bolsa Média'),
        desc = L('A medium backpack for street work. 20 slots, up to 25 kg.', 'Mochila média para operações de rua. 20 espaços, até 25 kg.'),
        weight = 1.5, slots = 20, maxWeight = 25.0,
        prop = 'xm3_prop_xm3_backpack_01a',
    },
    d11_bags_t3 = {
        name = L('Large Backpack', 'Bolsa Grande'),
        desc = L('A large backpack for heavy loads. 25 slots, up to 40 kg.', 'Mochila grande para carga pesada. 25 espaços, até 40 kg.'),
        weight = 2.0, slots = 25, maxWeight = 40.0,
        prop = 'ch_p_m_bag_var02_arm_s',
    },
    d11_bags_box_t1 = {
        name = L('Small Box', 'Caixa Pequena'),
        desc = L('A reinforced box, a little roomier than a backpack. 18 slots, up to 9.2 kg.',
            'Caixa reforçada, um pouco maior que a bolsa. 18 espaços, até 9,2 kg.'),
        weight = 1.5, slots = 18, maxWeight = 9.2,
        prop = 'prop_cs_box_clothes',
    },
    d11_bags_box_t2 = {
        name = L('Medium Box', 'Caixa Média'),
        desc = L('A reinforced medium box. 32 slots, up to 18.4 kg.', 'Caixa média reforçada. 32 espaços, até 18,4 kg.'),
        weight = 2.0, slots = 32, maxWeight = 18.4,
        prop = 'prop_paper_box_03',
    },
    d11_bags_box_t3 = {
        name = L('Large Box', 'Caixa Grande'),
        desc = L('A large reinforced box for dense loads. 46 slots, up to 29.9 kg.',
            'Caixa grande reforçada para carga densa. 46 espaços, até 29,9 kg.'),
        weight = 2.6, slots = 46, maxWeight = 29.9,
        prop = 'prop_cs_rub_box_01',
    },
    d11_bags_paper = {
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
