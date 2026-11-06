// Full ball lift: bottom feeder, a 300 mm (10-hole) sieve in the middle, and the DISPENSER on top: the
// same feeder parts flipped over. By default its port carries the wire-track interface (tunnel flange
// + relief, see feeder.scad) and the balls leave along the wire tunnel. EXIT_STYLE = "trough" gives the
// 100 mm drop trough with a 20 mm hole instead.
//
// Built on feeder.scad (all feeder parameters and parts come from there; edit them there).
// This file adds the sieve, the beams, the top feeder's placement and the exit trough.
//
// Coordinates: x across the plates, y through them (front keeper at -y), z up. The bottom
// funnel's bottom edge is z = 0.
//
//   openscad lift_full.scad                       # the assembly
//   View > Animate (FPS 12, Steps 24) in the GUI, or:  openscad --animate 24 -o frame.png lift_full.scad
//   One $t cycle = one lift stroke: S_M rises a stroke carrying every column ball up one hole, then
//   drops back; balls flow in through the bottom trough and out through the exit trough and its hole.
//   The rig's rocking (+6 / -18 deg tilt) is not shown: only the lift motion.
//   openscad -D 'part="exit_floor"' -D laser=true lift_full.scad -o f.svg   # 2D exit-trough parts

include <feeder.scad>

part = "full";            // [full, exit_floor, exit_side_x2, exit_cap]
show_beams = false;       // feeder.scad's single-feeder beams; this file draws full-length ones
show_sieve = false;       // feeder.scad's stub; this file draws the 10-hole sieve

/* [Lift] */
SIEVE_HOLES = 5;          // 5 x 30 = 150: the lift span between feeder and dispenser
SIEVE_L = SIEVE_HOLES * PITCH;
Z_SIEVE = H;              // sieve sits on top of the bottom funnel
Z_TOP = H + SIEVE_L + H;  // top of the upside-down top funnel (it occupies Z_TOP - H .. Z_TOP)

/* [Dispenser exit (top feeder)] */
EXIT_STYLE = "wire";      // [wire, trough] wire = tunnel flange + relief on the port, the wire track leaves from it; trough = the 100 mm drop trough
EXIT_L = 100;             // length out from the front keeper's outer face
EXIT_SLOPE = 3;           // [0:0.5:10] floor falls this many degrees away from the port
EXIT_HOLE = 20;           // drop hole at the far end
EXIT_SIDE = "front";      // [front, back] which face of the top feeder the trough leaves from
EXIT_WALL_H = PORT;       // side wall height above the floor
TRACK_DROP = 45;          // track wires this far under the hole (drawing only)

/* [Animation] */
animate = true;           // false: the static picture (balls at fixed spots)
STROKE = 34;              // S_M stroke = pitch + 2 x drop (NOTES: lift_demo.scad)
DROP = (STROKE - PITCH) / 2;

// ------------------------------------------------------------------ derived
SIEVE_M5_Z = [for (i = [0 : SIEVE_HOLES - 2]) if (i % 2 == 0 || i == SIEVE_HOLES - 2) PITCH * (i + 1)];   // short_parts.rail_m5_x
EXIT_PORT_Z = Z_TOP - PORT_C[1];                 // port centre after the flip
EXIT_Z0 = EXIT_PORT_Z - PORT / 2;                // floor top at the port = port bottom
EXIT_DROP = EXIT_L * tan(EXIT_SLOPE);
EXIT_HOLE_V = EXIT_L - EXIT_HOLE / 2 - WEB;      // hole centre, from the port face along the floor
EXIT_HW = PORT / 2 + T;                          // floor half width (walls stand on it)

