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
    ["type",        "cells"],  // "cells" (upright holes) or "scoop" (open tray)
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
    ["rib",         1.2],      // thickness of tubes / ribs between cells
    ["chamfer",     0.8],      // lead-in chamfer at the top of each hole
    ["strip",       9],        // front label strip depth (y), 0 = none
    ["deck",        1.6],      // label strip top plate (hollow below)
    ["text_size",   5],        // main label font size (mm)
    ["text_h",      0.6],      // raised text height (3 layers @ 0.2)
    ["col_text_size", 3.5],    // per-column labels (fit tests)
];

// ---------- Cells ----------
// d = max diameter, l = max length (incl. button top).
// "src" records where the number came from: "nominal" until measured.
CELLS = [
    ["AA",  [["d", 14.35], ["l", 50.32], ["src", "caliper 2026-11-24, largest of Steve's cells (mostly NiMH)"]]],
    ["AAA", [["d", 10.5], ["l", 44.5], ["src", "nominal IEC LR03 max — REPLACE WITH CALIPER"]]],
];

// ---------- Bins ----------
// grid:  gridfinity units [x, y]
// rows, cols: hole matrix
// label: main raised label; col_labels: optional per-column labels
BINS = [
    // Clearance ladder: 4 holes, 4 clearances, labeled. Print this first,
    // pick the clearance that feels right, then set BIN_DEFAULTS.clearance.
    ["aa_fit", [
        ["cell", "AA"], ["grid", [2, 1]],
        ["rows", 1], ["cols", 4],
        ["clearance", [0.3, 0.5, 0.7, 0.9]],
        ["label", "AA"],
        ["col_labels", ["0.3", "0.5", "0.7", "0.9"]],
        ["strip", 12],
    ]],

    // Production AA bin: 2 rows of 5. Print two for 20 cells.
    ["aa", [
        ["cell", "AA"], ["grid", [2, 1]],
        ["rows", 2], ["cols", 5],
        ["strip", 6], ["label", "AA"],
    ]],

    // AAA: 2 rows of 6. NOMINAL cell size until measured.
    ["aaa", [
        ["cell", "AAA"], ["grid", [2, 1]],
        ["rows", 2], ["cols", 6],
        ["strip", 6], ["label", "AAA"],
    ]],

    // Loose cells waiting for the charger: open bin, scoop front,
    // label ledge at the back (45° underside, no supports).
    ["recharge", [
        ["type", "scoop"], ["grid", [2, 1]],
        ["height", 33.4],          // total height, matches the AA bin
        ["scoop_r", 16],
        ["ledge", 10],             // label ledge depth at the back
        ["label", "Recharge"], ["icon", "recharge"],
        ["text_size", 6],
    ]],
];
