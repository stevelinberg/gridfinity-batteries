#!/usr/bin/env python3
"""Render every bin in src/batteries.scad (or the ones named) to build/.

For each bin id:
    build/<id>/<id>-body.stl   white body
    build/<id>/<id>-text.stl   black raised text
    build/<id>/<id>-lid.stl    lid, upside down for printing (lidded boxes)
    build/<id>/<id>.3mf        all parts as separate objects (lazy-union)
    build/<id>/<id>.png        colored preview
    build/<id>/<id>-closed.png lidded boxes: preview with the lid shut

Usage:
    ./build.py                 # all bins
    ./build.py aa_fit          # just these
    ./build.py --no-png        # skip previews
    OPENSCAD=/path/to/openscad ./build.py   # only if auto-detect fails

Finds OpenSCAD on PATH or as /Applications/OpenSCAD*.app (newest wins).
Needs an OpenSCAD development snapshot (2025+, Manifold backend);
the 2021.01 release cannot parse gridfinity-rebuilt-openscad.
"""
import argparse
import glob
import shutil
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ENTRY = ROOT / "bin.scad"
OUT = ROOT / "build"


def find_openscad():
    """$OPENSCAD, else `openscad` on PATH, else the newest OpenSCAD*.app
    in /Applications or ~/Applications (macOS)."""
    if os.environ.get("OPENSCAD"):
        return os.environ["OPENSCAD"]
    if shutil.which("openscad"):
        return "openscad"
    apps = []
    for d in ("/Applications", os.path.expanduser("~/Applications")):
        apps += glob.glob(os.path.join(d, "OpenSCAD*.app/Contents/MacOS/OpenSCAD"))
    if apps:
        return max(apps, key=os.path.getmtime)
    sys.exit("OpenSCAD not found. Install a development snapshot, or set\n"
             "OPENSCAD=/path/to/openscad")


OPENSCAD = find_openscad()
_seen = set()

# camera: translate x,y,z, rotate x,y,z, distance
PREVIEW = ["--render", "--imgsize=1600,1200", "--colorscheme=Tomorrow",
           "--projection=p", "--autocenter", "--viewall",
           "--camera=0,0,0,58,0,25,0"]


def scad(*args, defines=None):
    cmd = [OPENSCAD, "--backend=manifold"]
    for k, v in (defines or {}).items():
        cmd += ["-D", f"{k}={v}"]
    cmd += list(args) + [str(ENTRY)]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT)
    log = r.stdout + r.stderr
    if r.returncode != 0 or "ERROR" in log:
        sys.exit(f"openscad failed: {' '.join(cmd)}\n{log}")
    for line in log.splitlines():
        if line.startswith(("ECHO: \"BIN", "WARNING")) and line not in _seen:
            _seen.add(line)
            print("   ", line)
    return log


def bin_ids():
    log = scad("-o", "-", "--export-format=echo",
               defines={"list_bins": "true"})
    ids = {}
    for key in ("BIN_IDS", "LID_IDS"):
        m = re.search(key + r'=\[(.*?)\]', log)
        ids[key] = re.findall(r'"([^"]+)"', m.group(1)) if m else []
    return ids["BIN_IDS"], set(ids["LID_IDS"])


def build(bin_id, has_lid=False, png=True):
    d = OUT / bin_id
    d.mkdir(parents=True, exist_ok=True)
    q = lambda s: f'"{s}"'
    print(f"== {bin_id}")
    for part in ("body", "text") + (("lid",) if has_lid else ()):
        scad("--export-format=binstl", "-o", str(d / f"{bin_id}-{part}.stl"),
             defines={"bin_id": q(bin_id), "part": q(part)})
    # No colors in the 3MF: per-triangle colors import into Bambu Studio
    # as color *painting*, which overrides the filament you assign to an
    # object (and breaks multi-file plates). Assign filaments in Bambu.
    scad("--enable=lazy-union", "-O", "export-3mf/color-mode=none",
         "-o", str(d / f"{bin_id}.3mf"),
         defines={"bin_id": q(bin_id), "part": q("both")})
    if png:
        scad(*PREVIEW, "-o", str(d / f"{bin_id}.png"),
             defines={"bin_id": q(bin_id), "part": q("both")})
        if has_lid:
            scad(*PREVIEW, "-o", str(d / f"{bin_id}-closed.png"),
                 defines={"bin_id": q(bin_id), "part": q("closed")})


def main():
    print(f"using {OPENSCAD}")
    ap = argparse.ArgumentParser()
    ap.add_argument("bins", nargs="*")
    ap.add_argument("--no-png", action="store_true")
    a = ap.parse_args()
    known, lids = bin_ids()
    for b in a.bins:
        if b not in known:
            sys.exit(f"unknown bin '{b}'; known: {', '.join(known)}")
    for b in a.bins or known:
        build(b, has_lid=b in lids, png=not a.no_png)


if __name__ == "__main__":
    main()
