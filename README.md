# D11 Inventory for WHIP

> **Installing?** Follow [INSTALL.md](INSTALL.md) (English and Português): the whole D11 set on a stock whip_core
> 1.2.0, step by step, with the patch order, server.cfg and what to check in the console.

The inventory we run on District 11 (D11), built on [WHIP](https://github.com/WHIPFX/whip_core)'s own inventory
core. The renderer only draws: state, weights, rules and the server stay whip_core's, and every gesture goes through
`api.actions` (whip_core `docs/nui-inventory.md`). Version 2 adds the **physical trunk and physical ground**
(`d11_ptrunk`), built into the inventory, each one switchable on its own. Built for whip_core 1.2.0: every patch below
applies cleanly to a stock 1.2.0.

It depends on WHIP only (whip_core, whip_gunny, oxmysql). Nothing from our server comes with it: no shops, no
clothing packs, no vehicle packs. The trunk profiles for ONX and NoPixel cars are plain data, used only when those
cars exist.

> **English and Brazilian Portuguese.** One line in server.cfg picks the language of every D11 resource:
> `setr d11_locale en` (the default) or `setr d11_locale pt-BR`. See **Language** below.

## What's inside

`[d11-inventory]/`: drop this folder into your `resources/`.

| Resource | What it does |
| --- | --- |
| `d11_inventory` | Our inventory look as a WHIP renderer: a character card (name, account, cash, items, load), an "Equipped" section for the accessory strip (with optional radio, vest and weapon slots), pockets (slots 1-5 marked with their use key) and open bags as tabs, a "Nearby" ground panel, glovebox / boot / stash / ignition, full gamepad support. **Drag an item onto your character** (the real one, in the world: it gets an outline in the theme colour) to use or equip it. **Drag an item out of the window** to drop it from your hand: on foot you put it down, in a vehicle you wind the window down and toss it out (while moving too), and it falls with physics where it lands. |
| `d11_bags` | Backpacks (`d11_bags_t1`, `d11_bags_t2`, `d11_bags_t3`), a paper bag (`d11_bags_paper`) and boxes (`d11_bags_box_t1`, `_t2`, `_t3`: 18 / 32 / 46 slots) as inventory panels: open them from your pockets, straight from the ground or inside a trunk, close a tab with its x, the bag being filled is highlighted. Bags are inventory only: they are not drawn on the player (`prop` is the model on the ground). The boxes use WHIP's default icon. |
| `d11_ptrunk` | **Physical trunk and ground.** "View trunk" shows the boot from behind the car with every item as a prop with physics: move, turn, stack, drop on the ground, drag to bags and pockets, light, grid, orbit camera. Items on the ground become physics objects while the inventory is open. A car with no calibrated area opens the plain trunk. Ships a **starter pack of vehicle profiles** (121 GTA V, 63 ONX, 21 NoPixel cars), a calibration wizard and `/ptrunkexport` to share yours. See `d11_ptrunk/README.md`. |
| `d11_attachments` | Weapon attachments in your hands: right-click a whip_gunny weapon, **Acessórios** (Attachments), and the character raises it in an inspect pose with a marker per mount point (sight, muzzle, barrel, grip, flashlight). Attach / remove from what you carry, no workbench needed. Same `metadata.attachments` as gunny's bench. |

`whip_core-patches/`: **all optional**, everything works without them. whip_core is installed as is, so our changes to it ship as patches.

| Patch | Needed for |
| --- | --- |
| `whip_core-ground-panel-d11.patch` | Optional. Opens a bag lying on the ground in place. Without it, **Open** on a bag on the ground picks it up into your pockets and opens it there (d11_inventory finds out by itself). |
| `whip_core-inventory-drag-gestures-upstream.patch` | Optional. Our PR to WHIP ([WHIPFX/whip_core#65](https://github.com/WHIPFX/whip_core/pull/65)): drag onto your character / drag out to drop in whip's **own** inventory, plus "a drop from a vehicle lands beside your door". Skip it once the PR is merged. `d11_inventory` works without it. |
| `whip_core-inventory-noblur-d11.patch` | **Recommended** (our default): no screen blur when the inventory opens. `World.Blur = true` brings WHIP's blur back. |
| `whip_core-inventory-drive-d11.patch` | **Recommended** (our default), apply after noblur: walk (WASD + Shift) and drive (WASD + Space) with the inventory open, keyboard only. `World.Move = false` brings WHIP's frozen inventory back, `World.MoveLook = true` adds mouse look. |
| `whip_core-hotbar-slots-d11.patch` | Optional: keys 1-3 draw the weapons in the equipment slots, 4-5 the pockets (`Config.HotbarSlots`, see the patch header). |
| `whip_core-progress-keep-inventory-d11.patch` + `whip_gunny-mag-load-keep-inventory-d11.patch` | Optional, together: loading a magazine keeps the inventory open (drag ammo onto a magazine, `/pentes` loads them all). |
| `whip_core-trunk-opener-d11.patch` | **Required for the physical trunk**: "View trunk" opens it, and the lid waits for the props. |
| `whip_core-ground-physics-d11.patch` | **Required for the physical ground.** |
| `whip_core-store-panel-d11.patch` | Optional: bags and boxes open inside a trunk or stash (else they open in the pockets). |
| `whip_core-item-prop-resolver-d11.patch`, then `whip_core-item-prop-amount-d11.patch` | Optional: items on the ground and in the hand use the trunk's models, and money changes model with the amount. |

From your `resources/` folder (these patch paths start with `whip_core/`):

```
patch -p1 < whip_core-ground-panel-d11.patch
patch -p1 < whip_core-inventory-noblur-d11.patch
patch -p1 < whip_core-inventory-drive-d11.patch
patch -p1 < whip_core-hotbar-slots-d11.patch
patch -p1 < whip_core-progress-keep-inventory-d11.patch
patch -p1 < whip_gunny-mag-load-keep-inventory-d11.patch
patch -p1 < whip_core-trunk-opener-d11.patch
patch -p1 < whip_core-ground-physics-d11.patch
patch -p1 < whip_core-store-panel-d11.patch
patch -p1 < whip_core-item-prop-resolver-d11.patch
patch -p1 < whip_core-item-prop-amount-d11.patch
```

The drag-gestures patch is made inside whip_core: `cd whip_core` then `git apply ../whip_core-inventory-drag-gestures-upstream.patch` (or `patch -p1 <` it).

## Configuration

Every gesture is an **extra**: clicking Use (double click, the item menu), the use keys (1-5), dragging onto the
"Nearby" ground panel and shift-click always work, whatever is set here.

`d11_inventory/config.lua`:

```lua
D11Inventory = {
    DragToBody    = true,   -- drag onto your character (or the character card) to use / equip
    DragOutDrops  = true,   -- drag out of the window to drop on the ground
    DropInVehicle = true,   -- ...also from inside a vehicle (false: on foot only)
    DropAnimated  = true,   -- put-down / toss-out-the-window animation and physics (false: drops at once)
}
```

**Per scenario, from another script** (client side): a cell, handcuffs, a no-littering zone.

```lua
exports.d11_inventory:BlockGesture('cell', 'dropOut', 'You cannot drop things in here')  -- 'body', 'dropOut' or nil (both)
exports.d11_inventory:UnblockGesture('cell')
exports.d11_inventory:GestureAllowed('dropOut')   -- true, or false and the reason
```

A block is lifted by itself when the resource that set it stops. With the drag-gestures patch applied, whip_core's own
settings and blocks (`Config.InventoryDragToBody`, `InventoryDragOutDrops`, `InventoryDragOutInVehicle`,
`InventoryDragOutAnimated`, `exports.whip_core:BlockInventoryGesture`) are honoured too.

### Equipment slots

The accessory strip takes as many slots as you want, each one limited to the items you list
(`exports.whip_core:RegisterAccessorySlot`, enforced on the server). `d11_inventory` ships five: **Radio**, **Vest**
(`armour`), **Melee**, **Sidearm/SMG** and **Rifle** (whip_gunny items). They show in the "Equipped" row after a thin
divider; names on hover, a line icon while empty. A weapon in one of them is drawn and used like one in the pockets.

```lua
D11Inventory.GearSlots = {
    { slot = 17, label = 'Rádio',  accepts = 'radio',  icon = 'radio' },
    { slot = 18, label = 'Colete', accepts = 'armour', icon = 'armour' },
    -- ... melee, sidearm and rifle take lists of gunny_* items (see config.lua)
}
```

They need room in the strip. In `whip_core/config.lua`:

```lua
Config.ContainerSlots = { player = 30, accessory = 21 }   -- 1-5 WHIP, 6-16 worn clothes, 17-21 equipment
Config.MaxWeight      = { player = 80.0, accessory = 25.0 }
```

Slots 17 and up are drawn as equipment, so keep yours there (without whip-d11-clothing, 6-16 just stay unused).
`D11Inventory.GearSlots = {}` turns them off.

### The inventory in the world

Our defaults: free movement and no blur with the inventory open, physical trunk and ground, and an orbit camera around
you. Each one switches on its own in `d11_inventory/config.lua`; `false` / `true` gives you WHIP's own behaviour back:

```lua
D11Inventory_World = {
    Blur     = false,  -- screen blur behind the open inventory (WHIP's own: true). Needs the noblur patch
    Move     = true,   -- walk and drive with it open, keyboard only. Needs the drive patch
    MoveLook = false,  -- ...and turn the camera with the mouse while doing it
    Trunk    = true,   -- physical trunk (d11_ptrunk): false opens WHIP's plain trunk list
    Ground   = true,   -- physical ground (d11_ptrunk): items on the ground as physics objects
    Camera   = true,   -- the orbit camera around you with the inventory open (right / middle drag, wheel)
}
```

d11_inventory hands them to whip_core and d11_ptrunk when it starts (keep `ensure d11_inventory` before `d11_ptrunk`),
so change them there and restart the server.

Per-vehicle profiles, the wizard and how to share yours: `d11_ptrunk/README.md`.

## Language

```cfg
setr d11_locale en      # or pt-BR
```

English is the default. The inventory's texts are in `d11_inventory/locales.js` (the Portuguese text is the key, so a
new language is one more map there); d11_bags and d11_attachments keep theirs in their `config.lua` (`L(english,
portuguese)`). Item names that come from WHIP itself follow WHIP's own language.

## Requirements

- whip_core 1.2.0 (the patches are made for it).
- whip_gunny, for d11_attachments and magazines.
- oxmysql, for d11_ptrunk (it creates its two tables on start).
- Optional: `whip_theme_d12`, our WHIP theme. d11_attachments reads its tokens and falls back to the same colours without it.

## server.cfg

After the `ensure whip_*` lines:

```cfg
setr d11_locale en
ensure d11_inventory
setr whip_inventory_renderer d11_inventory
ensure d11_bags
ensure d11_attachments
ensure d11_ptrunk
setr whip_trunk_opener d11_ptrunk
setr whip_item_prop_resolver d11_ptrunk
```

Then run `ptrunkpreflight` in the server console: it checks resources, convars, patches, tables and profiles.

Restart whip_core after applying a patch. To try the renderer without the cfg line: developer mode (`/w`), then
`/whip_inventory_ui d11_inventory` (`/whip_inventory_ui none` goes back to whip's own).

## Notes

- The **Crafting** button shows only when a `d11_craft` resource is running (not part of this package).
- **Upgrading from 1.x:** the bag items were renamed to follow WHIP's resource prefix rule (`d11_bag_t1` → `d11_bags_t1`,
  `paperbag` → `d11_bags_paper`). With the server stopped, run `sql/upgrade-1.x-to-2.0.sql` once. A fresh install does
  not need it.
- Bags follow WHIP's weight rules: the bag weighs 1 / 1.5 / 2 kg plus its contents, with an inside limit of
  15 / 25 / 40 kg and 15 / 20 / 25 slots; the paper bag has 5 slots, 1 kg. Edit `d11_bags/config.lua`.

## License

The resources are MIT (see `LICENSE`). The files in `whip_core-patches/` change whip_core and are under
whip_core's own license (LGPL-3.0).

## Credits

- Fonts in `d11_inventory/fonts` and `d11_ptrunk/html/fonts`: Quantico (Andrea Herstowski) and Geist (Vercel), both under the SIL Open Font License.
- The physical trunk is a port of the D12 `velocity-physicaltrunk`, by the same authors; its vehicle profiles were calibrated on D12 and District 11.
- Built on WHIP by Whippy and the WHIP contributors.
