// ===================================================================
// battery_bin.scad — geometry for battery bins.
//
// "cells" bins (default): pockets laid out in column groups.
//   gridfinity base (lite = hollow feet, from gridfinity-rebuilt)
//   thin floor plate
//   outer wall + thin tube around each pocket + tie ribs (no solid block)
//   hollow label strip at the front whose thin deck carries the text
// "scoop" bins: open tray, see the end of this file.
//
// Pockets: a cell is "round" (d) or "rect" (fp = [x, y] footprint as
// placed), standing l tall. Upright AA, a coin on edge (fp [d, thick],
// l = d) and a flat button cell (d, l = thickness) are all just cells.
// Each pocket is hold × l deep. The bin top sits at the deepest pocket.
//
// The body and the text are separate parts, exported as separate objects
// (Bambu Studio: assign black to the text, done).
// ===================================================================

include <../lib/gridfinity-rebuilt-openscad/src/core/standard.scad>
use <../lib/gridfinity-rebuilt-openscad/src/core/base.scad>
use <../lib/gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-holes.scad>
use <../lib/gridfinity-rebuilt-openscad/src/helpers/shapes.scad>
use <../fonts/Jost-Bold.ttf>
use <util.scad>
include <batteries.scad>

// First font in FONT_PREFS (batteries.scad) that is actually installed.
// OpenSCAD silently substitutes missing fonts, so check the family that
// fontmetrics() really resolved to.
function _family(spec) =
    let(i = search(":", spec))
    len(i) > 0 ? [for (k = [0:i[0]-1]) spec[k]] : spec;
function _str(chars) = len(chars) == 0 ? "" : str(chars[0], _str([for (k = [1:1:len(chars)-1]) chars[k]]));
function font_ok(spec) = fontmetrics(font=spec).font.family == _str(_family(spec));
function pick_font(prefs) =
    let(ok = [for (f = prefs) if (font_ok(f)) f])
    len(ok) > 0 ? ok[0] : prefs[len(prefs) - 1];
EPS = 0.01;

// ---------- table access ----------

function bin_entry(id) =
    let(b = kv(BINS, id))
    assert(!is_undef(b), str("Unknown bin id: ", id))
    b;

function P(id, key) = bin_prop(bin_entry(id), key, BIN_DEFAULTS);

function cell(name) =
    let(c = kv(CELLS, name))
    assert(!is_undef(c), str("Unknown cell: ", name))
    c;
function cell_shape(name) = kv(cell(name), "shape", "round");
function cell_fp(name) =
    cell_shape(name) == "round" ? [kv(cell(name), "d"), kv(cell(name), "d")]
                                : kv(cell(name), "fp");
function cell_l(name) = kv(cell(name), "l");

function outer_size(id) = [for (g = P(id, "grid")) g * 42] - BASE_GAP_MM;
function inner_size(id) = outer_size(id) - 2 * [P(id, "wall"), P(id, "wall")];
function floor_top(id) = BASE_HEIGHT + P(id, "floor");

// ---------- layout: column groups ----------
// group = [cell, cols, rows, label, clearance]; label/clearance optional.
// Shorthand in BINS: cell + cols + rows (+ optional per-column
// "clearance" list and "col_labels", which become one group per column).

function groups(id) =
    let(g = kv(bin_entry(id), "groups"))
    !is_undef(g) ? g :
    let(cl = P(id, "clearance"), labels = kv(bin_entry(id), "col_labels"),
        c = P(id, "cell"), n = P(id, "cols"), r = P(id, "rows"))
    (is_list(cl) || !is_undef(labels))
        ? [for (i = [0:n-1]) [c, 1, r,
              is_undef(labels) ? undef : labels[i], at(cl, i)]]
        : [[c, n, r]];

function g_clr(id, g) = is_undef(g[4]) ? P(id, "clearance") : g[4];
function g_pocket(id, g) = cell_fp(g[0]) + [1, 1] * g_clr(id, g);
// Bin-level layout options:
//   space   [x, y] extra gap between pockets (finger room)
//   stagger true: odd rows shift half a pitch (hex packing, round cells)
//   raise   mm: odd rows get a raised floor, so neighbours stand at
//           alternating heights and every cell can be pinched
function g_pitch(id, g) = g_pocket(id, g) + [1, 1] * P(id, "rib") + P(id, "space");
// distance between row centres
function g_row(id, g) = let(p = g_pitch(id, g))
    P(id, "stagger") ? max(sqrt(p.x * p.x - p.x * p.x / 4), p.y * sqrt(3) / 2) : p.y;
