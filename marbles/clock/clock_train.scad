// Clock train MVP, LANTERN version: two "differential sun" planetaries on the FIXED escape-wheel axle (smooth 8 mm
// rod). No dial, no ring gears; the hands come straight off the parts that turn at the right speed.
// Every PLANET is a lantern: 16 straight 2.05 wire pins between two discs (serving both suns), trapped by solid covers
// (no bending). One planet per stage + a counterweight opposite it (shared pins only fit planets 360/(ZB-ZA) apart). Every SUN is a plain ply gear, 3 layers, teeth cut as the envelope of the pins (clock_lantern.py). Each mesh is
// wood on steel, and the pins span the sun's whole thickness, so a sun can warp or float along them.
//
// WHAT DRIVES WHAT (each colour is one rigid body that turns as a unit):
//   ORANGE  escape wheel (1 rev/min, seconds pointer) --6 standoffs--> MINUTE CARRIER (back + front annulus, tied by
//           M3 bolts + spacers) --> the minute planet on its M3 axle bolt; counterweight opposite
//   YELLOW  minute planet (lantern): A pins roll round the FIXED 59-tooth sun; B pins turn the 60-tooth MINUTE SUN.
//   RED     MINUTE SUN (on a 608) --5 standoffs--> HOUR CARRIER + MINUTE HAND --> the hour planet
//   PINK    hour planet: A pins roll round the FIXED 55-tooth sun; B pins turn the 60-tooth HOUR SUN.
//   BLUE    HOUR SUN (on a 608) + HOUR HAND (on spacers).
//   GREY    fixed: the rod; each fixed sun bolted (M3) to a 1515 MakerBeam XL piece, an SK8 on the beam clamping the rod.
//   output / carrier = 1 - (ZA * PB) / (PA * ZB): minutes 1 - 59/60 = 1/60, hours 1 - 55/60 = 1/12.
// Lantern, back -> front: cover | disc | [ sun A | gap | sun B ] | disc | cover, clamped by 2 M3 tie bolts (nuts or
// spacers set the gap); it spins on a centre M3 axle bolt nutted to both carriers.
// Output sun = 3 gear layers (22.2 bore: the 608) + a 16-bore keeper ring each side, bolted M3 at r16.
// Viewed from the front (+z toward the viewer); every hand turns clockwise.
// Animate (FPS 20, Steps 200): one run = `minutes_per_anim` minutes.
include <clock_lantern_profiles.scad>

/* [View] */
minutes_per_anim = 60;       // minutes of clock time per animation run
t_fixed = -1;                // >= 0: freeze at this fraction of the run
explode = 0;                 // spread the layers (mm)
section = false;             // cut away y < 0
show_pins = true;

/* [Mounting] */
// SK8, as measured in mowerbot/purchased_parts.scad (sk8_*)
SK8_W = 42; SK8_T = 14; SK8_H = 20; SK8_TOP = 33.5; SK8_UP_W = 20; SK8_FL_H = 6.5; SK8_HOLE = 5.5; SK8_HOLE_CC = 31.5;
BEAM = 15; BEAM_L = 50;      // 1515 MakerBeam XL piece
GAP = 24;                    // escape wheel front ring -> minute carrier
CAR_IN = 44.5;               // back carrier opening radius (SK8 + beam reach 43)
UP_R = 48;                   // minute sun -> hour carrier standoffs radius (outside the hour beam, 43.01; inside the lanterns)
/* [M3 spacing (spacers or nuts on thread)] */
SP_UP = 20;                  // minute sun front keeper -> hour carrier
SP_HAND = 15;                // hour sun front keeper -> hour hand (clear of the front carrier + its nuts)
SP_D = 7;

/* [Hidden] */
T = 2.63; PIN = 2.05; PIN_HOLE = 2.2;
A = CLOCK_A; N = N_PL; P = P_PL;
M_ZA = 59; H_ZA = 55; ZB = 60;
CB = 3;                                   // back carrier -> cover A (axle nut + tie heads)
FC = 3;                                   // cover B -> front carrier (tie nuts)
CAR_OUT = A + 14; FC_IN = A - LANTERN_R + 1;
$fn = 36;
tt = t_fixed >= 0 ? t_fixed : $t;
esc = -360 * minutes_per_anim * tt;
m_out = esc * (1 - M_ZA / ZB);
h_out = m_out * (1 - H_ZA / ZB);
E = explode;

C_FIX = "gainsboro"; C_SEC = "darkorange"; C_MPL = "gold"; C_MIN = "firebrick"; C_HPL = "hotpink"; C_HR = "royalblue";
C_HW = "dimgray"; C_PIN = [0.25, 0.25, 0.28];

