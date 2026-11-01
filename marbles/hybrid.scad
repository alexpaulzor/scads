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
  SUPPORTS    plywood frames on tabs (glue them), each with a window the
              marble rolls through and a notch per rail position.
  RAILS       wire, wrapped around the supports -- the supports are the
              bending jig. On a straight each wire zig-zags: narrow at the
              bottom center leaving a support, wide toward the side arriving
              at the next, then around the support back to narrow. The
              marble sinks as the gauge opens, so level wire still rolls.

Modules meet at ports: marble 31.75 mm (1.25") off the board, x halfway
between hole columns, each module starting joint_step below the port it
enters by. The pegboard grid does the aligning.

  straight - 2 zig-zag wires, one per side, up to 11 columns long
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

// --- staples ---
staple_up = 7;
staple_slack = 0.6;
staple_hole_d = hook_d + 0.5;

// --- C-turn ---
c_drop = 12 * q_step;
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


// ===== straight module: zig-zag wires through framed supports =====
//
// Each support is a plywood frame with a window the marble rolls through.
// The marble center sits at the ring center at every support (arriving on
// W, leaving on N), so the hand-over is level and the drop is in the spans.
// Between two supports each wire runs straight from N (narrow, near bottom
// center) on one support to W (wide, out toward the side) on the next, so
// the marble sinks as the gauge opens even though the wire is level. At
// the support the wire passes through notch W, runs across the far face to
// notch N and sets off again: it wraps the support, and the support is the
// bending jig. A wire starts by poking through N on the first support
// (tail bent down on the near face) and ends by wrapping the last support
// and poking back through N (tail bent down). One wire per rail per module.

// Every support has sup_n notches evenly spaced on a ring of radius rail_rr
// around the marble center (where a resting marble touches a wire), offset
// half a step so bottom and top center stay free. The straight rides pair
// n_idx (N, counted out from bottom center) leaving a support and the pair
// wide_step further out (W) arriving; the rest are for extra wires:
// guards, roofs, tunnels. The innermost pair is too narrow to ride on (the
// marble would roll off sideways), so it is left for lacing.
// The window is groove_in bigger than the ring, so every notch is a groove
// shallower than half the wire: wires drop in from the window, no forcing.
sup_n = 16;
sup_step = 360 / sup_n;
n_idx = 1;
wide_step = 1;
seg_cols = 2;
a_n = sup_step / 2 + n_idx * sup_step;
a_w = a_n + wide_step * sup_step;
g_n = 2 * rail_rr * sin(a_n);
g_w = 2 * rail_rr * sin(a_w);
h_n = rail_rr * cos(a_n);
h_w = rail_rr * cos(a_w);
// on top of the sinking, the supports step down this slope
rail_slope = 0;
seg_drop = h_n - h_w + rail_slope * seg_cols * peg_p;
groove_in = 0.5;
sup_win = rail_rr + groove_in;
// lacing holes: one between each pair of neighboring notches, lace_dr
// further out than the notch ring, oversized so wire feeds through easily
lace_dr = 8;
lace_d = rail_d + 1.5;
// wood left between neighboring lacing holes and outside them
lace_web = 3;
sup_margin = 7;
sup_in = 3;
sup_ring = max(rail_rr + notch_r + sup_margin, rail_rr + lace_dr + lace_d / 2 + lace_web);
sup_side = sup_ring;
sup_top = sup_ring;
sup_bot = sup_ring;
function sup_lace(i) = let(a = i * sup_step, r = rail_rr + lace_dr) [r * sin(a), -r * cos(a)];
tail = 5;
tab_h = 5;
sup_tab_ys = [-sup_bot + 2, sup_top - 2 - tab_h];
function sup_notch(i) = let(a = a_n + i * sup_step) [rail_rr * sin(a), -rail_rr * cos(a)];
function sup_W(sx) = [sx * rail_rr * sin(a_w), -h_w];
function sup_N(sx) = [sx * rail_rr * sin(a_n), -h_n];

echo(sup_n=sup_n, notch_step=sup_step, g_n=g_n, g_w=g_w, h_n=h_n, h_w=h_w,
    seg_drop=seg_drop, span=seg_cols * peg_p, slope=seg_drop / (seg_cols * peg_p));
echo(window_r=sup_win, notch_ring=rail_rr, groove_depth=rail_rr + notch_r - sup_win,
    groove_mouth=2 * sqrt(notch_r * notch_r - groove_in * groove_in), lace_ring=rail_rr + lace_dr, lace_d=lace_d,
    lace_web_between=2 * (rail_rr + lace_dr) * sin(sup_step / 2) - lace_d,
    support_size=[track_d + sup_side, sup_bot + sup_top]);
assert(g_w - rail_d < marble_od - 1, "wide gauge lets the marble fall through");

// ===== layout =====

// ["S", c0, n, y_entry, dir]: columns c0+0.5 .. c0+n+0.5, marble y leaving
//   the first support; travels toward dir
// ["C", x_port, y_entry, side]: half loop bulging toward side (+1 right)
y_start = 27 * peg_p;

function s_k(m) = floor(m[2] / seg_cols) + 1;
function s_drop_of(m) = (s_k(m) - 1) * seg_drop;
function step_y(m) = m[0] == "S" ? m[3] - s_drop_of(m) : m[2] - (c_drop - joint_step);
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


function s_xa(m) = (m[1] + 0.5) * peg_p;
function s_xb(m) = (m[1] + m[2] + 0.5) * peg_p;
function s_dir(m) = m[4];
function s_x0(m) = m[4] > 0 ? s_xa(m) : s_xb(m);
// support k: center x, and marble height arriving (reference for its plate)
function sup_x(m, k) = s_x0(m) + s_dir(m) * (sup_in + k * (m[2] * peg_p - 2 * sup_in) / (s_k(m) - 1));
function sup_y(m, k) = m[3] - k * seg_drop;
// marble path, for markers
function s_y(m, x) = let(t = (x - s_x0(m)) * s_dir(m) / (m[2] * peg_p)) m[3] - t * s_drop_of(m);
// staples bracket the rail line near each end
function s_staples(m) =
    [for (c=[m[1] + 1, m[1] + m[2]]) [c, floor((s_y(m, c * peg_p) - h_w) / peg_p) + 1]];

// Support plate in its own plane: x = out from the board (z), y = up;
// marble arriving at (track_d, 0).
module support_2d() {
    difference() {
        union() {
            translate([sheet_th, -sup_bot]) square([track_d + sup_side - sheet_th, sup_bot + sup_top]);
            for (y=sup_tab_ys) translate([0, y]) square([sheet_th + 0.01, tab_h]);
        }
        translate([track_d, 0]) {
            circle(r=sup_win, $fn=96);
            for (i=[0:sup_n-1]) translate(sup_notch(i)) circle(r=notch_r, $fn=24);
            for (i=[0:sup_n-1]) translate(sup_lace(i)) circle(d=lace_d, $fn=24);
        }
    }
}

function s_bb(m) = let(ys = s_staples(m),
        ylo = min([for (k=[0:s_k(m)-1]) sup_y(m, k)]) - sup_bot,
        yhi = max([for (k=[0:s_k(m)-1]) sup_y(m, k)]) + sup_top)
    [s_xa(m) + 1, min(min([for (s=ys) (s[1] - 1) * peg_p - 7]), ylo - 3),
     s_xb(m) - 1, max(max([for (s=ys) s[1] * peg_p + 7]), yhi + 3)];

module s_back_2d(m) {
    b = s_bb(m);
    difference() {
        translate([b[0], b[1]]) square([b[2] - b[0], b[3] - b[1]]);
        for (s=s_staples(m), r=[s[1], s[1] - 1]) translate([s[0] * peg_p, r * peg_p]) circle(d=staple_hole_d, $fn=16);
        for (k=[0:s_k(m)-1], ty=sup_tab_ys)
            translate([sup_x(m, k) - (sheet_th + tab_clr) / 2, sup_y(m, k) + ty - tab_clr / 2])
                square([sheet_th + tab_clr, tab_h + tab_clr]);
    }
}

// one wire, side sx (+1 = away from the board)
function s_rail(m, sx) = let(
        d = s_dir(m), K = s_k(m),
        fw = sheet_th / 2 + rail_d / 2,
        P = function(k, q, face) [sup_x(m, k) + d * face * fw, sup_y(m, k) + q[1], track_d + q[0]],
        N = sup_N(sx), W = sup_W(sx))
    concat(
        // start: tail down the near face of support 0, through notch N
        [P(0, N + [0, -tail], -1), P(0, N, -1), P(0, N, 1)],
        // every later support: arrive at W, through, across the far face to N
        [for (k=[1:K-1]) each [P(k, W, -1), P(k, W, 1), P(k, N, 1)]],
        // end: back through N and tail down the near face
        [P(K - 1, N, -1), P(K - 1, N + [0, -tail], -1)]);
function s_rails(m) = [for (sx=[-1, 1]) s_rail(m, sx)];


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
        color("tan") for (k=[0:s_k(m)-1]) rib_at(sup_x(m, k), sup_y(m, k)) linear_extrude(sheet_th) support_2d();
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
            translate([-s_bb(m)[0], -s_bb(m)[1] + 2 * (sup_bot + sup_top) + 6]) s_back_2d(m);
            for (k=[0:s_k(m)-1])
                translate([2 + (k % 6) * (track_d + sup_side + 3), sup_bot + 2 + floor(k / 6) * (sup_bot + sup_top + 3)])
                    support_2d();
        } else {
            translate([-c_xc(m) + (c_s(m) > 0 ? c_leg + 2 : c_u1 + 4), -c_yc(m) + c_u1 + 4]) c_back_2d(m);
            translate([2 * c_u1 + 20, c_u1 + 4]) c_frame_2d();
            for (i=[0:len(c_rib_angles)-1])
                translate([2 * c_u1 + 40 + c_rib_zmax + i * (c_rib_zmax + 4), 4 - c_u0]) c_rib_profile_2d();
        }
    }
}

