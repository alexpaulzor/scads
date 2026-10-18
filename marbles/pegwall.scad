/*

Modular wire marble run for 1" grid steel pegboard (2 panels of 13 x 30
holes side by side = 26 x 30 holes).

Everything that touches the board is a laser-cut plywood FIN: a plate
standing straight out from the board, perpendicular to the track, with a
hook tongue + lip in one hole and a straight anti-tip pin in the hole below.
Push it in level, drop it ~2 mm, done; lift and pull to remove. Nothing
flexes. Each fin carries a track station (comb + banded keeper, from
wire_jig.scad), so the fins hold the rails on the wall AND serve as the
solder jig: solder ties between fins right on the board, or not at all.

Modules connect at PORTS: marble center track_d out from the board, x on a
half-column (between fins), y on a 1/4" (q_step) grid. Each module's rails
start joint_step below the port it enters by, so every joint steps down.

  straight - open 2-rail track along the board, any length, q_step drops
  C-turn   - 4-rail enclosed half loop in the board's plane: enters along
             one level, drops c_drop, leaves the other way. All C-turns are
             identical (a left one is a right one turned around), built in
             one flat jig: cturn_jig.
  lift     - wire-coil spiral lift standing in front of the board; its
             channel rails bend over into the top level.

Render (see README for the full list):
  openscad -o wall.png marbles/pegwall.scad
  openscad -o fins0.svg  -D 'wall_part="fins"'  -D 'sheet=0' marbles/pegwall.scad
  openscad -o hook_test.svg -D 'wall_part="hook_test"' marbles/pegwall.scad

Measure your panel and plywood first and cut hook_test: peg_hole_d,
peg_sheet_t, sheet_th and kerf are guesses until you do.

*/

include <spiral_lift.scad>
include <wire_jig.scad>
part = "none";
lift_part = "none";
jig_part = "none";

wall_part = "wall";
sheet = 0;

// --- pegboard (measure yours) ---
peg_p = 25.4;
peg_cols = 26;
peg_rows = 30;
peg_hole_d = 6.35;
peg_sheet_t = 0.9;
// board edge beyond the outer hole centers
peg_edge = 12.7;

// --- fin hook ---
hook_clr = 0.3;
tongue_h = 3;
lip_d = 2.4;
lip_t = 3;
pin_h = 3;
strip_w = 6;
// tongue + lip, seen end-on, has to pass through the hole
hook_fit = norm([sheet_th, tongue_h + lip_d]);

// --- track standard ---
track_d = 38.1;
q_step = 6.35;
joint_step = 0.5;
// comb depth below the marble center on a fin
fin_base = 16;
// fins every this many columns along a straight
fin_every = 3;
rail_h = rail_r * cos(floor_a);

// --- layout ---
lvl_n = 10;
q_straight = 2;
q_c = 8;
c_drop = q_c * q_step;
y_bot = 4.5 * peg_p;
lvl_drop = (q_straight + q_c) * q_step;
x_lift_port = 3.5 * peg_p;
x_left = 6.5 * peg_p;
x_right = 22.5 * peg_p;
// level k (0 = top) entry port height and direction
function lvl_y(k) = y_bot + q_straight * q_step + (lvl_n - 1 - k) * lvl_drop;
function lvl_dir(k) = k % 2 == 0 ? 1 : -1;
function lvl_x0(k) = k == 0 ? x_lift_port : lvl_dir(k) > 0 ? x_left : x_right;
function lvl_x1(k) = k == lvl_n - 1 ? x_lift_port : lvl_dir(k) > 0 ? x_right : x_left;
function lvl_y_at(k, x) = let(y0 = lvl_y(k) - joint_step, y1 = lvl_y(k) - q_straight * q_step)
    y0 + (y1 - y0) * (x - lvl_x0(k)) / (lvl_x1(k) - lvl_x0(k));

