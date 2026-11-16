-- Os gestos podem ser usados agora? config.lua (D11Inventory), os bloqueios deste resource (BlockGesture) e os do
-- whip_core (InventoryGestureAllowed, quando o whip_core tem o patch de gestos). client/body.lua e client/drop.lua
-- perguntam aqui.

local GESTURES = { body = true, dropOut = true }
local blocks = {}   -- ['<resource>:<id>'] = { owner, gesture = 'body'|'dropOut'|nil, label }

D11Gestures = {}

--- true, ou false e o motivo (o texto do bloqueio; nil quando o config.lua desliga).
---@param gesture 'body'|'dropOut'
---@return boolean allowed
---@return string|nil why
function D11Gestures.allowed(gesture)
    if gesture == 'body' and D11Inventory.DragToBody == false then return false end
    if gesture == 'dropOut' and D11Inventory.DragOutDrops == false then return false end
    for _, b in pairs(blocks) do
        if b.gesture == nil or b.gesture == gesture then return false, b.label end
    end
    -- o do whip_core, se existir (sem o patch de gestos o export nao existe: o pcall falha e vale o nosso)
    local ok, allowed, why = pcall(function() return exports.whip_core:InventoryGestureAllowed(gesture) end)
    if ok and allowed == false then return false, why end
    return true
end

exports('BlockGesture', function(id, gesture, label)
    if type(id) ~= 'string' and type(id) ~= 'number' then return false, 'id deve ser texto ou numero' end
    if gesture ~= nil and not GESTURES[gesture] then return false, "gesture deve ser 'body', 'dropOut' ou nil" end
    if label ~= nil and (type(label) ~= 'string' or #label > 120) then return false, 'label deve ser texto (ate 120)' end
    local owner = GetInvokingResource() or GetCurrentResourceName()
    blocks[owner .. ':' .. tostring(id)] = { owner = owner, gesture = gesture, label = label }
    return true
end)

exports('UnblockGesture', function(id)
    local owner = GetInvokingResource() or GetCurrentResourceName()
    blocks[owner .. ':' .. tostring(id)] = nil
    return true
end)

exports('GestureAllowed', function(gesture) return D11Gestures.allowed(gesture) end)

-- o bloqueio cai junto com o resource que bloqueou
AddEventHandler('onClientResourceStop', function(res)
    for key, b in pairs(blocks) do
        if b.owner == res then blocks[key] = nil end
    end
end)
