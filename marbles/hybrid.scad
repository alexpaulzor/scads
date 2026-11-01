/*

Hybrid marble run for 1" grid steel pegboard: laser-cut 3 mm plywood sets
every position, wire does the rolling and the hanging. No solder, no snap
fits, no plywood touching the pegboard.

  BACK PLATE  flat on the pegboard; every module has one. Its holes line up
              with pegboard holes.
  STAPLES     wire U-hooks through the back plate into the pegboard: the
              top leg hooks up behind the steel, the bottom leg stops it
              tipping. The bridge holds the plate flat to the board. Tilt,
              hook, swing down -- like any pegboard hook.
  RIBS        stand out from the back plate on tabs (glue them). Each one
              has a notch for every rail, open toward the marble, so rails
              just drop in.
  RAILS       wire. Lay them in the notches; bend each end 90 deg away from
              the marble over the end rib's outer face. The rib is the bend
              jig, and the two end hooks keep the rail from sliding.
              Straights need no bending at all.

Modules meet at ports: marble 31.75 mm (1.25") off the board, x halfway
between hole columns, each module starting joint_step below the port it
enters by. The pegboard grid does the aligning.

  straight - 2 wire rails, up to 11 columns long
  C-turn   - 4 wire rails (enclosed) bent around a laser-cut form,
             threaded through framed ribs: drops 2" and reverses

  openscad -o hybrid.png marbles/hybrid.scad
  openscad -o mod0.svg  -D 'hy_part="module"' -D 'hy_mod=0' marbles/hybrid.scad
  openscad -o jigs.svg  -D 'hy_part="jigs"' marbles/hybrid.scad

Measure first: rail_d / hook_d (12 AWG copper and 14 ga steel are both about
2.05 mm; 12 ga steel is about 2.7 mm), peg_hole_d, panel_t, sheet_th, kerf.

*/

// --- pegboard ---
peg_p = 25.4;
peg_cols = 26;
peg_rows = 30;
peg_hole_d = 6.35;
panel_t = 0.9;
peg_edge = 12.7;

// --- stock ---
sheet_th = 3;
kerf = 0.1;
max_part = 300;
tab_clr = 0.1;

// --- marble + wire ---
marble_od = 16.2;
marble_r = marble_od / 2;
rail_d = 2.05;
hook_d = 2.05;
gauge = 10;
rail_rr = marble_r + rail_d / 2;
floor_a = asin(gauge / 2 / rail_rr);
rail_h = rail_rr * cos(floor_a);
notch_r = rail_d / 2 + 0.15;
// marble clearance kept by every rib
mclr = 0.5;

// --- track standard ---
track_d = 31.75;
joint_step = 0.5;
run_clr = 1.0;
q_step = 6.35;
// rails stop this far short of a port, ends bent away from the marble
rail_gap = 1;
end_rib_in = 4;
bend_leg = 5;

// --- ribs ---
rib_wall = 4;
comb_depth = 14;
gusset = 14;
strip_w = 4;
rib_pitch_cols = 2;

// --- staples ---
staple_up = 7;
staple_slack = 0.6;
staple_hole_d = hook_d + 0.5;

// --- C-turn ---
c_drop = 8 * q_step;
c_rs = (c_drop - joint_step - run_clr) / 2;
c_ri = c_rs - rail_h;
c_ro = c_ri + 2 * rail_h + run_clr;
c_leg = 6;
c_rib_angles = [60, 90, 120];
c_win_r = marble_r + 0.6;
c_rib_zmax = track_d + c_win_r + 5;
c_u0 = c_ri - notch_r - rib_wall;
c_u1 = c_ro + notch_r + rib_wall;
// bending forms: spring-back opens the wire up, so the form is smaller (guess)
spring_k = 0.9;

echo(rail_rr=rail_rr, floor_a=floor_a, rail_h=rail_h);
echo(c_rs=c_rs, c_ri=c_ri, c_ro=c_ro, c_drop=c_drop);
assert(c_ri - notch_r - rib_wall > 4, "C-turn too tight for its ribs");


// ===== layout =====

// ["S", c0, n, y_entry, dir]: columns c0+0.5 .. c0+n+0.5, marble y at the
//   entry end; drops q_straight * q_step toward dir
// ["C", x_port, y_entry, side]: half loop bulging toward side (+1 right)
q_straight = 2;
s_drop = q_straight * q_step;
y_start = 27 * peg_p;

