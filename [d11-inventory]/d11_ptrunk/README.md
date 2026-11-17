# d11_ptrunk: physical trunk for WHIP

The boot of a car, seen from behind it: every item in the trunk is a prop with physics that you move with the mouse,
inside the WHIP inventory (`d11_inventory` renderer, in "trunk mode"). It is a port of the D12 `velocity-physicaltrunk`
to WHIP, rebuilt on WHIP's own stores, prompts and panels.

## What it does

- **Opening:** the boot's own "View trunk" prompt opens the physical mode. The lid opens only once the props are in
  place.
- **Camera:** an orbit camera fixed to the boot. Right drag turns it, the wheel zooms, middle drag moves the focus, and
  the Camera button resets the view.
- **Trunk header:** Light, Grid, Highlights, Gizmo and Hide HUD (fades the inventory panels to almost nothing), plus a
  shortcut sheet.
- **Props with physics:**
  - settling, stacking and toppling, with the D12 engine;
  - auto-packing for items with no saved pose, and a saved pose per item;
  - a model per item (D12 propbrowser, WHIP catalogue, `Config.ItemModels`) and per stack size
    (`Config.ItemModelsByAmount`).
- **Ground:**
  - items on the ground are physics objects too: drag them with the inventory open, raise them (R/F), turn them on
    any axis (Q/E, Shift and Ctrl), stack them;
  - drop anywhere near the car.
- **Bags and boxes** (`d11_bags`): open them inside the trunk, and drag between the trunk, bags, the ground and your
  pockets.
- **Calibration wizard:** camera, then pivot and area, then light, per vehicle model, stored in the database and
  applied at once for everybody.
- **Fallback:** a car with no calibrated area opens WHIP's plain trunk list, as if this resource was not there.

## Switches

`D11Inventory_World` in `d11_inventory/config.lua` (on by default, each one on its own): `Trunk` (false: "View trunk"
opens WHIP's plain trunk list), `Ground` (false: ground items stay WHIP's own, dropping still works) and `Camera` (the
orbit camera around you with the inventory open). d11_inventory hands them over when it starts, so it starts first.

## Vehicle profiles: a shared starter pack

A car gets the physical trunk when its **area** (where items can sit) is calibrated. The package ships the profiles
calibrated on District 11 and D12, one block per car, by model name, in `data/profiles/`:

| File | Cars with an area | Loaded |
| --- | --- | --- |
| `base.lua` | 121 GTA V cars, plus the per-class defaults | always |
| `onx.lua` | 63 ONX cars (onx-cvp / onx-evp) | always (addon models: harmless without the pack) |
| `nopixel.lua` | 21 NoPixel 4 cars (7 addons, 14 that replace base cars) | only with a resource named `*nopixel*` running |

The NoPixel file is gated because those 14 cars replace base models with a different boot. Every other car opens the
plain trunk until someone calibrates it.

```lua
-- data/profiles/base.lua
adder = {
    spawn  = { x = 0.0, y = 1.759, z = -0.064, areaPoints = { ... } },  -- the area: required
    camera = { access = 'front', triggerRadius = 2.35, ... },           -- optional (else the class default)
    light  = { spots = { ... } },                                        -- optional (else no boot light)
},
```

**Per vehicle, everything is yours to tune.** Priority, highest first:

1. what the wizard saved in the database (`d11_ptrunk_profiles`);
2. the files in `Config.ProfilePacks`, the last one winning;
3. the class defaults (`class` in `base.lua`).

Your own cars: calibrate them in game with `/ptrunkwizard start`, then `/ptrunkexport` writes everything the database
holds to `export/profiles_<date>.lua` in this same format. Drop it in as a pack of your own:

```lua
Config.ProfilePacks = {
    { file = 'data/profiles/base.lua' },
    { file = 'data/profiles/onx.lua' },
    { file = 'data/profiles/nopixel.lua', resource = 'nopixel' },
    { file = 'data/profiles/my_server.lua' },   -- yours
}
```

Calibrated a car the pack lacks? Send the exported block back to the repository so the starter pack grows for
everybody.

## Requirements

- `whip_core` 1.2.0 with the patches in `whip_core-patches/` (top of this package):

  | Patch | What it adds | Without it |
  | --- | --- | --- |
  | `whip_core-trunk-opener-d11` | "View trunk" opens the physical mode; the lid waits for the props | **required** |
  | `whip_core-ground-physics-d11` | `HoldGroundProp`, `MoveGroundItem` | **required** |
  | `whip_core-item-prop-resolver-d11` | ground and hand use this resource's models | catalogue props |
  | `whip_core-item-prop-amount-d11` | the ground model follows the stack size | one model per item |
  | `whip_core-store-panel-d11` | bags and boxes open inside a trunk or stash | they open in the pockets |

- The `d11_inventory` renderer (trunk mode, ground drag) and `oxmysql`.
- Optional: `d11_bags` (bags and boxes).

## Install

```cfg
ensure d11_ptrunk
setr whip_trunk_opener d11_ptrunk
setr whip_item_prop_resolver d11_ptrunk
```

The tables `d11_ptrunk_pose` and `d11_ptrunk_profiles` are created on start. Run `/ptrunkpreflight` from the server
console to check resources, convars, patches, tables and profiles.

## Commands

Admin only, with the `whip.devtools` ACE (`Config.AdminAce`):

| Command | What it does |
| --- | --- |
| `/ptrunkwizard start` | Calibrate the nearest car: camera → pivot and area → light → confirm |
| `/ptrunkwizard auto` | Auto preset |
| `/ptrunkwizard load` | Copy another model's profile (also `/ptrunkwizardload <model>`) |
| `/ptrunkinfo` | Show the nearest car's profile |
| `/ptrunkpreflight` | Installation check (server console) |
| `/ptrunkphysics on\|off` | Turn physics on or off for everybody |
| `/ptrunkrepack` | Clear the saved poses of the open trunk |
| `/ptrunkexport [model ...]` | Write the database profiles to `export/` (names come from the packs, or pass them) |

Anyone can run these; they only print local state:

| Command | What it does |
| --- | --- |
| `/ptrunkprops` | Diagnostics of the open trunk's props |
| `/ptrunkmodels` | Which mapped models are missing from the game |

## License

MIT, see `LICENSE`. The fonts in `html/fonts` (Quantico, Geist) are under the SIL Open Font License.
