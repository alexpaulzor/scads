// Clock train MVP: two "differential sun" planetaries on the FIXED escape-wheel axle (smooth 8 mm rod). No dial, no ring
// gears; the hands come straight off the parts that turn at the right speed.
//
// WHAT DRIVES WHAT (each colour below is one rigid body that turns as a unit):
//   ORANGE  escape wheel (1 rev/min, seconds pointer) --6 standoffs--> MINUTE CARRIER --3 M3 axle bolts--> minute planets
//   YELLOW  minute planets: two ply layers pinned together (2 wire pins), spinning on their M3 axle bolt.
//           layer A rolls round the FIXED minute sun (59); layer B turns the MINUTE SUN (60).
//   RED     MINUTE SUN (60, on a 608) --5 standoffs--> HOUR CARRIER + MINUTE HAND --5 M3 axle bolts--> hour planets
//   PINK    hour planets: layer A rolls round the FIXED hour sun (55); layer B turns the HOUR SUN (60).
//   BLUE    HOUR SUN (60, on a 608) + HOUR HAND.
//   GREY    fixed: the rod; each fixed sun bolted (M3) to a 1515 MakerBeam XL piece, an SK8 on the beam clamping the rod.
//   output / carrier = 1 - (ZA * PB) / (PA * ZB): minutes 1 - 59/60 = 1/60, hours 1 - 55/60 = 1/12.
// Each output sun is 3 ply layers bolted together (the gear + 2 hub rings) to hold its 608 (7 thick).
// Viewed from the front (+z toward the viewer); every hand turns clockwise.
// Animate (FPS 20, Steps 200): one run = `minutes_per_anim` minutes.

/* [View] */
minutes_per_anim = 60;       // minutes of clock time per animation run
t_fixed = -1;                // >= 0: freeze at this fraction of the run
explode = 0;                 // spread the layers (mm)
section = false;             // cut away the near half (see the stack from the side)
body_colours = true;         // colour each rigid body (false: wood colours)

/* [Minute stage] */
M_MOD = 2.0; M_ZA = 59; M_PA = 12; M_ZB = 60; M_PB = 12; M_N = 3;
/* [Hour stage] */
H_MOD = 2.0; H_ZA = 55; H_PA = 10; H_ZB = 60; H_PB = 10; H_N = 5;
/* [Mounting] */
SK8_W = 42; SK8_T = 14; SK8_H = 20;   // SK8 (assumed standard): width, thickness along the rod, rod centre above its base
BEAM = 15; BEAM_L = 50;               // 1515 MakerBeam XL piece
GAP = 24;                             // carrier standoff length: room behind each fixed sun for its beam + SK8
CAR_IN = 44.5;                        // carrier opening radius (SK8 + beam reach 43)
UP_R = 50;                            // minute sun -> hour carrier standoffs radius (inside the minute sun's teeth)

/* [Hidden] */
T = 2.63; PA_DEG = 20;
$fn = 36;
tt = t_fixed >= 0 ? t_fixed : $t;
esc = -360 * minutes_per_anim * tt;
m_out = esc * (1 - M_ZA * M_PB / (M_PA * M_ZB));
h_out = m_out * (1 - H_ZA * H_PB / (H_PA * H_ZB));
E = explode;

C_FIX = body_colours ? "gainsboro" : "burlywood";
C_SEC = body_colours ? "darkorange" : "tan";
C_MPL = body_colours ? "gold" : "peru";
C_MIN = body_colours ? "firebrick" : "goldenrod";
C_HPL = body_colours ? "hotpink" : "sienna";
C_HR  = body_colours ? "royalblue" : "goldenrod";
C_HW  = "dimgray";        // hardware

function inv(a) = tan(a) - a * PI / 180;
module gear2d(z, m, bore = 0) {
    rp = m * z / 2; rb = rp * cos(PA_DEG); ra = rp + m; rf = max(rp - 1.25 * m, 1);
    half = 90 / z + inv(PA_DEG) * 180 / PI;
    st = 6;
    pts = [for (i = [0:st]) let(r = max(rb, rf) + (ra - max(rb, rf)) * i / st, a = acos(rb / r)) [r, half - inv(a) * 180 / PI]];
    tooth = concat([for (p = pts) [p[0] * cos(p[1]), p[0] * sin(p[1])]], [for (i = [st:-1:0]) [pts[i][0] * cos(-pts[i][1]), pts[i][0] * sin(-pts[i][1])]]);
    difference() {
        union() { circle(r = rf); for (k = [0:z - 1]) rotate(k * 360 / z) polygon(concat([[0, 0]], tooth)); }
        if (bore > 0) circle(d = bore);
    }
}
module slab(z0, col, h = T) { color(col) translate([0, 0, z0]) linear_extrude(h) children(); }
module bolt(p, z0, len, col = C_HW) { color(col) translate([p[0], p[1], z0]) { cylinder(d = 3, h = len); translate([0, 0, -2]) cylinder(d = 5.5, h = 2, $fn = 6); } }
module standoff(r, a, z0, len, col) { color(col) rotate(a) translate([r, 0, z0]) cylinder(d = 5, h = len, $fn = 6); }
module bearing608(z0) { color("silver") translate([0, 0, z0]) difference() { cylinder(d = 22, h = 7); translate([0, 0, -1]) cylinder(d = 8, h = 9); } }