function g_width(id, g) = (g[1] + (P(id, "stagger") && g[2] > 1 ? 0.5 : 0)) * g_pitch(id, g).x;
function g_height(id, g) = g_pitch(id, g).y + (g[2] - 1) * g_row(id, g) + P(id, "rib");

function _sum(v) = len(v) == 0 ? 0 : v[0] + _sum([for (i = [1:1:len(v)-1]) v[i]]);
function total_width(id) =
    _sum([for (g = groups(id)) g_width(id, g)]) + P(id, "rib");
// left edge (x) of group i
function g_x0(id, i) = -total_width(id) / 2 + P(id, "rib") / 2
    + _sum([for (k = [0:1:i-1]) g_width(id, groups(id)[k])]);
function g_xc(id, i) = g_x0(id, i) + g_width(id, groups(id)[i]) / 2;

// y extent of the pocket region (front edge = back of the label strip)
function holes_y0(id) = -inner_size(id).y / 2 + P(id, "strip");
function holes_y1(id) =  inner_size(id).y / 2;
function holes_yc(id) = (holes_y0(id) + holes_y1(id)) / 2;

function pocket_depth(id, g) = P(id, "hold") * cell_l(g[0]);
// depth of pocket in row r (raised rows are shallower)
function row_depth(id, g, r) = pocket_depth(id, g) - (r % 2 == 1 ? P(id, "raise") : 0);
function top_z(id) = floor_top(id)
    + max([for (g = groups(id)) pocket_depth(id, g)]);

// Every pocket: [group index, [x, y], row]
function pockets(id) = [
    for (i = [0:len(groups(id))-1])
        let(g = groups(id)[i], p = g_pitch(id, g))
        for (c = [0:g[1]-1], r = [0:g[2]-1])
            [i, [g_x0(id, i) + (c + 0.5 + (P(id, "stagger") && r % 2 == 1 ? 0.5 : 0)) * p.x,
                 holes_yc(id) + (r - (g[2] - 1) / 2) * g_row(id, g)], r]
];

module _check_fit(id) {
    have = [inner_size(id).x, holes_y1(id) - holes_y0(id)];
    need = [total_width(id), max([for (g = groups(id)) g_height(id, g)])];
    assert(need.x <= have.x + EPS,
        str(id, ": columns need ", need.x, " mm, only ", have.x, " available"));
    assert(need.y <= have.y + EPS,
        str(id, ": rows need ", need.y, " mm, only ", have.y, " available"));
    echo(str("BIN ", id, ": outer ", outer_size(id), " top_z ", top_z(id),
             " pockets ", len(pockets(id)), " spare [x,y] ", have - need));
}

// ---------- 2D pocket shapes ----------

module pocket2d(id, g, grow=0) {
    s = g_pocket(id, g) + [2, 2] * grow;
    if (cell_shape(g[0]) == "round") circle(d=s.x);
    else rounded_square(s, min(0.6 + grow, min(s) / 2 - EPS), center=true);
}

// ---------- parts ----------

module bin_base(id) {
    grid = P(id, "grid");
    holes = bundle_hole_options(
        refined_hole=false, magnet_hole=P(id, "magnets"),
        screw_hole=false, crush_ribs=true, chamfer=true, supportless=true);
    if (P(id, "base") == "lite")
        gridfinity_base_lite(grid, wall_thickness=d_wall,
            bottom_thickness=1, hole_options=holes, only_corners=true);
    else
        gridfinityBase(grid, hole_options=holes, only_corners=true);
}

module _footprint(id, shrink=0) {
    rounded_square(outer_size(id) - 2 * [shrink, shrink],
        BASE_TOP_RADIUS - shrink, center=true);
}