// ===== hook-in support: omega wire + tab, no back plate =====
//
// The support's back edge sits flat on the steel. A tab on that edge goes
// into one pegboard hole; a small wire OMEGA locks it:
//   - feet: behind the steel, turned outward past the hole edge
//   - legs: forward through the hole, one each side of the tab
//   - bridge: across the support, through a curved slot above the tab
// Hang it: push the omega's feet through the hole (legs pinched together),
// push the support's tab into the hole between the legs -- the tab wedges
// them apart so the feet can't slip back out -- with the bridge entering
// the slot mouth at the back edge, then push the support down om_drop.
// The bridge stays at one height while the support slides past it, so the
// slot is a cam: it pushes the bridge out (away from the board) past the
// seat by om_over, the point of most tension, then curls back toward the
// board into a pocket at the top. Seated, the legs pull the bridge toward
// the board and the support's weight pushes it up into the pocket, so it
// snaps in and stays; lift the support back over the peak to take it off.
//
// Hole rows are 1" apart but each span sinks seg_drop, so supports come in
// peg_variants versions with the tab 25.4 / peg_variants lower each time;
// after the last one the sequence repeats one hole row down.

om_d = 1.6;
om_r = om_d / 2;
om_drop = 2;
// legs slack at the slot mouth by om_pull; tight by om_pull when seated
om_pull = 1.5;
// over-center bump past the seat
om_over = 0.8;
// fraction of the drop where the bump peaks
om_peak = 0.6;
om_foot = 4;
peg_variants = 10;
peg_step = peg_p / peg_variants;
tab_out = 1.5;
// hole center relative to the ring center, variant 0
peg_y0 = 9;
// bridge seat above the hole center, and out from the board
om_rise = 6.5;
om_out = 4;
slot_w = om_d + 0.3;
// omega legs sit beside the tab
om_c = sheet_th / 2 + om_r + 0.05;
peg_tab_h = peg_hole_d - om_drop - 0.6;

