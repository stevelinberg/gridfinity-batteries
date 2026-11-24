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
- `aa_fit` fit-test bin built: 2x1, one row of 4 AA holes with
  **clearance ladder 0.3 / 0.5 / 0.7 / 0.9 mm** (diametral), labeled. Renders
  clean (manifold). Body ≈ 27 cm³ ≈ 34 g PLA if printed 100% solid; real
  use should be lower.
- **Cell dimensions are nominal IEC values, not measured yet.** Waiting on
  Steve's caliper numbers (asked 2026-11-24).
- Bambu Studio hasn't been tested on the two-object 3MF yet.

## Next steps

1. Get caliper measurements (AA first), update `CELLS`, rebuild `aa_fit`,
   show the preview, then Steve prints it.
2. From the fit test: choose the default clearance; check label legibility
   (5 mm / 3.5 mm DejaVu Bold, 0.6 mm raised); check that the 3MF imports
   as body + text in Bambu Studio.
3. Real AA bin (size TBD with Steve), then AAA, then the others in the
   list above.
4. Open questions: stacking lip on/off per bin; magnets (Steve's
   baseplates?); thinner walls/ribs (0.8 mm?) to save more filament.
5. Set up GitHub Releases upload for rendered STLs.
6. Later: write the project note in Spellbook.
