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
  - coin cells CR2032, CR2016, CR1620 (vertical slots)
  - button cells LR44, LR41, SR936/394 (shallow pockets; maybe one shared
    bin with labeled rows)
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
- 3MF: `--enable=lazy-union` gives two objects (body white, text black).

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
| `aa` ×2 | 2x1 | 10 AA each | 5x2 |
| `aaa` | 2x1 | 18 AAA | 3 staggered rows of 6 |
| `9v` ×2 | 2x1 | 4 9V each | upright, snaps up |
| `npbx1` | 2x1 | 6 NP-BX1 | upright, +2.8 mm finger spacing |
| `coin` | 2x1 | 14 CR2032 + 10 CR2016 | slots on edge; alternate slots 13 / 5 mm deep (`raise` 8) so every coin can be pinched |
| `button` | 2x2 | 24 AG13/LR44 + 18 AG3 | flat, staggered, 70 % deep |
| `recharge` | 2x2 | loose | scoop tray, "Recharge" + icon |

## Next steps

1. Steve renders on his Mac (Futura) and prints the batch. Then get
   feedback: coin-slot and button-pocket fit, whether flat buttons can be
   picked out (may need a fingernail notch), 0.8 tube stiffness.
2. Steve commits a Bambu project 3MF per bin under `bambu/`.
3. Layout options now in place: `stagger`, `raise`, `space` (bin-level
   keys, see `BIN_DEFAULTS`). CR1620: Steve has only one, so no bin for
   now. Still to do: AAAA, A23.
4. Later: charger/tester cradles; GitHub Releases upload; Spellbook note.
