// The rocking ball lift as built (from the video) plus the parts in
// lift_parts.py, animated. View > Animate, FPS 10, Steps 60; one cycle =
// one turn of the cam = every ball up one hole.
//
// As built: F (MDF sieve strip) on a 2020 that hangs from an 8 mm shaft in
// pillow blocks on a fixed horizontal 2020; M (the mirrored strip) on its
// own 2020, sliding beside F; a backing plate behind F (cardboard in the
// video, lift_backing_plate here).
// Added (lift_parts.py, wood colours): cam arm on F's 2020 with the pivot
// bearing and cam slot; cam disc on a fixed shaft; M's link and its anchor;
// keepers on F's M5 bolts lapping M's edge.
// Proposed, not designed yet (green, see-through): feed ramp + fixed trough
// at the bottom, exit chute + fixed hopper with an overflow lip at the top.
//
// Axes: x across, y toward the viewer, z up. Rig frame = before rocking.

/* [Animation] */
t_fixed = -1;
t = t_fixed >= 0 ? t_fixed : $t;
show_proposed = true;
section_view = false;

/* [Strips] */
L = 300; W = 46; T = 3.2;
hole_d = 20; pitch = 30; n_holes = 10;
m5_u = [30, 90, 150, 210, 270];
ball_d = 19.05;
drop = 2;

/* [Drive] */
tilt_fwd = 12; tilt_back = 12;
cam_r = 10; link = 100; pivot_up = 45; arm_trim = 0.98805;
guard_gap = 4; m_gap = 0.45;

// ---------- geometry (same as lift_demo.scad / lift_parts.py)
lift = pitch + 2 * drop;
s_span = sin(tilt_fwd) + sin(tilt_back);
arm = arm_trim * lift / s_span;
cam_arm = 2 * cam_r / s_span;
yG = -guard_gap;
yB_rest = yG + ball_d / 2;
yM0 = yB_rest + ball_d / 2 + m_gap;
yB_ride = T + ball_d / 2;
yBK = yG - T;                                   // backing plate back face; F's 2020 front face
Mbase = [62, yM0 + T + 10, L + 15];             // M's link pin (M5 + T-nut in the right side slot)
P = [-6, Mbase[1] + arm, Mbase[2] + pivot_up];  // pivot, in the cam arm's plane
slotC = P + [0, cam_arm, 0];
Ccam = [-6, slotC[1], P[2] - cam_arm * (sin(tilt_fwd) - sin(tilt_back)) / 2];
A = Mbase + [0, 0, link];

function pin_at(tt) = Ccam + [0, cam_r * sin(360 * tt), -cam_r * cos(360 * tt)];
function tilt_at(tt) = asin((P[2] - pin_at(tt)[2]) / cam_arm);
pin = pin_at(t); tilt = tilt_at(t);
function rotx(v, a) = [v[0], v[1] * cos(a) - v[2] * sin(a), v[1] * sin(a) + v[2] * cos(a)];
function world(v, tl) = P + rotx(v - P, -tl);
function m_slide(tl) = let(w = world(Mbase, tl) - A, u = rotx([0, 0, 1], -tl), b = w * u, c = w * w - link * link) -b - sqrt(b * b - c);
zs = [for (i = [0:72]) m_slide(tilt_at(i / 72))];
zs_min = min(zs); zs_max = max(zs);
zM = -drop + (m_slide(tilt) - zs_min);
Mpin0 = Mbase + [0, 0, zs_min + drop];
echo(t = t, tilt = tilt, M_rel = zM, stroke = zs_max - zs_min);

function hole_z(i) = pitch / 2 + i * pitch;
function rest_z(i) = hole_z(i) - (hole_d - ball_d) / 2;
function sm(e0, e1, x) = let(s = min(1, max(0, (x - e0) / (e1 - e0)))) s * s * (3 - 2 * s);

// ---------- helpers
module t2020(len) { color("silver") difference() { cube([20, 20, len]);
    for (f = [[0, 10], [20, 10], [10, 0], [10, 20]]) translate([f[0] - 3.1, f[1] - 3.1, -1]) cube([6.2, 6.2, len + 2]); } }
module t2020x(len) { translate([0, 0, 20]) rotate([0, 90, 0]) t2020(len); }      // along x
module plate_yz(x0, th) { translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(th) children(); }   // 2D (y, z) -> slab at x0..x0+th
module axle(p, len, d = 8) { color("dimgray") translate(p) rotate([0, 90, 0]) cylinder(d = d, h = len, center = true, $fn = 24); }

