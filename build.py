#!/usr/bin/env python3
"""Render every bin in src/batteries.scad (or the ones named) to build/.

For each bin id:
    build/<id>/<id>-body.stl   white body
    build/<id>/<id>-text.stl   black raised text
    build/<id>/<id>-lid.stl    lid, upside down for printing (lidded boxes)
    build/<id>/<id>.3mf        Bambu Studio 3MF: the bin as ONE object with
                               "body" (filament 1) and "text" (filament 2)
                               parts, plus the lid as a second object
    build/<id>/<id>.png        colored preview
    build/<id>/<id>-closed.png lidded boxes: preview with the lid shut

Usage:
    ./build.py                 # all bins
    ./build.py aa_fit          # just these
    ./build.py --no-png        # skip previews
    TEXT_FILAMENT=6 ./build.py # text on filament 6 (default 2; body 1)
    OPENSCAD=/path/to/openscad ./build.py   # only if auto-detect fails

Finds OpenSCAD on PATH or as /Applications/OpenSCAD*.app (newest wins).
Needs an OpenSCAD development snapshot (2025+, Manifold backend);
the 2021.01 release cannot parse gridfinity-rebuilt-openscad.
"""
import argparse
import struct
import uuid
import zipfile
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
# Filament slots in Bambu Studio's list (1-based). Override per run:
#   TEXT_FILAMENT=6 ./build.py
BODY_FILAMENT = int(os.environ.get("BODY_FILAMENT", "1"))
TEXT_FILAMENT = int(os.environ.get("TEXT_FILAMENT", "2"))
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


# ---------------------------------------------------------------------------
# Bambu Studio 3MF writer.
# Same layout Bambu itself saves (see bambu/aa_fit.3mf): each bin is ONE
# object whose parts are the body and the text, and each part carries its
# own filament ("extruder") in Metadata/model_settings.config. No per-
# triangle colors, so nothing turns into color painting.
# ---------------------------------------------------------------------------

def read_stl(path):
    """Binary STL -> (vertices, triangles), vertices de-duplicated."""
    data = Path(path).read_bytes()
    n = struct.unpack_from("<I", data, 80)[0]
    verts, index, tris = [], {}, []
    for i in range(n):
        rec = struct.unpack_from("<12f", data, 84 + 50 * i)
        tri = []
        for k in range(3):
            v = tuple(round(c, 5) for c in rec[3 + 3 * k: 6 + 3 * k])
            if v not in index:
                index[v] = len(verts)
                verts.append(v)
            tri.append(index[v])
        if len(set(tri)) == 3:
            tris.append(tri)
    return verts, tris


