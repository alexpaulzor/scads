/*

Laser-cut wooden solder jig for wire marble track. Nothing snaps or flexes:
each jig "station" is a set of flat pieces whose edges meet exactly through
the rail centers, so every rail sits in a half-depth notch in each of two
neighboring pieces. The pieces come together around the wires and a rubber
band (in the notches on their outer edges) holds them shut.

Open styles (open2, rail3, channel4): 2 pieces per station.
  comb   - stands in a slotted base board; rails drop into its half notches.
           Its top edge dips under the marble, so the combs alone (keepers
           off) also work as a test stand you can roll marbles on.
  keeper - drops on top of the rails. Band over the keeper, hooked under the
           comb's side notches.

Enclosed styles (tube3, tube4): a core plus one outer piece per rail gap.
  core   - fills the inside of the tube, touching every rail. After the ties
           are soldered, turn it edge-on inside the tube and slide it out.
  outer pieces - one between each pair of neighboring rails; each pulls
           straight away from the marble center. The bottom one stands in
           the base board. Band around the whole station.

Wood chars instead of melting and doesn't sink the heat like aluminum did.
Solder ties midway between stations (station_pitch apart), not at them.

  openscad -o jig.svg      -D 'jig_part="straight_laser"' -D 'style="tube4"' marbles/wire_jig.scad
  openscad -o jig_etch.svg -D 'jig_part="straight_etch"'  -D 'style="tube4"' marbles/wire_jig.scad
  openscad -o view.png     -D 'jig_part="straight_view"'  marbles/wire_jig.scad

The *_etch layers engrave a station number on every piece and next to its
slot in the base board (stations on a sloped path all differ in height).

*/

include <wire_track.scad>
part = "none";

jig_part = "straight_view";

// Rail hole radius: wire plus a little play (kerf is compensated separately)
hole_r = wire_r + jig_clr;
// Room kept between the comb's top edge and a rolling marble
jig_mclr = 0.5;
// Solid wood around the rail holes
st_wall = 4;
// Room under the rails for the ties and your soldering iron
jig_floor_room = 10;
station_pitch = 40;
n_stations = 4;
band_w = 3;
band_d = 1.5;
label_size = 3.5;
sheet_w = 400;
sheet_h = 300;

// Rails sit this far above the base board, leaving room under them for ties
function rest_h(s) = former_r_max(track_rails(s)) + wire_od + jig_floor_room;

function rail_xy(s) = [for (rl=track_rails(s)) rail_pt(rl)];
function open_style(s) = !is_enclosed(track_rails(s));
function st_r(s) = max([for (rl=track_rails(s)) rl[1]]) + hole_r + st_wall;
function open_w(s) = 2 * (max([for (p=rail_xy(s)) abs(p[0])]) + hole_r + st_wall);
function keeper_top(s) = max(concat([marble_r + 4], [for (p=rail_xy(s)) p[1] + hole_r + st_wall]));
function n_pieces(s) = open_style(s) ? 2 : len(track_rails(s)) + 1;

// Comb/keeper parting line, left to right through every rail center; between
// rails it dips under the marble so the comb alone is a usable test stand.
function lerp_y(a, b, x) = a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0]);
function dip_y(x) = let(mr = marble_r + jig_mclr)
    abs(x) < mr ? -sqrt(mr * mr - x * x) : 1e9;
function parting(s, step=0.5) =
    let(p = sort_rails(rail_xy(s)), w = open_w(s), n = len(p))
    concat(
        [[-w/2, p[0][1]]],
        [for (i=[0:n-2]) each
            [for (x=[p[i][0] : step : p[i+1][0] - step/2])
                [x, min(lerp_y(p[i], p[i+1], x), dip_y(x))]]],
        [p[n-1], [w/2, p[n-1][1]]]);

module rail_holes(s) {
    for (p=rail_xy(s))
        translate(p) circle(r=hole_r, $fn=base_fn/2);
}

module base_tabs(x0, x1, base_y) {
    // one tab if the piece is narrow, else two
    w = x1 - x0;
    for (x=(w < 3 * jig_tab_w + 4 ? [(x0 + x1)/2] : [x0 + jig_tab_w/2 + 2, x1 - jig_tab_w/2 - 2]))
        translate([x - jig_tab_w/2, base_y - sheet_th])
            square([jig_tab_w, sheet_th + 0.01]);
}

