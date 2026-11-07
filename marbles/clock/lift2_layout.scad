// Two-lane lift on ONE pendulum spine: layout only (shapes and assemblies, bottom end). No swing, no
// stroke, no drive: everything is drawn at rest, M at its low point. (2026-11-07)
//
// The idea: one pair of beams serves BOTH lanes from opposite faces.
//   SPINE  the pendulum: one 2020 T-slot (= F, the fixed beam). Lane A's fixed sieve S_F_A bolts to its
//          FRONT face, lane B's S_F_B to its BACK face.
//   M      the slider: one 2020 V-slot beside the spine, a 20 mm gap between them (the ball gap). Lane A's
//          moving sieve S_M_A stands off its front face, S_M_B off its back face, each SM_STANDOFF out, so
//          each lane's two sieves are the usual 8.4 apart. Both lanes' balls share the one gap.
//   CENTRE GUARD  a thin clear plate between the lanes, its edge in the spine's slot on the gap side.
//   KEEPERS  a 2040 V-slot rail in front of lane A and one behind lane B (the guards), tied to the spine
//          by flat strips on the spine's outer face.
//   FEED   ONE track (along x, the pivot axis, 3 deg) brings balls in under M's end; a flip-flop vane at
//          the fork sends them alternately left and right; each branch runs straight into its lane's
//          bottom hole through a slot in that lane's S_F (in S_F's plane, so it never crosses S_M).
//
// Axes: x across (the pivot axis), y front -> back (lane A at -y, lane B at +y), z up.
//   openscad lift2_layout.scad            part = "all" | "lane" (lane A only, sectioned) | "plates" (2D S_F / S_M)

part = "all";             // [all, lane, plates]
show_balls = true;
show_keepers = true;
show_m = true;

/* [Sizes] */
BALL = 19.05; r = BALL / 2;
T = 2.82;                 // sieve sheet (mdf3)
GAP_SM = 8.4;             // S_F to S_M, plate to plate (as the current lift)
PITCH = 30; HOLE_D = 20;
HOLE_X = 30;              // ball line: the middle of the 20 mm gap
Z_HOLE = 40;              // bottom hole centre
SLOPE = 3;                // feed slope, deg
SHOW_L = 300;             // how much of the column to draw
G_CENTRE = 2;             // centre guard thickness
KEEP_CLR = 1.2;           // keeper face to a ball seated in S_M

// ---------------------------------------------------------------- derived
SF_Y = 10 + T / 2;                         // |y| of S_F's mid-plane (on the spine's face)
SM_Y = 10 + T + GAP_SM + T / 2;            // |y| of S_M's mid-plane
SM_STANDOFF = T + GAP_SM;                  // M's face to S_M
KEEP_Y = SM_Y + r + KEEP_CLR;              // |y| of the keeper rail's inner face
M_Z0 = Z_HOLE + r + 6;                     // M's lowest end clears the feed track
SF_W = 44; SM_X0 = 16; SM_X1 = 60;         // plate spans in x
function zc(x) = Z_HOLE + (x - HOLE_X) * tan(SLOPE);    // ball centre along the feed, rising outward
X_EDGE = SF_W;                             // the feed leaves S_F's slot here
X_FORK = 100;                              // fork (flip-flop vane) position
X_SPLIT = 68;                              // branches are on their lane lines from here in

// ---------------------------------------------------------------- helpers
module beam2020(len) difference() {
  cube([20, 20, len]);
  for (a = [0, 90, 180, 270]) translate([10, 10, -1]) rotate([0, 0, a]) translate([-3.1, 10 - 1.8, 0]) cube([6.2, 2, len + 2]);
}
module beam2040(len) { beam2020(len); translate([20, 0, 0]) beam2020(len); }
module plate_xz(yc, th) translate([0, yc + th / 2, 0]) rotate([90, 0, 0]) linear_extrude(th) children();   // centred on yc
module ball(p) if (show_balls) translate(p) color("steelblue") sphere(d = BALL, $fn = 28);