// ------------------------------------------------------------------ 2D exit-trough parts (flat, cut files)
// floor (u across, v out from the port face); the walls stand on its edges, the cap on its end
module exit_floor2d() difference() {
  union() {
    translate([-EXIT_HW, 0]) square([2 * EXIT_HW, EXIT_L]);
    translate([-TAB / 2, -T]) square([TAB, T + 0.01]);                         // into the port's bottom notch
  }
  translate([0, EXIT_HOLE_V]) circle(d = EXIT_HOLE, $fn = 96);
}
// side wall (v out from the port face, w up from the floor's underside)
module exit_side2d() union() {
  square([EXIT_L, T + EXIT_WALL_H]);
  translate([-T, T + PORT / 2 - TAB / 2]) square([T + 0.01, TAB]);           // into the port's side notch
}
// end cap (u across, w up from the floor's underside)
module exit_cap2d() translate([-EXIT_HW, 0]) square([2 * EXIT_HW, T + EXIT_WALL_H]);

// ------------------------------------------------------------------ 3D
module sieve3d() color("burlywood") translate([0, 0, Z_SIEVE]) plate3d(0) difference() {
  square([COL_W, SIEVE_L]);
  for (i = [0 : SIEVE_HOLES - 1]) translate([HOLE_X, PITCH / 2 + PITCH * i]) circle(d = HOLE_D);
  for (z = SIEVE_M5_Z) translate([BEAM_X, z]) circle(d = M5, $fn = 32);
}

// the exit trough, in a local frame: origin at the port face's centre-bottom (floor top), v = -y out
module exit_trough3d() {
  rotate([EXIT_SLOPE, 0, 0]) {             // floor falls away from the port (-y)
    color("peru") translate([0, 0, -T]) mirror([0, 1, 0]) linear_extrude(T) exit_floor2d();
    color("peru") for (sx = [-1, 1]) translate([sx * (PORT / 2 + T / 2) - T / 2, 0, -T])
      rotate([90, 0, 90]) mirror([1, 0, 0]) linear_extrude(T) exit_side2d();
    color("peru") translate([0, -EXIT_L, -T]) rotate([90, 0, 0]) linear_extrude(T) exit_cap2d();
    if (show_balls && !animate) color("steelblue") {
      translate([0, -BALL_D / 2 - 6, BALL_D / 2]) sphere(d = BALL_D);                       // rolling out
      translate([0, -EXIT_HOLE_V, BALL_D / 2 - 6]) sphere(d = BALL_D);                      // dropping through
    }
  }
}

module track3d() {                          // whatever catches the ball: two wire rails, drawing only
  hz = EXIT_Z0 - EXIT_HOLE_V * sin(EXIT_SLOPE) - T - TRACK_DROP;
  color("silver") for (sx = [-1, 1]) translate([PORT_C[0] - 60, Y_EXIT - EXIT_HOLE_V * cos(EXIT_SLOPE) + sx * 6, hz])
    rotate([0, 90 + 2, 0]) cylinder(d = TUN_WIRE, h = 120, $fn = 12);
  if (show_balls && !animate) color("steelblue") translate([PORT_C[0] + 25, Y_EXIT - EXIT_HOLE_V * cos(EXIT_SLOPE), hz + BALL_D / 2 + 1]) sphere(d = BALL_D);
}

Y_EXIT = EXIT_SIDE == "front" ? Y_FK : Y_BK + T;  // the face the exit trough leaves from

