// Minute reduction: a Wolfrom planetary, 60:1 in one stage, concentric with the escape wheel (seconds).
//   sun 21 (on the escape wheel, 1 rev/min) -> 4 planets 19 -> fixed ring 59 (on the frame)
//                                                       \-> output ring 63 (free: carries the minute hand)
// The planets mesh both rings. The output ring and the planets' second layer are cut at a slightly smaller module
// (MOD2) so its centre distance matches: same 19 teeth, two layers pinned together.
// Ratio (1 + 59/21) / (1 - 59/63) = 60. Equal spacing of 4 planets: (21 + 59) / 4 and (63 - 59) / 4 are whole.
// Animate (FPS 20, Steps 120): one animation = one minute of the sun (seconds hand) = 6 deg of the minute ring.
// Ply3 layers, front to back: carrier front / planet layer B + output ring / planet layer A + sun + fixed ring / carrier back.

/* [Gears] */
MOD = 2.0;                     // module of the sun / planet layer A / fixed ring
ZS = 21; ZP = 19; Z1 = 59; Z2 = 63;
N_PL = 4;
PA = 20;                       // pressure angle
T = 2.63;                      // ply3
ring_rim = 8;                  // ring gear rim width outside the tooth roots
show_hands = true;
explode = 0;                   // spread the layers apart (mm) to see them
t_fixed = -1;                  // >= 0: freeze at this fraction of a minute; -1: animate

/* [Hidden] */
A = MOD * (ZS + ZP) / 2;                       // centre distance (40 at module 2)
MOD2 = 2 * A / (Z2 - ZP);                      // output ring + planet layer B module (1.818)
$fn = 48;
sun_a = 360 * (t_fixed >= 0 ? t_fixed : $t);  // sun: one turn per animation (= one minute)
car_a = sun_a * ZS / (ZS + Z1);                // carrier (fixed ring 1)
pl_rel = -(sun_a - car_a) * ZS / ZP;           // planet spin relative to the carrier
ring2_a = car_a + pl_rel * ZP / Z2;            // output ring: sun / 60
echo(str("module 2 layer ", MOD2, "; centre distance ", A, "; output ring turns ", ring2_a, " deg per sun turn of ", sun_a,
         " -> ratio ", sun_a / max(ring2_a, 1e-9)));

function inv(a) = tan(a) - a * PI / 180;       // involute function (a in deg)
// one involute flank point at radius r for base radius rb (angle in deg)
function flank(rb, r) = let(a = acos(rb / r)) [r, inv(a) * 180 / PI];

// 2D external involute gear (z teeth, module m); add = addendum, ded = dedendum (in modules)
module gear2d(z, m, add = 1.0, ded = 1.25) {
    rp = m * z / 2; rb = rp * cos(PA); ra = rp + add * m; rf = max(rp - ded * m, 1);
    half = 90 / z + inv(PA) * 180 / PI;        // half tooth angle at the base circle
    steps = 8;
    pts = [for (i = [0:steps]) let(r = max(rb, rf) + (ra - max(rb, rf)) * i / steps, f = flank(rb, r)) [r, half - f[1]]];
    tooth = concat([[rf, half + 360 / z / 4 * 0]], [for (p = pts) [p[0] * cos(p[1]), p[0] * sin(p[1])]],
                   [for (i = [steps:-1:0]) let(p = pts[i]) [p[0] * cos(-p[1]), p[0] * sin(-p[1])]]);
    union() {
        circle(r = rf);
        for (k = [0:z - 1]) rotate(k * 360 / z) polygon(concat([[0, 0]], [for (p = tooth) p]));
    }
}

module ring2d(z, m) {                          // internal gear: a disc with an external gear's shape as the hole
    difference() {
        circle(r = m * z / 2 + 1.25 * m + ring_rim);
        offset(delta = 0.15) gear2d(z, m, add = 1.25, ded = 1.0);
    }
}

module layer(z_off, col) { color(col) translate([0, 0, z_off]) linear_extrude(T) children(); }

E = explode;
// fixed ring (frame) with the sun and planet layer A in its plane
layer(0, "burlywood") ring2d(Z1, MOD);
layer(0, "goldenrod") rotate(sun_a + 180 / ZS) difference() { gear2d(ZS, MOD); circle(d = 22.2); }     // sun: 608 seat
for (k = [0:N_PL - 1]) rotate(car_a + k * 360 / N_PL) translate([A, 0]) {
    layer(0, "peru") rotate(pl_rel + (k % 2) * 180 / ZP) difference() { gear2d(ZP, MOD); circle(d = 3.3); }
    layer(T + E, "sienna") rotate(pl_rel + (k % 2) * 180 / ZP) difference() { gear2d(ZP, MOD2); circle(d = 3.3); }
}
// output ring (minute) in planet layer B's plane
layer(T + E, "tan") rotate(ring2_a) ring2d(Z2, MOD2);
// carrier plates front and back (M3 planet axles)
for (zc = [-T - E, 2 * T + 2 * E]) layer(zc, [0.55, 0.55, 0.6, 0.5]) rotate(car_a) difference() {
    circle(r = A + 6);
    circle(d = 22.2);
    for (k = [0:N_PL - 1]) rotate(k * 360 / N_PL) translate([A, 0]) circle(d = 3.3);
}
// hands: seconds on the sun (escape wheel), minute on the output ring
if (show_hands) {
    color("black") translate([0, 0, 3 * T + 3 * E + 2]) rotate(sun_a) translate([-5, -1]) cube([95, 2, 1]);
    color("darkred") translate([0, 0, 3 * T + 3 * E + 4]) rotate(ring2_a) translate([-4, -2]) cube([75, 4, 1]);
}
