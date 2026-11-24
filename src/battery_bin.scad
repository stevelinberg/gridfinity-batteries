// ===================================================================
// battery_bin.scad — geometry for upright-cell battery bins.
//
// Structure (bottom to top):
//   gridfinity base (lite = hollow feet, from gridfinity-rebuilt)
//   thin floor plate
//   outer wall + thin tubes around each cell + tie ribs (no solid block)
//   solid label strip at the front, carrying raised text
//
// The body and the text are separate parts so they can be exported as
// separate objects (Bambu Studio: assign black to the text, done).
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

// ---------- derived geometry (all functions of a bin id) ----------

function bin_entry(id) =
    let(b = kv(BINS, id))
    assert(!is_undef(b), str("Unknown bin id: ", id))
    b;

function P(id, key) = bin_prop(bin_entry(id), key, BIN_DEFAULTS);

function cell_of(id) =
    let(c = kv(CELLS, P(id, "cell")))
    assert(!is_undef(c), str("Unknown cell: ", P(id, "cell")))
    c;

function outer_size(id) = [for (g = P(id, "grid")) g * 42] - BASE_GAP_MM;
function inner_size(id) = outer_size(id) - 2 * [P(id, "wall"), P(id, "wall")];

// Hole diameter for column c.
function hole_d(id, c) = kv(cell_of(id), "d") + at(P(id, "clearance"), c);
function max_hole_d(id) = kv(cell_of(id), "d") + vmax(P(id, "clearance"));
function pitch(id) = max_hole_d(id) + P(id, "rib");

function floor_top(id) = BASE_HEIGHT + P(id, "floor");
function top_z(id) = floor_top(id) + P(id, "hold") * kv(cell_of(id), "l");

// y extent of the hole region (front edge is the back of the label strip)
function holes_y0(id) = -inner_size(id).y / 2 + P(id, "strip");
function holes_y1(id) =  inner_size(id).y / 2;

// Centre of hole [col, row]
function hole_xy(id, c, r) =
    let(n = [P(id, "cols"), P(id, "rows")], p = pitch(id))
    [ (c - (n.x - 1) / 2) * p,
      (holes_y0(id) + holes_y1(id)) / 2 + (r - (n.y - 1) / 2) * p ];

module _check_fit(id) {
    n = [P(id, "cols"), P(id, "rows")];
    need = [n.x * pitch(id) + P(id, "rib"), n.y * pitch(id) + P(id, "rib")];
    have = [inner_size(id).x, holes_y1(id) - holes_y0(id)];
    assert(need.x <= have.x + EPS,
        str(id, ": columns need ", need.x, " mm, only ", have.x, " available"));
    assert(need.y <= have.y + EPS,
        str(id, ": rows need ", need.y, " mm, only ", have.y, " available"));
    echo(str("BIN ", id, ": outer ", outer_size(id), " top_z ", top_z(id),
             " hole pitch ", pitch(id), " spare [x,y] ", have - need));
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

module _holes(id, extra_top=1) {
    n = [P(id, "cols"), P(id, "rows")];
    ch = P(id, "chamfer");
    for (c = [0:n.x-1], r = [0:n.y-1]) {
        d = hole_d(id, c);
        translate(hole_xy(id, c, r)) {
            translate([0, 0, floor_top(id)])
                cylinder(d=d, h=top_z(id) - floor_top(id) + extra_top);
            translate([0, 0, top_z(id) - ch])
                cylinder(d1=d, d2=d + 2 * ch + 2 * EPS, h=ch + EPS);
        }
    }
}

module battery_bin_body(id) {
    _check_fit(id);
    n = [P(id, "cols"), P(id, "rows")];
    inner = inner_size(id);
    rib = P(id, "rib");
    zf = floor_top(id) - EPS;
    zt = top_z(id);

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
                translate([-inner.x / 2 - EPS, holes_y0(id) - rib])
                    square([inner.x + 2 * EPS, rib + EPS]);
            // tubes around each hole
            for (c = [0:n.x-1], r = [0:n.y-1])
                translate(hole_xy(id, c, r))
                    circle(d=hole_d(id, c) + 2 * rib);
            // tie ribs: through each row (x) and each column (y)
            for (r = [0:n.y-1])
                translate([0, hole_xy(id, 0, r).y])
                    square([inner.x + 2 * EPS, rib], center=true);
            for (c = [0:n.x-1])
                translate([hole_xy(id, c, 0).x, (holes_y0(id) + holes_y1(id)) / 2])
                    square([rib, holes_y1(id) - holes_y0(id) + 2 * EPS], center=true);
        }
        _holes(id);
    }

    // label strip deck: a thin plate bridging front wall -> strip back wall.
    // Hollow underneath (short bridge), carries the raised text.
    if (P(id, "strip") > 0) {
        deck = P(id, "deck");
        translate([-inner.x / 2 - EPS, -inner.y / 2 - EPS, zt - deck])
            cube([inner.x + 2 * EPS, P(id, "strip") + 2 * EPS, deck]);
    }
}

module battery_bin_text(id, font_prefs=FONT_PREFS) {
    font = pick_font(font_prefs);
    echo(str("BIN ", id, ": font ", font));
    n = [P(id, "cols"), P(id, "rows")];
    inner = inner_size(id);
    strip = P(id, "strip");
    y0 = -inner.y / 2;
    cols = kv(bin_entry(id), "col_labels");
    cs = P(id, "col_text_size");
    ms = P(id, "text_size");
    label = P(id, "label");

    assert(strip > 0 || (is_undef(label) && is_undef(cols)),
        str(id, ": labels need a label strip"));

    translate([0, 0, top_z(id) - EPS])
    linear_extrude(P(id, "text_h") + EPS) {
        if (!is_undef(cols)) {
            for (c = [0:n.x-1])
                translate([hole_xy(id, c, 0).x, y0 + strip - 0.8 - cs / 2])
                    text(cols[c], size=cs, font=font,
                         halign="center", valign="center");
        }
        if (!is_undef(label)) {
            avail = is_undef(cols) ? strip : strip - cs - 1.2;
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