// strips in their own 2D frame (u along, v across)
module strip2d(ball_holes = true, ends_only = false) {
    difference() {
        square([L, W]);
        for (i = [0:n_holes - 1]) if (ball_holes || (ends_only && (i == 0 || i == n_holes - 1)))
            translate([pitch / 2 + i * pitch, 30]) circle(d = hole_d, $fn = 64);
        for (u = m5_u) translate([u, 10]) circle(d = 5, $fn = 24);
    }
}
module on_xz(y0, mirror_x = false) {     // strip u -> z, v -> x, thickness T toward +y from y0
    translate([mirror_x ? 60 : 0, y0 + T, 0]) mirror([mirror_x ? 1 : 0, 0, 0]) rotate([90, 0, 0]) rotate([0, 0, 90]) mirror([0, 1, 0]) linear_extrude(T) children();
}

// cam arm outline in (y, z), matches lift_parts.cam_arm
module cam_arm2d() {
    difference() {
        offset(r = 3) offset(delta = -3) union() {
            translate([yBK - 20, L + 15]) square([26, 62]);
            translate([P[1], P[2]]) circle(r = 18, $fn = 64);
            translate([slotC[0] == undef ? slotC[1] - 22 : slotC[1] - 22, slotC[2] - 11]) square([44, 22]);
            hull() { translate([yBK - 10, L + 55]) circle(r = 9); translate([P[1], P[2]]) circle(r = 9); }
            hull() { translate([P[1], P[2]]) circle(r = 9); translate([slotC[1], slotC[2]]) circle(r = 9); }
        }
        translate([P[1], P[2]]) circle(d = 22, $fn = 64);
        for (z = [L + 25, L + 45]) translate([yBK - 10, z]) circle(d = 5, $fn = 24);
        hull() for (s = [-1, 1]) translate([slotC[1] + s * cam_r, slotC[2]]) circle(d = 5.5, $fn = 24);
    }
}

// ---------- balls (rig frame)
module ball(p) { translate(p) color("steelblue") sphere(d = ball_d, $fn = 32); }
module ball_k(k) {
    pick = sm(0.0, 0.06, t); give = sm(0.5, 0.56, t);
    zride = rest_z(k) + zM;
    z = t < 0.5 ? max(rest_z(k), zride) : max(rest_z(k + 1), zride);
    y = yB_rest + (yB_ride - yB_rest) * (pick - give);
    if (k + (t >= 0.5 ? 1 : 0) <= n_holes - 1) ball([30, y, z]);
}
module balls() {
    for (k = [0:n_holes - 2]) ball_k(k);
    f = sm(0.6, 0.95, t);
    ball([30, yB_rest - 55 * (1 - f), rest_z(0) + 14 * (1 - f)]);                 // rolling in down the feed ramp
    if (t >= 0.56) ball([30, yB_rest - 55 * f, rest_z(n_holes - 1) - 12 * f]);    // rolling out down the exit chute
}

// ---------- the rocking rig (rig frame)
module rig() {
    // F, washers, backing plate, F's 2020 (bolt stack front to back)
    color("burlywood") on_xz(0) strip2d();
    for (u = m5_u) color("dimgray") translate([10, yG, u]) rotate([-90, 0, 0]) cylinder(d = 10, h = guard_gap, $fn = 6);
    color("antiquewhite") on_xz(yBK) strip2d(false, true);
    translate([0, yBK - 20, -10]) t2020(L + 65);
    // keepers on the top and bottom bolts: nut stack + lap plate over M's edge
    for (u = [m5_u[0], m5_u[4]]) {
        color("dimgray") translate([10, T, u]) rotate([-90, 0, 0]) cylinder(d = 9, h = yM0 + T + 0.5 - T, $fn = 6);
        color("peru") translate([4, yM0 + T + 0.5, u - 11]) cube([15.5, T, 22]);
    }
    // M on its 2020, sliding; link pin in its right side slot near the top
    translate([0, 0, zM]) {
        color("tan") on_xz(yM0, true) strip2d();
        translate([40, yM0 + T, -10]) t2020(L + 35);
        axle(Mpin0, 14, 5);
    }
    // cam arm (3 layers) on the left side of F's 2020
    color("peru") plate_yz(-3 * T, 3 * T) cam_arm2d();
    color("dimgray") translate(P) rotate([0, 90, 0]) difference() { cylinder(d = 22, h = 7, center = true, $fn = 32); cylinder(d = 8, h = 8, center = true, $fn = 24); }
    // proposed: feed ramp and exit chute ride on the rig
    if (show_proposed) color("lightgreen", 0.55) {
        hull() { translate([22, yBK - 3, rest_z(0) - 10.5]) cube([16, 3, 3]); translate([22, yBK - 60, rest_z(0) + 4]) cube([16, 3, 3]); }
        for (x = [20, 38]) hull() { translate([x, yBK - 3, rest_z(0) - 10.5]) cube([2, 3, 14]); translate([x, yBK - 60, rest_z(0) + 4]) cube([2, 3, 14]); }
        hull() { translate([22, yBK - 3, rest_z(n_holes - 1) - 10.5]) cube([16, 3, 3]); translate([22, yBK - 62, rest_z(n_holes - 1) - 24]) cube([16, 3, 3]); }
        for (x = [20, 38]) hull() { translate([x, yBK - 3, rest_z(n_holes - 1) - 10.5]) cube([2, 3, 14]); translate([x, yBK - 62, rest_z(n_holes - 1) - 24]) cube([2, 3, 14]); }
    }
}