function step_y(m) = m[0] == "S" ? m[3] - s_drop : m[2] - (c_drop - joint_step);
function chain(specs, y, acc=[]) =
    len(acc) == len(specs) ? acc :
    let(sp = specs[len(acc)], m = sp[0] == "S"
            ? ["S", sp[1], sp[2], y, sp[3]]
            : ["C", sp[1], y, sp[2]])
    chain(specs, step_y(m) - joint_step, concat(acc, [m]));

// three switchback levels across both panels
layout = chain([
    ["S", 2, 10, 1], ["S", 12, 10, 1], ["C", 22.5 * peg_p, 1],
    ["S", 12, 10, -1], ["S", 2, 10, -1], ["C", 2.5 * peg_p, -1],
    ["S", 2, 10, 1], ["S", 12, 10, 1], ["C", 22.5 * peg_p, 1],
    ["S", 12, 10, -1], ["S", 2, 10, -1]], y_start);


// ===== straight module =====

function s_xa(m) = (m[1] + 0.5) * peg_p;
function s_xb(m) = (m[1] + m[2] + 0.5) * peg_p;
function s_ya(m) = m[4] > 0 ? m[3] : m[3] - s_drop;
function s_yb(m) = m[4] > 0 ? m[3] - s_drop : m[3];
function s_y(m, x) = s_ya(m) + (s_yb(m) - s_ya(m)) * (x - s_xa(m)) / (s_xb(m) - s_xa(m));
function s_rib_xs(m) = concat(
    [s_xa(m) + end_rib_in],
    [for (k=[rib_pitch_cols : rib_pitch_cols : m[2] - 1]) s_xa(m) + k * peg_p],
    [s_xb(m) - end_rib_in]);
// staple: [hole column, upper hole row]
// the staple's two holes bracket the rail line (the plate sits behind the
// marble, so it can run above the rails)
function s_staples(m) =
    [for (c=[m[1] + 1, m[1] + m[2]]) [c, floor((s_y(m, c * peg_p) - rail_h) / peg_p) + 1]];

// Rib in its own plane: x = out from the board (z), y = up; marble center
// at (track_d, 0).
function dip_y(x) = let(mr = marble_r + mclr) abs(x) < mr ? -sqrt(mr * mr - x * x) : 1e9;
function open_parting(step=0.5) = let(w = gauge / 2 + notch_r + rib_wall)
    concat([[-w, -rail_h]],
        [for (x=[-gauge / 2 : step : gauge / 2]) [x, min(-rail_h, dip_y(x))]],
        [[w, -rail_h]]);
tab_ys_open = [-comb_depth + 0.5, -comb_depth - gusset + 0.5];
tab_h = 5;

module open_rib_2d() {
    w = gauge / 2 + notch_r + rib_wall;
    difference() {
        union() {
            translate([track_d, 0])
                polygon(concat(open_parting(), [[w, -comb_depth], [-w, -comb_depth]]));
            translate([sheet_th, -comb_depth]) square([track_d - w - sheet_th + 0.01, 6]);
            polygon([[sheet_th, -comb_depth - gusset], [sheet_th, -comb_depth],
                [sheet_th + gusset, -comb_depth]]);
            translate([sheet_th, -comb_depth - gusset]) square([strip_w, gusset + 6]);
            for (y=tab_ys_open) translate([0, y]) square([sheet_th + 0.01, tab_h]);
        }
        for (sx=[-1, 1]) translate([track_d + sx * gauge / 2, -rail_h]) circle(r=notch_r, $fn=24);
    }
}

module s_back_2d(m) {
    ys = s_staples(m);
    y0 = min(min([for (s=ys) (s[1] - 1) * peg_p - 7]),
             min(s_ya(m), s_yb(m)) - comb_depth - gusset - 3);
    y1 = max(max([for (s=ys) s[1] * peg_p + 7]), max(s_ya(m), s_yb(m)) - comb_depth + 9);
    difference() {
        translate([s_xa(m) + 1, y0]) square([s_xb(m) - s_xa(m) - 2, y1 - y0]);
        for (s=ys, r=[s[1], s[1] - 1]) translate([s[0] * peg_p, r * peg_p]) circle(d=staple_hole_d, $fn=16);
        for (x=s_rib_xs(m), ty=tab_ys_open)
            translate([x - (sheet_th + tab_clr) / 2, s_y(m, x) + ty - tab_clr / 2])
                square([sheet_th + tab_clr, tab_h + tab_clr]);
    }
}

function s_rails(m) = [for (sx=[-1, 1]) let(z = track_d + sx * gauge / 2,
        xa = s_xa(m) + rail_gap, xb = s_xb(m) - rail_gap)
    [[xa, s_y(m, xa) - rail_h - bend_leg, z], [xa, s_y(m, xa) - rail_h, z],
     [xb, s_y(m, xb) - rail_h, z], [xb, s_y(m, xb) - rail_h - bend_leg, z]]];


