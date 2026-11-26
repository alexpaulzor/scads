// Clock train MVP, PIN-WHEEL version: two "differential sun" planetaries on the FIXED escape-wheel axle (smooth 8 mm
// rod). No dial, no ring gears; the hands come straight off the parts that turn at the right speed.
// Every SUN is a pin wheel: 2.05 wire pins between TWO ply discs, ends bent over (radially inward) on the discs' outer
// faces. Every PLANET is a ply gear 2 layers thick with teeth cut as the envelope of the pins (clock_pins.py), so each
// mesh is wood on steel and a planet can float along its pins without losing the mesh.
//
// WHAT DRIVES WHAT (each colour is one rigid body that turns as a unit):
//   ORANGE  escape wheel (1 rev/min, seconds pointer) --6 standoffs--> MINUTE CARRIER (back + front annulus, tied by 3
//           M3 bolts + 40 spacers between the planets) --> minute planets
//   YELLOW  minute planet: gear A (2 layers) + 15 spacer + gear B (2 layers), clamped by one M3 bolt + nuts; the bolt is
//           the planet's shaft, turning in holes in both carriers.
//           gear A rolls round the FIXED 59-pin sun; gear B turns the 60-pin MINUTE SUN.
//   RED     MINUTE SUN (on a 608) --5 standoffs--> HOUR CARRIER + MINUTE HAND --> hour planets
//   PINK    hour planet: gear A rolls round the FIXED 55-pin sun; gear B turns the 60-pin HOUR SUN.
//   BLUE    HOUR SUN (on a 608) + HOUR HAND.
//   GREY    fixed: the rod; each fixed sun bolted (M3) to a 1515 MakerBeam XL piece, an SK8 on the beam clamping the rod.
//   output / carrier = 1 - (ZA * PB) / (PA * ZB): minutes 1 - 59/60 = 1/60, hours 1 - 55/60 = 1/12.
// Stage stack (back -> front): back carrier | bend room | sun A back disc | planet A | sun A front disc | 2 rows of bent
// ends | sun B back disc | planet B | sun B front disc | front carrier. A fixed sun's discs are held apart by 8 spacers
// on its 4 M3 bolts (2 of them into the beam); an output sun's by 3 cut rings that are also its 608 housing.
// Only the pins the teeth work on are wire; everything that just holds parts apart is a bought M3 spacer (SP_*).
// Viewed from the front (+z toward the viewer); every hand turns clockwise.
// Animate (FPS 20, Steps 200): one run = `minutes_per_anim` minutes.
include <clock_pins_profiles.scad>

/* [View] */
minutes_per_anim = 60;       // minutes of clock time per animation run
t_fixed = -1;                // >= 0: freeze at this fraction of the run
explode = 0;                 // spread the layers (mm)
section = false;             // cut away the near half (see the stack from the side)
show_pins = true;            // draw the sun pins (slow)

/* [Mounting] */
// SK8, as measured in mowerbot/purchased_parts.scad (sk8_*): flange width, length along the rod, rod centre above the base,
// total height, upright width, flange height, bolt holes (d, centre-centre)
SK8_W = 42; SK8_T = 14; SK8_H = 20; SK8_TOP = 33.5; SK8_UP_W = 20; SK8_FL_H = 6.5; SK8_HOLE = 5.5; SK8_HOLE_CC = 31.5;
BEAM = 15; BEAM_L = 50;      // 1515 MakerBeam XL piece
GAP = 24;                    // escape wheel front ring -> minute carrier
/* [Bought M3 spacers] */
SP_SUN = 8;                  // a sun's two discs apart
SP_HUB = 15;                 // planet: gear A to gear B
SP_CAGE = 40;                // back carrier to front carrier
SP_UP = 20;                  // minute sun front disc -> hour carrier
SP_HAND = 12;                // hour sun front disc -> hour hand (clear of the front carrier + its nuts)
SP_D = 7;                    // spacer diameter as drawn
CAR_IN = 44.5;               // back carrier opening radius (SK8 + beam reach 43)
UP_R = 50;                   // minute sun -> hour carrier standoffs radius