// --- C-turn ---
// marble path radius on the entry side; the exit side rides run_clr lower
c_rs = (c_drop - joint_step - run_clr) / 2;
c_ri = c_rs - rail_h;
c_ro = c_ri + 2 * rail_h + run_clr;
// cross-section: x toward the loop center (right of travel), y out of the
// board; [angle from "down" (into the board), radius]
function c_rail(x, y) = [atan2(x, -y), norm([x, y])];
c_style = [c_rail(rail_h, -gauge/2), c_rail(rail_h, gauge/2),
           c_rail(-rail_h - run_clr, -gauge/2), c_rail(-rail_h - run_clr, gauge/2)];

// --- lift ---
x_axis = 1 * peg_p;
x_lm = x_axis + lift_m;
x_ch = x_lm + rail_h;
y_pocket = y_bot - joint_step;
y_ex = lvl_y(0) + 3;
y_coil0 = y_pocket - lift_dz - 1.3 * coil_pitch;
y_coil1 = y_ex + exit_overrun - lift_dz + coil_pitch;
lift_turns = (y_coil1 - y_coil0) / coil_pitch;
lift_wire_l = lift_turns * norm([2 * PI * coil_r, coil_pitch]) + 2 * coil_r;
collar_col = 3;
collar_hw = 12;
y_bot_collar = y_coil0 - hub_h - sheet_th;
y_top_collar = y_coil1 + hub_h;
y_motor_collar = y_bot_collar - 1 - coupler_l - (n20_shaft_l - coupler_shaft_depth) - 6;
channel_y0 = y_pocket + marble_od;
channel_y1 = y_ex - rail_h;

echo(hook_fit=hook_fit, peg_hole_d=peg_hole_d);
echo(levels=lvl_n, top_port_y=lvl_y(0), bottom_port_y=y_bot, level_spacing=lvl_drop,
    straight_drop=q_straight * q_step);
echo(c_ri=c_ri, c_ro=c_ro, c_rs=c_rs, c_gaps=rail_gaps(track_rails(c_style)),
    c_enclosed=is_enclosed(track_rails(c_style)));
echo(lift_turns=lift_turns, lift_wire_l=lift_wire_l, y_coil0=y_coil0, y_coil1=y_coil1,
    y_motor_collar=y_motor_collar);
assert(hook_fit < peg_hole_d - 0.1, "hook tongue + lip won't pass through the hole");
assert(is_enclosed(track_rails(c_style)), "C-turn rails let the marble escape");
assert(y_top_collar + 10 < (peg_rows - 1) * peg_p + peg_edge, "lift runs off the top of the board");


// ===== fins =====

function hook_row(y) = floor((y + 6) / peg_p);

// Fin plane: u = out from the board face, v = height on the board
// A fin is [col, station heights, collar heights]; it hangs from one hook
// (plus the anti-tip pin below it) at the row of its highest item.
function fin_top_y(f) = max(concat(f[1], f[2]));
function fin_row(f) = hook_row(fin_top_y(f));
function fin_gusset(y) = track_d - open_w("open2")/2;
function fin_low(f) = min(concat(
    [for (y=f[1]) y - fin_base - fin_gusset(y)],
    [for (y=f[2]) y - 8 - track_d],
    [(fin_row(f) - 1) * peg_p - peg_hole_d/2 - 4]));

module hook_2d(r, th=tongue_h) {
    hy = r * peg_p;
    py = (r - 1) * peg_p;
    hr = peg_hole_d / 2;
    // tongue rests on the bottom of the hole, lip hangs behind the sheet
    translate([-(peg_sheet_t + hook_clr), hy - hr])
        square([peg_sheet_t + hook_clr + 0.01, th]);
    translate([-(peg_sheet_t + hook_clr + lip_t), hy - hr - lip_d])
        square([lip_t, lip_d + th]);
    // anti-tip pin in the hole below
    translate([-(peg_sheet_t + 0.5), py - hr])
        square([peg_sheet_t + 0.51, pin_h]);
}

// open2 station: comb under the rails, arm and gusset back to the strip,
// all below the marble
module fin_station_2d(y_t) {
    s = "open2";
    w = open_w(s);
    g = fin_gusset(y_t);
    difference() {
        union() {
            translate([track_d, y_t])
                polygon(concat(parting(s), [[w/2, -fin_base], [-w/2, -fin_base]]));
            translate([0, y_t - fin_base])
                square([track_d, fin_base - 10]);
            polygon([[0, y_t - fin_base - g], [0, y_t - fin_base], [g, y_t - fin_base]]);
        }
        translate([track_d, y_t]) {
            rail_holes(s);
            for (sx=[-1, 1])
                band_notch([sx * w/2, -fin_base + 4], 0);
        }
    }
}

