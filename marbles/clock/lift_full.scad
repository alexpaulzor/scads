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

part = "full";            // [full, cut, exit_floor, exit_side_x2, exit_cap]  cut = 2D section of the assembly at CUT_Z (top view)
CUT_Z = 190;
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


// ------------------------------------------------------------------ guard rails + V-wheels (2026-11-07)
// The steel balls bent the lift keepers K_F / K_M (300 x 80 plates across the ball gap). They are replaced by
// 2020 rails that stand in the same two planes, held by brackets, and every V-wheel now sits on the
// fixed side, so the moving beam M carries nothing but S_M.
//   R_F  front guard: a 2020 beside F, its back face in F's front-face plane (where K_F was). Corner
//        brackets in the outside corner between F's front face and R_F's side.
//   R_B  back guard: a 2040 (or two 2020s side by side) behind M, RAIL_CLR off M's back face (where K_M
//        was). Its outer half lines up with F's far face, so a flat TIE strip bolts F to it: no keeper
//        spans the gap any more, the load path is 2020 / 2040 all the way.
//   BW   back wheels x2: on a plate on R_B's inner side face, riding M's back V-groove. They hold M across
//        (the V) and push it forward. Eccentric spacer = preload.
//   FW   far wheels x2: on an axle between a FRONT CAGE plate (on R_F's front face) and a BACK CAGE plate
//        (on R_B's back face), riding M's far V-groove. They hold M front-to-back (the V) and push it
//        toward F. The two cage plates also brace R_F to R_B around M. Eccentric spacer = preload.
//   M is captive on the wheels alone: the sieve edges in the near slots only need clearance now.
show_rails = true;
FRONT_GUARD = "keeper";             // [rail, keeper] keeper = clear acrylic K_F on F's front face, held in a wood frame (the far-wheel cage's front plate)
KEEP_T = 3;                         // acrylic keeper thickness
RAIL_CLR = 1;                       // R_B to M's back face
WHEEL_OD = 23.9; WHEEL_W = 10.2;    // solid V-wheel (OpenBuilds), ridge diameter / width
WHEEL_AX = 9.85;                    // axle centre from the groove face (39.7 c-c across a 20 mm beam)
PLATE_T = 3;                        // BW plates (3 mm: the wheel sits close to R_B's side)
CAGE_T = 6;                         // tie strips and cage plates (birch6 / mdf6)

FX0 = COL_W - 20;  FY0 = -20;       // F: x 26..46, y -20..0
MX0 = COL_W - 60;  MY0 = -8.4;      // M: x -14..6, y -8.4..11.6 (rest position)
RZ0 = Z_SIEVE; RZ1 = Z_SIEVE + SIEVE_L;   // rails cover the sieve span between the two boxes
RF = [MX0 + 20, FY0 - 20];                // R_F min corner (x, y)
RB = [MX0 + 20, MY0 + 20 + RAIL_CLR];     // R_B min corner; 40 in x, 20 in y
BW_Y = MY0 + 20 + WHEEL_AX;               // back-wheel axle (along x), centred on M's back groove x
FW_X = MX0 - WHEEL_AX;                    // far-wheel axle (along y), centred on M's far groove y
BW_Z = [RZ0 + 20, RZ1 - 20];
FW_Z = [RZ0 + 50, RZ1 - 50];
BRK_Z = [RZ0 + 12, (RZ0 + RZ1) / 2, RZ1 - 12];
CAGE_X0 = FW_X - 22;                      // cage plates' outer edge
CAGE_Z = [FW_Z[0] - 14, FW_Z[1] + 14];
WHEEL_DEG = animate ? -DZ_M / (WHEEL_OD / 2 - 2.1) * 180 / PI : 0;   // rolls on the groove flanks