module C(col) { color(col) if (section) intersection() { children(); translate([-300, 0, -200]) cube([600, 600, 400]); } else children(); }
module slab(z0, col, h = T) { C(col) translate([0, 0, z0]) linear_extrude(h) children(); }
module ann(r0, r1) { difference() { circle(r = r1, $fn = 120); circle(r = r0, $fn = 72); } }
module standoff(r, a, z0, len, col) { C(col) rotate(a) translate([r, 0, z0]) cylinder(d = 5, h = len, $fn = 6); }
module spacer(p, z0, len) { C("silver") translate([p[0], p[1], z0]) difference() { cylinder(d = SP_D, h = len, $fn = 6); translate([0, 0, -1]) cylinder(d = 3.2, h = len + 2); } }
module nut(p, z0) { C(C_HW) translate([p[0], p[1], z0]) cylinder(d = 6.35, h = 2.4, $fn = 6); }
module m3(p, z0, len) { C(C_HW) translate([p[0], p[1], z0]) { cylinder(d = 3, h = len, $fn = 12); translate([0, 0, -2]) cylinder(d = 5.5, h = 2, $fn = 24); } }
module bearing608(z0) { C("silver") translate([0, 0, z0]) difference() { cylinder(d = 22, h = 7); translate([0, 0, -1]) cylinder(d = 8, h = 9); } }

// z offsets inside one stage (from the back carrier's back face), explode-aware
function zl(i) = T + CB + E + [0, T, 2 * T, 2 * T + ZONE, 3 * T + ZONE, 4 * T + ZONE][i] + E * [0, 1, 2, 6, 7, 8][i];
// 0 cover, 1 disc, 2 zone start, 3 disc, 4 cover, 5 end
function z_sunA() = zl(2) + SUN_CLR + E;
function z_sunB() = z_sunA() + L_SUN * T + SUN_GAP + 2 * E;
function z_fc() = zl(5) + FC + E;
function stage_depth() = z_fc() + T;

module sun(z0, prof, ang, col, bore, holes) {
    for (i = [0:L_SUN - 1]) slab(z0 + i * T, col) rotate(ang) difference() { polygon(prof); circle(d = bore); for (h = holes) translate(h) circle(d = 3.3); }
}

// one lantern, in its own frame (centre at the origin): 16 pins on radius rp between its two discs
module lantern(rp, col) {
    holes = [for (k = [0:P - 1]) [rp * cos(k * 360 / P), rp * sin(k * 360 / P)]];
    module disc(hs) { difference() { circle(r = LANTERN_R, $fn = 64); circle(d = 3.4); for (s = [-1, 1]) translate([0, s * TIE_D]) circle(d = 3.3);
                      for (h = hs) translate(h) circle(d = PIN_HOLE, $fn = 10); } }
    slab(zl(0), col) disc([]); slab(zl(1), col) disc(holes); slab(zl(3), col) disc(holes); slab(zl(4), col) disc([]);
    if (show_pins) C(C_PIN) for (h = holes) translate([h[0], h[1], zl(1)]) cylinder(d = PIN, h = zl(4) - zl(1), $fn = 8);
    for (s = [-1, 1]) let(q = [0, s * TIE_D]) {
        m3(q, zl(0), zl(5) - zl(0) + 2.6); nut(q, zl(5));
        spacer(q, zl(2), zl(3) - zl(2));
    }
}

