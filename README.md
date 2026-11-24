# gridfinity-batteries

My own Gridfinity battery-storage system, in OpenSCAD and built by Claude (sigh).

One bin per battery type, all generated from one data table
(`src/batteries.scad`). The base geometry comes from
[gridfinity-rebuilt-openscad](https://github.com/kennetek/gridfinity-rebuilt-openscad)
(MIT), included as a git submodule.

```bash
git clone --recurse-submodules https://github.com/stevelinberg/gridfinity-batteries.git
```

```bash
./build.py            # renders every bin into build/<id>/: body STL, text STL, two-object 3MF, PNG
```

Needs an OpenSCAD development snapshot (2025+); the 2021.01 release is too old.
Printing: white body, black text (separate objects); the text sits on the top
layers, so there's only one color change and no prime tower is needed.

Rendered STLs are published under GitHub Releases. Project notes for future
work are in `CLAUDE.md`.

Labels use Futura Bold when it's installed (it ships with macOS; not included here).
Otherwise they fall back to the bundled Jost Bold, an open Futura look-alike
(`fonts/Jost-OFL.txt`). Change the order in `FONT_PREFS` in `src/batteries.scad`.