def _mesh_xml(oid, verts, tris):
    out = [f'  <object id="{oid}" p:UUID="{uuid.uuid4()}" type="model">\n   <mesh>\n    <vertices>\n']
    out += [f'     <vertex x="{x}" y="{y}" z="{z}"/>\n' for x, y, z in verts]
    out.append('    </vertices>\n    <triangles>\n')
    out += [f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>\n' for a, b, c in tris]
    out.append('    </triangles>\n   </mesh>\n  </object>\n')
    return "".join(out)


def write_bambu_3mf(path, objects, center=(128, 128)):
    """objects: [(object_name, [(part_name, stl_path, filament), ...]), ...]
    Geometry keeps its OpenSCAD coordinates, shifted to the plate centre."""
    NS = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
          'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
          'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" '
          'requiredextensions="p"')
    head = '<?xml version="1.0" encoding="UTF-8"?>\n'
    sub, main_objs, build_items, cfg_objs, inst, asm = [], [], [], [], [], []
    mesh_id = 0
    obj_id = 1000
    tf = f"1 0 0 0 1 0 0 0 1 {center[0]} {center[1]} 0"
    for oname, parts in objects:
        obj_id += 1
        comps, cfg_parts = [], []
        for vi, (pname, stl, fil) in enumerate(parts):
            mesh_id += 1
            verts, tris = read_stl(stl)
            sub.append(_mesh_xml(mesh_id, verts, tris))
            comps.append(f'    <component p:path="/3D/Objects/object_1.model" objectid="{mesh_id}" '
                         f'p:UUID="{uuid.uuid4()}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n')
            cfg_parts.append(
                f'    <part id="{mesh_id}" subtype="normal_part">\n'
                f'      <metadata key="name" value="{pname}"/>\n'
                f'      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
                f'      <metadata key="extruder" value="{fil}"/>\n'
                f'    </part>\n')
            asm.append(f'   <assemble_item object_id="{obj_id}" volume_id="{vi}" '
                       f'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n')
        main_objs.append(f'  <object id="{obj_id}" p:UUID="{uuid.uuid4()}" type="model">\n'
                         f'   <components>\n{"".join(comps)}   </components>\n  </object>\n')
        build_items.append(f'  <item objectid="{obj_id}" p:UUID="{uuid.uuid4()}" '
                           f'transform="{tf}" printable="1"/>\n')
        cfg_objs.append(f'  <object id="{obj_id}">\n'
                        f'    <metadata key="name" value="{oname}"/>\n'
                        f'    <metadata key="extruder" value="{parts[0][2]}"/>\n'
                        f'{"".join(cfg_parts)}  </object>\n')
        inst.append(f'    <model_instance>\n      <metadata key="object_id" value="{obj_id}"/>\n'
                    f'      <metadata key="instance_id" value="0"/>\n'
                    f'      <metadata key="identify_id" value="{obj_id}"/>\n    </model_instance>\n')
        asm.insert(len(asm) - len(parts),
                   f'   <assemble_item object_id="{obj_id}" instance_id="0" transform="{tf}" offset="0 0 0"/>\n')

    main = (head + f'<model unit="millimeter" xml:lang="en-US" {NS}>\n'
            ' <metadata name="Application">BambuStudio-02.09.02.62</metadata>\n'
            ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
            ' <metadata name="Title">gridfinity-batteries</metadata>\n'
            f' <resources>\n{"".join(main_objs)} </resources>\n'
            f' <build p:UUID="{uuid.uuid4()}">\n{"".join(build_items)} </build>\n</model>\n')
    objfile = (head + f'<model unit="millimeter" xml:lang="en-US" {NS}>\n'
               ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
               f' <resources>\n{"".join(sub)} </resources>\n <build/>\n</model>\n')
    cfg = (head + '<config>\n' + "".join(cfg_objs) +
           '  <plate>\n    <metadata key="plater_id" value="1"/>\n'
           '    <metadata key="plater_name" value=""/>\n'
           '    <metadata key="locked" value="false"/>\n' + "".join(inst) + '  </plate>\n'
           '  <assemble>\n' + "".join(asm) + '  </assemble>\n</config>\n')
    rels = (head + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
            ' <Relationship Target="/3D/3dmodel.model" Id="rel-1" '
            'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n</Relationships>\n')
    mrels = (head + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
             ' <Relationship Target="/3D/Objects/object_1.model" Id="rel-1" '
             'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n</Relationships>\n')
    ctypes = (head + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
              ' <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
              ' <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
              ' <Default Extension="config" ContentType="text/xml"/>\n'
              '</Types>\n')
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", ctypes)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", main)
        z.writestr("3D/_rels/3dmodel.model.rels", mrels)
        z.writestr("3D/Objects/object_1.model", objfile)
        z.writestr("Metadata/model_settings.config", cfg)


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
    # Bambu-style 3MF: the bin is one object (body + text parts, text on
    # its own filament); the lid is a second object.
    objs = [(bin_id, [("body", d / f"{bin_id}-body.stl", BODY_FILAMENT),
                      ("text", d / f"{bin_id}-text.stl", TEXT_FILAMENT)])]
    if has_lid:
        objs.append((f"{bin_id} lid", [("lid", d / f"{bin_id}-lid.stl", BODY_FILAMENT)]))
    write_bambu_3mf(d / f"{bin_id}.3mf", objs)
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