function tab_xs(x0, x1) = let(w = x1 - x0)
    w < 3 * jig_tab_w + 4 ? [(x0 + x1)/2] : [x0 + jig_tab_w/2 + 2, x1 - jig_tab_w/2 - 2];

module band_notch(p, a) {
    translate(p) rotate([0, 0, a])
        square([band_w, 2 * band_d], center=true);
}

// --- open styles ---

module open_comb_2d(s, base_y) {
    w = open_w(s);
    difference() {
        union() {
            polygon(concat(parting(s), [[w/2, base_y], [-w/2, base_y]]));
            base_tabs(-w/2, w/2, base_y);
        }
        rail_holes(s);
        for (sx=[-1, 1])
            band_notch([sx * w/2, base_y + 4], 0);
    }
}

module open_keeper_2d(s) {
    w = open_w(s);
    t = keeper_top(s);
    difference() {
        polygon(concat(parting(s), [[w/2, t], [-w/2, t]]));
        rail_holes(s);
        band_notch([0, t], 0);
    }
}

// --- enclosed styles ---

module core_2d(s) {
    difference() {
        polygon(rail_xy(s));
        rail_holes(s);
    }
}

// Rail angles around the marble center, sorted, with the wrap-around one
function rail_as(s) = let(rs = track_rails(s)) [for (rl=rs) rl[0]];
// Piece k sits between rails k and k+1; returns [a0, a1] with a1 > a0
function sector(s, k) = let(a = rail_as(s), n = len(a), a0 = a[k], a1 = a[(k + 1) % n])
    [a0, a1 > a0 ? a1 : a1 + 360];
// The outer piece straddling straight down stands in the base board
function bottom_k(s) = let(n = len(rail_as(s)))
    [for (k=[0:n-1]) let(sc = sector(s, k)) if ((sc[0] <= 0 && sc[1] >= 0) || (sc[0] <= 360 && sc[1] >= 360)) k][0];
function foot_hw(s) = let(sc = sector(s, bottom_k(s)))
    st_r(s) * min(abs(sin(sc[0])), abs(sin(sc[1]))) - 1;

module wedge(a0, a1, r=300) {
    polygon(concat([[0, 0]], [for (i=[0:16]) pt(a0 + (a1 - a0) * i / 16, r)]));
}

module outer_2d(s, k, base_y) {
    sc = sector(s, k);
    r = st_r(s);
    fw = foot_hw(s);
    difference() {
        union() {
            intersection() {
                difference() {
                    circle(r=r, $fn=base_fn);
                    polygon(rail_xy(s));
                }
                wedge(sc[0], sc[1]);
            }
            if (k == bottom_k(s)) {
                translate([-fw, base_y])
                    square([2 * fw, base_y < -r ? -r + 3 - base_y : 0.01]);
                base_tabs(-fw, fw, base_y);
            }
        }
        rail_holes(s);
        // the bottom piece hooks the band at both ends; the rest carry it
        for (a=(k == bottom_k(s) ? [sc[0] + 10, sc[1] - 10] : [(sc[0] + sc[1]) / 2]))
            band_notch(pt(a, r), a);
    }
}

// --- stations ---

// Piece i of a station whose rails rest base_h above the base board
// (0 = the piece that stands in the board).
module piece_2d(s, i, base_h) {
    base_y = -base_h;
    if (open_style(s)) {
        if (i == 0) open_comb_2d(s, base_y);
        else open_keeper_2d(s);
    } else {
        bk = bottom_k(s);
        n = len(rail_as(s));
        if (i == 0) outer_2d(s, bk, base_y);
        else if (i == n) core_2d(s);
        else outer_2d(s, (bk + i) % n, base_y);
    }
}

// x positions of a station's base tabs, in the station plane
function station_tab_xs(s) = open_style(s)
    ? tab_xs(-open_w(s)/2, open_w(s)/2)
    : tab_xs(-foot_hw(s), foot_hw(s));

// Station i of a straight, level jig
function straight_base_h(s) = rest_h(s);

