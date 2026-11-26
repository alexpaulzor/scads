// Clock train MVP: two "differential sun" planetaries on the FIXED escape-wheel axle, no dial, no tubes, no ring gears.
// Each stage: the planet CARRIER is the input; sun A is FIXED (clamped to the axle); sun B is the OUTPUT (on a 608) and
// carries its hand directly. Each planet has two layers pinned together, one meshing each sun (the B layer is cut at a
// slightly different module so both share one centre distance).
//   output / carrier = 1 - (ZA * PB) / (PA * ZB)
//   MINUTES: carrier = escape wheel (1 rev/min); fixed sun 59 / planets 12  ||  output sun 60 / planets 12  -> 1/60
//   HOURS:   carrier = minute sun;               fixed sun 22 / planets 10  ||  output sun 24 / planets 10  -> 1/12
// Seconds: the pointer on the escape wheel. Planets are cantilevered on M3 axles from their carrier, so each hand sits
// right in front of its own sun. Viewed from the front (+z toward the viewer); everything turns clockwise.
// Animate (FPS 20, Steps 200): one animation = `minutes_per_anim` minutes.

/* [View] */
minutes_per_anim = 60;       // minutes of clock time per animation run (60: watch the minute hand go round once)
t_fixed = -1;                // >= 0: freeze at this fraction of the run
explode = 0;                 // spread the layers (mm)

/* [Minute stage] */
M_MOD = 1.5; M_ZA = 59; M_PA = 12; M_ZB = 60; M_PB = 12; M_N = 3;
/* [Hour stage] */
H_MOD = 1.5; H_ZA = 22; H_PA = 10; H_ZB = 24; H_PB = 10; H_N = 2;

/* [Hidden] */
T = 2.63; PA_DEG = 20;
$fn = 40;
tt = t_fixed >= 0 ? t_fixed : $t;
esc = -360 * minutes_per_anim * tt;                         // escape wheel (seconds): one turn per minute, clockwise
m_out = esc * (1 - M_ZA * M_PB / (M_PA * M_ZB));            // minute sun
h_out = m_out * (1 - H_ZA * H_PB / (H_PA * H_ZB));          // hour sun
echo(str("per escape-wheel turn: minute sun ", 360 * (1 - M_ZA * M_PB / (M_PA * M_ZB)), " deg (1/", 1 / (1 - M_ZA * M_PB / (M_PA * M_ZB)),
         "), hour sun 1/", 1 / ((1 - M_ZA * M_PB / (M_PA * M_ZB)) * (1 - H_ZA * H_PB / (H_PA * H_ZB)))));

function inv(a) = tan(a) - a * PI / 180;
module gear2d(z, m, bore = 0) {
    rp = m * z / 2; rb = rp * cos(PA_DEG); ra = rp + m; rf = max(rp - 1.25 * m, 1);
    half = 90 / z + inv(PA_DEG) * 180 / PI;
    st = 8;
    pts = [for (i = [0:st]) let(r = max(rb, rf) + (ra - max(rb, rf)) * i / st, a = acos(rb / r)) [r, half - inv(a) * 180 / PI]];
    tooth = concat([for (p = pts) [p[0] * cos(p[1]), p[0] * sin(p[1])]], [for (i = [st:-1:0]) [pts[i][0] * cos(-pts[i][1]), pts[i][0] * sin(-pts[i][1])]]);
    difference() {
        union() { circle(r = rf); for (k = [0:z - 1]) rotate(k * 360 / z) polygon(concat([[0, 0]], tooth)); }
        if (bore > 0) circle(d = bore);
    }
}
module slab(z0, col) { color(col) translate([0, 0, z0]) linear_extrude(T) children(); }

// one stage. carrier angle c (deg), output sun angle o; z0 = carrier plate's back face
module stage(z0, MOD, ZA, PA, ZB, PB, N, c, o, outer_bore, label) {
    A = MOD * (ZA + PA) / 2;                    // centre distance
    MODB = 2 * A / (ZB + PB);
    E = explode;
    // carrier plate (input): an annulus with the planet axles
    slab(z0, [0.55, 0.55, 0.62, 0.85]) rotate(c) difference() {
        circle(r = A + PA * MOD / 2 + 3);
        circle(r = A - PA * MOD / 2 - 2);
        for (k = [0:N - 1]) rotate(k * 360 / N) translate([A, 0]) circle(d = 3.3);
    }
    // layer A: fixed sun (clamped to the axle) + planets' A layers
    slab(z0 + T + E, "burlywood") rotate(180 / ZA) gear2d(ZA, MOD, 8.2);
    // layer B: output sun (608) + planets' B layers
    slab(z0 + 2 * (T + E), "goldenrod") rotate(o + 180 / ZB) gear2d(ZB, MODB, outer_bore);
    for (k = [0:N - 1]) {
        th = c + k * 360 / N;                   // planet position
        psiA = th * (1 + ZA / PA);              // meshing the fixed sun (at 0)
        psiB = th + (th - o) * ZB / PB;         // meshing the output sun (at o)
        rotate(th) translate([A, 0]) {
            slab(z0 + T + E, "peru") rotate(psiA - th) gear2d(PA, MOD, 3.3);
            slab(z0 + 2 * (T + E), "sienna") rotate(psiB - th) gear2d(PB, MODB, 3.3);
        }
    }
}

// escape wheel front ring (schematic) with the seconds pointer
color("tan", 0.5) translate([0, 0, -6]) linear_extrude(T) rotate(esc) difference() { circle(r = 120); circle(r = 70); }
color("black") translate([0, 0, -6 + T]) rotate(esc) translate([110, -3]) square([22, 6]);   // seconds pointer, at 3 o'clock at t = 0

z_m = 0;
stage(z_m, M_MOD, M_ZA, M_PA, M_ZB, M_PB, M_N, esc, m_out, 22.2, "minutes");
z_mh = z_m + 3 * (T + explode);                         // minute hand plane, in front of the minute sun
color("darkred") translate([0, 0, z_mh + 0.5]) rotate(m_out) translate([-6, -2.5]) square([118, 5]) ;   // minute hand
color("darkred") translate([0, 0, z_mh + 0.5]) rotate(m_out) translate([0, 0]) circle(r = 12);
z_h = z_mh + T + 2;
stage(z_h, H_MOD, H_ZA, H_PA, H_ZB, H_PB, H_N, m_out, h_out, 22.2, "hours");
color("navy") translate([0, 0, z_h + 3 * (T + explode) + 0.5]) rotate(h_out) translate([-5, -3]) square([70, 6]);   // hour hand
color("dimgray") translate([0, 0, -12]) cylinder(d = 8, h = z_h + 3 * (T + explode) + 14);   // fixed axle