module _pocket_cuts(id) {
    ch = P(id, "chamfer");
    zt = top_z(id);
    for (pk = pockets(id)) {
        g = groups(id)[pk[0]];
        depth = row_depth(id, g, pk[2]);
        c = min(ch, depth / 3);
        translate(pk[1]) {
            translate([0, 0, zt - depth])
                linear_extrude(depth + 1) pocket2d(id, g);
            hull() {
                translate([0, 0, zt - c]) linear_extrude(EPS) pocket2d(id, g);
                translate([0, 0, zt]) linear_extrude(EPS) pocket2d(id, g, c);
            }
            sz = g_pocket(id, g);
            // fingernail notch on the front side, a little below the floor
            nt = P(id, "notch");
            if (nt[0] > 0)
                translate([-nt[0] / 2, -sz.y / 2 - nt[1], zt - depth - nt[2]])
                    cube([nt[0], nt[1] + sz.y / 2, depth + nt[2] + 1]);
            // finger channels at both x-ends: grip the cell by its rims
            // (never deeper than 75 % of the slot, so small cells can't
            // slide out sideways under the channel)
            cw = P(id, "channel");
            cd = min(cw[1], 0.75 * depth);
            if (cw[0] > 0)
                for (m = [0, 1]) mirror([m, 0, 0])
                    translate([sz.x / 2 - EPS, -g_pitch(id, g).y / 2 - EPS, zt - cd])
                        cube([cw[0], g_pitch(id, g).y + 2 * EPS, cd + 1]);
        }
    }
}

module battery_bin_body(id) {
    _check_fit(id);
    inner = inner_size(id);
    rib = P(id, "rib");
    zf = floor_top(id) - EPS;
    zt = top_z(id);
    gs = groups(id);
    ng = len(gs);

    bin_base(id);

    // floor plate (bridges the hollow lite feet)
    translate([0, 0, BASE_HEIGHT - EPS])
        linear_extrude(P(id, "floor") + EPS) _footprint(id);

    difference() {
        translate([0, 0, zf]) linear_extrude(zt - zf) union() {
            // outer wall
            difference() {
                _footprint(id);
                _footprint(id, P(id, "wall"));
            }
            // back wall of the (hollow) label strip
            if (P(id, "strip") > 0)
                translate([-inner.x / 2 - EPS, holes_y0(id) - P(id, "wall")])
                    square([inner.x + 2 * EPS, P(id, "wall") + EPS]);
            // a tube around every pocket (solid below shallow pockets)
            for (pk = pockets(id))
                translate(pk[1]) pocket2d(id, gs[pk[0]], rib);
            // tie ribs: each column front-to-back
            for (pk = pockets(id))
                translate([pk[1].x, holes_yc(id)])
                    square([rib, holes_y1(id) - holes_y0(id) + 2 * EPS], center=true);
            // each row across its group; outermost groups run to the wall
            for (i = [0:ng-1]) {
                x0 = i == 0 ? -inner.x / 2 - EPS : g_x0(id, i);
                x1 = i == ng - 1 ? inner.x / 2 + EPS
                                 : g_x0(id, i) + g_width(id, gs[i]);
                for (pk = pockets(id)) if (pk[0] == i)
                    translate([x0, pk[1].y - rib / 2]) square([x1 - x0, rib]);
            }
        }
        _pocket_cuts(id);
    }

    // label strip deck: thin plate bridging front wall -> strip back wall
    if (P(id, "strip") > 0) {
        deck = P(id, "deck");
        translate([-inner.x / 2 - EPS, -inner.y / 2 - EPS, zt - deck])
            cube([inner.x + 2 * EPS, P(id, "strip") + 2 * EPS, deck]);
    }
}

module battery_bin_text(id, font_prefs=FONT_PREFS) {
    font = pick_font(font_prefs);
    echo(str("BIN ", id, ": font ", font));
    inner = inner_size(id);
    strip = P(id, "strip");
    y0 = -inner.y / 2;
    gs = groups(id);
    cs = P(id, "col_text_size");
    ms = P(id, "text_size");
    label = P(id, "label");
    has_g = len([for (g = gs) if (!is_undef(g[3])) 1]) > 0;

    assert(strip > 0 || (is_undef(label) && !has_g),
        str(id, ": labels need a label strip"));

    translate([0, 0, top_z(id) - EPS])
    linear_extrude(P(id, "text_h") + EPS) {
        if (has_g) {
            yl = is_undef(label) ? y0 + strip / 2 : y0 + strip - 0.8 - cs / 2;
            for (i = [0:len(gs)-1]) if (!is_undef(gs[i][3]))
                translate([g_xc(id, i), yl])
                    text(gs[i][3], size=cs, font=font,
                         halign="center", valign="center");
        }
        if (!is_undef(label)) {
            avail = has_g ? strip - cs - 1.2 : strip;
            translate([0, y0 + avail / 2])
                text(label, size=ms, font=font,
                     halign="center", valign="center");
        }
    }
}

