# d11_attachments

Acessórios na arma em mãos, como a inspeção de armas da VPS (`d12-item-inspect`), sobre o `whip_gunny`.

- **Entrada:** clique direito numa arma do gunny que aceita acessório → **Acessórios**. Se ela não estiver
  sacada, é sacada; o inventário fecha, o ped levanta a arma na pose de inspeção (congelada, os outros
  veem igual) e cada ponto de encaixe vira um marcador na tela.
- **Pontos:** Mira, Bocal, Cano, Empunhadura, Lanterna (as categorias do gunny que a arma tem) e
  Carregador (só mostra o pente e as balas; no gunny o pente estendido é um carregador, trocado com o R).
- **Acoplar/Remover:** opções com o que está nos bolsos. O servidor grava em `metadata.attachments` (+
  `attachmentMeta`), o mesmo estado da bancada do gunny, e manda `whip_gunny:client:attachmentInstalled`
  / `attachmentRemoved` para o gunny pôr/tirar o componente da arma sacada. O HUD D12 lê o componente
  do ped, então a silhueta acompanha. Ao sacar de novo, o gunny reaplica a partir da metadata.
- **Câmera:** botão no canto alterna 1ª pessoa / externa (armas longas abrem na externa). ESC, Backspace
  ou clique fora fecham.

O catálogo vem de `whip_gunny/items/attachments.lua`, lido em runtime (`shared/catalog.lua`). Armas de
packs (`RegisterWeapon` com `attachments`) não entram.

Nada no gunny é alterado. Pendente (2ª fase): skins/acabamentos (`COMPONENT_*_VARMOD_*`), que o gunny
não tem; precisam de patch em `docs/patches/` criando a categoria.