// ===== C-turn module =====

function c_xp(m) = m[1];
function c_s(m) = m[3];
function c_xc(m) = m[1] + m[3] * c_leg;
function c_yc(m) = m[2] - c_rs;
function c_dir(m, a) = [m[3] * sin(a), cos(a)];

// C rib in its plane: x = out from the board, y = u, radial distance from
// the loop center. Window around the marble path, rails in notches that
// open into the window.
c_tab_us = [c_u0 + 1, c_u1 - 1 - tab_h];
module c_rib_profile_2d() {
    difference() {
        union() {
            translate([sheet_th, c_u0]) square([c_rib_zmax - sheet_th, c_u1 - c_u0]);
            for (u=c_tab_us) translate([0, u]) square([sheet_th + 0.01, tab_h]);
        }
        hull() for (u=[c_rs, c_rs + run_clr]) translate([track_d, u]) circle(r=c_win_r, $fn=48);
        for (u=[c_ri, c_ro], sx=[-1, 1]) translate([track_d + sx * gauge / 2, u]) circle(r=notch_r, $fn=24);
    }
}

// End frame: carries both legs, top and bottom, in one piece
module c_frame_2d() {
    c_rib_profile_2d();
    mirror([0, 1]) c_rib_profile_2d();
    translate([sheet_th, -c_u0 - 0.01]) square([c_rib_zmax - sheet_th, 2 * c_u0 + 0.02]);
    for (u=[-c_u0 + 2, c_u0 - 2 - tab_h]) translate([0, u]) square([sheet_th + 0.01, tab_h]);
}
c_frame_tab_us = concat(c_tab_us, [for (u=c_tab_us) -u - tab_h], [-c_u0 + 2, c_u0 - 2 - tab_h]);

// staple: hole column just inside the turn, rows bracketing the center
function c_staple(m) = [round((c_xc(m) + m[3] * 7) / peg_p), floor(c_yc(m) / peg_p) + 1];

module c_back_2d(m) {
    s = c_s(m);
    st = c_staple(m);
    difference() {
        union() {
            translate([s > 0 ? c_xp(m) + 1 : c_xc(m), c_yc(m) - c_u1 - 3])
                square([abs(c_xc(m) - c_xp(m)) - 1, 2 * (c_u1 + 3)]);
            translate([c_xc(m), c_yc(m)])
                intersection() {
                    circle(r=c_u1 + 3, $fn=96);
                    translate([s > 0 ? 0 : -(c_u1 + 3), -(c_u1 + 3)]) square([c_u1 + 3, 2 * (c_u1 + 3)]);
                }
        }
        for (r=[st[1], st[1] - 1]) translate([st[0] * peg_p, r * peg_p]) circle(d=staple_hole_d, $fn=16);
        // frame mortises
        for (u=c_frame_tab_us)
            translate([c_xp(m) + s * end_rib_in - (sheet_th + tab_clr) / 2, c_yc(m) + u - tab_clr / 2])
                square([sheet_th + tab_clr, tab_h + tab_clr]);
        // radial rib mortises
        for (a=c_rib_angles, u=c_tab_us)
            translate([c_xc(m), c_yc(m)]) rotate([0, 0, -s * a])
                translate([-(sheet_th + tab_clr) / 2, u - tab_clr / 2])
                square([sheet_th + tab_clr, tab_h + tab_clr]);
    }
}

// rails: [r, z] for each of the 4; legs, 180 deg arc, legs; ends bent
// away from the marble path
function c_rail(m, r, z, away) = let(s = c_s(m), xa = c_xp(m) + s * rail_gap,
        xc = c_xc(m), yc = c_yc(m))
    concat(
        [[xa, yc + r + away * bend_leg, z], [xa, yc + r, z]],
        [for (a=[0 : 7.5 : 180]) [xc + s * r * sin(a), yc + r * cos(a), z]],
        [[xa, yc - r, z], [xa, yc - r - away * bend_leg, z]]);
function c_rails(m) = [for (sx=[-1, 1]) each [
    c_rail(m, c_ri, track_d + sx * gauge / 2, -1),
    c_rail(m, c_ro, track_d + sx * gauge / 2, 1)]];


// ===== staples =====

