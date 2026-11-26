// ===================================================================
// batteries.scad — THE data table.
//
// Two tables:
//   CELLS  — physical cell dimensions (from caliper measurements).
//   BINS   — one short entry per printable bin. Any key not given in a
//            bin falls back to BIN_DEFAULTS.
//
// All dimensions in mm. Every entry is a list of [key, value] pairs,
// read with kv(list, key, default) from util.scad.
// ===================================================================

// ---------- Label font ----------
// First installed font wins. Futura ships with macOS (licensed with the OS,
// so it is NOT in this repo). Jost is an open-source (OFL) Futura look-alike
// bundled in fonts/, so renders elsewhere (cloud, Linux) look nearly the same.
// Override for one build: -D 'FONT_PREFS=["Futura:style=Medium"]'
FONT_PREFS = ["Futura:style=Bold", "Jost:style=Bold"];

// ---------- Global defaults (any bin may override) ----------
BIN_DEFAULTS = [
    ["type",        "cells"],  // "cells" (pockets), "scoop" (open tray),
                               // "lidbox" (compartments under a hinged lid)
    // Diametral clearance added to the measured cell diameter.
    // May be a single number or a per-column list (fit tests).
    ["clearance",   0.3],      // chosen from aa_fit print 2026-11-24
    // Fraction of cell length held below the top of the bin.
    // 0.5 = "half exposed for grabbing".
    ["hold",        0.5],
    ["base",        "lite"],   // "lite" (hollow feet) or "solid"
    ["magnets",     false],    // 6x2 mm magnet holes in the base corners
    ["floor",       1.2],      // floor plate on top of the base, mm
    ["wall",        1.2],      // outer wall thickness
    ["rib",         0.8],      // tubes / ribs between cells (2 lines @ 0.4)
    ["chamfer",     0.8],
    ["space",       [0, 0]],   // extra gap between pockets [x, y]
    ["stagger",     false],    // hex-offset odd rows (round cells)
    ["raise",       0],        // raise odd rows' floors by this much (mm)
    ["notch",       [0, 0, 0]],// fingernail notch at each pocket's front:
                               //   [width, reach past pocket, below floor]
    ["channel",     [0, 0]],   // finger channels at both x-ends of each
                               //   pocket: [width, depth from top]      // lead-in chamfer at the top of each hole
    ["strip",       9],        // front label strip depth (y), 0 = none
    ["deck",        1.6],      // label strip top plate (hollow below)
    ["text_size",   5],        // main label font size (mm)
    ["text_h",      0.6],      // raised text height (3 layers @ 0.2)
    ["col_text_size", 3.5],    // per-group labels
    // lidded boxes
    ["depth",       15],       // inside depth under the lid
    ["lid_t",       3.2],      // lid thickness (16 layers)
    ["mesh",        3.0],      // lid hex holes, across flats
    ["mesh_wall",   1.0],      // lid hex walls
];

// ---------- Cells ----------
// shape "round": d = max diameter.  shape "rect": fp = [x, y] footprint
// as placed in the bin.  l = height as the cell sits in its pocket
// (length for upright cells, diameter for coins on edge, thickness for
// flat button cells).  Measured 2026-11-24 with calipers, largest cell.
CELLS = [
    ["AA",     [["d", 14.35], ["l", 50.32]]],  // mostly NiMH
    ["AAA",    [["d", 10.4],  ["l", 44.25]]],
    ["9V",     [["shape", "rect"], ["fp", [17.2, 25.9]], ["l", 47.5]]],
    ["NPBX1",  [["shape", "rect"], ["fp", [9.45, 29.4]], ["l", 42.9]]],
    // coins stand on edge in slots: footprint = diameter x thickness
    ["CR2032", [["shape", "rect"], ["fp", [20, 3.12]], ["l", 20]]],
    ["CR2016", [["shape", "rect"], ["fp", [20, 1.65]], ["l", 20]]],
    // button cells also stand on edge in slots, like coins
    ["AG13",   [["shape", "rect"], ["fp", [11.44, 5.16]], ["l", 11.44]]],  // = LR44
    ["AG3",    [["shape", "rect"], ["fp", [7.82, 3.51]],  ["l", 7.82]]],   // = LR41
];

// ---------- Bins ----------
// grid: gridfinity units [x, y].
// Uniform layout: cell + cols + rows.  Mixed layout: "groups", a list of
//   [cell, cols, rows, label, clearance]  placed left to right; label and
//   clearance are optional.  label: main raised label in the front strip.
BINS = [
    // Clearance ladder (printed 2026-11-24: 0.3 won).
    ["aa_fit", [
        ["cell", "AA"], ["grid", [2, 1]],
        ["rows", 1], ["cols", 4],
        ["clearance", [0.3, 0.5, 0.7, 0.9]],
        ["label", "AA"],
        ["col_labels", ["0.3", "0.5", "0.7", "0.9"]],
        ["strip", 12], ["rib", 1.2],
    ]],

    // 2 rows of 5. Print two for 20 cells. Back row stands 10 mm
    // higher (15 mm held), so it can be pinched front-to-back.
    ["aa", [
        ["cell", "AA"], ["grid", [2, 1]],
        ["rows", 2], ["cols", 5], ["raise", 10],
        ["strip", 6], ["label", "AA"],
    ]],

    // 3 staggered rows of 6; the middle row stands 8 mm higher.
    ["aaa", [
        ["cell", "AAA"], ["grid", [2, 1]],
        ["rows", 3], ["cols", 6], ["stagger", true], ["raise", 8],
        ["strip", 6], ["label", "AAA"],
    ]],

    // 4 upright, snaps up. Print two for 8.
    ["9v", [
        ["cell", "9V"], ["grid", [2, 1]],
        ["rows", 1], ["cols", 4],
        ["strip", 10], ["label", "9V"], ["text_size", 6],
    ]],

    // Sony NP-BX1, 6 upright (contacts up), spaced for fingers.
    ["npbx1", [
        ["cell", "NPBX1"], ["grid", [2, 1]],
        ["rows", 1], ["cols", 6], ["space", [2.8, 0]],
        ["strip", 6], ["label", "NP-BX1"],
    ]],

    // Small cells live loose in lidded boxes. (Slots on edge were too
    // loose: cells rolled around.) Hex-mesh lid shows what's inside.
    ["coin", [
        ["type", "lidbox"], ["grid", [2, 1]], ["strip", 8],
        ["text_size", 4.5],
        ["compartments", [["CR2032", 1], ["CR2016", 1]]],
    ]],

    ["button", [
        ["type", "lidbox"], ["grid", [2, 1]], ["strip", 8],
        ["text_size", 4.5],
        ["compartments", [["AG13 / LR44", 2], ["AG3", 1]]],
    ]],

    // Odd loose cells with no bin of their own.
    ["weirdos", [
        ["type", "lidbox"], ["grid", [2, 1]], ["strip", 8],
        ["text_size", 5.5],
        ["compartments", [["Weirdos", 1]]],
    ]],

    // Loose cells waiting for the charger (also NP-BX1s): one big
    // compartment under a hex-mesh lid, so it can be carried without
    // spilling. Same height as the AA bin. (Was an open scoop tray.)
    ["recharge", [
        ["type", "lidbox"], ["grid", [2, 2]], ["strip", 8],
        ["depth", 22],             // total height 33.4
        ["text_size", 5], ["icon", "recharge"],
        ["compartments", [["Recharge", 1]]],
    ]],
];
