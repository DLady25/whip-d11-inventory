// Idiomas do d11_inventory. O texto em pt-BR e a chave (renderer.js: T('Comida')); aqui so a traducao.
// Escolha: setr d11_locale en | pt-BR no server.cfg (padrao en). Outro idioma: um mapa novo e o nome dele em LOCALES.
export const LOCALES = {
    en: {
        // tipos de item e lugares
        'Comida': 'Food', 'Bebida': 'Drink', 'Consumível': 'Consumable', 'Médico': 'Medical', 'Utilitário': 'Tool',
        'Arma': 'Weapon', 'Munição': 'Ammo', 'Chave': 'Key', 'Documento': 'Document', 'Recipiente': 'Container',
        'Acessório': 'Accessory', 'Eletrônico': 'Electronic', 'Dinheiro': 'Money', 'Proteção': 'Protection',
        'Roupa': 'Clothing', 'Diverso': 'Misc', 'Porta-luvas': 'Glovebox', 'Porta-malas': 'Trunk',
        'Armazenamento': 'Storage', 'Armazenamento externo': 'External storage', 'No chão': 'On the ground',
        'Pescoço': 'Neck', 'Item': 'Item',
        // no personagem
        'Equipar': 'Equip', 'Usar': 'Use',
        // cabecalho, ficha, secoes
        'Inventário': 'Inventory', 'Crafting': 'Crafting', 'Comandos': 'Controls', 'Sem personagem': 'No character',
        'Conta ': 'Account ', 'ID ': 'ID ', 'Em mãos': 'Cash', 'Itens': 'Items', 'Carga': 'Load', 'Equipado': 'Equipped', 'Equipamento': 'Gear', 'Rádio': 'Radio', 'Colete': 'Vest', 'Arma branca': 'Melee', 'Pistola/Sub': 'Sidearm/SMG', 'Rifle': 'Rifle',
        'Mochila': 'Backpack', 'Bolsos': 'Pockets', 'Acesso rápido': 'Quick access', 'Slots 1-': 'Slots 1-',
        'Revista': 'Search', 'Jogador': 'Player', 'Ignição': 'Ignition', 'Somente leitura': 'Read only',
        'Enchendo': 'Filling', 'Aberta': 'Open', 'Aberto': 'Open', 'Painel': 'Panel', 'Fechar': 'Close',
        'Por perto': 'Nearby', 'Chão': 'Ground', 'Abrir': 'Open',
        // dica e menu
        // municao e pentes (client/ammo.lua)
        'Essa munição não serve nesse pente.': 'This ammo does not fit that magazine.', 'Carregar todos os pentes': 'Load all magazines',
        'Quantidade': 'Amount', 'Peso': 'Weight', ' cada)': ' each)', 'Esse item não tem uso.': 'This item has no use.',
        // ajuda (?)
        'Mouse e teclado': 'Mouse & keyboard', 'Arrastar': 'Drag', 'Mover o item': 'Move the item',
        'No personagem': 'Onto your character',
        'Arraste até o anel no seu personagem (ou a ficha) para usar ou equipar':
            'Drag onto your character (or the character card) to use or equip',
        'Fora da janela': 'Out of the window', 'Arraste para fora para largar no chão': 'Drag it out to drop it on the ground',
        'Shift + clique': 'Shift + click', 'Enviar para o outro lado': 'Send to the other side', 'Duplo clique': 'Double click',
        'Botão direito': 'Right click', 'Opções (Usar, Dar, Dividir…)': 'Options (Use, Give, Split…)',
        'Acesso rápido, fora do inventário': 'Quick access, outside the inventory', 'Controle': 'Gamepad',
        'Analógico esq.': 'Left stick', 'Mover o cursor': 'Move the cursor', 'D-pad': 'D-pad',
        'Pular para o slot vizinho': 'Jump to the next slot', 'Toque: clicar · Segurar: arrastar · 2x: usar':
            'Tap: click · Hold: drag · 2x: use', 'Opções · Arrastando: mover 1': 'Options · While dragging: move 1',
        'RB + A': 'RB + A', 'LB / RB': 'LB / RB', 'Trocar de coluna': 'Switch column', 'Voltar / soltar / fechar': 'Back / drop / close',
        'Dar e Dividir pedem a quantidade no próprio menu.': 'Give and Split ask for the amount in the menu itself.',
        // faixa de botoes do controle
        'Escolher': 'Choose', 'Confirmar': 'Confirm', 'Voltar': 'Back', 'Mover': 'Move', 'Segurar: arrastar': 'Hold: drag',
        'Enviar': 'Send', 'Opções': 'Options',
        // fantasma do arrasto (style.css le de data-label)
        'Largar no chão': 'Drop on the ground', 'Soltar para usar': 'Release to use',
        // porta-malas fisico (d11_ptrunk)
        'Guardar no porta-malas': 'Store in the trunk', 'O porta-malas está cheio.': 'The trunk is full.',
        'Retirar': 'Take out', 'Inspecionar': 'Inspect', 'Posicionar com o teclado': 'Position with the keyboard',
        'Endireitar': 'Straighten', 'Luz': 'Light', 'Grade': 'Grid', 'Destaques': 'Highlights', 'Gizmo': 'Gizmo', 'Ocultar HUD': 'Hide HUD', 'Câmera': 'Camera', 'Não cabe mais nada aí.': 'Nothing more fits in there.', 'Guardar em': 'Put in',
        'Voltar a câmera para a vista inicial': 'Reset the camera to the starting view', 'Atalhos': 'Shortcuts',
        'Arrastar': 'Drag', 'Mover objeto · fora do porta-malas: chão': 'Move object · outside the trunk: ground',
        'Clique': 'Click', 'Selecionar objeto': 'Select object', 'Duplo clique': 'Double click',
        'Abrir bolsa ou caixa': 'Open bag or box', 'Mover o selecionado': 'Move the selected one',
        'Subir / descer': 'Raise / lower', 'Girar': 'Rotate', 'Botão direito': 'Right button',
        'Opções · arrastando: girar câmera': 'Options · dragging: rotate camera',
        'Meio · Shift+direito': 'Middle · Shift+right', 'Mover o foco': 'Move the focus', 'Roda': 'Wheel',
        'Solte para retirar': 'Release to take out',
        'Guardar nos bolsos': 'Put in pockets', 'Guardar aqui': 'Put here', 'Mover para cá': 'Move here',
        'R/F: altura · Q/E: girar (Shift/Ctrl: outro eixo)': 'R/F: height · Q/E: rotate (Shift/Ctrl: other axis)',
    },
};

/** Numeros no idioma (separador de milhar e decimal). */
export const NUMBER_LOCALE = { en: 'en-US', 'pt-BR': 'pt-BR' };
