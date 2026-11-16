# D11 Inventory for WHIP

The inventory we run on District 11 (D11), built on [WHIP](https://github.com/WHIPFX/whip_core)'s own inventory
core. The renderer only draws: state, weights, rules and the server stay whip_core's, and every gesture goes through
`api.actions` (whip_core `docs/nui-inventory.md`). Built and tested on whip_core 1.0.1; the patches below also
apply cleanly to whip_core 1.1.0.

> **English and Brazilian Portuguese.** One line in server.cfg picks the language of every D11 resource:
> `setr d11_locale en` (the default) or `setr d11_locale pt-BR`. See **Language** below.

## What's inside

`[d11-inventory]/`: drop this folder into your `resources/`.

| Resource | What it does |
| --- | --- |
| `d11_inventory` | Our inventory look as a WHIP renderer: a character card (name, account, cash, items, load), an "Equipped" section for the accessory strip, pockets and open bags as tabs, quick-access slots, a "Nearby" ground panel, glovebox / boot / stash / ignition, full gamepad support. **Drag an item onto your character** (the real one, in the world: it gets an outline in the theme colour) to use or equip it. **Drag an item out of the window** to drop it from your hand: on foot you put it down, in a vehicle you wind the window down and toss it out (while moving too), and it falls with physics where it lands. |
| `d11_bags` | Backpacks (`d11_bag_t1`, `d11_bag_t2`, `d11_bag_t3`) and a paper bag (`paperbag`) as inventory panels: open them from your pockets or straight from the ground, close a tab with its x, the bag being filled is highlighted. Bags are inventory only: they are not drawn on the player (`prop` is the model on the ground). |
| `d11_attachments` | Weapon attachments in your hands: right-click a whip_gunny weapon, **Acessórios** (Attachments), and the character raises it in an inspect pose with a marker per mount point (sight, muzzle, barrel, grip, flashlight). Attach / remove from what you carry, no workbench needed. Same `metadata.attachments` as gunny's bench. |

`whip_core-patches/`: **all optional**, everything works without them. whip_core is installed as is, so our changes to it ship as patches.

| Patch | Needed for |
| --- | --- |
| `whip_core-ground-panel-d11.patch` | Optional. Opens a bag lying on the ground in place. Without it, **Open** on a bag on the ground picks it up into your pockets and opens it there (d11_inventory finds out by itself). |
| `whip_core-inventory-drag-gestures-upstream.patch` | Optional. Our PR to WHIP ([WHIPFX/whip_core#65](https://github.com/WHIPFX/whip_core/pull/65)): drag onto your character / drag out to drop in whip's **own** inventory, plus "a drop from a vehicle lands beside your door". Skip it once the PR is merged. `d11_inventory` works without it. |
| `whip_core-inventory-noblur-d11.patch` | Optional: no screen blur when the inventory opens. |
| `whip_core-inventory-drive-d11.patch` | Optional, apply after noblur: walk (WASD + Shift) and drive (WASD + Space) with the inventory open, keyboard only. Mouse look with `setr whip_inventory_drive_look 1`. |

From your `resources/` folder (these patch paths start with `whip_core/`):

```
patch -p1 < whip_core-ground-panel-d11.patch
patch -p1 < whip_core-inventory-noblur-d11.patch
patch -p1 < whip_core-inventory-drive-d11.patch
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

## Language

```cfg
setr d11_locale en      # or pt-BR
```

English is the default. The inventory's texts are in `d11_inventory/locales.js` (the Portuguese text is the key, so a
new language is one more map there); d11_bags and d11_attachments keep theirs in their `config.lua` (`L(english,
portuguese)`). Item names that come from WHIP itself follow WHIP's own language.

## Requirements

- whip_core 1.0.1 or newer.
- whip_gunny, for d11_attachments.
- Optional: `whip_theme_d12`, our WHIP theme. d11_attachments reads its tokens and falls back to the same colours without it.

## server.cfg

After the `ensure whip_*` lines:

```cfg
setr d11_locale en
ensure d11_inventory
setr whip_inventory_renderer d11_inventory
ensure d11_bags
ensure d11_attachments
```

Restart whip_core after applying a patch. To try the renderer without the cfg line: developer mode (`/w`), then
`/whip_inventory_ui d11_inventory` (`/whip_inventory_ui none` goes back to whip's own).

## Notes

- The **Crafting** button in the inventory opens our `d11_craft` (not released yet); without it the button does nothing.
- Bags follow WHIP's weight rules: the bag weighs 1 / 1.5 / 2 kg plus its contents, with an inside limit of
  15 / 25 / 40 kg and 15 / 20 / 25 slots; the paper bag has 5 slots, 1 kg. Edit `d11_bags/config.lua`.

## License

The resources are MIT (see `LICENSE`). The files in `whip_core-patches/` change whip_core and are under
whip_core's own license (LGPL-3.0).

## Credits

- Fonts in `d11_inventory/fonts`: Quantico (Andrea Herstowski) and Geist (Vercel), both under the SIL Open Font License.
- Built on WHIP by Whippy and the WHIP contributors.