// one stage: z0 = back carrier's back face; c = carrier angle, o = output sun angle
module stage(z0, ZA, SUN_A, SUN_B, rp, c, o, CCAR, CPL, COUT) {
    translate([0, 0, z0]) {
        // CARRIERS: back annulus (opening for the fixed sun's mount) + front annulus, tied by M3 + spacers between planets
        // tie posts at 90 and 270 deg; COUNTERWEIGHT at 180 deg (a stack of washers on an M5 bolt, tuned by balancing)
        for (zc = [0, z_fc()]) slab(zc, CCAR) rotate(c) difference() { ann(zc == 0 ? CAR_IN : FC_IN, CAR_OUT); for (k = [0:3]) rotate(k * 90) translate([A, 0]) circle(d = k == 2 ? 5.3 : 3.3); }
        for (a = [90, 270]) rotate(c + a) { spacer([A, 0], T, z_fc() - T); m3([A, 0], 0, z_fc() + T + 2.6); nut([A, 0], z_fc() + T); }
        rotate(c + 180) { C(C_HW) translate([A, 0, -2]) cylinder(d = 5, h = z_fc() + T + 6, $fn = 16);
            C("silver") for (i = [0:3]) translate([A, 0, T + 2 + i * 1.6]) difference() { cylinder(d = 20, h = 1.5); translate([0, 0, -1]) cylinder(d = 5.3, h = 4); } }
        // FIXED SUN A + its mount behind it: 1515 beam bolted flat to its back, SK8 on the beam round the rod
        sun(z_sunA(), SUN_A, 0, C_FIX, 8.4, [[-15, -27.5], [15, -27.5], [-15, 27.5], [15, 27.5]]);
        for (h = [[-15, -27.5], [15, -27.5], [-15, 27.5], [15, 27.5]]) { m3(h, z_sunA() - (h[1] < 0 ? 12 : 0), L_SUN * T + (h[1] < 0 ? 12 : 0) + 2.6); nut(h, z_sunA() + L_SUN * T); }
        C(C_FIX) translate([0, 0, z_sunA()]) mirror([0, 0, 1]) {
            translate([-BEAM_L / 2, -SK8_H - BEAM, 0]) cube([BEAM_L, BEAM, BEAM]);
            translate([0, -SK8_H, 0.5]) difference() {
                union() { translate([-SK8_W / 2, 0, 0]) cube([SK8_W, SK8_FL_H, SK8_T]); translate([-SK8_UP_W / 2, 0, 0]) cube([SK8_UP_W, SK8_TOP, SK8_T]); }
                translate([0, SK8_H, -1]) cylinder(d = 8.2, h = SK8_T + 2);
                for (x = [-1, 1]) translate([x * SK8_HOLE_CC / 2, -1, SK8_T / 2]) rotate([-90, 0, 0]) cylinder(d = SK8_HOLE, h = SK8_FL_H + 2);
            }
        }
        // OUTPUT SUN B: 3 gear layers (608 in their 22.2 bore) + a 16-bore keeper ring each side, 3 M3 at r16
        hb = [for (k = [0:2]) [16 * cos(k * 120 + 60), 16 * sin(k * 120 + 60)]];
        sun(z_sunB(), SUN_B, o, COUT, 22.2, hb);
        for (zz = [z_sunB() - T, z_sunB() + L_SUN * T]) slab(zz, COUT) rotate(o) difference() { circle(r = 21); circle(d = 16); for (h = hb) translate(h) circle(d = 3.3); }
        rotate(o) for (h = hb) { m3(h, z_sunB() - T, (L_SUN + 2) * T + 2.6); nut(h, z_sunB() + (L_SUN + 1) * T); }
        bearing608(z_sunB() + 0.4);
        // THE PLANET (lantern) on its axle bolt: its turn rolling on the fixed sun (the same pins then fit the output sun)
        psi = c * (1 + ZA / P);
        rotate(c) translate([A, 0]) {
            m3([0, 0], 0, z_fc() + T + 2.6); nut([0, 0], T); nut([0, 0], z_fc() - 2.4); nut([0, 0], z_fc() + T);
            rotate(psi - c) lantern(rp, CPL);
        }
    }
}

module train() {
    zw = -GAP - 2;
    // ORANGE: escape wheel (schematic front ring) + seconds pointer + standoffs to the minute carrier
    slab(zw, C_SEC) rotate(esc) ann(92, 122);
    C(C_SEC) translate([0, 0, zw + T]) rotate(esc) translate([112, -3]) cube([22, 6, 2]);
    for (k = [0:5]) standoff(80, esc + k * 60 + 30, zw + T, -zw - T, C_SEC);
    stage(0, M_ZA, sun_minute_A(), sun_minute_B(), minute_r, esc, m_out, C_SEC, C_MPL, C_MIN);
    // RED: minute sun front keeper -> 5 standoffs -> hour carrier (+ minute hand on its back face)
    z_mk = z_sunB() + (L_SUN + 1) * T;                     // front face of the minute sun's front keeper
    z_h = z_mk + SP_UP + 4 * E;
    for (k = [0:4]) standoff(UP_R, m_out + k * 72 + 36, z_sunB() + L_SUN * T, z_h - z_sunB() - L_SUN * T, C_MIN);
    stage(z_h, H_ZA, sun_hour_A(), sun_hour_B(), hour_r, m_out, h_out, C_MIN, C_HPL, C_HR);
    C(C_MIN) translate([0, 0, z_h - 1.6]) rotate(m_out) translate([UP_R - 4, -3.5]) cube([100, 7, 1.6]);   // minute hand
    // BLUE: SP_HAND spacers on the hour sun's 3 bolts, hour hand (with a round hub) on them, clear of the front carrier
    z_hk = z_h + z_mk;
    z_hh = z_hk + SP_HAND + E;
    rotate(h_out) for (k = [0:2]) spacer([16 * cos(k * 120 + 60), 16 * sin(k * 120 + 60)], z_hk + 2.4, SP_HAND - 2.4);
    slab(z_hh, C_HR) rotate(h_out) difference() { union() { circle(r = 21); translate([0, -4]) square([80, 8]); }
        circle(d = 8.4); for (k = [0:2]) rotate(k * 120 + 60) translate([16, 0]) circle(d = 3.3); }
    // GREY: the rod + front collar
    C(C_FIX) translate([0, 0, zw - 20]) cylinder(d = 8, h = z_hh + T + 16 - zw + 20);
    C(C_HW) translate([0, 0, z_hh + T + 3]) difference() { cylinder(d = 16, h = 8); translate([0, 0, -1]) cylinder(d = 8, h = 10); }
}

train();
