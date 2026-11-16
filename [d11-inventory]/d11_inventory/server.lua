-- Fecha um painel do proprio jogador (o "x" da aba no renderer). So o que ele tem aberto: ClosePanel e por source.
RegisterNetEvent('d11_inventory:closePanel', function(id)
    if type(id) ~= 'string' or #id > 80 then return end
    exports.whip_core:ClosePanel(source, id)
end)
