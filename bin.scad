// Entry point. Render one bin from the data table in src/batteries.scad.
//
//   openscad -D 'bin_id="aa_fit"' -D 'part="body"' -o aa_fit-body.stl bin.scad
//
// part: "body"  — white bin body only
//       "text"  — black raised text only
//       "lid"   — lid only, upside down for printing (lidded boxes)
//       "both"  — body, text (and lid, beside it) as separate top-level
//                 objects: use with --enable=lazy-union for a 3MF
//       "closed"— preview only: lidded box with the lid shut
// list_bins=true just echoes the bin ids and which have lids (build.py).

use <src/battery_bin.scad>
use <src/util.scad>
include <src/batteries.scad>

bin_id = "aa_fit";
part = "both";
list_bins = false;

$fa = 4;
$fs = 0.25;

if (list_bins) {
    echo(str("BIN_IDS=", [for (b = BINS) b[0]]));
    echo(str("LID_IDS=", [for (b = BINS) if (kv(b[1], "type") == "lidbox") b[0]]));
} else {
    if (part == "body" || part == "both" || part == "closed")
        color("white") bin_body(bin_id);
    if (part == "text" || part == "both" || part == "closed")
        color("black") bin_text(bin_id, FONT_PREFS);
    if (part == "lid" || part == "both")
        color("white") bin_lid(bin_id, "print");
    if (part == "closed")
        color("gainsboro") bin_lid(bin_id, "closed");
}