// ---------------------------------------------------------------- 2D plates (x, z)
module sf2d() difference() {                 // fixed sieve, bottom end: bottom hole + feed slot from its edge
  translate([0, Z_HOLE - 22]) square([SF_W, SHOW_L]);
  hull() { translate([HOLE_X, Z_HOLE]) circle(d = HOLE_D, $fn = 48); translate([X_EDGE + 2, zc(X_EDGE + 2)]) circle(d = BALL + 2, $fn = 48); }
  for (i = [1 : 8]) translate([HOLE_X, Z_HOLE + PITCH * i]) circle(d = HOLE_D, $fn = 48);
  for (i = [1 : 2 : 8]) translate([10, Z_HOLE + PITCH * i + PITCH / 2]) circle(d = 5, $fn = 24);   // M5 into the spine
}
module sm2d() difference() {                 // moving sieve: holes from the bottom one up (at M's low point: 2 below S_F's)
  translate([SM_X0, Z_HOLE - 2 - 16]) square([SM_X1 - SM_X0, SHOW_L]);
  translate([SF_W, Z_HOLE - 30]) square([SM_X1, 38]);           // notch: the feed branch's outer wall passes here
  for (i = [0 : 8]) translate([HOLE_X, Z_HOLE - 2 + PITCH * i]) circle(d = HOLE_D, $fn = 48);
  for (i = [1 : 2 : 8]) translate([50, Z_HOLE + PITCH * i + PITCH / 2]) circle(d = 5, $fn = 24);   // M5 + standoff into M
}

// ---------------------------------------------------------------- assemblies
module spine() color("silver") translate([0, -10, -10]) beam2020(SHOW_L + Z_HOLE + 10);                     // T-slot, the pendulum
module slider() if (show_m) color("rosybrown") translate([40, -10, M_Z0]) beam2020(SHOW_L + Z_HOLE - M_Z0);   // V-slot, M
module lane(s) {                             // s = -1: lane A (front), +1: lane B (back)
  color("burlywood") plate_xz(s * SF_Y, T) sf2d();
  color("tan", 0.85) plate_xz(s * SM_Y, T) sm2d();
  color("dimgray") for (i = [1 : 2 : 8]) translate([50, s > 0 ? 10 : -10 - SM_STANDOFF, Z_HOLE + PITCH * i + PITCH / 2])
    rotate([-90, 0, 0]) cylinder(d = 8, h = SM_STANDOFF, $fn = 6);                                         // standoffs M -> S_M
  if (show_keepers) {
    color("lightsteelblue") translate([0, s > 0 ? KEEP_Y : -KEEP_Y - 20, Z_HOLE - 20]) beam2040(SHOW_L);   // keeper rail (guard)
  }
}
module centre_guard() color("lightcyan", 0.45) translate([17, -G_CENTRE / 2, Z_HOLE - 14]) cube([21, G_CENTRE, SHOW_L]);
module ties() color("peru") for (z = [Z_HOLE + 60, Z_HOLE + 200]) translate([-6, -KEEP_Y - 20, z]) cube([6, 2 * (KEEP_Y + 20), 20]);

