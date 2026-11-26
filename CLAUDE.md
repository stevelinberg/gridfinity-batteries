# CLAUDE.md — gridfinity-batteries

**Session ritual:** read this file first. Before a session ends, update
*Status* and *Next steps*, then commit and push, so any future session on
any device can pick up from here.

## Goal

Custom Gridfinity battery storage bins in OpenSCAD, printed on Steve's
Bambu A1 and P2S (AMS 2). This repo is the workshop. A project note goes
into the Obsidian vault "Spellbook" (repo `stevelinberg/spellbook`) later;
it hasn't been written yet.

## Decisions (made by Steve; don't relitigate)

- **OpenSCAD**, building on **gridfinity-rebuilt-openscad** for base
  geometry (correct profile, stacking lip, optional magnets, "lite"
  hollow base).
- **Parametric:** one data table (`src/batteries.scad`) of cell dimensions
  and bin layouts; each bin is a short entry. Clearance is a parameter.
- **One separately printable bin per battery type**, no mega-bin. Planned:
  - AA (alkaline + NiMH; holes sized to the largest cell measured)
  - AAA (same), AAAA, 9V/6LR61, A23
  - coin cells and button cells: **loose in lidded boxes** (changed
    2026-11-25: slots and pockets were too loose and cells rolled around).
    Hinged, snap-shut, see-through hex-mesh lid, so they can be carried
    without spilling and you can see when one is empty.
  - "Weirdos": same lidded box, for odd loose cells with no bin of their own
  - Sony NP-BX1 camera batteries
  - loose "to recharge" bin with a scoop front
  - later: cradles for battery testers and chargers
- **Save filament:** short bins with cells half-exposed for grabbing; thin
  ribs and floor instead of solid blocks; lite base; hex cutouts in walls
  only where they really save material (taller bins).
- **White bins, raised black text on the top face.** Body and text are
  exported as **separate objects** (two STLs and a two-object 3MF) so Bambu
  Studio can assign black with one click. Text sits on the topmost layers,
  so there's only one color change, and Steve prints with the prime tower off.
  → Nothing in the body may rise above the label's top surface.
- **Repo layout:** SCAD source + data table + build script that renders
  all STLs and PNG previews. Rendered STLs go to **GitHub Releases**, not
  git. Steve's saved **Bambu Studio project 3MFs** (one per bin, after a
  good print) **are committed**, under `bambu/`.

## Layout

```
bin.scad                  entry point: -D bin_id=... -D part=body|text|both
build.py                  renders all bins -> build/<id>/ (gitignored)
src/batteries.scad        THE data table: BIN_DEFAULTS, CELLS, BINS
src/battery_bin.scad      geometry for upright-cell bins
src/util.scad             key/value table helpers
fonts/Jost-Bold.ttf       OFL Futura look-alike, fallback when Futura is absent
lib/gridfinity-rebuilt-openscad   git submodule (pinned commit)
bambu/                    saved Bambu Studio project 3MFs (committed)
```

Clone with `git clone --recurse-submodules`, or run
`git submodule update --init` afterward.

### Why a submodule, not vendored
Upstream is MIT-licensed and actively maintained. A submodule pins an exact
commit (reproducible), keeps our history free of ~100 upstream files, makes
updates a deliberate `git -C lib/... checkout <tag>` + commit, and keeps
attribution obvious. The cost is the `--recurse-submodules` clone step.
We use only its public-ish modules (`gridfinity_base_lite`,
`gridfinityBase`, `bundle_hole_options`, `rounded_square`, constants), so
an upgrade that breaks the build shows up right away.

### Bin geometry (`src/battery_bin.scad`)
**cells bins** (default): pockets laid out in **column groups**
(`groups` = list of `[cell, cols, rows, label, clearance]`, placed left
to right; `cell/cols/rows` shorthand for uniform bins). A cell is
`round` (d) or `rect` (fp = [x, y] as placed), standing `l` tall. An
upright AA, a coin on edge (fp [d, thickness], l = d) and a flat button
cell (d, l = thickness) are all just cells. Each pocket is `hold × l`
deep. The bin top sits at the deepest pocket, and shallower pockets have
solid plugs under them. Structure: lite gridfinity base (hollow feet),
then a 1.2 mm floor plate bridging the feet, then a 1.2 mm outer wall, a
0.8 mm tube around each pocket, and tie ribs (front-to-back per column,
across per row within its group). A hollow label strip at the front has a
1.6 mm deck carrying the group labels and/or the main label.
**scoop bins** (`type: "scoop"`): open tray, quarter-round scoop at the
front, 10 mm label ledge at the back with a 45° underside, and a
hand-drawn battery+bolt icon (`icon_recharge`).
**lidbox bins** (`type: "lidbox"`): compartments (`compartments` =
`[[label, width weight], ...]`) behind a solid 8 mm label strip. The
**scoop rises the full inside depth** (r = `depth`, 15), tangent to the
floor and to the strip face at the lid's underside. **No ledges or lips
around the inside** (2026-11-26: Steve found the old ledge caught cells
being scooped out). The lid's front edge rests in a 2 mm **rebate** along
the back of the strip. Side rails have a 45° underside, and dividers rise
to the lid. The lid is inset and flush with the rim (3.2 mm, 3 mm hex
mesh, 1 mm walls), with a rounded back edge and two Ø2 side pins that
snap down through 1.8 mm keyhole throats (each jaw has a relief slit), so
the hinge lifts off and opens to vertical. A **pull tab stands up** at the
front edge (16 × 1.6 × 3 mm), over the finger dip at the first divider (or
the right end). Steve found the old tuck-in latch tab worked better as a
pull tab and blocked the finger hole. Holding it shut: two **side detent
bumps** (r 0.8, 0.5 proud, 0.25 interference) click into dimples in the
rails. Checked in OpenSCAD: closed, there's no overlap. Opening, only the
detents touch (≈0.2 mm³ at 1.5–3°), then it's clear at 10/30/60/90°. The
lid is a separate white part printed **right side up** (`-lid.stl`, third
3MF object), 6.2 mm tall, so the box text is still the last thing printed.
Previews include `<id>-closed.png`.
No stacking lip: the cells stick up, so nothing can stack anyway.