show_wheels = true;
module vwheel() if (show_wheels) {        // axis along z, centred
  color("dimgray") rotate([0, 0, WHEEL_DEG]) {
    rotate_extrude($fn = 48) polygon([[2.5, -WHEEL_W / 2], [9.6, -WHEEL_W / 2], [WHEEL_OD / 2, 0], [9.6, WHEEL_W / 2], [2.5, WHEEL_W / 2]]);
    color("orange") translate([6, -1, -WHEEL_W / 2 - 0.2]) cube([3.5, 2, WHEEL_W + 0.4]);   // mark, to see it turn
  }
}
module beam2040(len) { beam2020(len); translate([20, 0, 0]) beam2020(len); }
module corner_bracket() color("silver") difference() {   // 2020 corner bracket, inside corner at the origin, legs +x and -y
  union() { translate([0, -3, -10]) cube([20, 3, 20]); translate([0, -20, -10]) cube([3, 20, 20]);
            hull() { translate([3, -4, -1.5]) cube([0.1, 1, 3]); translate([16, -4, -1.5]) cube([0.1, 1, 3]); translate([3, -17, -1.5]) cube([1, 0.1, 3]); } }
  translate([10, 0, 0]) rotate([90, 0, 0]) cylinder(d = 5.5, h = 10, center = true, $fn = 16);
  translate([0, -10, 0]) rotate([0, 90, 0]) cylinder(d = 5.5, h = 10, center = true, $fn = 16);
}
module tie3d() color("peru") translate([COL_W, FY0, -10]) cube([CAGE_T, RB[1] + 20 - FY0, 20]);   // F's far face -> R_B's far face
module bw3d(z) {
  color("peru") translate([RB[0] - PLATE_T, RB[1], z - 20]) cube([PLATE_T, 20, 40]);
  translate([MX0 + 10, BW_Y, z]) rotate([0, 90, 0]) vwheel();
  color("silver") translate([MX0 + 10, BW_Y, z]) rotate([0, 90, 0]) cylinder(d = 5, h = 2 * (RB[0] - MX0 - 10) + 2, center = true, $fn = 16);
  color("gold") translate([MX0 + 10 + WHEEL_W / 2, BW_Y, z]) rotate([0, 90, 0]) cylinder(d = 7, h = RB[0] - PLATE_T - MX0 - 10 - WHEEL_W / 2, $fn = 6);   // eccentric spacer
}
// front plate of the far-wheel cage: on R_F's front face (rail), or over the keeper on F's front face (keeper)
CAGE_FY = FRONT_GUARD == "rail" ? RF[1] : FY0 - KEEP_T;        // its back face
CAGE_FX1 = FRONT_GUARD == "rail" ? RF[0] + 20 : COL_W;          // its inner edge
CAGE_FZ = FRONT_GUARD == "rail" ? CAGE_Z : [RZ0, RZ1];          // keeper: full height, a frame round the acrylic
CAGE_BZ = CAGE_FZ;
WIN = [MX0 + 16, FX0 + 4];                                      // keeper frame window, x (column x 6..26, F's bolt row at 36)
STANDOFF_Z = FRONT_GUARD == "rail" ? [CAGE_Z[0] + 8, CAGE_Z[1] - 8] : [RZ0 + 8, (RZ0 + RZ1) / 2, RZ1 - 8];
KEEP_X = [MX0 + 12, COL_W];                                     // acrylic K_F: covers the column, bolts on F's front slot
module cage3d() {
  color("peru", 0.8) difference() {
    translate([CAGE_X0, CAGE_FY - CAGE_T, CAGE_FZ[0]]) cube([CAGE_FX1 - CAGE_X0, CAGE_T, CAGE_FZ[1] - CAGE_FZ[0]]);
    if (FRONT_GUARD == "keeper") translate([WIN[0], CAGE_FY - CAGE_T - 1, RZ0 + 12]) cube([WIN[1] - WIN[0], CAGE_T + 2, SIEVE_L - 24]);
  }
  color("peru", 0.8) difference() {                               // back plate on R_B's back face; notched round the back wheels
    translate([CAGE_X0, RB[1] + 20, CAGE_BZ[0]]) cube([RB[0] + 40 - CAGE_X0, CAGE_T, CAGE_BZ[1] - CAGE_BZ[0]]);
    for (z = BW_Z) translate([MX0 + 10 - WHEEL_W / 2 - 3, RB[1] + 19, z - WHEEL_OD / 2 - 3]) cube([WHEEL_W + 6, CAGE_T + 2, WHEEL_OD + 6]);
  }
  if (FRONT_GUARD == "keeper") color("lightcyan", 0.35) translate([KEEP_X[0], FY0 - KEEP_T, RZ0]) cube([KEEP_X[1] - KEEP_X[0], KEEP_T, SIEVE_L]);
  for (z = FW_Z) {
    translate([FW_X, MY0 + 10, z]) rotate([90, 0, 0]) vwheel();
    color("silver") translate([FW_X, CAGE_FY - CAGE_T, z]) rotate([-90, 0, 0]) cylinder(d = 5, h = RB[1] + 20 + 2 * CAGE_T - CAGE_FY, $fn = 16);
    color("gold") for (y = [[CAGE_FY, MY0 + 10 - WHEEL_W / 2], [MY0 + 10 + WHEEL_W / 2, RB[1] + 20]])   // spacer tubes
      translate([FW_X, y[0], z]) rotate([-90, 0, 0]) cylinder(d = 8, h = y[1] - y[0], $fn = 16);
  }
  color("silver") for (z = STANDOFF_Z) translate([CAGE_X0 + 6, CAGE_FY, z]) rotate([-90, 0, 0]) cylinder(d = 8, h = RB[1] + 20 - CAGE_FY, $fn = 16);   // standoffs
}
module rails3d() {
  if (FRONT_GUARD == "rail") color("lightsteelblue") translate([RF[0], RF[1], RZ0]) beam2020(SIEVE_L);
  color("lightsteelblue") translate([RB[0], RB[1], RZ0]) beam2040(SIEVE_L);
  for (z = BRK_Z) { if (FRONT_GUARD == "rail") translate([FX0, FY0, z]) corner_bracket(); translate([0, 0, z]) tie3d(); }
  if (FRONT_GUARD == "keeper") color("dimgray") for (z = BRK_Z) translate([FX0 + 10, CAGE_FY - CAGE_T - HEAD_H, z]) rotate([-90, 0, 0]) cylinder(d = HEAD_D, h = HEAD_H, $fn = 24);   // frame + keeper bolts into F's front slot
  for (z = BW_Z) bw3d(z);
  cage3d();
}
FW_GAP_FRONT = MY0 + 10 - WHEEL_W / 2 - CAGE_FY;
echo(str("RAILS: R_F back face y ", FY0, " (K_F's plane), R_B front face y ", RB[1], " (K_M's plane ", MY0 + 20, " + ", RAIL_CLR,
         "); rails z ", RZ0, "..", RZ1, "; ball column gap between rails ", RB[1] - FY0, " for a ", BALL_D, " ball"));