// one stage: z0 = carrier plate's back face; c = carrier angle, o = output sun angle
module stage(z0, MOD, ZA, PA, ZB, PB, N, c, o, CCAR, CPL, COUT) {
    A = MOD * (ZA + PA) / 2;                    // centre distance
    MODB = 2 * A / (ZB + PB);
    zA = z0 + T + E; zB = z0 + 2 * (T + E);
    // CARRIER (input): annulus with the planet axle bolts (bolt clamped to the carrier by a nut; the planet spins on it)
    slab(z0, CCAR) rotate(c) difference() {
        circle(r = A + PA * MOD / 2 + 4);
        circle(r = CAR_IN);
        for (k = [0:N - 1]) rotate(k * 360 / N) translate([A, 0]) circle(d = 3.3);
    }
    for (k = [0:N - 1]) rotate(c + k * 360 / N) bolt([A, 0], z0, 3 * T + 2 * E + 4, CCAR);
    // FIXED SUN + its mount behind it: 1515 beam bolted flat to the sun's back, SK8 on the beam round the rod
    slab(zA, C_FIX) rotate(180 / ZA) difference() { gear2d(ZA, MOD, 8.4); for (x = [-15, 15]) translate([x, -SK8_H - BEAM / 2]) circle(d = 3.3); }
    color(C_FIX) translate([0, 0, zA]) mirror([0, 0, 1]) {
        translate([-BEAM_L / 2, -SK8_H - BEAM, 0]) cube([BEAM_L, BEAM, BEAM]);
        translate([-SK8_W / 2, -SK8_H, 0.5]) difference() { cube([SK8_W, SK8_H + 12.8, SK8_T]); translate([SK8_W / 2, SK8_H, -1]) cylinder(d = 8.2, h = SK8_T + 2); }
    }
    // OUTPUT SUN (gear + 2 hub rings, bolted) on its 608
    slab(zB, COUT) rotate(o + 180 / ZB) difference() { gear2d(ZB, MODB, 22.2); for (k = [0:2]) rotate(k * 120 + 60) translate([16, 0]) circle(d = 3.3); }
    slab(zB + T + E, COUT, 2 * T) rotate(o) difference() { circle(r = 21); circle(d = 22.2); for (k = [0:2]) rotate(k * 120 + 60) translate([16, 0]) circle(d = 3.3); }
    bearing608(zB + 0.3);
    // PLANETS: layer A (meshes the fixed sun) + layer B (meshes the output sun), tied by 2 wire pins, spinning on the axle bolt
    for (k = [0:N - 1]) {
        th = c + k * 360 / N;
        psiA = th * (1 + ZA / PA);
        psiB = th + (th - o) * ZB / PB;
        rotate(th) translate([A, 0]) {
            slab(zA, CPL) rotate(psiA - th) difference() { gear2d(PA, MOD, 3.3); for (s = [-1, 1]) translate([s * PA * MOD / 5, 0]) circle(d = 2.2); }
            slab(zB, CPL) rotate(psiA - th) difference() { rotate(psiB - psiA) gear2d(PB, MODB, 3.3); for (s = [-1, 1]) translate([s * PA * MOD / 5, 0]) circle(d = 2.2); }
            color("black") rotate(psiA - th) for (s = [-1, 1]) translate([s * PA * MOD / 5, 0, zA - 0.5]) cylinder(d = 2.05, h = 2 * T + E + 1);
        }
    }
}

module train() {
    zw = -GAP - 2;                                                    // escape wheel front ring
    // ORANGE: escape wheel (schematic front ring) + seconds pointer + standoffs to the minute carrier
    slab(zw, C_SEC) rotate(esc) difference() { circle(r = 122); circle(r = 92); }
    color(C_SEC) translate([0, 0, zw + T]) rotate(esc) translate([112, -3]) cube([22, 6, 2]);
    A_m = M_MOD * (M_ZA + M_PA) / 2;
    for (k = [0:5]) standoff(A_m + M_PA * M_MOD / 2 + 1, esc + k * 60 + 30, zw + T, -zw - T, C_SEC);
    stage(0, M_MOD, M_ZA, M_PA, M_ZB, M_PB, M_N, esc, m_out, C_SEC, C_MPL, C_MIN);
    // RED: minute sun -> 5 standoffs -> hour carrier (+ minute hand on it)
    z_mf = 3 * (T + E) + 2 * T + E;                                   // front of the minute sun's hub rings
    z_h = z_mf + GAP;                                                 // hour carrier
    for (k = [0:4]) standoff(UP_R, m_out + k * 72 + 36, 3 * (T + E), z_h - 3 * (T + E), C_MIN);
    stage(z_h, H_MOD, H_ZA, H_PA, H_ZB, H_PB, H_N, m_out, h_out, C_MIN, C_HPL, C_HR);
    color(C_MIN) translate([0, 0, z_h - 1.6]) rotate(m_out) translate([UP_R - 4, -3.5]) cube([96, 7, 1.6]);        // minute hand
    // BLUE: hour hand on the hour sun's hub
    color(C_HR) translate([0, 0, z_h + 3 * (T + E) + 2 * T + E]) rotate(h_out) translate([-6, -4]) cube([82, 8, 1.6]);
    // GREY: the rod + front collar
    color(C_FIX) translate([0, 0, zw - 20]) cylinder(d = 8, h = z_h + 8 * T + 4 * E - zw + 26);
    color(C_HW) translate([0, 0, z_h + 3 * (T + E) + 2 * T + E + 3]) difference() { cylinder(d = 16, h = 8); translate([0, 0, -1]) cylinder(d = 8, h = 10); }
}

if (section) difference() { train(); translate([-300, -600, -200]) cube([600, 600, 400]); }   // cut away y < 0
else train();