/* [Hidden] */
T = 2.63; PIN = 2.05; PIN_HOLE = 2.2; BEND_L = 4;
A = 72; P = 12; N = 3;       // both stages: centre distance, planet teeth, planets
M_ZA = 59; H_ZA = 55; ZB = 60;
CB = 3; G = SP_SUN; MID = SP_HUB - SP_SUN;   // bend room behind sun A; disc-to-disc round a planet; between the two suns
FG = SP_CAGE - (CB + 4 * T + 2 * G + MID);    // sun B front disc -> front carrier
CAR_OUT = A + 14; FC_IN = max(minute_A_RIM, minute_B_RIM, hour_A_RIM) + 1;
$fn = 36;
tt = t_fixed >= 0 ? t_fixed : $t;
esc = -360 * minutes_per_anim * tt;
m_out = esc * (1 - M_ZA / ZB);
h_out = m_out * (1 - H_ZA / ZB);
E = explode;

C_FIX = "gainsboro"; C_SEC = "darkorange"; C_MPL = "gold"; C_MIN = "firebrick"; C_HPL = "hotpink"; C_HR = "royalblue";
C_HW = "dimgray"; C_PIN = [0.25, 0.25, 0.28];

// colour + (with section) cut away y < 0 inside the colour, so cut faces keep the part's colour
module C(col) { color(col) if (section) intersection() { children(); translate([-300, 0, -200]) cube([600, 600, 400]); } else children(); }
module slab(z0, col, h = T) { C(col) translate([0, 0, z0]) linear_extrude(h) children(); }
module ann(r0, r1) { difference() { circle(r = r1, $fn = 120); circle(r = r0, $fn = 72); } }
module standoff(r, a, z0, len, col) { C(col) rotate(a) translate([r, 0, z0]) cylinder(d = 5, h = len, $fn = 6); }
module spacer(p, z0, len) { C("silver") translate([p[0], p[1], z0]) difference() { cylinder(d = SP_D, h = len, $fn = 6); translate([0, 0, -1]) cylinder(d = 3.2, h = len + 2); } }
module nut(p, z0) { C(C_HW) translate([p[0], p[1], z0]) cylinder(d = 6.35, h = 2.4, $fn = 6); }
module bearing608(z0) { C("silver") translate([0, 0, z0]) difference() { cylinder(d = 22, h = 7); translate([0, 0, -1]) cylinder(d = 8, h = 9); } }
module bolt(z0, len, col) { C(col) { cylinder(d = 3, h = len, $fn = 12); translate([0, 0, z0 - 2]) cylinder(d = 5.5, h = 2, $fn = 6); } }

// a pin wheel: back disc at z0, 3 hub rings, front disc; Z pins on radius R, bent inward on both outer faces
module pin_wheel(z0, Z, R, RIM, ang, col, bore, hub_in, hub_out, holes, rings) {
    zf = z0 + T + G + 2 * E;
    for (zz = [z0, zf]) slab(zz, col) rotate(ang) difference() {
        circle(r = RIM, $fn = 120); circle(d = bore);
        for (k = [0:Z - 1]) rotate((k + 0.5) * 360 / Z) translate([R, 0]) circle(d = PIN_HOLE, $fn = 10);
        for (h = holes) translate(h) circle(d = 3.3);
    }
    if (rings) for (i = [0:2]) slab(z0 + T + E + i * (G + E) / 3, col, G / 3 - 0.05) rotate(ang) difference() { ann(hub_in, hub_out); for (h = holes) translate(h) circle(d = 3.3); }
    else rotate(ang) for (h = holes) spacer(h, z0 + T + E, G + E);
    rotate(ang) for (h = holes) { C(C_HW) translate([h[0], h[1], z0 - 2]) cylinder(d = 3, h = zf + T - z0 + 5, $fn = 12); nut(h, zf + T); }
    if (show_pins) C(C_PIN) rotate(ang) for (k = [0:Z - 1]) rotate((k + 0.5) * 360 / Z) translate([R, 0, 0]) {
        translate([0, 0, z0 - PIN / 2]) cylinder(d = PIN, h = zf + T - z0 + PIN, $fn = 8);
        for (zz = [z0 - PIN / 2, zf + T + PIN / 2]) translate([-BEND_L, 0, zz]) rotate([0, 90, 0]) cylinder(d = PIN, h = BEND_L, $fn = 8);
    }
}