// 3D wire staple at hole column c, upper row r
module staple(c, r) {
    x = c * peg_p;
    zf = sheet_th + hook_d / 2;
    zb = -panel_t - staple_slack - hook_d / 2;
    color("silver") {
        wire([x, r * peg_p, zf], [x, (r - 1) * peg_p, zf]);
        wire([x, r * peg_p, zf], [x, r * peg_p, zb]);
        wire([x, r * peg_p, zb], [x, r * peg_p + staple_up, zb]);
        wire([x, (r - 1) * peg_p, zf], [x, (r - 1) * peg_p, zb - 3]);
    }
}
staple_leg = sheet_th + panel_t + staple_slack + hook_d;

module wire(a, b, d=rail_d) {
    hull() {
        translate(a) sphere(d=d, $fn=8);
        translate(b) sphere(d=d, $fn=8);
    }
}
module polywire(pts) {
    for (i=[0:len(pts)-2]) wire(pts[i], pts[i + 1]);
}


// ===== 3D placement =====

// rib plane -> board: rib x -> z, rib y -> y, thickness along board x
module rib_at(x, y) {
    multmatrix([[0, 0, 1, x - sheet_th / 2], [0, 1, 0, y], [1, 0, 0, 0], [0, 0, 0, 1]])
        children();
}
// radial rib: rib y (u) along dir(a) from the loop center
module rib_radial(m, a) {
    d = c_dir(m, a);
    t = [d[1], -d[0]];
    multmatrix([[0, d[0], t[0], c_xc(m) - t[0] * sheet_th / 2],
                [0, d[1], t[1], c_yc(m) - t[1] * sheet_th / 2],
                [1, 0, 0, 0], [0, 0, 0, 1]])
        children();
}

module module_3d(m) {
    if (m[0] == "S") {
        color("burlywood") linear_extrude(sheet_th) s_back_2d(m);
        color("tan") for (x=s_rib_xs(m)) rib_at(x, s_y(m, x)) linear_extrude(sheet_th) open_rib_2d();
        color("silver") for (r=s_rails(m)) polywire(r);
        for (s=s_staples(m)) staple(s[0], s[1]);
    } else {
        color("burlywood") linear_extrude(sheet_th) c_back_2d(m);
        color("tan") {
            rib_at(c_xp(m) + c_s(m) * end_rib_in, c_yc(m)) linear_extrude(sheet_th) c_frame_2d();
            for (a=c_rib_angles) rib_radial(m, a) linear_extrude(sheet_th) c_rib_profile_2d();
        }
        color("silver") for (r=c_rails(m)) polywire(r);
        staple(c_staple(m)[0], c_staple(m)[1]);
    }
}

module board() {
    w = (peg_cols - 1) * peg_p + 2 * peg_edge;
    h = (peg_rows - 1) * peg_p + 2 * peg_edge;
    color("slategray")
        translate([-peg_edge, -peg_edge, -panel_t])
        difference() {
            cube([w, h, panel_t]);
            for (c=[0:peg_cols-1], r=[0:peg_rows-1])
                translate([peg_edge + c * peg_p, peg_edge + r * peg_p, -1])
                    cylinder(d=peg_hole_d, h=3, $fn=12);
        }
}

module wall() {
    board();
    for (m=layout) module_3d(m);
    % for (i=[0, 3, 6]) let(m = layout[i])
        translate([(s_xa(m) + s_xb(m)) / 2, s_y(m, (s_xa(m) + s_xb(m)) / 2), track_d])
            sphere(r=marble_r, $fn=48);
}


// ===== checks =====

// back plate bounding boxes [x0, y0, x1, y1]
function s_bb(m) = let(ys = s_staples(m))
    [s_xa(m) + 1, min(min([for (s=ys) (s[1] - 1) * peg_p - 7]), min(s_ya(m), s_yb(m)) - comb_depth - gusset - 3),
     s_xb(m) - 1, max(max([for (s=ys) s[1] * peg_p + 7]), max(s_ya(m), s_yb(m)) - comb_depth + 9)];
function c_bb(m) = let(x0 = c_xp(m) + c_s(m), x1 = c_xc(m) + c_s(m) * (c_u1 + 3))
    [min(x0, x1), c_yc(m) - c_u1 - 3, max(x0, x1), c_yc(m) + c_u1 + 3];
function bb(m) = m[0] == "S" ? s_bb(m) : c_bb(m);
function overlap(a, b) = a[0] < b[2] && b[0] < a[2] && a[1] < b[3] && b[1] < a[3];
plate_clashes = [for (i=[0:len(layout)-1], j=[0:len(layout)-1])
    if (i < j && overlap(bb(layout[i]), bb(layout[j]))) [i, j]];
echo(plate_clashes=plate_clashes,
    plate_sizes=[for (m=layout) let(b = bb(m)) [round(b[2] - b[0]), round(b[3] - b[1])]]);
