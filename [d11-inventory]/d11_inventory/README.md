# d11_inventory — inventário D11 no WHIP

Renderer de inventário do WHIP (`docs/nui-inventory.md` do whip_core) no desenho do `ox_inventory`
D12 da VPS (`d12-hud-theme.css` @ `bc7f7683d`, release `inv-d12-theme-fix3-20261112`).

**Só desenha.** Estado, pesos, regras, servidor e a volta de um movimento recusado continuam no
whip_core; todo gesto é uma chamada de `api.actions`. Nada da lógica do WHIP foi alterado.

## Ativar

No `server.cfg`, depois dos `ensure whip_*`:

```cfg
ensure d11_inventory
setr whip_inventory_renderer d11_inventory
```

Vale para quem entrar depois. Para testar sem mexer no cfg, com modo desenvolvedor (`/w`):
`/whip_inventory_ui d11_inventory` (e `/whip_inventory_ui none` para voltar ao do WHIP).
Depois de editar: `ensure d11_inventory` (o WHIP recarrega o renderer em quem estiver jogando).

## O que tem

| Parte | Como ficou (VPS → aqui) |
| --- | --- |
| Posição e tamanho | Coluna do jogador colada à esquerda (24 px, 605 px de largura, topo 54 px em 1080p); externos à direita (566 px). 1em = 16 px em 1080p e escala com a altura da tela |
| Cabeçalho | Marca, "INVENTÁRIO", campo de quantidade (Dar/Dividir), `?` com os atalhos, `Esc` |
| Ficha | Nome, conta, ID; chips Em mãos (dinheiro nos bolsos e acessórios), Itens, Carga |
| Equipado | Seção da ficha, abaixo de uma linha: contador ocupados/total, cada encaixe com o nome por baixo e barra azul quando ocupado. Hierarquia: ficha > equipado > bolsos (Mochila › Bolsos) > acesso rápido |
| Controle (gamepad) | Cursor sempre disponível, no esquema do WHIP: LS move (desacelera em cima de slot), A segurado arrasta / toque clica / dois toques usa, X opções (arrastando: move só um), Y usa, RB+A envia, B fecha menu → solta → fecha, D-pad pula de slot em slot (ou ajusta a quantidade num campo), LB/RB troca de coluna. Dicas de botão na faixa do WHIP. Mexer o mouse esconde o cursor |
| Grade | 5 colunas, slot em faixas: tipo (letra) + peso + quantidade em cima, imagem, nome + tipo embaixo; raridade (`metadata.rarity`) como moldura; carga em azul com barra fina |
| Acesso rápido | Cartão embaixo com os slots 1-5 (a hotbar do WHIP) |
| Externos | Baú / porta-malas / porta-luvas com título e carga; ignição; painéis (carteira, mochila); chão ("Por perto"); revista de outro jogador; preço no modo estoque de loja |
| Interações | Arrastar (bota em cima: mesmo movimento do WHIP; vermelho quando o WHIP recusaria), botão direito arrastando = um, Shift+clique = enviar, duplo clique = usar, botão direito = opções do WHIP (Dar/Dividir pedem quantidade), dica ao passar o mouse, aviso quando o servidor recusa |

## O que a VPS tem e aqui não

- Vida, fome, sede, energia, banco, emprego e placas do colete na ficha: o WHIP não entrega esses
  dados ao inventário.
- Abas Status e Criar: não existem no WHIP.
- Loja: continua a tela de loja do próprio WHIP (com o tema D12).

## Conferido

Na prévia oficial do WHIP (`whip_core/dev/inventory-preview/preview.js d11_inventory
--resources D:\Server\WHIP_LEGACY\themes`): cenas bolsos+chão, baú+carteira, carro (porta-luvas e
ignição); arrastar enviou `moveItem`, Shift+clique `dropToGround`, Dividir `splitItem` (padrão metade),
menu e dica corretos. Controle (mensagens `navInput`/`navAnalog` como o jogo manda): D-pad, X abre o
menu, B fecha, dicas na faixa, arrasto com A segurado + analógico trocou os slots 1 e 2. Não testado no jogo.