// one stage: z0 = back carrier's back face; c = carrier angle, o = output sun angle
module stage(z0, ZA, PROF_A, PROF_B, RA, RIMA, RB, RIMB, c, o, CCAR, CPL, COUT) {
    z_fa = z0 + T + CB + E;                 // sun A back disc
    z_fb = z_fa + 2 * T + G + 3 * E + MID;  // sun B back disc
    z_fc = z_fb + 2 * T + G + 3 * E + FG;   // front carrier
    // CARRIERS: back annulus (opening for the fixed sun's mount) + front annulus, tied by 3 M3 bolts + SP_CAGE spacers
    // between the planets; the planet shafts turn in the other 3 holes
    slab(z0, CCAR) rotate(c) difference() { ann(CAR_IN, CAR_OUT); for (k = [0:2 * N - 1]) rotate(k * 180 / N) translate([A, 0]) circle(d = 3.3); }
    slab(z_fc, CCAR) rotate(c) difference() { ann(FC_IN, CAR_OUT); for (k = [0:2 * N - 1]) rotate(k * 180 / N) translate([A, 0]) circle(d = 3.3); }
    for (k = [0:N - 1]) rotate(c + (k + 0.5) * 360 / N) {
        spacer([A, 0], z0 + T, z_fc - z0 - T);
        translate([A, 0, 0]) bolt(z0, z_fc + T + 3 - z0, C_HW); nut([A, 0], z_fc + T);
    }
    // FIXED SUN A (pin wheel) + its mount behind it: 1515 beam bolted flat to the back disc, SK8 on the beam round the rod
    pin_wheel(z_fa, ZA, RA, RIMA, 0, C_FIX, 8.4, 0, 0, [[-15, -27.5], [15, -27.5], [-15, 27.5], [15, 27.5]], false);
    C(C_FIX) translate([0, 0, z_fa]) mirror([0, 0, 1]) {
        translate([-BEAM_L / 2, -SK8_H - BEAM, 0]) cube([BEAM_L, BEAM, BEAM]);
        translate([0, -SK8_H, 0.5]) difference() {
            union() { translate([-SK8_W / 2, 0, 0]) cube([SK8_W, SK8_FL_H, SK8_T]); translate([-SK8_UP_W / 2, 0, 0]) cube([SK8_UP_W, SK8_TOP, SK8_T]); }
            translate([0, SK8_H, -1]) cylinder(d = 8.2, h = SK8_T + 2);
            for (x = [-1, 1]) translate([x * SK8_HOLE_CC / 2, -1, SK8_T / 2]) rotate([-90, 0, 0]) cylinder(d = SK8_HOLE, h = SK8_FL_H + 2);
        }
    }
    // OUTPUT SUN B (pin wheel) on its 608 (in the hub rings; the discs' 16 bore keeps it in)
    pin_wheel(z_fb, ZB, RB, RIMB, o, COUT, 16, 11.1, 21, [for (k = [0:2]) [16 * cos(k * 120 + 60), 16 * sin(k * 120 + 60)]], true);
    bearing608(z_fb + T + E + 0.4);
    // PLANETS: gear A (2 layers) in sun A's gap, gear B (2 layers) in sun B's gap, SP_HUB spacer between, all clamped by
    // one M3 bolt + 2 nuts; the bolt is the shaft (head behind the back carrier, a loose nut in front of the front one)
    z_pa = z_fa + T + E + (G - 2 * T) / 2; z_pb = z_fb + T + E + (G - 2 * T) / 2;
    for (k = [0:N - 1]) {
        th = c + k * 360 / N;
        psiA = th * (1 + ZA / P);
        psiB = th + (th - o) * ZB / P;
        rotate(th) translate([A, 0]) {
            for (i = [0:1]) slab(z_pa + i * T, CPL) rotate(psiA - th) difference() { polygon(PROF_A); circle(d = 3.3); }
            for (i = [0:1]) slab(z_pb + i * T, CPL) rotate(psiB - th) difference() { polygon(PROF_B); circle(d = 3.3); }
            spacer([0, 0], z_pa + 2 * T, z_pb - z_pa - 2 * T);
            bolt(z0, z_fc + T + 3 - z0, C_HW);
            nut([0, 0], z_pa - 2.4); nut([0, 0], z_pb + 2 * T); nut([0, 0], z_fc + T);
        }
    }
}
function stage_depth() = T + CB + 2 * (2 * T + G) + MID + FG + T + 7 * E;

