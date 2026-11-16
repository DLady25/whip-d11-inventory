-- Bolsas D11 no WHIP (d11_bag_t1/t2/t3 e paperbag).
-- Regra de peso do WHIP (decisao 2026-11-15): a bolsa pesa pouco e o conteudo soma no peso de quem carrega
-- (bolsos 80 kg). maxWeight e o limite interno da bolsa, checado no onValidate (RegisterPanelItem nao tem maxWeight).
-- Sem limite de bolsas por jogador e aninhamento pela regra do WHIP (ate 4 niveis).
-- prop: modelo no chao. A bolsa nao aparece no jogador (so inventario).
D11Bags = {
    d11_bag_t1 = {
        name = 'Bolsa', desc = 'Mochila pequena para carga discreta. 15 espacos, ate 15 kg.',
        weight = 1.0, slots = 15, maxWeight = 15.0,
        prop = 'sf_prop_sf_backpack_03a',
    },
    d11_bag_t2 = {
        name = 'Bolsa Media', desc = 'Mochila media para operacoes de rua. 20 espacos, ate 25 kg.',
        weight = 1.5, slots = 20, maxWeight = 25.0,
        prop = 'xm3_prop_xm3_backpack_01a',
    },
    d11_bag_t3 = {
        name = 'Bolsa Grande', desc = 'Mochila grande para carga pesada. 25 espacos, ate 40 kg.',
        weight = 2.0, slots = 25, maxWeight = 40.0,
        prop = 'ch_p_m_bag_var02_arm_s',
    },
    paperbag = {
        name = 'Saco de Papel', desc = 'Saco de lanche. 5 espacos, ate 1 kg.',
        weight = 0.01, slots = 5, maxWeight = 1.0,
        prop = 'prop_paper_bag_small',
    },
}

D11BagsAction = 'd11_bags:open'
