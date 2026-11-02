// Ball lift test rig: one fixed sieve strip (F) and one moving sieve strip
// (M), both the 300 x 46 mm MDF strip from lift_sieve.py, each bolted to a
// 2020. A crank at the top drives M. Animate in OpenSCAD: View > Animate,
// FPS 10, Steps 60. One animation cycle = one crank turn = every ball up one
// step; it loops seamlessly (a new ball feeds in at the bottom, the top one
// leaves).
//
// Axes: x across (left/right), y toward the viewer (front), z up.
// Back to front: back guard 2020 (fixed) | gap | F | balls | M | M's 2020.
//
// motion = "slider": crank + connecting rod, M slides straight up and down
//   on wooden keys in its right-hand slot. This is the default because the
//   ball stays on F's face the whole lift.
// motion = "circle": two equal cranks (top driven, bottom idler) move M
//   round a circle. A circle that gives the 34 mm lift also swings 17 mm
//   sideways, which drags the riding ball across F's M5 heads one way or off
//   F's 6 mm edge the other way (set `swing` smaller to see how far it can go).

/* [Animation] */
t_fixed = -1;                 // set 0..1 to show one moment instead of animating
t = t_fixed >= 0 ? t_fixed : $t;   // 0..1, one crank turn
motion = "slider";            // [slider, circle]
swing = 17;                   // sideways radius for motion = "circle"
lean = 5;                     // deg, top tipped back toward the wall
show_frame = true;
section_view = false;         // cut away everything outside the ball column (x 22..38) to see the hand-offs

/* [Sieve strip (as cut)] */
L = 300; W = 46; T = 3.2;     // strip; T = MDF thickness
hole_d = 20; hole_v = 30;     // ball holes, centre 30 mm from the bolt edge
pitch = 30; n_holes = 10;     // first hole pitch/2 from the end
m5_d = 5; m5_v = 10; m5_u = [30, 90, 150, 210, 270];

/* [Balls] */
ball_d = 19.05;               // 3/4" steel; set to your toy marbles' size to compare
drop = 2;                     // hand-off drop: stroke = pitch + 2 * drop

/* [Layout] */
guard_gap = 4;                // back guard face this far behind F's back face
m_gap = 0.45;                 // M's back face clears a resting ball's front by this
rod = 100;                    // connecting rod length
crank_r = (pitch + 2 * drop) / 2;

// ---------- derived positions (y)
yF0 = 0;                        // F back face
yF1 = T;                        // F front face
yG = -guard_gap;                // back guard face
yB_rest = yG + ball_d / 2;      // ball resting in F, against the guard
yM0 = yB_rest + ball_d / 2 + m_gap;   // M back face
yB_ride = yF1 + ball_d / 2;     // ball riding in M, against F's face
echo(t = t, stroke = 2 * crank_r, ball_rest_y = yB_rest, ball_ride_y = yB_ride, M_back_face_y = yM0);
assert(yB_ride + ball_d / 2 > yM0, "riding ball never reaches M's hole");