// arm for a lift collar, half-lap slot open away from the board
module fin_collar_2d(y) {
    difference() {
        union() {
            translate([0, y - 8]) square([track_d + collar_hw, 16]);
            polygon([[0, y - 8 - track_d], [0, y - 8], [track_d, y - 8]]);
        }
        translate([track_d, y - sheet_th/2]) square([collar_hw + 1, sheet_th]);
    }
}

module fin_2d(f) {
    r = fin_row(f);
    low = fin_low(f);
    hook_2d(r);
    translate([0, low]) square([strip_w, r * peg_p + peg_hole_d/2 + 4 - low]);
    for (y=f[1]) fin_station_2d(y);
    for (y=f[2]) fin_collar_2d(y);
}

module keeper_at_2d(y_t) {
    translate([track_d, y_t]) open_keeper_2d("open2");
}

// fin plane -> board: u -> z (out), v -> y, extrusion -> x
module fin_place(col) {
    multmatrix([[0, 0, 1, col * peg_p - sheet_th/2], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]])
        children();
}

// ===== layout data =====

// [col, [station heights], [collar heights]] for every fin on the board
function straight_fins(k) = let(
        a = min(lvl_x0(k), lvl_x1(k)), b = max(lvl_x0(k), lvl_x1(k)),
        c0 = ceil(a / peg_p), c1 = floor(b / peg_p),
        cs = [for (c=[c0 : fin_every : c1]) c],
        cols = cs[len(cs) - 1] == c1 ? cs : concat(cs, [c1]))
    [for (c=cols) [c, [lvl_y_at(k, c * peg_p)], []]];

// C-turn k joins level k to level k+1
function c_side(k) = lvl_dir(k);
function c_xp(k) = lvl_x1(k);
function c_yin(k) = lvl_y(k) - q_straight * q_step;
function c_fin(k) = [c_xp(k) / peg_p + c_side(k) / 2,
    [c_yin(k) - joint_step, lvl_y(k + 1)], []];

// lift: pickup trough, exit leg + top bearing collar, channel collars,
// bottom bearing + motor collars
y_mid_collars = [for (y=[channel_y0 + 40 : 150 : channel_y1 - 40]) y];
lift_fins = concat(
    [[2, [y_pocket], []], [3, [y_pocket], []], [3, [y_ex - 1.5], [y_top_collar]],
     [collar_col, [], [y_bot_collar, y_motor_collar]]],
    [for (y=y_mid_collars) [collar_col, [], [y]]]);

all_fins = concat(
    [for (k=[0:lvl_n-1]) each straight_fins(k)],
    [for (k=[0:lvl_n-2]) c_fin(k)],
    lift_fins);

// every hole a fin hooks into; no two fins may share one
used_holes = [for (f=all_fins) each [[f[0], fin_row(f)], [f[0], fin_row(f) - 1]]];
function count_eq(v, x) = len([for (e=v) if (e == x) e]);
clashes = [for (h=used_holes) if (count_eq(used_holes, h) > 1) h];
echo(fins=len(all_fins), holes_used=len(used_holes),
    hole_clashes=clashes);
assert(len(clashes) == 0, "two fins want the same pegboard hole");
assert(max([for (h=used_holes) h[1]]) < peg_rows && min([for (h=used_holes) h[1]]) >= 0,
    "a fin hooks outside the board");


// ===== C-turn geometry =====

// Stations along a C-turn in its own frame: entry port at the origin,
// heading +x (a right-hand turn). [x, y, hx, hy, kind]
c_leg = peg_p;
c_xc = c_leg;
c_yc = -joint_step - c_rs;
c_stations = concat(
    [for (x=[0, c_leg/2]) [x, -joint_step, 1, 0, "in"]],
    [for (a=[90 : -22.5 : -90]) [c_xc + c_rs * cos(a), c_yc + c_rs * sin(a), sin(a), -cos(a), "arc"]],
    [for (x=[c_leg/2, 0]) [x, c_yc - c_rs, -1, 0, "out"]]);
