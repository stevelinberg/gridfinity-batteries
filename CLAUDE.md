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
- AA **measured**: d 14.35, l 50.32. Other cells still nominal.
- Steve: **no magnets**, 0.4 nozzle, 0.2 layers, prints on the P2S.
- `aa_fit` printed fine with Futura labels. **Clearance 0.3** chosen and
  set as the default.
- Purge tower mystery: Bambu's slice preview shows **no** tower, and
  prime tower is off in the project. The ~1 mm stub on the plate is most
  likely the printer's start routine (purge/flow calibration), not the
  model. Low priority.
- Steve's Bambu project for `aa_fit` is committed locally on his Mac, but
  the push failed: the clone used an HTTPS remote. Fix: switch the remote
  to SSH (`git@github.com:...`), then `git pull --rebase`.
- **New bins (previews made, not printed):**
  - `aa`: 2x1, 2 rows of 5 (10 cells), 6 mm label strip. Steve will
    print **two** of them.
  - `aaa`: 2x1, 2 rows of 6. **Nominal dims**, waiting on calipers.
  - `recharge`: 2x1 open tray (`type: "scoop"`), scoop fillet at the
    front, 10 mm label ledge at the back with a 45° underside, raised
    "Recharge" text and a hand-drawn battery+bolt icon (`icon_recharge`).
- Wall/rib study (mesh volume): `aa` 32.2 cm³ at 1.2/1.2 vs 24.9 cm³ at
  0.8/0.8 (−23%, ~9 g). `recharge`: 25.5 → 23.2 cm³ (small saving). Steve
  says 1.2 feels sturdy but flexes slightly. Waiting on his decision.

## Next steps

1. Steve's answers: 0.8 ribs (keep 1.2 outer wall?); AAA measurements;
   9V and button-cell measurements and counts.
2. Build `9v` (rectangular pockets: add `shape: "rect"`) and the button
   cell bin (shallow pockets, labeled rows), then a batch print:
   2× aa, aaa, recharge, 9v, buttons.
3. Then: AAAA, A23, coin cells (vertical slots), NP-BX1.
4. Open question: stacking lip on/off.
5. Set up GitHub Releases upload for rendered STLs.
6. Later: write the project note in Spellbook.