function peg_hole_y(k) = peg_y0 - k * peg_step;
// bridge path in the support's frame, seated at (om_out, yb): x out from
// the board as the support slides down past it (u = 0 at the mouth)
function smooth(t) = t * t * (3 - 2 * t);
function om_cam_x(u) = u < om_peak
    ? (om_out - om_pull) + (om_pull + om_over) * smooth(u / om_peak)
    : (om_out + om_over) - om_over * smooth((u - om_peak) / (1 - om_peak));
function om_cam(yb, n=16) = [for (i=[0:n]) let(u = i / n) [om_cam_x(u), yb - om_drop + u * om_drop]];
echo(peg_step=peg_step, om_d=om_d, gap_beside_tab=(peg_hole_d - sheet_th) / 2,
    peg_hole_y=[for (k=[0:peg_variants-1]) peg_hole_y(k)]);
assert(om_c + om_r <= peg_hole_d / 2, "omega wire too thick to pass beside the tab");
assert(peg_hole_y(peg_variants - 1) - peg_hole_d / 2 - 3 > -sup_bot
    && peg_hole_y(0) + om_rise + slot_w / 2 + 3 < sup_top, "tab/slot range doesn't fit the support");

// Support in its own plane (x = out from the board, y = up), seated:
// back edge on the steel at x = 0, ring center at (track_d, 0), tab in the
// hole centered at y = peg_hole_y(k).
module peg_support_2d(k) {
    yh = peg_hole_y(k);
    yb = yh + om_rise;
    difference() {
        union() {
            translate([0, -sup_bot]) square([track_d + sup_side, sup_bot + sup_top]);
            // tab rests on the bottom of the hole
            translate([-(panel_t + tab_out), yh - peg_hole_d / 2 + 0.1])
                square([panel_t + tab_out + 0.01, peg_tab_h]);
        }
        translate([track_d, 0]) {
            circle(r=sup_win, $fn=96);
            for (i=[0:sup_n-1]) translate(sup_notch(i)) circle(r=notch_r, $fn=24);
            for (i=[0:sup_n-1]) translate(sup_lace(i)) circle(d=lace_d, $fn=24);
        }
        // bridge slot: straight in from the back edge, then the cam
        pts = concat([[-1, yb - om_drop]], om_cam(yb));
        for (i=[0:len(pts)-2])
            hull() for (q=[pts[i], pts[i + 1]]) translate(q) circle(d=slot_w, $fn=20);
    }
}

