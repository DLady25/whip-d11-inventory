-- d11_inventory settings.
--
-- Language (every D11 resource): setr d11_locale en | pt-BR in server.cfg. Default: en.
--
-- The inventory gestures are EXTRAS: clicking Use (double click, the item menu), the use keys (1-5), dragging onto
-- the "Nearby" ground panel and shift-click always work, whatever is set here. false switches a gesture off
-- (letting go there does nothing).
D11Inventory = {
    DragToBody    = true,   -- drag onto your character (or the character card) to use / equip
    DragOutDrops  = true,   -- drag out of the window to drop on the ground
    DropInVehicle = true,   -- ...also from inside a vehicle (false: on foot only)
    DropAnimated  = true,   -- put-down / toss-out-of-the-window animation and physics (false: drops at once)
}

-- For a while, from another script (a cell, handcuffs, a zone), client side:
--   exports.d11_inventory:BlockGesture('cell', 'dropOut', 'You cannot drop things in here')
--   exports.d11_inventory:UnblockGesture('cell')
-- gesture: 'body', 'dropOut' or nil (both). A block goes away by itself when the resource that set it stops.
-- whip_core's own blocks (exports.whip_core:BlockInventoryGesture, from the drag-gestures patch) count here too.