// ------------------------------------------------------------------ animation
function ease(x) = (1 - cos(180 * max(0, min(1, x)))) / 2;
G_M = $t < 0.5 ? ease(2 * $t) : 1 - ease(2 * $t - 1);   // S_M: 0 = down, 1 = up
DZ_M = animate ? -DROP + STROKE * G_M : 0;              // S_M / M offset from its rest
F_COL = ease(2 * $t);                                   // column balls step up during the up-stroke
N_COL = (Z_TOP - 2 * HOLES[0][1]) / PITCH;              // hole steps from the bottom hole to the top hole (17)
HOLE_Z = EXIT_Z0 - EXIT_HOLE_V * sin(EXIT_SLOPE) - T;   // floor underside at the hole, about
TRACK_Z = EXIT_Z0 - EXIT_HOLE_V * sin(EXIT_SLOPE) - T - TRACK_DROP;
function lerp(a, b, u) = a + (b - a) * u;
function rot_slope(v, h) = [0, -v * cos(EXIT_SLOPE) - h * sin(EXIT_SLOPE), -v * sin(EXIT_SLOPE) + h * cos(EXIT_SLOPE)];
D0 = T / 2 - Y_FK;                                      // funnel plane to the front keeper's face
// ball centre along the whole path; s in ball slots: -1..0 bottom trough, 0..1 bottom channel,
// 1..1+N_COL the column, then the top channel, the exit trough, the drop and the track
function ball_at(s) =
  s < 0 ? [PORT_C[0], lerp(Y_FK - TR_L + BALL_D / 2, T / 2, s + 1), TR_PB + BALL_D / 2]
  : s < 1 ? let(p = PATH[round(60 * s)]) [p[0], T / 2, p[1]]
  : s <= 1 + N_COL ? [HOLE_X, T / 2, HOLES[0][1] + (s - 1) * PITCH]
  : s < 2 + N_COL ? let(p = PATH[round(60 * (2 + N_COL - s))]) [p[0], T / 2, Z_TOP - p[1]]
  : EXIT_STYLE == "wire" ? exit_tunnel_at((s - 2 - N_COL) * EXIT_TUN_TOTAL)   // out along the wire tunnel
  : s < 3 + N_COL ? let(v = -D0 + (s - 2 - N_COL) * (D0 + EXIT_HOLE_V))
      v < 0 ? [PORT_C[0], Y_EXIT - v, EXIT_Z0 + BALL_D / 2]
            : [PORT_C[0], Y_EXIT, EXIT_Z0] + rot_slope(v, BALL_D / 2)
  : let(q = s - 3 - N_COL, h = [PORT_C[0], Y_EXIT, EXIT_Z0] + rot_slope(EXIT_HOLE_V, BALL_D / 2))
      q < 0.45 ? [h[0], h[1], lerp(h[2], TRACK_Z + BALL_D / 2 + 1, pow(q / 0.45, 2))]
               : [h[0] + (q - 0.45) / 0.55 * 60, h[1], TRACK_Z + BALL_D / 2 + 1 - (q - 0.45) / 0.55 * 60 * sin(2)];
module balls_anim() color("steelblue") for (k = [0 : 4 + N_COL]) {
  base = k - 1;
  s = (base < 1 || base >= 1 + N_COL) ? base + $t : base + F_COL;
  if (s <= (EXIT_STYLE == "wire" ? 3 : 4) + N_COL) translate(ball_at(s)) sphere(d = BALL_D, $fn = 32);
}
// S_M: the moving sieve, bolted to M's front face; it carries the column balls up one hole per stroke
module sieve_m3d() color("tan", 0.55) translate([HOLE_X - 30, -8.4, Z_SIEVE + DZ_M]) rotate([90, 0, 0]) linear_extrude(T) difference() {
  square([COL_W, SIEVE_L]);
  for (i = [0 : SIEVE_HOLES - 1]) translate([30, PITCH / 2 + PITCH * i]) circle(d = HOLE_D);
}

// ---- dispenser exit: wire tunnel from the flange, level for EXIT_TUN_L1 then falling at EXIT_TUN_DEG
EXIT_TUN_L1 = 30;
EXIT_TUN_L2 = 140;
EXIT_TUN_DEG = 8;
EXIT_TUN_Y0 = Y_FK - 2 * T;                       // the flange's outer face
EXIT_TUN_TOTAL = (T / 2 - EXIT_TUN_Y0) + EXIT_TUN_L1 + EXIT_TUN_L2;
// ball centre at distance u along the exit path, from the funnel's plane (port centre)
function exit_tunnel_at(u) = let(a = T / 2 - EXIT_TUN_Y0, c = [PORT_C[0], 0, EXIT_PORT_Z])
  u < a + EXIT_TUN_L1 ? c + [0, T / 2 - u, 0]
  : c + [0, EXIT_TUN_Y0 - EXIT_TUN_L1, 0] + (u - a - EXIT_TUN_L1) * [0, -cos(EXIT_TUN_DEG), -sin(EXIT_TUN_DEG)];
