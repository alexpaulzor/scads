// Ball lift test rig: one fixed sieve strip (F) and one moving sieve strip
// (M), both the 300 x 46 mm MDF strip from lift_sieve.py, each bolted to a
// 2020. Animate in OpenSCAD: View > Animate, FPS 10, Steps 60. One
// animation cycle = one turn of the cam = every ball up one step; it loops
// seamlessly (a new ball feeds in at the bottom, the top one leaves).
//
// ONE MOTION DOES EVERYTHING
// The whole rig hangs from a pivot at the top (axle along x) and rocks
// forward and back. The pivot sits `arm` mm in front of M's top pin, so
// rocking also raises and lowers the rig there. M slides on keys along the
// rig, but its top pin hangs from a fixed link, so M stays at about the same
// height while F rises and falls around it: that relative slide is the lift,
// and it is in step with the rock by construction.
//   - An off-centre cam on a fixed axle, its pin riding in a horizontal slot
//     in the rig's front arm, rocks the rig.
//   - Rig tipped forward (top toward the viewer) = F up, so M sits low
//     against F: balls roll forward out of F into M.
//   - Rig tipped back = F down, M high: balls roll back from M into F one
//     hole higher, and lean on F / the back guard for the rest of the turn.
//
// Axes: x across, y toward the viewer (front), z up.
// Back to front: back guard 2020 | gap | F | balls | M | M's 2020.

/* [Animation] */
t_fixed = -1;                 // set 0..1 to show one moment instead of animating
t = t_fixed >= 0 ? t_fixed : $t;   // 0..1, one cam turn
show_frame = true;
section_view = false;         // cut away everything outside the ball column (x 22..38)

/* [Sieve strip (as cut)] */
L = 300; W = 46; T = 3.2;     // strip; T = MDF thickness
hole_d = 20; hole_v = 30;     // ball holes, centre 30 mm from the bolt edge
pitch = 30; n_holes = 10;     // first hole pitch/2 from the end
m5_d = 5; m5_v = 10; m5_u = [30, 90, 150, 210, 270];

/* [Balls] */
ball_d = 19.05;               // 3/4" steel; set to your toy marbles' size to compare
drop = 2;                     // hand-off drop: lift = pitch + 2 * drop

/* [Rocking drive] */
tilt_fwd = 12;                // deg, top toward the viewer, at M's low point (symmetric swing: = tilt_back)
tilt_back = 12;               // deg, top toward the wall, at M's high point
cam_r = 10;                   // off-centre cam (eccentric) radius
link = 100;                   // fixed link from the frame down to M's top pin
pivot_up = 45;                // pivot this far above M's top pin

/* [Layout] */
guard_gap = 4;                // back guard face this far behind F's back face
m_gap = 0.45;                 // M's back face clears a resting ball's front by this

// ---------- geometry (rig frame, before rocking)
lift = pitch + 2 * drop;
s_span = sin(tilt_fwd) + sin(tilt_back);
arm_trim = 0.98805;                   // fine trim so the solved stroke comes out = lift (34.0002 at +-12 deg)
arm = arm_trim * lift / s_span;        // pivot ahead of M's top pin (sets the lift)
cam_arm = 2 * cam_r / s_span;         // cam slot ahead of the pivot (sets the rock)
yF0 = 0; yF1 = T;
yG = -guard_gap;
yB_rest = yG + ball_d / 2;
yM0 = yB_rest + ball_d / 2 + m_gap;
yB_ride = yF1 + ball_d / 2;
yGF = yB_ride + ball_d / 2 + 0.5;
yB_front = yGF - ball_d / 2;
Mbase = [50, yM0 + T + 10, L + 15];             // M's top pin, rig frame, reference for the link solve
P = [30, Mbase[1] + arm, Mbase[2] + pivot_up];  // rocking pivot
slotC = P + [0, cam_arm, 0];                    // cam slot centre on the front arm (rig frame)
Ccam = [30, slotC[1], P[2] - cam_arm * (sin(tilt_fwd) - sin(tilt_back)) / 2];   // cam axle (fixed)
A = Mbase + [0, 0, link];                       // fixed anchor of M's link

// cam pin; the slot on the arm stays at the pin's height, which sets the tilt
function pin_at(tt) = Ccam + [0, cam_r * sin(360 * tt), -cam_r * cos(360 * tt)];   // tt = 0: pin at the bottom
function tilt_at(tt) = asin((P[2] - pin_at(tt)[2]) / cam_arm);                       // + = top forward
pin = pin_at(t);
tilt = tilt_at(t);

// rotate a rig-frame point by the tilt about P (top forward = rotate -tilt about x)
function rotx(v, a) = [v[0], v[1] * cos(a) - v[2] * sin(a), v[1] * sin(a) + v[2] * cos(a)];
function world(v, tl) = P + rotx(v - P, -tl);
// M's slide (along the rig) that keeps the link length, at a given tilt
function m_slide(tl) =
    let(w = world(Mbase, tl) - A, u = rotx([0, 0, 1], -tl), b = w * u, c = w * w - link * link)
    -b - sqrt(b * b - c);                       // M's pin hangs BELOW the anchor
zs = [for (i = [0:72]) m_slide(tilt_at(i / 72))];
zs_min = min(zs); zs_max = max(zs);
zM = -drop + (m_slide(tilt) - zs_min);          // M relative to F: -drop .. -drop + stroke
Mpin0 = Mbase + [0, 0, zs_min + drop];          // M's pin when M's holes line up with F's
echo(t = t, tilt = tilt, M_rel = zM, stroke = zs_max - zs_min, arm = arm, cam_arm = cam_arm);