module straight_base_2d(s) {
    w = open_style(s) ? open_w(s) + 20 : 2 * st_r(s) + 20;
    difference() {
        translate([-w/2, -15])
            square([w, (n_stations - 1) * station_pitch + 30]);
        for (i=[0:n_stations-1], x=station_tab_xs(s))
            translate([x, i * station_pitch])
                square([jig_tab_w, sheet_th], center=true);
    }
}

// Lay pieces out on a grid. items = [[style, piece, base_h, label], ...]
function cell_w(s) = (open_style(s) ? open_w(s) : 2 * st_r(s)) + 4;
function cell_h(s, base_h) = max(keeper_top(s), st_r(s)) + base_h + sheet_th + 4;

module straight_laser(s, etch=false) {
    items = [for (i=[0:n_stations-1], p=[0:n_pieces(s)-1]) [s, p, straight_base_h(s), str(i + 1)]];
    cw = cell_w(s);
    ch = cell_h(s, straight_base_h(s));
    bw = (open_style(s) ? open_w(s) : 2 * st_r(s)) + 20;
    cols = max(1, floor((sheet_w - bw - 10) / cw));
    if (!etch) {
        offset(delta=kerf/2) {
            translate([bw/2 + 5, 20]) straight_base_2d(s);
            for (j=[0:len(items)-1])
                translate([bw + 10 + (j % cols + 0.5) * cw,
                        5 + floor(j / cols) * ch + items[j][2] + sheet_th])
                    piece_2d(s, items[j][1], items[j][2]);
        }
    } else {
        for (i=[0:n_stations-1])
            translate([bw/2 + 5 + bw/2 - 8, 20 + i * station_pitch + 3])
                text(str(i + 1), size=label_size, halign="center");
        for (j=[0:len(items)-1])
            translate([bw + 10 + (j % cols + 0.5) * cw,
                    5 + floor(j / cols) * ch + items[j][2] + sheet_th])
                label_at(s, items[j][1], items[j][2], items[j][3]);
    }
}

// Station number engraved somewhere solid on each piece
module label_at(s, i, base_h, label) {
    p = open_style(s)
        ? (i == 0 ? [0, -base_h + 5] : [0, keeper_top(s) - 6])
        : (i == 0 ? [0, -base_h + 5] : [0, 0]);
    if (open_style(s) || i == 0 || i == len(rail_as(s)))
        translate(p) text(label, size=label_size, halign="center", valign="center");
}

module station_3d(s, base_h, explode=0) {
    for (i=[0:n_pieces(s)-1]) {
        // pull each piece away from the rails by `explode`
        d = open_style(s) ? [0, i == 0 ? -explode : explode]
            : i == len(rail_as(s)) ? [0, 0]
            : let(sc = sector(s, (bottom_k(s) + i) % len(rail_as(s)))) pt((sc[0] + sc[1]) / 2, explode);
        color(i == 0 ? "burlywood" : i == len(rail_as(s)) && !open_style(s) ? "peru" : "tan")
            translate(concat(d, -sheet_th/2))
            linear_extrude(sheet_th)
            piece_2d(s, i, base_h);
    }
}

module straight_view(s) {
    bh = straight_base_h(s);
    rotate([90, 0, 0]) {
        for (i=[0:n_stations-1])
            translate([0, 0, -i * station_pitch])
                station_3d(s, bh, i == 0 ? 6 : 0);
        color("silver")
            for (p=rail_xy(s))
                translate(concat(p, -(n_stations - 0.5) * station_pitch))
                    cylinder(r=wire_r, h=n_stations * station_pitch, $fn=base_fn/4);
    }
    color("burlywood")
        translate([0, 0, -bh - sheet_th])
        linear_extrude(sheet_th)
        straight_base_2d(s);
}

echo(jig_style=style, open=open_style(style), pieces_per_station=n_pieces(style),
    rest_h=rest_h(style));

if (jig_part == "straight_view") straight_view(style);
else if (jig_part == "straight_laser") straight_laser(style);
else if (jig_part == "straight_etch") straight_laser(style, etch=true);
else if (jig_part == "station") station_3d(style, rest_h(style), 6);