c_offsets = rail_offsets(c_style);
// inner pair: toward the loop center (+x in the cross-section)
function c_has(kind, o) = kind == "arc" || (kind == "in") == (o[0] > 0);


// ===== 3D: board, track, lift =====

module board() {
    w = (peg_cols - 1) * peg_p + 2 * peg_edge;
    h = (peg_rows - 1) * peg_p + 2 * peg_edge;
    color("slategray")
        translate([-peg_edge, -peg_edge, -peg_sheet_t])
        difference() {
            cube([w, h, peg_sheet_t]);
            for (c=[0:peg_cols-1], r=[0:peg_rows-1])
                translate([peg_edge + c * peg_p, peg_edge + r * peg_p, -1])
                    cylinder(d=peg_hole_d, h=3, $fn=12);
        }
}

module rod(a, b) {
    hull() {
        translate(a) sphere(r=wire_r, $fn=8);
        translate(b) sphere(r=wire_r, $fn=8);
    }
}

// open2 rails along level k
module level_rails(k) {
    x0 = k == 0 ? x_lift_port : lvl_x0(k);
    x1 = k == lvl_n - 1 ? x_lift_port : lvl_x1(k);
    for (o=rail_offsets("open2"))
        rod([x0, lvl_y_at(k, x0) + o[1], track_d + o[0]],
            [x1, lvl_y_at(k, x1) + o[1], track_d + o[0]]);
}

function c_world(k, st, o) = let(s = c_side(k))
    [c_xp(k) + s * st[0] + s * st[3] * o[0] * 1, c_yin(k) + st[1] - st[2] * o[0], track_d + o[1]];

module c_rails(k) {
    for (i=[0:len(c_stations)-2], o=c_offsets)
        if (c_has(c_stations[i][4], o) && c_has(c_stations[i + 1][4], o))
            rod(c_world(k, c_stations[i], o), c_world(k, c_stations[i + 1], o));
}

module lift_3d() {
    n = ceil(lift_turns * 24);
    // coil, standing in front of the board
    color("silver")
        for (i=[0:n-1]) {
            t0 = -360 * lift_turns * i / n;
            t1 = -360 * lift_turns * (i + 1) / n;
            rod([x_axis + coil_r * cos(t0), y_coil0 - t0 / 360 * coil_pitch, track_d + coil_r * sin(t0)],
                [x_axis + coil_r * cos(t1), y_coil0 - t1 / 360 * coil_pitch, track_d + coil_r * sin(t1)]);
        }
    color("silver")
        for (o=rail_offsets("open2")) {
            // channel rails up the outside, bending over into level 0
            rod([x_ch, channel_y0, track_d + o[0]], [x_ch, channel_y1, track_d + o[0]]);
            rod([x_ch, channel_y1, track_d + o[0]], [x_lift_port, lvl_y(0) + o[1], track_d + o[0]]);
            // pickup trough from level n-1's port to just short of the coil
            rod([x_lift_port, y_pocket + o[1], track_d + o[0]],
                [x_lm - 6, y_pocket + o[1], track_d + o[0]]);
        }
    color("dimgray")
        translate([x_axis, y_motor_collar, track_d])
        rotate([-90, 0, 0])
        cylinder(d=rod_d, h=y_top_collar + sheet_th - y_motor_collar, $fn=12);
    color("orange")
        for (y=[y_coil0 - hub_h, y_coil1])
            translate([x_axis, y, track_d]) rotate([-90, 0, 0]) hub();
    color("black")
        translate([x_axis - n20_w/2, y_motor_collar - n20_l + 6, track_d - n20_t/2])
        cube([n20_w, n20_l, n20_t]);
    color("burlywood")
        for (f=all_fins, y=f[2])
            translate([0, y - sheet_th/2, 0])
            rotate([90, 0, 0]) mirror([0, 0, 1])
            linear_extrude(sheet_th) collar_2d(y);
}