function hole_z(i) = pitch / 2 + i * pitch;
function rest_z(i) = hole_z(i) - (hole_d - ball_d) / 2;
function sm(e0, e1, x) = let(s = min(1, max(0, (x - e0) / (e1 - e0)))) s * s * (3 - 2 * s);

// ---------- parts
module strip2d() {
    difference() {
        square([L, W]);
        for (i = [0:n_holes - 1]) translate([pitch / 2 + i * pitch, hole_v]) circle(d = hole_d, $fn = 64);
        for (u = m5_u) translate([u, m5_v]) circle(d = m5_d, $fn = 24);
    }
}
module stripF() { color("burlywood") translate([0, yF0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
    rotate([0, 0, 90]) mirror([0, 1, 0]) linear_extrude(T) strip2d(); }
module stripM() { color("tan") translate([60, yM0, 0]) mirror([1, 0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
    rotate([0, 0, 90]) mirror([0, 1, 0]) linear_extrude(T) strip2d(); }
module t2020_w(w, len) { color("silver") cube([w, 20, len]); }
module t2020(len) {
    color("silver") difference() {
        cube([20, 20, len]);
        for (f = [[0, 10], [20, 10], [10, 0], [10, 20]]) translate([f[0], f[1], -1])
            translate([-3.1, -3.1, 0]) cube([6.2, 6.2, len + 2]);
    }
}
module pinx(p, d = 8, h = 30) { color("dimgray") translate(p) rotate([0, 90, 0]) cylinder(d = d, h = h, center = true, $fn = 24); }
module bar(p0, p1, w = 12) { hull() { translate(p0) rotate([0, 90, 0]) cylinder(d = w, h = T * 2, center = true, $fn = 24);
                                       translate(p1) rotate([0, 90, 0]) cylinder(d = w, h = T * 2, center = true, $fn = 24); } }

// ---------- balls (rig frame)
module ball_k(k) {
    pick = sm(0.0, 0.06, t);
    give = sm(0.5, 0.56, t);
    zride = rest_z(k) + zM;
    z = t < 0.5 ? max(rest_z(k), zride) : max(rest_z(k + 1), zride);
    fwd = (pick - give) * max(0, min(1, tilt / 2));
    y = yB_rest + (yB_ride - yB_rest) * (pick - give) + (yB_front - yB_ride) * fwd;
    if (k + (t >= 0.5 ? 1 : 0) <= n_holes - 1)
        translate([30, y, z]) color("steelblue") sphere(d = ball_d, $fn = 32);
}
module feed_exit() {
    f = sm(0.6, 0.95, t);
    translate([30, yB_rest - 60 * (1 - f), rest_z(0) + 20 * (1 - f)]) color("steelblue") sphere(d = ball_d, $fn = 32);
    if (t >= 0.56) translate([30, yB_rest - 70 * f, rest_z(n_holes - 1) - 12 * f]) color("steelblue") sphere(d = ball_d, $fn = 32);
}
module balls() { for (k = [0:n_holes - 2]) ball_k(k); feed_exit(); }

// ---------- the rocking rig (rig frame)
module rig() {
    stripF();
    translate([0, -20, -20]) t2020(L + 75);                                     // F's 2020
    translate([20, yG - 20, hole_z(0) + 20]) t2020(hole_z(n_holes - 1) - hole_z(0) - 40);    // back guard
    translate([20, yGF, hole_z(0) - 10]) t2020_w(19.5, hole_z(n_holes - 1) - hole_z(0) + 20); // front guard
    // M on its 2020, sliding on keys in its right-hand slot; link pin on top
    translate([0, 0, zM]) {
        stripM();
        translate([40, yM0 + T, -10]) t2020(L + 30);
        pinx(Mpin0);
    }
    for (z = [5, L - 25]) color("peru") translate([56, yM0 + T + 10 - 1.25, z]) cube([30, 2.5, 20]);   // keys
    translate([80, yM0 + T + 4, -20]) t2020(L + 75);                             // post carrying the keys
    // top plate tying F's 2020 and the key post to the pivot boss and the cam arm
    color("peru") translate([-10, -20, L + 55]) cube([115, P[1] + 20 - 10, 6]);
    color("peru") translate([24, P[1] - 10, L + 55]) cube([6, 20, P[2] - L - 55 + 10]);              // pivot boss
    color("peru") difference() {                                                  // front arm with the cam slot
        translate([24, P[1] - 10, P[2] - 12]) cube([6, cam_arm + cam_r + 25, 24]);
        translate([22, slotC[1] - cam_r - 5, P[2] - 4.5]) cube([10, 2 * cam_r + 10, 9]);
    }
}

// ---------- fixed stand: pivot bearing, cam axle, M's link anchor
if (show_frame && !section_view) {
    pinx(P, 8, 160);
    for (x = [-50, 110]) color("dimgray") translate([x, P[1] - 15, P[2] - 15]) cube([6, 30, 150]);  // uprights
    color("dimgray") translate([-50, P[1] - 15, P[2] + 135]) cube([166, 30, 8]);                    // cross piece
    color("dimgray") translate([-50, A[1] - 6, A[2] - 6]) cube([166, 12, 12]);                      // anchor bar
    color("darkorange") translate(Ccam + [4, 0, 0]) rotate([0, 90, 0]) cylinder(r = cam_r + 8, h = 5, $fn = 48);   // cam disc
    pinx(Ccam, 8, 60);
    pinx(pin, 7, 26);
    mp = world(Mpin0 + [0, 0, zM], tilt);
    color("darkorange") bar(A, mp, 10);
    pinx(A, 8, 30);
}
translate(P) rotate([-tilt, 0, 0]) translate(-P) {
    if (section_view) { intersection() { rig(); translate([22, -200, -100]) cube([16, 400, 800]); } balls(); }
    else { rig(); balls(); }
}