assert(len(plate_clashes) == 0, "two back plates overlap");
assert(max([for (m=layout) let(b = bb(m)) max(b[2] - b[0], b[3] - b[1])]) <= max_part,
    "a back plate is bigger than the stock");

function rail_len(p) = len(p) < 2 ? 0 : norm(p[1] - p[0]) + rail_len([for (i=[1:len(p)-1]) p[i]]);
staple_holes = [for (m=layout) each
    (m[0] == "S" ? [for (s=s_staples(m)) each [[s[0], s[1]], [s[0], s[1] - 1]]]
                 : [[c_staple(m)[0], c_staple(m)[1]], [c_staple(m)[0], c_staple(m)[1] - 1]])];
function count_eq(v, x) = len([for (e=v) if (e == x) e]);
echo(modules=len(layout), staples=len(staple_holes) / 2,
    hole_clashes=[for (h=staple_holes) if (count_eq(staple_holes, h) > 1) h]);
echo(straight_rail_lengths=[for (m=layout) if (m[0] == "S") round(rail_len(s_rails(m)[0]))],
    c_rail_lengths=[for (r=c_rails(layout[2])) round(rail_len(r))]);
echo(bottom_port_y=step_y(layout[len(layout) - 1]), lowest_staple_row=min([for (h=staple_holes) h[1]]));
assert(min([for (h=staple_holes) h[1]]) >= 0, "a staple falls off the bottom of the board");
assert(max([for (m=layout) if (m[0] == "S") m[2]]) * peg_p <= max_part, "a straight is longer than the stock");


// ===== jigs =====

// Staple bender: two pins (M4 bolts or nails) set the 1" bridge; the slot
// sets the hook leg length -- push a leg in to the bottom and bend over.
pin_d = 4;
module staple_jig_2d() {
    difference() {
        square([60, 40]);
        for (sx=[-1, 1]) translate([30 + sx * (peg_p / 2 - pin_d / 2 - hook_d / 2), 26]) circle(d=pin_d, $fn=24);
        // hook leg gauge
        translate([8, -0.01]) square([hook_d + 0.3, staple_leg]);
        // anti-tip leg gauge (longer)
        translate([48, -0.01]) square([hook_d + 0.3, staple_leg + 3]);
    }
}

// C-turn rail form: wrap the wire around it; glue a 3-layer stack (middle
// layer is the groove)
module c_form_2d(r, layer) {
    rf = (r - rail_d / 2) * spring_k;
    difference() {
        union() {
            circle(r=layer == 1 ? rf : rf + 3, $fn=128);
            // handle tab to clamp in a vise
            translate([-rf - 3, -8]) square([rf + 3, 16]);
        }
        circle(d=6.4, $fn=24);
        // wire end anchor
        if (layer == 1) translate([0, rf - 1]) square([3, 3], center=true);
    }
}
echo(c_form_radii=[for (r=[c_ri, c_ro]) (r - rail_d / 2) * spring_k], spring_k=spring_k);

module jigs_2d() {
    offset(delta=kerf / 2) {
        staple_jig_2d();
        for (i=[0:2]) {
            translate([110 + i * 35, 30]) c_form_2d(c_ri, i);
            translate([110 + i * 75, 110]) c_form_2d(c_ro, i);
        }
    }
}


// ===== cut sheet for one module =====

module module_parts_2d(m) {
    offset(delta=kerf / 2) {
        if (m[0] == "S") {
            translate([-s_xa(m), -min(s_ya(m), s_yb(m)) + comb_depth + gusset + 40]) s_back_2d(m);
            for (i=[0:len(s_rib_xs(m))-1])
                translate([i * 52 + 2, comb_depth + gusset + 2]) open_rib_2d();
        } else {
            translate([-c_xc(m) + (c_s(m) > 0 ? c_leg + 2 : c_u1 + 4), -c_yc(m) + c_u1 + 4]) c_back_2d(m);
            translate([2 * c_u1 + 20, c_u1 + 4]) c_frame_2d();
            for (i=[0:len(c_rib_angles)-1])
                translate([2 * c_u1 + 40 + c_rib_zmax + i * (c_rib_zmax + 4), 4 - c_u0]) c_rib_profile_2d();
        }
    }
}

hy_part = "wall";
hy_mod = 0;
if (hy_part == "wall") wall();
else if (hy_part == "module") module_parts_2d(layout[hy_mod]);
else if (hy_part == "module_3d") module_3d(layout[hy_mod]);
else if (hy_part == "jigs") jigs_2d();