module wall() {
    board();
    for (f=all_fins) {
        color("burlywood") fin_place(f[0]) linear_extrude(sheet_th) fin_2d(f);
        color("tan") fin_place(f[0]) linear_extrude(sheet_th) for (y=f[1]) keeper_at_2d(y);
    }
    color("silver") for (k=[0:lvl_n-1]) level_rails(k);
    color("silver") for (k=[0:lvl_n-2]) c_rails(k);
    lift_3d();
    % for (k=[0, lvl_n/2, lvl_n-1])
        translate([(lvl_x0(k) + lvl_x1(k)) / 2, lvl_y_at(k, (lvl_x0(k) + lvl_x1(k)) / 2), track_d])
            marble();
}


// ===== lift collars (horizontal plates, half-lapped into a fin) =====

// Collar plane: x along the board, second coord = z (out from the board)
function collar_is_end(y) = y < channel_y0 || y > channel_y1;
// Mid collars are an open2 comb turned on its side: "down" points away from
// the coil, so the edge between the channel rails dips clear of the marble.
module collar_2d(y) {
    fx = collar_col * peg_p;
    end = collar_is_end(y);
    w = open_w("open2");
    difference() {
        if (end)
            translate([x_axis - rod_d - 6, track_d - collar_hw])
                square([fx + 8 - (x_axis - rod_d - 6), 2 * collar_hw]);
        else
            // comb (x_c, y_c) -> collar (x_lm - y_c, track_d + x_c)
            multmatrix([[0, -1, 0, x_lm], [1, 0, 0, track_d], [0, 0, 1, 0], [0, 0, 0, 1]])
                difference() {
                    polygon(concat(parting("open2"), [[w/2, x_lm - fx - 8], [-w/2, x_lm - fx - 8]]));
                    rail_holes("open2");
                }
        if (end) {
            if (y == y_motor_collar)
                translate([x_axis - n20_w/2 - clr/2, track_d - n20_t/2 - clr/2])
                    square([n20_w + clr, n20_t + clr]);
            else
                translate([x_axis, track_d]) circle(d=rod_d + clr, $fn=24);
        }
        // half lap: open toward the board
        translate([fx - sheet_th/2, track_d - collar_hw - 1])
            square([sheet_th, collar_hw + 1]);
    }
}

// ===== C-turn flat jig (stations from wire_jig.scad) =====

c_base_h = rest_h(c_style);
module cturn_jig_base_2d() {
    difference() {
        offset(r=18) for (i=[0:len(c_stations)-2])
            hull() {
                translate([c_stations[i][0], c_stations[i][1]]) circle(r=0.1);
                translate([c_stations[i + 1][0], c_stations[i + 1][1]]) circle(r=0.1);
            }
        for (st=c_stations, x=station_tab_xs(c_style))
            translate([st[0], st[1]] + [st[3], -st[2]] * x)
                rotate([0, 0, atan2(st[3], st[2])])
                square([sheet_th, jig_tab_w], center=true);
    }
}

module cturn_jig_view() {
    color("burlywood") translate([0, 0, -sheet_th]) linear_extrude(sheet_th) cturn_jig_base_2d();
    for (st=c_stations)
        multmatrix([[st[3], 0, st[2], st[0]], [-st[2], 0, st[3], st[1]], [0, 1, 0, c_base_h], [0, 0, 0, 1]])
            station_3d(c_style, c_base_h);
    color("silver")
        for (i=[0:len(c_stations)-2], o=c_offsets)
            if (c_has(c_stations[i][4], o) && c_has(c_stations[i + 1][4], o))
                rod([c_stations[i][0], c_stations[i][1], c_base_h] + concat([c_stations[i][3], -c_stations[i][2]] * o[0], o[1]),
                    [c_stations[i + 1][0], c_stations[i + 1][1], c_base_h] + concat([c_stations[i + 1][3], -c_stations[i + 1][2]] * o[0], o[1]));
}


// ===== cut sheets =====

// pieces: [kind, arg, label]
fin_items = concat(
    [for (f=all_fins) ["fin", f, str("c", f[0], " r", fin_row(f))]],
    [for (f=all_fins, y=f[1]) ["keeper", y, ""]],
    [for (f=all_fins, y=f[2]) ["collar", y, ""]]);

