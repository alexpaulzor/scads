// Full ball lift: bottom feeder, a 300 mm (10-hole) sieve in the middle, and an upside-down feeder
// on top whose trough carries balls OUT, 100 mm, and drops them through a 20 mm hole onto a
// track below.
//
// Built on feeder.scad (all feeder parameters and parts come from there; edit them there).
// This file adds the sieve, the beams, the top feeder's placement and the exit trough.
//
// Coordinates: x across the plates, y through them (front keeper at -y), z up. The bottom
// funnel's bottom edge is z = 0.
//
//   openscad lift_full.scad                       # the assembly
//   openscad -D 'part="exit_floor"' -D laser=true lift_full.scad -o f.svg   # 2D exit-trough parts

include <feeder.scad>

part = "full";            // [full, exit_floor, exit_side_x2, exit_cap]
show_beams = false;       // feeder.scad's single-feeder beams; this file draws full-length ones
show_sieve = false;       // feeder.scad's stub; this file draws the 10-hole sieve

/* [Lift] */
SIEVE_HOLES = 10;         // 10 x 30 = 300 long
SIEVE_L = SIEVE_HOLES * PITCH;
Z_SIEVE = H;              // sieve sits on top of the bottom funnel
Z_TOP = H + SIEVE_L + H;  // top of the upside-down top funnel (it occupies Z_TOP - H .. Z_TOP)

/* [Exit trough (top feeder)] */
EXIT_L = 100;             // length out from the front keeper's outer face
EXIT_SLOPE = 3;           // [0:0.5:10] floor falls this many degrees away from the port
EXIT_HOLE = 20;           // drop hole at the far end
EXIT_SIDE = "front";      // [front, back] which face of the top feeder the trough leaves from
EXIT_WALL_H = PORT;       // side wall height above the floor
TRACK_DROP = 45;          // track wires this far under the hole (drawing only)

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
  rotate([-EXIT_SLOPE, 0, 0]) {            // floor falls away from the port
    color("peru") translate([0, 0, -T]) mirror([0, 1, 0]) linear_extrude(T) exit_floor2d();
    color("peru") for (sx = [-1, 1]) translate([sx * (PORT / 2 + T / 2) - T / 2, 0, -T])
      rotate([90, 0, 90]) mirror([1, 0, 0]) linear_extrude(T) exit_side2d();
    color("peru") translate([0, -EXIT_L, -T]) rotate([90, 0, 0]) linear_extrude(T) exit_cap2d();
    if (show_balls) color("steelblue") {
      translate([0, -BALL_D / 2 - 6, BALL_D / 2]) sphere(d = BALL_D);                       // rolling out
      translate([0, -EXIT_HOLE_V, BALL_D / 2 - 6]) sphere(d = BALL_D);                      // dropping through
    }
  }
}

module track3d() {                          // whatever catches the ball: two wire rails, drawing only
  hz = EXIT_Z0 - EXIT_HOLE_V * sin(EXIT_SLOPE) - T - TRACK_DROP;
  color("silver") for (sx = [-1, 1]) translate([PORT_C[0] - 60, Y_EXIT - EXIT_HOLE_V * cos(EXIT_SLOPE) + sx * 6, hz])
    rotate([0, 90 + 2, 0]) cylinder(d = TUN_WIRE, h = 120, $fn = 12);
  if (show_balls) color("steelblue") translate([PORT_C[0] + 25, Y_EXIT - EXIT_HOLE_V * cos(EXIT_SLOPE), hz + BALL_D / 2 + 1]) sphere(d = BALL_D);
}

Y_EXIT = EXIT_SIDE == "front" ? Y_FK : Y_BK + T;  // the face the exit trough leaves from

module full() {
  assembly("trough");                                                       // bottom feeder, ball comes in at the port
  sieve3d();
  translate([0, 0, Z_TOP]) mirror([0, 0, 1]) assembly("none");              // top feeder, upside down
  translate([PORT_C[0], Y_EXIT, EXIT_Z0]) mirror([0, EXIT_SIDE == "front" ? 0 : 1, 0]) exit_trough3d();
  track3d();
  // beams: F (fixed) between the funnels' F_END lines, M (moving) full height
  color("lightsteelblue") translate([COL_W - 20, -20, F_END]) beam2020(Z_TOP - 2 * F_END);
  color("rosybrown") translate([COL_W - 60, -8.4, -10]) beam2020(Z_TOP + 20);
  if (show_balls) color("steelblue") for (i = [0 : 2 : SIEVE_HOLES - 1])
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