module peg_support_etch_2d(k) {
    translate([track_d - sup_ring + 4, -sup_bot + 3]) text(str(k), size=4);
}

// omega, in board coordinates around its hole (hole center at the origin,
// board face at z = 0), seated
function omega_pts(k) = let(zb = -(panel_t + om_r), yb = om_rise)
    [[-(om_c + om_foot), 0, zb], [-om_c, 0, zb], [-om_c, 0, om_r], [-om_c, yb, om_out],
     [om_c, yb, om_out], [om_c, 0, om_r], [om_c, 0, zb], [om_c + om_foot, 0, zb]];
echo(omega_wire_length=rail_len(omega_pts(0)));

module omega_3d(k) {
    color("gold") for (i=[0:len(omega_pts(k))-2])
        hull() for (q=[omega_pts(k)[i], omega_pts(k)[i + 1]]) translate(q) sphere(d=om_d, $fn=10);
}

// one support + omega hung in a patch of board
module peg_demo(k=0) {
    color("slategray") translate([-30, -40, -panel_t]) difference() {
        cube([60, 80, panel_t]);
        for (c=[-1:1], r=[-1:2]) translate([30 + c * peg_p, 40 + r * peg_p, -1]) cylinder(d=peg_hole_d, h=3, $fn=24);
    }
    // support plane: x -> z, y -> y, centered on x = 0
    translate([0, -peg_hole_y(k), 0])
        multmatrix([[0, 0, 1, -sheet_th / 2], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]])
        color("burlywood") linear_extrude(sheet_th) peg_support_2d(k);
    omega_3d(k);
    % translate([0, -peg_hole_y(k), track_d]) sphere(r=marble_r, $fn=48);
}

// all variants on one sheet
module peg_variants_2d(etch=false) {
    for (k=[0:peg_variants-1])
        translate([(k % 5) * (track_d + sup_side + panel_t + tab_out + 4) + panel_t + tab_out + 2,
                   floor(k / 5) * (sup_bot + sup_top + 4) + sup_bot + 2])
            if (etch) peg_support_etch_2d(k);
            else offset(delta=kerf / 2) peg_support_2d(k);
}

// Omega bending gauge: wrap the wire over the 3 mm tongue for the bridge,
// bend the legs at the first line, the feet at the second.
module omega_gauge_2d() {
    leg = norm([om_rise, om_out - om_r]) ;
    difference() {
        translate([-15, -5]) square([30, leg + panel_t + 20]);
        // slot the legs drop into, one tab thickness apart
        for (sx=[-1, 1]) translate([sx * om_c - (om_d + 0.2) / 2, -5.01]) square([om_d + 0.2, leg + 5]);
    }
}

hy_part = "wall";
hy_mod = 0;
if (hy_part == "wall") wall();
else if (hy_part == "module") module_parts_2d(layout[hy_mod]);
else if (hy_part == "module_3d") module_3d(layout[hy_mod]);
else if (hy_part == "jigs") jigs_2d();
else if (hy_part == "support") offset(delta=kerf / 2) support_2d();
else if (hy_part == "peg_support") offset(delta=kerf / 2) peg_support_2d(0);
else if (hy_part == "peg_variants") peg_variants_2d();
else if (hy_part == "peg_variants_etch") peg_variants_2d(etch=true);
else if (hy_part == "peg_demo") peg_demo(0);
