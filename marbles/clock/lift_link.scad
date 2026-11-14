// Lift link experiment: F swings on its SK8 shaft, M rides on F, a rigid link from a frame arm holds M.
// Seen from the clock face (camera in front): x = right, z = up, y = toward the wall.
// Origin = centre of F's SK8 shaft (the pivot). Everything in mm.
//
// Use: Window > Customizer for the numbers. View > Animate (FPS 20, Steps 80) to swing it;
// or set tilt_fixed to look at one angle. The console echoes where M sits and how the link leans.

/* [Swing] */
amp = 12.0;            // swing, deg each side
tilt_fixed = 999;      // set to an angle (deg) to freeze; 999 = animate. + = the bottom swings right
show_ends = true;      // ghost the rig at both ends of the swing

/* [Rig: your measurements] */
keeper_t = 2.82;       // the mdf3 layer under F's SK8
sk8_h = 20;            // SK8: shaft centre to its base
m_offset = 10;         // M's centre is this far left of F's centre
cross_top = 75;        // top of M's crossbar above the shaft, M on its bottom stop
travel = 36;           // M's travel, stop to stop
lane = 20;             // ball lane between F and each M side beam (front / back)

/* [Link pin on M] */
pin_dx = 40;           // pin left of M's centre (bracket on the crossbar); 0 = over M's centre
pin_up = 0;            // pin above the crossbar's top

/* [Frame arm and link] */
arm_auto = true;       // true: put the arm where M lands exactly on both stops at +-amp (ignores arm_x / arm_z)
arm_x = 82.8;          // manual arm pin: left of the shaft
arm_z = 199.2;         // manual arm pin: above the shaft
link = 110;            // link, pin to pin (your turnbuckle: 100 minimum)

/* [Hidden] */
F_X = -(10 + keeper_t + sk8_h);   // F's centre
M_X = F_X - m_offset;             // M's centre
PX = M_X - pin_dx;                // pin, rig frame (x)
PZ0 = cross_top + pin_up;         // pin, rig frame (z) with M on its bottom stop
$fn = 32;

// rig turned by t: + = counter-clockwise seen from the front = bottom swings right
function R(p, t) = [p[0] * cos(t) - p[1] * sin(t), p[0] * sin(t) + p[1] * cos(t)];

// arm placement: the point `link` from the pin at both ends (bottom stop at -amp, top stop at +amp), the upper one
function auto_arm() =
    let(p1 = R([PX, PZ0], -amp), p2 = R([PX, PZ0 + travel], amp),
        m = (p1 + p2) / 2, u = p2 - p1, c = norm(u), h = sqrt(max(0, link * link - c * c / 4)),
        n = [-u[1], u[0]] / c, a1 = m + n * h, a2 = m - n * h)
    a1[1] > a2[1] ? a1 : a2;
A = arm_auto ? auto_arm() : [-arm_x, arm_z];

// M's height up its travel (0 = bottom stop) at tilt t, holding the link length; the pin hangs below the arm
function slide(t) =
    let(b0 = R([PX, PZ0], t), u = R([0, 1], t), w = b0 - A, b = w * u, c = w * w - link * link, d = b * b - c)
    d < 0 ? undef : -b - sqrt(d);
function pinw(t, s) = R([PX, PZ0 + s], t);
function lean(t) = let(p = pinw(t, slide(t))) atan2(A[0] - p[0], A[1] - p[1]);

tilt = tilt_fixed != 999 ? tilt_fixed : amp * sin(360 * $t);
s_now = slide(tilt);
s_lo = slide(-amp); s_hi = slide(amp); s_0 = slide(0);

echo(str("ARM PIN: ", -A[0], " left, ", A[1], " above the shaft", arm_auto ? " (auto)" : " (manual)"));
echo(str("PIN ON M: ", -PX, " left of the shaft (", pin_dx, " left of M's centre), ", pin_up, " above the crossbar top"));
echo(str("M at -amp: ", s_lo, "   at rest: ", s_0, "   at +amp: ", s_hi, "   (stops at 0 and ", travel, ")"));
echo(str("stroke ", s_hi - s_lo, "; link lean ", lean(-amp), " / ", lean(0), " / ", lean(amp), " deg off vertical"));
echo(str("NOW tilt ", tilt, ": M ", s_now, " up its travel", s_now == undef ? " (LINK CAN'T REACH)" : ""));

// ---------- parts
module beam(x0, x1, y0, y1, z0, z1) translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);
module on_rig(t) multmatrix([[cos(t), 0, -sin(t), 0], [0, 1, 0, 0], [sin(t), 0, cos(t), 0], [0, 0, 0, 1]]) children();

module rig(t, s, a = 1) {
    on_rig(t) {
        // F: 1 m 2020, its top a little above the shaft; keeper on its right face, spine sieve on its left
        color("silver", a) beam(F_X - 10, F_X + 10, -10, 10, -300, 60);
        color("burlywood", a) beam(F_X + 10, F_X + 10 + keeper_t, -30, 30, -300, 30);
        color("tan", a * .8) beam(F_X - 13.2, F_X - 10, -38, 38, -300, 50);
        // SK8 on the keeper, clamping the shaft
        color("gray", a) beam(F_X + 10 + keeper_t, F_X + 10 + keeper_t + sk8_h + 7, -7, 7, -21, 21);
        // M: front and back side beams (toward you / toward the wall), crossbar across their tops
        for (y = [-(10 + lane + 10), 10 + lane + 10])
            color("gainsboro", a * .8) beam(M_X - 10, M_X + 10, y - 10, y + 10, -320 + s, cross_top + s - 20);
        color("dimgray", a) beam(M_X - 10, M_X + 10, -75, 75, cross_top + s - 20, cross_top + s);
        // bracket from M's crossbar out to the link pin
        if (pin_dx != 0 || pin_up > 0)
            color("orange", a * .8) beam(min(PX - 6, M_X - 10), max(PX + 6, M_X + 10), -6, 6, cross_top + s, cross_top + s + pin_up + 4);
    }
}
module link_rod(t, s, col) {
    p = pinw(t, s);
    v = [A[0] - p[0], 0, A[1] - p[1]];
    color(col) translate([p[0], 0, p[1]]) rotate([0, atan2(v[0], v[2]), 0]) cylinder(d = 6, h = norm(v));
    color("black") translate([p[0], 0, p[1]]) rotate([90, 0, 0]) cylinder(d = 9, h = 14, center = true);
}

// fixed: shaft, KP08s (lowered), frame arm along y
color("black") rotate([90, 0, 0]) cylinder(d = 8, h = 160, center = true);
for (y = [-70, 70]) color("slategray") translate([-20, y - 7, 6]) cube([40, 14, 28]);
color("black") translate([A[0] - 10, -90, A[1] + 4]) cube([20, 180, 20]);
color("black") translate([A[0], 0, A[1]]) rotate([90, 0, 0]) cylinder(d = 9, h = 14, center = true);

if (s_now != undef) { rig(tilt, s_now); link_rod(tilt, s_now, "orangered"); }
if (show_ends && s_lo != undef && s_hi != undef) {
    rig(-amp, s_lo, .18); link_rod(-amp, s_lo, "royalblue");
    rig(amp, s_hi, .18); link_rod(amp, s_hi, "firebrick");
}
