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

-- Equipment slots: extra accessory-strip slots, each taking only the items listed. They join the "Equipped" row
-- of the character sheet after a thin divider; the renderer takes every slot from 17 up as equipment (6-16 are
-- the worn clothes of whip-d11-clothing). The slots must fit in whip_core's Config.ContainerSlots.accessory
-- (21 here). icon: radio, armour, melee, sidearm, rifle, phone, cash, vehicle_key (empty-slot picture).
-- Add, remove or reorder freely; {} turns it off. label is pt-BR (translated by locales.js).
local MELEE = { 'gunny_bat', 'gunny_hatchet', 'gunny_torch', 'gunny_knife', 'gunny_dagger', 'gunny_switchblade',
    'gunny_machete', 'gunny_crowbar', 'gunny_hammer', 'gunny_wrench', 'gunny_golfclub', 'gunny_nightstick',
    'gunny_knuckle', 'gunny_poolcue', 'gunny_bottle', 'gunny_battleaxe', 'gunny_stone_hatchet', 'gunny_stunrod',
    'gunny_candycane' }
local SIDEARM = { 'gunny_pistol', 'gunny_pistol_mk2', 'gunny_combatpistol', 'gunny_appistol', 'gunny_pistol50',
    'gunny_snspistol', 'gunny_snspistol_mk2', 'gunny_heavypistol', 'gunny_vintagepistol', 'gunny_ceramicpistol',
    'gunny_gadgetpistol', 'gunny_revolver', 'gunny_revolver_mk2', 'gunny_doubleaction', 'gunny_navyrevolver',
    'gunny_marksmanpistol', 'gunny_flaregun', 'gunny_stungun', 'gunny_smg', 'gunny_smg_mk2', 'gunny_microsmg',
    'gunny_minismg', 'gunny_assaultsmg', 'gunny_combatpdw', 'gunny_machinepistol', 'gunny_tecpistol' }
local LONG = { 'gunny_rifle', 'gunny_rifle_mk2', 'gunny_carbinerifle', 'gunny_carbinerifle_mk2', 'gunny_advancedrifle',
    'gunny_specialcarbine', 'gunny_specialcarbine_mk2', 'gunny_bullpuprifle', 'gunny_bullpuprifle_mk2',
    'gunny_compactrifle', 'gunny_militaryrifle', 'gunny_heavyrifle', 'gunny_tacticalrifle', 'gunny_battlerifle',
    'gunny_assaultshotgun', 'gunny_heavyshotgun', 'gunny_autoshotgun', 'gunny_pumpshotgun', 'gunny_pumpshotgun_mk2',
    'gunny_sawnoffshotgun', 'gunny_dbshotgun', 'gunny_bullpupshotgun', 'gunny_combatshotgun', 'gunny_musket',
    'gunny_mg', 'gunny_combatmg', 'gunny_combatmg_mk2', 'gunny_gusenberg', 'gunny_sniperrifle', 'gunny_heavysniper',
    'gunny_heavysniper_mk2', 'gunny_marksmanrifle', 'gunny_marksmanrifle_mk2', 'gunny_precisionrifle' }

D11Inventory.GearSlots = {
    { slot = 17, label = 'Rádio',       accepts = 'radio',  icon = 'radio' },
    { slot = 18, label = 'Colete',      accepts = 'armour', icon = 'armour' },
    { slot = 19, label = 'Arma branca', accepts = MELEE,    icon = 'melee' },
    { slot = 20, label = 'Pistola/Sub', accepts = SIDEARM,  icon = 'sidearm' },
    { slot = 21, label = 'Rifle',       accepts = LONG,     icon = 'rifle' },
}