// ---------- fixed: frame, pivot, cam, link anchor, proposed trough and hopper
module fixed() {
    // pivot shaft in two pillow blocks under a horizontal 2020
    axle(P, 70);
    for (x = [P[0] - 26, P[0] + 26]) color("lightgray") translate([x - 7, P[1] - 15, P[2] - 4]) cube([14, 30, 34]);
    translate([P[0] - 60, P[1] - 10, P[2] + 30]) t2020x(200);
    // cam: fixed shaft on a hanger, disc with pin in the arm's slot, handle
    color("lightgray") translate([Ccam[0] - 32, Ccam[1] - 8, Ccam[2] - 4]) cube([8, 16, P[2] + 30 - Ccam[2] + 4]);
    axle(Ccam, 60);
    color("peru") translate(Ccam + [-14, 0, 0]) rotate([0, 90, 0]) rotate([0, 0, -360 * t]) linear_extrude(3 * T) difference() {
        circle(r = cam_r + 16, $fn = 64); circle(d = 8, $fn = 24); }
    axle(pin + [-8, 0, 0], 26, 5);
    let(h = Ccam + [-20, (cam_r + 10) * -sin(360 * t), (cam_r + 10) * cos(360 * t)]) { axle(h, 30, 6); }
    // M's link from the anchor (on a second fixed 2020 above M)
    mp = world(Mpin0 + [0, 0, zM], tilt);
    color("peru") hull() { translate(A + [4, 0, 0]) rotate([0, 90, 0]) cylinder(d = 14, h = 2 * T, center = true, $fn = 24);
                           translate(mp + [4, 0, 0]) rotate([0, 90, 0]) cylinder(d = 14, h = 2 * T, center = true, $fn = 24); }
    color("peru") translate([A[0] + 8, A[1] - 15, A[2] - 45]) cube([2 * T, 30, 75]);
    axle(A + [4, 0, 0], 16, 5);
    translate([-60, A[1] - 10, A[2] + 30]) t2020x(200);
    // proposed: fixed trough feeding the ramp mouth, fixed hopper under the exit chute
    if (show_proposed) color("mediumseagreen", 0.5) {
        zt = rest_z(0);
        // feed trough: its end sits just above the ramp's mouth; a ball drops in once per swing
        hull() { translate([22, -75, zt + 24]) cube([16, 3, 3]); translate([22, -160, zt + 46]) cube([16, 3, 3]); }
        for (x = [20, 38]) hull() { translate([x, -75, zt + 24]) cube([2, 3, 12]); translate([x, -160, zt + 46]) cube([2, 3, 12]); }
        // hopper: catch tray under the exit chute, tipped toward -x
        zh = rest_z(n_holes - 1) - 48;
        translate([10, -160, zh]) rotate([0, 4, 0]) cube([52, 116, 3]);    // reaches forward to catch the chute at either tilt
        translate([60, -160, zh - 4]) cube([3, 116, 12]);                    // overflow lip (weir) at the high end
        // queue channel along -x to the clock track outlet
        translate([-120, -125, zh - 9]) rotate([0, 4, 0]) cube([132, 24, 3]);
        for (y = [-127, -101]) translate([-120, y, zh - 9]) rotate([0, 4, 0]) cube([132, 2, 12]);
        translate([-128, -125, zh - 60]) cube([8, 24, 52]);                 // outlet down to the clock track
        // overflow track: over the lip, away along +x
        translate([63, -150, zh - 6]) rotate([0, 6, 0]) cube([110, 22, 3]);
    }
}

fixed();
translate(P) rotate([-tilt, 0, 0]) translate(-P) {
    if (section_view) { intersection() { rig(); translate([22, -300, -100]) cube([16, 600, 800]); } balls(); }
    else { rig(); balls(); }
}