// feed: one track in along x at y = 0, a flip-flop at the fork, two branches onto the lane lines (y = +-SF_Y)
module chan(p0, p1) {                        // a U channel between two ball-centre points (floor + walls, 21 inside)
  for (w = [[0, -r - 0.5, 2], [-10.5 - 2, -r - 0.5, 14], [10.5, -r - 0.5, 14]])
    hull() for (p = [p0, p1]) translate(p + [0, w[0], w[1]] + [0, 0, 0]) cube([0.01, w[0] == 0 ? 21 : 2, w[2]], center = false);
}
module feed() color("silver") {
  for (s = [-1, 1]) {
    // branch: straight on the lane line from S_F's edge out to X_SPLIT, then bending to the fork
    hull() for (x = [X_EDGE, X_SPLIT]) translate([x, s * SF_Y - 10.5, zc(x) - r - 2.5]) cube([0.01, 21, 2]);
    hull() { translate([X_SPLIT, s * SF_Y - 10.5, zc(X_SPLIT) - r - 2.5]) cube([0.01, 21, 2]);
             translate([X_FORK, -10.5, zc(X_FORK) - r - 2.5]) cube([0.01, 21, 2]); }
    // outer walls
    hull() for (x = [X_EDGE, X_SPLIT]) translate([x, s * (SF_Y + 10.5) - (s < 0 ? 2 : 0), zc(x) - r - 2.5]) cube([0.01, 2, 14]);
    hull() { translate([X_SPLIT, s * (SF_Y + 10.5) - (s < 0 ? 2 : 0), zc(X_SPLIT) - r - 2.5]) cube([0.01, 2, 14]);
             translate([X_FORK, s * 10.5 - (s < 0 ? 2 : 0), zc(X_FORK) - r - 2.5]) cube([0.01, 2, 14]); }
  }
  // divider between the branches, from the fork tip to S_F's edge
  hull() { translate([X_EDGE, -1, zc(X_EDGE) - r - 2.5]) cube([0.01, 2, 14]); translate([X_SPLIT, -1, zc(X_SPLIT) - r - 2.5]) cube([0.01, 2, 14]); }
  hull() { translate([X_SPLIT, -1, zc(X_SPLIT) - r - 2.5]) cube([0.01, 2, 14]); translate([X_FORK - 14, 0, zc(X_FORK - 14) - r - 2.5]) cube([0.01, 0.2, 14]); }
  // the single track in
  hull() for (x = [X_FORK, X_FORK + 150]) translate([x, -10.5, zc(x) - r - 2.5]) cube([0.01, 21, 2]);
  for (s = [-1, 1]) hull() for (x = [X_FORK, X_FORK + 150]) translate([x, s * 10.5 - (s < 0 ? 2 : 0), zc(x) - r - 2.5]) cube([0.01, 2, 14]);
  // flip-flop vane on a vertical pin at the fork: each ball that passes flips it to the other side
  color("darkorange") translate([X_FORK - 4, 0, zc(X_FORK) - r - 2.5]) {
    cylinder(d = 3, h = 16, $fn = 16);
    rotate([0, 0, 180 + 18]) linear_extrude(12) polygon([[0, -1.2], [16, -0.4], [16, 0.4], [0, 1.2]]);
  }
}

module column_balls() for (s = [-1, 1]) {
  ball([HOLE_X, s * SF_Y, Z_HOLE]);                                         // in the bottom hole (S_F)
  ball([X_EDGE + 6, s * SF_Y, zc(X_EDGE + 6)]);                             // next one waiting in its branch
  for (i = [1 : 5]) ball([HOLE_X, s * (i % 2 == 0 ? SF_Y : SM_Y), Z_HOLE + PITCH * i - (i % 2 == 0 ? 0 : 2)]);
}
module queue() for (k = [0 : 4]) ball([X_FORK + 8 + k * (BALL + 0.4), 0, zc(X_FORK + 8 + k * (BALL + 0.4))]);

module all() {
  spine(); slider(); centre_guard(); ties();
  lane(-1); lane(1);
  feed();
  column_balls(); queue();
}

if (part == "all") all();
if (part == "lane") intersection() { all(); translate([-20, -100, -50]) cube([200, 100, 600]); }
if (part == "plates") { translate([0, 0]) sf2d(); translate([70, 0]) sm2d(); }

echo(str("LIFT2: S_F mid-planes y +-", SF_Y, ", S_M +-", SM_Y, " (standoff ", SM_STANDOFF, "), keeper inner faces +-", KEEP_Y,
         ", lanes ", 2 * SF_Y, " apart in S_F, ball seated in S_F reaches |y| ", SF_Y - r, " (centre guard +-", G_CENTRE / 2, ")"));
