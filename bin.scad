// Entry point. Render one bin from the data table in src/batteries.scad.
//
//   openscad -D 'bin_id="aa_fit"' -D 'part="body"' -o aa_fit-body.stl bin.scad
//
// part: "body"  — white bin body only
//       "text"  — black raised text only
//       "both"  — both as separate top-level objects (use with
//                 --enable=lazy-union for a two-object 3MF, or for previews)
// list_bins=true just echoes the bin ids (used by build.py).

use <src/battery_bin.scad>
include <src/batteries.scad>

bin_id = "aa_fit";
part = "both";
list_bins = false;

$fa = 4;
$fs = 0.25;

if (list_bins) {
    echo(str("BIN_IDS=", [for (b = BINS) b[0]]));
} else {
    if (part == "body" || part == "both")
        color("white") battery_bin_body(bin_id);
    if (part == "text" || part == "both")
        color("black") battery_bin_text(bin_id);
}