## Label font

Steve chose **Futura** (`FONT_PREFS` in `src/batteries.scad`, default
`Futura:style=Bold`). Futura comes with macOS under Apple's license, so it
**must not be committed**. When Futura is missing (cloud/Linux), the text
falls back to bundled **Jost Bold**, an OFL Futura look-alike: a static
wght=700 instance cut from Google Fonts' `Jost[wght].ttf`.
OpenSCAD silently substitutes missing fonts, so `pick_font()` checks the
resolved family through `fontmetrics()`. The build log prints
`BIN <id>: font ...`.
**Release/print STLs should be rendered on Steve's Mac**, so the text is
real Futura. Cloud renders are previews only. Other macOS Futura styles:
Medium, Condensed Medium, Condensed ExtraBold. Override for one build with
`-D 'FONT_PREFS=["Futura:style=Medium"]'`.

## Toolchain

- Needs an **OpenSCAD development snapshot** (2025+, Manifold backend).
  The 2021.01 release (Ubuntu apt) can't parse gridfinity-rebuilt.
  On a Mac: install a snapshot from openscad.org/downloads#snapshots.
- Cloud sessions: files.openscad.org and GitHub release downloads are
  blocked by the proxy. What works is `dockerd &` then
  `docker pull openscad/openscad:dev`, plus a wrapper at
  `/usr/local/bin/openscad` that runs
  `docker run --rm -v /home/user:/home/user -w "$PWD" openscad/openscad:dev openscad "$@"`.
- Previews: `./build.py` (PNG via `--render`, colors honored).
- 3MF: `--enable=lazy-union` gives separate objects (body white, text
  black, lid). **Gotcha:** lazy-union also stops `for()` from unioning
  its children, so `intersection() { A; for (...) ... }` intersects
  every iteration and comes out empty. Always wrap such loops in an
  explicit `union()`. This bit the lid mesh (2026-11-25): the 3MF lid
  was solid while the STL was fine. Check by comparing per-object
  volumes in the 3MF vs the STLs (trimesh).

## Status (2026-11-24)

- Submodule pinned at upstream `910e22d`.
- All of Steve's current cells are **measured** (see `CELLS`).
- Steve: **no magnets**, 0.4 nozzle, 0.2 layers, prints on the P2S.
- `aa_fit` printed fine with Futura labels. **Clearance 0.3** is the
  default. Coins and buttons use 0.5 / 0.4 in their groups (narrow slots
  and small pockets print tight). These are untested.
- Steve chose **0.8 mm tubes/ribs**, keeping the **1.2 mm outer wall**.
  These are now the defaults; `aa_fit` keeps 1.2.
- Purge-tower stub: `bambu/aa_fit.3mf` has prime tower off, but defines
  `wrapping_exclude_area` 153–216 × 235–256 (back centre), exactly where
  the stub printed. So it's the printer's start routine (clumping/wrap
  detection pad), not the model. Closed.
- Git: Steve now pushes over SSH, which works.
- **Designed, not yet printed** (batch planned; ~248 cm³ mesh volume ≈
  ≤ 310 g PLA for the whole batch):

| bin | grid | holds | notes |
|---|---|---|---|
| `aa` ×2 | 2x1 | 10 AA each | 5x2; back row `raise` 10 (15 mm held) for pinching |
| `aaa` | 2x1 | 18 AAA | 3 staggered rows of 6; middle row `raise` 8 |
| `9v` ×2 | 2x1 | 4 9V each | upright, snaps up |
| `npbx1` | 2x1 | 6 NP-BX1 | upright, +2.8 mm finger spacing |
| `coin` | 2x1 lidbox | CR2032 \| CR2016 compartments | 15 mm deep, hex-mesh snap lid. Replaces the slot design |
| `button` | 2x1 lidbox | AG13/LR44 (⅔) \| AG3 (⅓) | same. Replaces the slot design |
| `weirdos` | 2x1 lidbox | one compartment | odd loose cells |
| `recharge` | 2x2 | loose | scoop tray, "Recharge" + icon; scoop r 22 (was 16) |

## Next steps

1. Lidboxes (`coin`, `button`, `weirdos`): Steve printed `weirdos` and
   `coin` (lid mesh OK after the lazy-union fix). 2026-11-26 fixes: pull
   tab up (was a latch tab under the lid), side detents instead, no inside
   ledges, full-depth scoop, rebate front support, bigger Recharge scoop.
   Next: reprint one and tune DET_OUT (detent click) and PIN_THROAT if
   needed.
2. `aa` ×2 + `aaa`: ready to print (raised rows, 0.8 tubes). Then 9V,
   NP-BX1, Recharge. Get feedback on pinch grip and tube stiffness.
3. Steve commits a Bambu project 3MF per bin under `bambu/`.
4. Layout options in place: `stagger`, `raise`, `space`, `notch`
   (unused), `channel` (unused now). No CR1620 bin (Steve has just one).
   Still to do: AAAA, A23.
5. Later: charger/tester cradles; GitHub Releases upload; Spellbook note.