module tunnel_seg(L, rings = true) {            // along -y from the origin
  for (a = TUN_ANGLES) translate([TUN_RW * cos(a), 0, TUN_RW * sin(a)]) rotate([90, 0, 0]) cylinder(d = TUN_WIRE, h = L, $fn = 12);
  if (rings) for (k = [1 : floor(L / 25)]) translate([0, -k * 25, 0]) rotate([90, 0, 0])
    rotate_extrude($fn = 64) translate([(TUN_RING_OD - TUN_WIRE) / 2, 0]) circle(d = TUN_WIRE, $fn = 12);
}
module exit_tunnel3d() color("silver") translate([PORT_C[0], EXIT_TUN_Y0, EXIT_PORT_Z]) {
  translate([0, T + 2, 0]) tunnel_seg(T + 2, false);          // the wire ends through the flange + relief
  tunnel_seg(EXIT_TUN_L1);
  translate([0, -EXIT_TUN_L1, 0]) rotate([EXIT_TUN_DEG, 0, 0]) tunnel_seg(EXIT_TUN_L2);
}

module full() {
  assembly("trough", !animate && show_balls, false);                       // bottom feeder, ball comes in at the port
  sieve3d();
  if (animate) sieve_m3d();
  if (animate && show_balls) balls_anim();
  translate([0, 0, Z_TOP]) mirror([0, 0, 1]) assembly(EXIT_STYLE == "wire" ? "flange" : "none", !animate && show_balls, true);   // dispenser: the feeder, upside down
  if (EXIT_STYLE == "wire") exit_tunnel3d();                                  // drawn unmirrored, so it falls away
  if (EXIT_STYLE == "trough") {
    translate([PORT_C[0], Y_EXIT, EXIT_Z0]) mirror([0, EXIT_SIDE == "front" ? 0 : 1, 0]) exit_trough3d();
    track3d();
  }
  // beams: F (fixed) between the funnels' F_END lines, M (moving) full height
  color("lightsteelblue") translate([COL_W - 20, -20, F_END]) beam2020(Z_TOP - 2 * F_END);
  color("rosybrown") translate([COL_W - 60, -8.4, DISP_Y_END - 10 + DZ_M]) beam2020(Z_TOP - 2 * DISP_Y_END + 20);
  if (show_balls && !animate) color("steelblue") for (i = [0 : 2 : SIEVE_HOLES - 1])
    translate([HOLE_X, T / 2, Z_SIEVE + PITCH / 2 + PITCH * i]) sphere(d = BALL_D);
}

echo(str("LIFT: sieve ", SIEVE_HOLES, " holes, ", SIEVE_L, " long, z ", Z_SIEVE, "..", Z_SIEVE + SIEVE_L,
         "; top funnel z ", Z_TOP - H, "..", Z_TOP, "; top hole z ", Z_TOP - HOLES[0][1], "; exit port centre z ", EXIT_PORT_Z));
echo(str("EXIT TROUGH: ", EXIT_L, " long out the ", EXIT_SIDE, ", floor falls ", EXIT_SLOPE, " deg (", round(EXIT_DROP * 10) / 10,
         " mm), ", PORT, " wide inside, drop hole d", EXIT_HOLE, " centred ", EXIT_HOLE_V, " out (ball ", BALL_D,
         ", hole after kerf ~", EXIT_HOLE - KERF, ")"));
echo(str(Z_TOP - HOLES[N_HOLES - 1][1] - (Z_SIEVE + SIEVE_L - PITCH / 2) == PITCH ? "ok   " : "WARN ",
         "hole pitch carries through sieve -> top funnel: ", Z_TOP - HOLES[N_HOLES - 1][1] - (Z_SIEVE + SIEVE_L - PITCH / 2)));

if (part == "full") full();
else if (part == "exit_floor") out2d() exit_floor2d();
else if (part == "exit_side_x2") out2d() exit_side2d();
else if (part == "exit_cap") out2d() exit_cap2d();
