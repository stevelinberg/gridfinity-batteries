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
fonts/DejaVuSans-Bold.ttf bundled so text renders the same on every machine
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
  NiMH). In `CELLS`. Other cells are still nominal placeholders.
- Steve: **no magnets** (no baseplates yet), 0.4 nozzle, 0.2 layers.
- `aa_fit` rebuilt with real dims: 2x1, 4 holes, clearance ladder
  0.3/0.5/0.7/0.9, labeled. Preview approved for printing; waiting on
  Steve's print result.
- Bambu Studio hasn't been tested on the two-object 3MF yet.

### AA capacity estimates (clearance 0.5, rib/wall 1.2, pitch 16.05)
Label strip at the front. "Stagger" = hex-offset second row; 1-wide bins
leave room for a ~6–8 mm label strip only with 2 rows.

| grid | square (strip ≥9) | 2 rows square, slim strip ~5.8 | staggered rows + ~8 mm strip |
|------|------|------|------|
| 1x1 | 2 | 4 | 3 |
| 2x1 | 4 | 8 | 8 (4/4) |
| 3x1 | 7 | 14 | 14 (7/7) |
| 4x1 | 10 | 20 | 19 (10/9) |
| 2x2 | 16 | 16 | 20 (5 rows of 4) |

Steve wants 12–24 AAs. Leading options: one 3x1 (14), two 3x1 (28),
or one 2x2 (20). Pending Steve's choice.

## Next steps

1. Steve prints `aa_fit` and reports which clearance feels right. Then set
   `BIN_DEFAULTS.clearance`; check label legibility (5 / 3.5 mm DejaVu Bold,
   0.6 mm raised) and how the 3MF imports in Bambu Studio.
2. Implement staggered (hex) packing in `battery_bin.scad` (`pack` key),
   and the real AA bin at the size Steve picks.
3. AAA (needs caliper numbers), then the rest of the list above.
4. Open questions: stacking lip on/off; thinner walls/ribs (0.8 mm?).
5. Set up GitHub Releases upload for rendered STLs.
6. Later: write the project note in Spellbook.