// bounding box of a piece: [x0, y0, x1, y1] in its own 2D frame
function item_bb(it) =
    it[0] == "fin" ? let(f = it[1])
        [-(peg_sheet_t + hook_clr + lip_t), fin_low(f),
         track_d + max(open_w("open2")/2, len(f[2]) > 0 ? collar_hw : 0),
         max(concat([fin_row(f) * peg_p + peg_hole_d/2 + 4], [for (y=f[1]) y - 7], [for (y=f[2]) y + 8]))]
    : it[0] == "keeper" ? [track_d - open_w("open2")/2, it[1] - marble_r - 1,
         track_d + open_w("open2")/2, it[1] + keeper_top("open2")]
    : let(end = collar_is_end(it[1]), x0 = end ? x_axis - rod_d - 6 : x_ch - wire_r - jig_clr,
          hw = end ? collar_hw : open_w("open2")/2)
        [x0, track_d - hw, collar_col * peg_p + 8, track_d + hw];

module item_2d(it) {
    if (it[0] == "fin") fin_2d(it[1]);
    else if (it[0] == "keeper") keeper_at_2d(it[1]);
    else collar_2d(it[1]);
}

// Shelf packing, computed once: [sheet, x, y] per item
gap = 2;
function pack(items, i=0, sh=0, x=0, y=0, rowh=0, acc=[]) =
    i >= len(items) ? acc :
    let(bb = item_bb(items[i]), w = bb[2] - bb[0] + gap, h = bb[3] - bb[1] + gap,
        wrap = x + w > sheet_w,
        nx = wrap ? 0 : x, ny = wrap ? y + rowh : y, nrow = wrap ? h : max(rowh, h),
        newsheet = ny + h > sheet_h,
        sx = newsheet ? 0 : nx, sy = newsheet ? 0 : ny, srow = newsheet ? h : nrow,
        s2 = newsheet ? sh + 1 : sh)
    pack(items, i + 1, s2, sx + w, sy, srow, concat(acc, [[s2, sx - bb[0], sy - bb[1]]]));
fin_pack = pack(fin_items);
fin_sheets = fin_pack[len(fin_pack) - 1][0] + 1;
echo(cut_pieces=len(fin_items), fin_sheets=fin_sheets);

module sheet_2d(n, etch=false) {
    for (i=[0:len(fin_items)-1])
        if (fin_pack[i][0] == n)
            translate([fin_pack[i][1], fin_pack[i][2]]) {
                if (!etch) offset(delta=kerf/2) item_2d(fin_items[i]);
                else if (fin_items[i][2] != "")
                    translate([strip_w + 2, item_bb(fin_items[i])[1] + 3])
                        text(fin_items[i][2], size=label_size);
            }
}

// Hook test coupon: three fins with the tongue 0.3 mm smaller / nominal /
// larger, to try in your board; the hole in each tells them apart (1, 2, 3)
module hook_test_2d() {
    for (i=[0:2])
        translate([i * 20, 0]) offset(delta=kerf/2) difference() {
            union() {
                hook_2d(1, tongue_h + 0.3 * (i - 1));
                translate([0, -4]) square([14, peg_p + 12]);
            }
            for (j=[0:i]) translate([8, 6 + j * 5]) circle(d=2.5, $fn=12);
        }
}


if (wall_part == "wall") wall();
else if (wall_part == "fins") sheet_2d(sheet);
else if (wall_part == "fins_etch") sheet_2d(sheet, true);
else if (wall_part == "cturn_jig") cturn_jig_view();
else if (wall_part == "cturn_jig_base") offset(delta=kerf/2) cturn_jig_base_2d();
else if (wall_part == "cturn_jig_pieces") {
    items = [for (i=[0:len(c_stations)-1], p=[0:n_pieces(c_style)-1]) [p, i]];
    cw = cell_w(c_style);
    ch = cell_h(c_style, c_base_h);
    offset(delta=kerf/2)
        for (j=[0:len(items)-1])
            translate([(j % 8 + 0.5) * cw, floor(j / 8) * ch + c_base_h + sheet_th + 2])
                piece_2d(c_style, items[j][0], c_base_h);
}
else if (wall_part == "hook_test") hook_test_2d();
