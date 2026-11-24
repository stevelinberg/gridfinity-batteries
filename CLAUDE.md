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

### Bin geometry (upright cells, `src/battery_bin.scad`)
Lite gridfinity base (hollow feet), then a 1.2 mm floor plate bridging the
feet, then an outer wall, a thin tube around each cell, and tie ribs through
each row and column. A hollow label strip at the front has a 1.6 mm deck
that carries the text. Height = base 7 + floor + `hold` × cell length (0.5,
so cells stand half exposed). There's no stacking lip yet: the cells stick
up, so nothing can stack on these anyway (open question below).

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

- Repo scaffolded; submodule pinned at upstream `910e22d` (2025-08-31).
- AA **measured**: d 14.35, l 50.32 (largest of Steve's cells, mostly
  NiMH). Other cells are still nominal placeholders.
- Steve: **no magnets** (no baseplates yet), 0.4 nozzle, 0.2 layers.
- **`aa_fit` printed** (Futura labels, 3MF import worked). All four holes
  fit, and **0.3 mm was fine**, so `BIN_DEFAULTS.clearance` is now 0.3.
  The labels (5 / 3.5 mm Futura Bold, 0.6 raised) printed legibly.
- Bambu still printed a tiny (~1 mm) purge/prime tower even though Steve
  thought he'd turned it off. Not yet diagnosed. Once his Bambu project 3MF
  is committed in `bambu/`, check `Metadata/project_settings.config`
  (`enable_prime_tower`, filament per object, layer of first color change).

### AA capacity (clearance 0.3, rib/wall 1.2 → pitch 15.85)
"Slim strip" = 2 square rows plus a ~6.2 mm label strip (fits 5 mm text).
"Staggered" = hex-offset rows; needs the `pack` feature (not built yet).

| grid | square, slim strip | staggered + label strip |
|------|------|------|
| 2x1 | 10 (5x2) | 9 (5/4), 8.3 mm strip |
| 3x1 | 14 (7x2) | 14 (7/7), 8.3 mm strip |
| 4x1 | 20 (10x2) | 19 (10/9) |
| 2x2 | 20 (5x4), 16 mm strip | **23** (5/4/5/4/5), 9 mm strip |

Steve wants 12–24 AAs. Waiting on his bin-size choice.

## Next steps

1. Steve picks the AA bin size and wall/rib thickness (1.2 felt fine, or
   try 0.8?). Build it (implement `pack="hex"` if he picks 2x2), and
   preview it.
2. Diagnose the purge tower from his saved Bambu 3MF.
3. AAA (needs caliper numbers), then the rest of the list above.
4. Open question: stacking lip on/off.
5. Set up GitHub Releases upload for rendered STLs.
6. Later: write the project note in Spellbook.