// ===================================================================
// Scoop bins ("type" = "scoop"): open tray for loose cells, a scoop
// fillet along the front, and a label ledge along the back whose top is
// the highest surface (so the text is still the last thing printed).
// ===================================================================

function scoop_top(id) = P(id, "height");

module scoop_bin_body(id) {
    inner = inner_size(id);
    zf = floor_top(id) - EPS;
    zt = scoop_top(id);
    r = P(id, "scoop_r");
    ledge = P(id, "ledge");
    deck = P(id, "deck");
    yb = inner.y / 2;          // back inner wall
    yf = -inner.y / 2;         // front inner wall

    echo(str("BIN ", id, ": scoop tray, outer ", outer_size(id),
             " top_z ", zt, " open depth ", zt - floor_top(id)));

    bin_base(id);
    translate([0, 0, BASE_HEIGHT - EPS])
        linear_extrude(P(id, "floor") + EPS) _footprint(id);

    // outer wall
    translate([0, 0, zf]) linear_extrude(zt - zf) difference() {
        _footprint(id);
        _footprint(id, P(id, "wall"));
    }

    // profiles in the (y, z) plane, extruded across the full inner width
    rotate([90, 0, 90])
    linear_extrude(inner.x + 2 * EPS, center=true) {
        // scoop: fills the front-bottom corner with a concave quarter round
        translate([yf - EPS, zf])
            difference() {
                square([r + EPS, r]);
                translate([r + EPS, r]) circle(r=r, $fn=96);
            }
        // label ledge with a 45° underside (prints without supports)
        polygon([
            [yb + EPS, zt],
            [yb - ledge, zt],
            [yb - ledge, zt - deck],
            [yb + EPS, zt - deck - ledge],
        ]);
    }
}

// Simple "recharge" icon: battery outline with a lightning bolt.
// h = overall height in mm; drawn centred, battery pointing right.
module icon_recharge(h) {
    w = h * 1.9;               // body width
    t = max(0.9, h * 0.14);    // outline stroke (≥ 2 lines @ 0.4 nozzle)
    nub = [h * 0.18, h * 0.45];
    difference() {
        square([w, h], center=true);
        square([w - 2 * t, h - 2 * t], center=true);
    }
    translate([w / 2 - EPS, 0]) square([nub.x + EPS, nub.y], center=[false, true]);
    // bolt
    s = (h - 2 * t) * 0.92 / 10;
    scale([s, s]) polygon([
        [ 1.2,  5.0], [-3.2, -0.6], [ 0.0, -0.6],
        [-1.2, -5.0], [ 3.2,  0.6], [ 0.0,  0.6],
    ]);
}

module scoop_bin_text(id, font) {
    inner = inner_size(id);
    ledge = P(id, "ledge");
    ms = P(id, "text_size");
    label = P(id, "label");
    icon = P(id, "icon");
    ih = ms * 1.1;                         // icon height
    iw = is_undef(icon) ? 0 : ih * 1.9 + ih * 0.18;
    gap = is_undef(icon) ? 0 : ms * 0.6;
    tw = is_undef(label) ? 0 : textmetrics(label, size=ms, font=font).size.x;
    total = iw + gap + tw;
    yc = inner.y / 2 - ledge / 2;

    translate([0, 0, scoop_top(id) - EPS])
    linear_extrude(P(id, "text_h") + EPS) {
        if (!is_undef(icon))
            translate([-total / 2 + ih * 0.95, yc]) icon_recharge(ih);
        if (!is_undef(label))
            translate([-total / 2 + iw + gap, yc])
                text(label, size=ms, font=font, halign="left", valign="center");
    }
}

// ---------- dispatch on "type" ----------

module bin_body(id) {
    if (P(id, "type") == "scoop") scoop_bin_body(id);
    else battery_bin_body(id);
}

module bin_text(id, font_prefs=FONT_PREFS) {
    if (P(id, "type") == "scoop") {
        font = pick_font(font_prefs);
        echo(str("BIN ", id, ": font ", font));
        scoop_bin_text(id, font);
    } else battery_bin_text(id, font_prefs);
}
