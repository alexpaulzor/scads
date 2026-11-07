// Pendulum pivot hub: two laminated cheeks on the 2020 spine's SIDE faces, one 608 skate bearing in each,
// on a FIXED 8 mm axle that crosses the spine through a drilled hole. Replaces the KP08 pillow blocks and the
// extrusion fittings. (2026-11-07)
//
// Each cheek is 5 laser-cut layers, bolted to the spine with 2 M5 into T-nuts in the side slot (above and
// below the bearing):
//   L1  inner retainer  (against the spine)  hole 17: holds the bearing's outer race, clears the inner race
//   L2-L4 pocket        hole 22 (press fit)
//   L5  outer retainer  hole 17
// The axle sits AX_BACK behind the spine's centre so the 22 mm pocket keeps WEB of wood to the spine's front
// face plane (the cheeks stop flush with it; the sieve / interface plates are in front of that plane).
//
// The cheeks stand beside the spine, exactly where the two ball lanes run (the lanes flank the beam), so
// the hub must sit where there are NO balls: above the exit (flange) row of the top interface plate.
//
// Axes: x along the axle (across the lanes), y front (+) / back, z up. Spine: x -10..10, y -20..0.
//   openscad pivot_hub.scad                     3D: spine top, hub, axle, frame clamps, interface plate ghost
//   openscad -D 'part="layers"' -o l.svg pivot_hub.scad    2D: one cheek's 5 layers (cut 2 sets)

part = "assembly";        // [assembly, layers]
show_ghost = true;

/* [Stock + hardware] */
T = 2.82;                 // layer thickness (mdf3 2.82; ply3 / birch3 hold a press fit better)
N_POCKET = 3;             // pocket layers (3 x 2.82 = 8.46 for a 7 mm bearing)
BRG_OD = 22; BRG_W = 7; BRG_ID = 8;   // 608
SEAT = 22.0;              // pocket hole (nominal; the cut file adds the kerf)
LIP = 17;                 // retainer hole: under the outer race (19-22), clear of the inner race (~12)
AXLE = 8;                 // fixed axle
DRILL = 8.5;              // hole across the spine
M5 = 5.0;
WEB = 4;

/* [Placement] */
AX_BACK = 5;              // axle behind the spine centre (y = -10 - AX_BACK)
BOLT_Z = 20;              // M5 into the side slot at z = +-BOLT_Z from the axle
CHEEK_BACK = 10;          // cheek reaches this far behind the spine's back face

// ---------------------------------------------------------------- derived
AY = -10 - AX_BACK;                            // axle y
CH_Y0 = -20 - CHEEK_BACK; CH_Y1 = 0;           // cheek extent in y
CH_H = 2 * (BOLT_Z + M5 / 2 + WEB + 2);        // cheek height
N_L = N_POCKET + 2;
CH_T = N_L * T;                                // cheek thickness (x)
FRONT_WEB = -AY - SEAT / 2;                    // pocket to the front face plane
echo(str("PIVOT HUB: axle at y ", AY, " (", AX_BACK, " behind the spine centre); pocket to front face ", FRONT_WEB,
         ", to back of cheek ", AY - SEAT / 2 - CH_Y0, "; cheek ", CH_Y1 - CH_Y0, " x ", CH_H, " x ", CH_T,
         " (", N_L, " layers); bearings ", 20 + 2 * (T + N_POCKET * T / 2), " apart (centre to centre); bolts M5 x ",
         ceil((CH_T + 6) / 5) * 5));

// one layer, 2D in (y, z) with the axle at the origin's (AY, 0)
module cheek2d() offset(r = 3) offset(delta = -3) translate([CH_Y0, -CH_H / 2]) square([CH_Y1 - CH_Y0, CH_H]);
module layer2d(kind) difference() {
  cheek2d();
  translate([AY, 0]) circle(d = kind == "pocket" ? SEAT : LIP, $fn = 96);
  for (s = [-1, 1]) translate([-10, s * BOLT_Z]) circle(d = M5, $fn = 32);
}
KINDS = [for (i = [0 : N_L - 1]) i == 0 || i == N_L - 1 ? "retainer" : "pocket"];

// ---------------------------------------------------------------- 3D
module beam2020(len) difference() {
  cube([20, 20, len]);
  for (a = [0, 90, 180, 270]) translate([10, 10, -1]) rotate([0, 0, a]) translate([-3.1, 10 - 1.8, 0]) cube([6.2, 2, len + 2]);
}
module on_x(x0) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(T) children();   // (y, z) layer at x0..x0+T
module cheek(side) for (i = [0 : N_L - 1]) {        // side +1: x 10 outward, -1: x -10 outward
  x0 = side > 0 ? 10 + i * T : -10 - (i + 1) * T;
  color(KINDS[i] == "pocket" ? "burlywood" : "tan") on_x(x0) layer2d(KINDS[i]);
}
module bearing(side) {
  xc = side * (10 + T + N_POCKET * T / 2);
  color("dimgray") translate([xc, AY, 0]) rotate([0, 90, 0]) difference() {
    cylinder(d = BRG_OD, h = BRG_W, center = true, $fn = 48); cylinder(d = BRG_ID, h = BRG_W + 1, center = true, $fn = 24);
  }
}
module assembly() {
  color("silver") difference() {
    translate([-10, -20, -200]) beam2020(200 + 40);                             // the spine's top (cut short)
    translate([0, AY, 0]) rotate([0, 90, 0]) cylinder(d = DRILL, h = 30, center = true, $fn = 32);   // the drilled hole
  }
  for (s = [-1, 1]) { cheek(s); bearing(s); }
  color("dimgray") for (s = [-1, 1]) for (z = [-BOLT_Z, BOLT_Z])                 // M5 heads
    translate([s * (10 + CH_T), -10, z]) rotate([0, s * 90, 0]) cylinder(d = 8.5, h = 4, $fn = 24);
  color("lightgray") translate([0, AY, 0]) rotate([0, 90, 0]) cylinder(d = AXLE, h = 140, center = true, $fn = 32);   // fixed axle
  color("darkgray") for (s = [-1, 1]) translate([s * (10 + CH_T + 3), AY, 0]) rotate([0, 90, 0]) cylinder(d = 16, h = 6, center = true, $fn = 32);  // shaft collars
  color("peru", 0.8) for (s = [-1, 1]) translate([s * 62 - 3, AY - 20, -25]) difference() {   // frame clamp plates (sketch: on the frame)
    cube([6, 40, 70]); translate([-1, 20, 25]) rotate([0, 90, 0]) cylinder(d = AXLE, h = 8, $fn = 32);
  }
  if (show_ghost) {                                                               // the top interface plate, its exit row below the hub
    color("burlywood", 0.35) translate([-35.9, 0, -CH_H / 2 - 4 - 90]) cube([71.8, T, 90]);
    color("steelblue", 0.5) for (x = [-20, 20]) for (z = [-CH_H / 2 - 4 - 45, -CH_H / 2 - 4 - 75])
      translate([x, T / 2, z + (z > -CH_H / 2 - 4 - 60 ? 0 : 0)]) sphere(d = 19.05, $fn = 24);
  }
}

if (part == "assembly") assembly();
if (part == "layers") for (i = [0 : N_L - 1]) translate([i * (CH_Y1 - CH_Y0 + 6) - AY, 0]) layer2d(KINDS[i]);