// ---------- the strip, 2D in its own frame (u along, v across)
module strip2d() {
    difference() {
        square([L, W]);
        for (i = [0:n_holes - 1]) translate([pitch / 2 + i * pitch, hole_v]) circle(d = hole_d, $fn = 64);
        for (u = m5_u) translate([u, m5_v]) circle(d = m5_d, $fn = 24);
    }
}
// F: bolt band on the left (x 0..20), holes at x = 30
module stripF() { color("burlywood") translate([0, yF0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
    rotate([0, 0, 90]) mirror([0, 1, 0]) linear_extrude(T) strip2d(); }
// M: mirrored, bolt band on the right (x 40..60), holes at x = 30
module stripM() { color("tan") translate([60, yM0, 0]) mirror([1, 0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
    rotate([0, 0, 90]) mirror([0, 1, 0]) linear_extrude(T) strip2d(); }

module t2020(len) {
    color("silver") difference() {
        cube([20, 20, len]);
        for (f = [[0, 10], [20, 10], [10, 0], [10, 20]]) translate([f[0], f[1], -1])
            translate([-3.1, -3.1, 0]) cube([6.2, 6.2, len + 2]);
    }
}

// ---------- motion
a = 180 + 360 * t;                          // t = 0: M at the bottom
zc = (rod + crank_r);                       // crank centre above M's pin (relative)
function slider_z(a) = crank_r * cos(a) - sqrt(rod * rod - pow(crank_r * sin(a), 2));
zs_min = slider_z(180);
zM = motion == "slider" ? -drop + (slider_z(a) - zs_min) : -drop + crank_r - crank_r * cos(360 * t);
xM = motion == "slider" ? 0 : swing * sin(360 * t);

function hole_z(i) = pitch / 2 + i * pitch;
function rest_z(i) = hole_z(i) - (hole_d - ball_d) / 2;       // ball sitting on a hole's bottom
function sm(e0, e1, x) = let(s = min(1, max(0, (x - e0) / (e1 - e0)))) s * s * (3 - 2 * s);

// one ball that starts this turn in F at level k
module ball_k(k) {
    pick = sm(0.0, 0.06, t);                // F -> M at the bottom
    give = sm(0.5, 0.56, t);                // M -> F at the top
    zride = rest_z(k) + zM;
    z = t < 0.5 ? max(rest_z(k), zride) : max(rest_z(k + 1), zride);
    y = yB_rest + (yB_ride - yB_rest) * (pick - give);
    x = 30 + xM * (pick - give);
    if (k + (t >= 0.5 ? 1 : 0) <= n_holes - 1)
        translate([x, y, z]) color("steelblue") sphere(d = ball_d, $fn = 32);
}
// feeder and exit balls
module feed_exit() {
    f = sm(0.6, 0.95, t);
    // incoming ball rolls in from behind to level 0
    translate([30, yB_rest - 60 * (1 - f), rest_z(0) + 20 * (1 - f)]) color("steelblue") sphere(d = ball_d, $fn = 32);
    // the ball that just reached the top rolls out the back
    if (t >= 0.56) translate([30, yB_rest - 70 * f, rest_z(n_holes - 1) - 12 * f]) color("steelblue") sphere(d = ball_d, $fn = 32);
}

// ---------- assembly
module balls() { for (k = [0:n_holes - 2]) ball_k(k); feed_exit(); }

module rig() {
    // fixed: F on its 2020, back guard (stops short at the feed and exit levels)
    stripF();
    translate([0, -20, -30]) t2020(L + 170);
    translate([20, yG - 20, hole_z(0) + 20]) t2020(hole_z(n_holes - 1) - hole_z(0) - 40);
    // moving: M and its 2020 (slot on the right rides fixed keys)
    translate([xM, 0, zM]) {
        stripM();
        translate([40, yM0 + T, -10]) t2020(L + 30);
        // top pin for the connecting rod
        translate([50, yM0 + T + 10, L + 15]) rotate([90, 0, 0]) color("dimgray") cylinder(d = 8, h = 30, center = true, $fn = 24);
    }
    // guide keys (fixed) in M's right-hand slot, top and bottom
    if (motion == "slider") for (z = [5, L - 25]) color("peru")
        translate([60 - 4, yM0 + T + 10 - 1.25, z]) cube([24, 2.5, 20]);
    // crank at the top
    pin_z = L + 15 + zM;
    cz = L + 15 - drop + crank_r - zs_min + 0;            // crank centre
    crank_c = [50, yM0 + T + 10 + 22, motion == "slider" ? L + 15 - drop - zs_min : L + 15 - drop + crank_r];
    cp = crank_c + [crank_r * sin(a - 180 + 180) * (motion == "slider" ? 1 : 0) + (motion == "slider" ? 0 : swing * sin(360 * t)),
                    0, motion == "slider" ? crank_r * cos(a) : -crank_r * cos(360 * t)];
    color("peru") translate(crank_c) rotate([90, 0, 0]) rotate([0, 0, -a]) linear_extrude(T * 2, center = true) difference() {
        circle(r = crank_r + 12, $fn = 64); circle(d = 8, $fn = 24); }
    color("dimgray") translate(cp) rotate([90, 0, 0]) cylinder(d = 8, h = 30, center = true, $fn = 24);
    if (motion == "slider") color("peru") hull() {
        translate(cp + [0, -9, 0]) rotate([90, 0, 0]) cylinder(d = 14, h = T * 2, center = true, $fn = 32);
        translate([50, yM0 + T + 13, pin_z]) rotate([90, 0, 0]) cylinder(d = 14, h = T * 2, center = true, $fn = 32);
    }
    if (motion == "circle") {           // bottom idler crank for parallel motion
        bc = [50, yM0 + T + 10 + 22, -25 - drop + crank_r];
        color("peru") translate(bc) rotate([90, 0, 0]) rotate([0, 0, -360 * t]) linear_extrude(T * 2, center = true)
            difference() { circle(r = crank_r + 12, $fn = 64); circle(d = 8, $fn = 24); }
    }
    // frame
    if (show_frame) {
        color("gainsboro") translate([-30, -90, -46]) cube([140, 170, 6]);
        translate([90, yM0 + T, -40]) t2020(crank_c[2] + 60);                  // right post
        translate([-20, yM0 + T + 30, crank_c[2] + 20]) rotate([0, 90, 0]) t2020(130);   // top bar
        if (motion == "slider") for (z = [5, L - 25]) color("peru")
            translate([80, yM0 + T + 4, z]) cube([10, 12, 20]);              // key blocks on the post
    }
}

rotate([-lean, 0, 0]) {
    if (section_view) { intersection() { rig(); translate([22, -200, -100]) cube([16, 400, 700]); } balls(); }
    else { rig(); balls(); }
}
