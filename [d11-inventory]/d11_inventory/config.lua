-- d11_inventory: os gestos do inventario. Sao EXTRAS: clicar em Usar (duplo clique, menu), as teclas de uso (1-5),
-- arrastar ate o painel do chao ("Por perto") e Shift+clique funcionam sempre, com qualquer valor aqui.
-- false desliga o gesto (soltar ali nao faz nada).
D11Inventory = {
    DragToBody    = true,   -- arrastar ate o personagem (ou a ficha) usa ou equipa o item
    DragOutDrops  = true,   -- arrastar para fora da janela larga no chao
    DropInVehicle = true,   -- ... tambem de dentro do veiculo (false: so a pe)
    DropAnimated  = true,   -- com a animacao (pousar a pe, jogar pela janela) e a fisica da queda (false: larga na hora)
}

-- Por um tempo, de outro script (cela, algemado, uma zona), no cliente:
--   exports.d11_inventory:BlockGesture('cela', 'dropOut', 'Voce nao pode largar coisas aqui')
--   exports.d11_inventory:UnblockGesture('cela')
-- gesture: 'body', 'dropOut' ou nil (os dois). O bloqueio cai sozinho se o resource que bloqueou parar.
-- Os bloqueios do whip_core (exports.whip_core:BlockInventoryGesture, docs/patches/whip_core-inventory-drag-gestures)
-- tambem valem aqui quando o whip_core os tem.