module train() {
    zw = -GAP - 2;
    // ORANGE: escape wheel (schematic front ring) + seconds pointer + standoffs to the minute carrier
    slab(zw, C_SEC) rotate(esc) ann(92, 122);
    C(C_SEC) translate([0, 0, zw + T]) rotate(esc) translate([112, -3]) cube([22, 6, 2]);
    for (k = [0:5]) standoff(80, esc + k * 60 + 30, zw + T, -zw - T, C_SEC);
    stage(0, M_ZA, planet_minute_A(), planet_minute_B(), minute_A_R, minute_A_RIM, minute_B_R, minute_B_RIM, esc, m_out, C_SEC, C_MPL, C_MIN);
    // RED: minute sun front disc -> 5 standoffs -> hour carrier (+ minute hand on its back face)
    z_mfd = T + CB + 2 * (2 * T + G) + MID - T + 6 * E;     // minute sun front disc (back face)
    z_h = z_mfd + T + SP_UP + E;
    for (k = [0:4]) standoff(UP_R, m_out + k * 72 + 36, z_mfd + T, z_h - z_mfd - T, C_MIN);
    stage(z_h, H_ZA, planet_hour_A(), planet_hour_B(), hour_A_R, hour_A_RIM, hour_B_R, hour_B_RIM, m_out, h_out, C_MIN, C_HPL, C_HR);
    C(C_MIN) translate([0, 0, z_h - 1.6]) rotate(m_out) translate([UP_R - 4, -3.5]) cube([96, 7, 1.6]);        // minute hand
    // BLUE: SP_HAND spacers on the hour sun's 3 bolts, hour hand (with a round hub) on them, clear of the front carrier
    z_hfd = z_h + z_mfd + T;
    z_hh = z_hfd + SP_HAND + E;
    rotate(h_out) for (k = [0:2]) spacer([16 * cos(k * 120 + 60), 16 * sin(k * 120 + 60)], z_hfd + 2.4, SP_HAND - 2.4);
    slab(z_hh, C_HR) rotate(h_out) difference() { union() { circle(r = 21); translate([0, -4]) square([76, 8]); }
        circle(d = 8.4); for (k = [0:2]) rotate(k * 120 + 60) translate([16, 0]) circle(d = 3.3); }
    // GREY: the rod + front collar
    C(C_FIX) translate([0, 0, zw - 20]) cylinder(d = 8, h = z_hh + T + 16 - zw + 20);
    C(C_HW) translate([0, 0, z_hh + T + 3]) difference() { cylinder(d = 16, h = 8); translate([0, 0, -1]) cylinder(d = 8, h = 10); }
}

train();