echo(str("WHEELS: back x2 at z ", BW_Z, " axle y ", BW_Y, " (x ", MX0 + 10, "); wheel x ", MX0 + 10 - WHEEL_W / 2, "..", MX0 + 10 + WHEEL_W / 2,
         ", BW plate x ", RB[0] - PLATE_T, "..", RB[0], " (", RB[0] - PLATE_T - (MX0 + 10 + WHEEL_W / 2), " for the eccentric)"));
echo(str("FRONT GUARD: ", FRONT_GUARD, FRONT_GUARD == "keeper" ? str(" -- acrylic ", KEEP_X[1] - KEEP_X[0], " x ", SIEVE_L, " x ", KEEP_T, " on F's front face, window x ", WIN, " in a ", CAGE_FX1 - CAGE_X0, " x ", SIEVE_L, " frame; ball front gap to the acrylic ", -4.2 - BALL_D / 2 - FY0) : ""));
echo(str("WHEELS: far x2 at z ", FW_Z, " axle x ", FW_X, " (y ", MY0 + 10, "); axle plate to plate ", RB[1] + 20 + CAGE_T - (CAGE_FY - CAGE_T),
         " (spacer tubes ", FW_GAP_FRONT, " front, ", RB[1] + 20 - (MY0 + 10 + WHEEL_W / 2), " back)"));

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
  if (show_rails) rails3d();
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
else if (part == "cut") projection(cut = true) translate([0, 0, -CUT_Z]) full();
else if (part == "exit_floor") out2d() exit_floor2d();
else if (part == "exit_side_x2") out2d() exit_side2d();
else if (part == "exit_cap") out2d() exit_cap2d();
