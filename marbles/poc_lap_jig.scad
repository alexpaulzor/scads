/*

Laser-cut solder jig for one lap of the proof-of-concept run (poc_run.scad).

The base board is a ring following the lap's plan view, with a pair of slots
for every station; each station is cut to its own height so the rails come
out at the lap's slope. Every lap of the run has the same plan, so one jig
builds all of them.

Stations stop one station short of the seam where the lap's two ends overlap
in plan; leave the rail ends long there and join laps on the frame.

  python3 marbles/poc_layout.py    # regenerates poc_path.scad incl. stations
  openscad -o lap_base.svg       -D 'lap_part="base"'        marbles/poc_lap_jig.scad
  openscad -o lap_base_etch.svg  -D 'lap_part="base_etch"'   marbles/poc_lap_jig.scad
  openscad -o lap_pieces0.svg    -D 'lap_part="pieces"' -D 'lap_sheet=0' marbles/poc_lap_jig.scad
  openscad -o lap_pieces0_etch.svg -D 'lap_part="pieces_etch"' -D 'lap_sheet=0' marbles/poc_lap_jig.scad
  openscad -o lap_jig.png        marbles/poc_lap_jig.scad

*/

include <wire_jig.scad>
include <poc_path.scad>
jig_part = "none";

lap_part = "view";
lap_sheet = 0;
// Width of the base ring each side of the track centerline
ring_band = 25;

st = poc_lap_stations;
n_st = len(st);
z_min = min([for (s=st) s[2]]);
// one rest height for all styles so the rails line up across style changes
rest_common = max([for (s=st) rest_h(s[5])]);
function st_base_h(s) = rest_common + s[2] - z_min;
function st_right(s) = [s[4], -s[3]];
function st_ang(s) = atan2(s[4], s[3]);

items = [for (i=[0:n_st-1], p=[0:n_pieces(st[i][5])-1])
    [st[i][5], p, st_base_h(st[i]), str(i + 1)]];
cw = max([for (it=items) cell_w(it[0])]);
ch = max([for (it=items) cell_h(it[0], it[2])]);
cols = floor((sheet_w - 10) / cw);
rows = floor((sheet_h - 10) / ch);
per_sheet = cols * rows;
n_sheets = ceil(len(items) / per_sheet);

echo(lap_stations=n_st, lap_pieces=len(items), sheets=n_sheets,
    rest_common=rest_common, max_base_h=max([for (s=st) st_base_h(s)]));

module base_2d() {
    ring = [for (s=st) [s[0], s[1]]];
    difference() {
        offset(r=ring_band) polygon(ring);
        offset(r=-ring_band) polygon(ring);
        for (s=st, x=station_tab_xs(s[5]))
            translate([s[0], s[1]] + st_right(s) * x)
                rotate([0, 0, st_ang(s)])
                square([sheet_th, jig_tab_w], center=true);
    }
}

module base_etch_2d() {
    for (i=[0:n_st-1]) {
        s = st[i];
        // number on the inside of each station, plus a heading arrow
        translate([s[0], s[1]] - st_right(s) * (ring_band - 6))
            rotate([0, 0, st_ang(s) - 90])
            text(str(i + 1), size=label_size, halign="center", valign="center");
    }
}

module pieces_2d(sheet) {
    offset(delta=kerf/2)
        for (j=[sheet * per_sheet : min(len(items), (sheet + 1) * per_sheet) - 1]) {
            k = j - sheet * per_sheet;
            it = items[j];
            translate([5 + (k % cols + 0.5) * cw, 5 + floor(k / cols) * ch + it[2] + sheet_th])
                piece_2d(it[0], it[1], it[2]);
        }
}

module pieces_etch_2d(sheet) {
    for (j=[sheet * per_sheet : min(len(items), (sheet + 1) * per_sheet) - 1]) {
        k = j - sheet * per_sheet;
        it = items[j];
        translate([5 + (k % cols + 0.5) * cw, 5 + floor(k / cols) * ch + it[2] + sheet_th])
            label_at(it[0], it[1], it[2], it[3]);
    }
}

// Station frame: x -> right of travel, y -> up, z -> along travel
module st_frame(s) {
    multmatrix([
        [s[4], 0, s[3], s[0]],
        [-s[3], 0, s[4], s[1]],
        [0, 1, 0, st_base_h(s)],
        [0, 0, 0, 1]])
        children();
}

module lap_view() {
    color("burlywood")
        translate([0, 0, -sheet_th])
        linear_extrude(sheet_th)
        base_2d();
    for (s=st)
        st_frame(s) station_3d(s[5], st_base_h(s));
    // rails between stations (style of the earlier station)
    color("silver")
        for (i=[0:n_st-2], o=rail_offsets(st[i][5]))
            if (len([for (o2=rail_offsets(st[i + 1][5])) if (norm(o2 - o) < 0.01) 1]) > 0)
                hull() {
                    for (s=[st[i], st[i + 1]])
                        translate([s[0], s[1], st_base_h(s)] + concat(st_right(s) * o[0], o[1]))
                            sphere(r=wire_r, $fn=8);
                }
}

if (lap_part == "view") lap_view();
else if (lap_part == "base") offset(delta=kerf/2) base_2d();
else if (lap_part == "base_etch") base_etch_2d();
else if (lap_part == "pieces" && lap_sheet < n_sheets) pieces_2d(lap_sheet);
else if (lap_part == "pieces_etch" && lap_sheet < n_sheets) pieces_etch_2d(lap_sheet);
