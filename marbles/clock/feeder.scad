// Side-entry feeder box for the bottom of the rocking ball lift.
//
// One box of laser-cut sheet parts around a funnel plate:
//   funnel        in S_F's plane, directly under S_F, bolted to F's back slot with 2 M5.
//                 Sieve column (ball holes continue S_F's line) + a J channel from a
//                 pocket (where balls enter sideways) down into the bottom hole.
//   front keeper  front of the funnel, GAP away; above F's end its inner edge rides in
//                 F's far slot. Carries the PORT (balls come in here).
//   back keeper   behind the funnel, GAP away. Access holes over the beam-bolt heads.
//   walls         separate spacer walls in each gap, tabbed into the funnel AND that
//                 gap's keeper. Front and back walls can share a line through the funnel
//                 (their tabs must not share a slot).
//   port          standard interface: PORT x PORT opening, a TAB slot centred on each
//                 side (where a PORT-inside duct's walls land), 4 M5 at the corners.
//                 Port bolts pass through all three plates and clamp the walls.
//
// Coordinates (all parts share them):
//   plate x  across: x = 0 is the sieve's 6 mm edge (toward M), x = COL_W is F's far
//            face, x grows outward away from the lift.
//   plate y  up: y = 0 is the funnel's bottom edge, y = H its top (S_F starts there).
//   3D: X = plate x, Z = plate y, Y = toward the BACK (the front keeper is at -Y,
//       facing the default OpenSCAD camera).
//
// Use:
//   part = "assembly"  3D view (explode, show_* toggles below)
//   part = "funnel" | "front_keeper" | "back_keeper" | "wall" (pick wall_i)   2D shape
//   laser = true       2D shape grown by kerf/2 for cutting (what the G-code script uses)
// The console prints a CHECK report: every wall's clearance from the channel, ball
// holes, bolts, bolt heads and F; every tab slot's wood to every hole and edge.
// Lines starting "WARN" need fixing; everything else is fine.
//
//   python3 marbles/clock/feeder_scad_gcode.py   # one G-code per part, from this file

/* [View] */
part = "assembly";        // [assembly, funnel, front_keeper, back_keeper, wall]
wall_i = 0;               // which wall when part = "wall" (index into WALLS)
laser = false;            // grow 2D parts by kerf/2 (cut files)
explode = 0;              // [0:60] pull the layers apart in the assembly
show_beams = true;
show_balls = true;
show_bolts = true;
show_sieve = true;        // S_F stub above the funnel

/* [Material] */
T = 3.1;                  // sheet thickness (mdf_3mm profile; plywood 2.6)
KERF = 0.10;              // mdf_3mm profile
FIT = 0.0;                // extra slot width for tabs (MDF: 0 is tight and snug)
WEB = max(4, T);          // thinnest wood allowed between any cut and an edge or another cut
TAB = 10;                 // tab / slot length

/* [Lift geometry (from the sieve)] */
BALL_D = 19.05;
HOLE_D = 20;              // ball holes
PITCH = 30;
COL_W = 46;               // sieve width
HOLE_X = COL_W - 30;      // ball-hole line (sieve's v = 30)
BEAM_X = COL_W - 10;      // F's back-face slot line (sieve's v = 10)
N_HOLES = 4;              // ball holes in the funnel's sieve column
BAND = 20;                // wood under the bottom hole
H = BAND + 15 + PITCH * (N_HOLES - 1) + 15;   // funnel height (140)
W = 96;                   // funnel / keeper width
INSIDE = 20;              // keeper to keeper, inside
GAP = (INSIDE - T) / 2;   // funnel face to each keeper (8.45)
F_END = 65;               // plate y of F's bottom end (front walls must stay out of F above this)
FK_X0_LOW = COL_W - 12;   // front keeper's inner edge below F's end (reaches under F)
FK_X0_HIGH = COL_W - 6;   // ... above F's end: 6 mm into F's far slot
BK_X0 = 6;                // back keeper's inner edge (clear of M's body at x < 6)

/* [Channel] */
CH_W = HOLE_D + 1;        // channel width (ball 19.05)
PORT_C = [68, 108];       // pocket / port centre
CH_P1 = [PORT_C[0], 35];  // bezier control points of the channel centreline: pocket -> P1 -> P2 -> bottom hole
CH_P2 = [HOLE_X + 26, 41];

/* [Port] */
PORT = 20;                // square opening = inside of a standard duct
PORT_BOLT = 18;           // corner M5 offset from the port centre (x and y)

/* [Bolts] */
M5 = 5.0;                 // all M5 holes exactly 5.0
BEAM_BOLT_Y = [(35 + 65) / 2 + 30, (35 + 65) / 2 + 60];   // [80, 110]: gaps between ball holes, on BEAM_X
HEAD_D = 9.5;             // M5 bolt head diameter (button head 9.5, socket head 8.5)
HEAD_H = 5;               // head height (socket head 5, button head 2.75); must be < GAP
HEAD_CLR = 1;             // keep walls this far from a head
ACCESS_D = HEAD_D + 1;    // back keeper access hole over each beam-bolt head (0 = none)

/* [Walls] */
// [name, side ("F" front gap / "B" back gap), orient ("v" runs along y at x = f .. f+T,
//  "h" runs along x at y = f .. f+T), f, lo, hi, [tab starts along the wall]]
// Tabs go into BOTH the funnel and the keeper on that side, at the same positions.
X_OUT = W - WEB - T;      // outer walls
Y_TOP = H - WEB - T;      // top walls
Y_BOT = WEB;              // bottom walls
WALLS = [
  ["outer_front",  "F", "v", X_OUT, Y_BOT + T, Y_TOP, [9.1, 39.1, 69.1, 99.1]],
  ["top_front",    "F", "h", Y_TOP, COL_W + 0.5, W - WEB, [48.5, 78.5]],
  ["bottom_front", "F", "h", Y_BOT, FK_X0_LOW + WEB, W - WEB, [40, 70]],
  ["outer_back",   "B", "v", X_OUT, Y_BOT + T, Y_TOP, [24.1, 54.1]],
  ["top_back",     "B", "h", Y_TOP, 30, W - WEB, [32]],
  ["bottom_back",  "B", "h", Y_BOT, BK_X0 + WEB, W - WEB, [12, 55]],
  ["inner_back",   "B", "h", 93.5, 30, 46, [32]],   // between the two beam-bolt heads
];

$fn = 64;

// ------------------------------------------------------------------ derived geometry
HOLES = [for (i = [0 : N_HOLES - 1]) [HOLE_X, BAND + 15 + PITCH * i]];
BEAM_BOLTS = [for (y = BEAM_BOLT_Y) [BEAM_X, y]];
PORT_BOLTS = [for (sx = [-1, 1], sy = [-1, 1]) PORT_C + [sx * PORT_BOLT, sy * PORT_BOLT]];
function bez(p0, p1, p2, p3, t) = pow(1 - t, 3) * p0 + 3 * pow(1 - t, 2) * t * p1 + 3 * (1 - t) * t * t * p2 + pow(t, 3) * p3;
PATH = [for (i = [0 : 60]) bez(PORT_C, CH_P1, CH_P2, HOLES[0], i / 60)];

// rectangles are [x0, y0, x1, y1]
function wall_rect(w) = w[2] == "v" ? [w[3], w[4], w[3] + T, w[5]] : [w[4], w[3], w[5], w[3] + T];
function slot_rect(w, t) = w[2] == "v" ? [w[3] - FIT / 2, t, w[3] + T + FIT / 2, t + TAB]
                                       : [t, w[3] - FIT / 2, t + TAB, w[3] + T + FIT / 2];
function port_rects(open) = concat(
  [[PORT_C[0] + PORT / 2, PORT_C[1] - TAB / 2, PORT_C[0] + PORT / 2 + T + FIT, PORT_C[1] + TAB / 2],
   [PORT_C[0] - PORT / 2 - T - FIT, PORT_C[1] - TAB / 2, PORT_C[0] - PORT / 2, PORT_C[1] + TAB / 2],
   [PORT_C[0] - TAB / 2, PORT_C[1] + PORT / 2, PORT_C[0] + TAB / 2, PORT_C[1] + PORT / 2 + T + FIT],
   [PORT_C[0] - TAB / 2, PORT_C[1] - PORT / 2 - T - FIT, PORT_C[0] + TAB / 2, PORT_C[1] - PORT / 2]],
  open ? [[PORT_C[0] - PORT / 2, PORT_C[1] - PORT / 2, PORT_C[0] + PORT / 2, PORT_C[1] + PORT / 2]] : []);

// ------------------------------------------------------------------ distance helpers (for the CHECK report)
function rp(r, p) = let(dx = max(r[0] - p[0], 0, p[0] - r[2]), dy = max(r[1] - p[1], 0, p[1] - r[3])) sqrt(dx * dx + dy * dy);
function rc(r, c, rad) = rp(r, c) - rad;                                     // rect to circle
function rr(a, b) = let(dx = max(b[0] - a[2], 0, a[0] - b[2]), dy = max(b[1] - a[3], 0, a[1] - b[3])) sqrt(dx * dx + dy * dy);
function rpath(r, pts, rad) = min([for (p = pts) rp(r, p)]) - rad;           // rect to channel
function minl(l) = len(l) ? min(l) : 999;
function fk_x0(y) = y < F_END ? FK_X0_LOW : FK_X0_HIGH;
function r2(x) = round(x * 100) / 100;

// clearances of a wall's body (in the gap)
function wall_body(w) = let(r = wall_rect(w)) [
  ["channel", rpath(r, PATH, CH_W / 2)],
  ["ball holes", minl([for (h = HOLES) rc(r, h, HOLE_D / 2)])],
  ["port bolts", minl([for (b = PORT_BOLTS) rc(r, b, M5 / 2)])],
  ["bolt heads", w[1] == "B" ? minl([for (b = BEAM_BOLTS) rc(r, b, HEAD_D / 2 + HEAD_CLR)]) : 999],
  ["F beam", w[1] == "F" ? (r[2] <= COL_W - 20 || r[0] >= COL_W || r[3] <= F_END ? 999 : -1) : 999],
  ["keeper edge", w[1] == "F" ? r[0] - fk_x0(r[1]) : r[0] - BK_X0]];
// wood around one tab slot, in the funnel (both sides' slots) and in its keeper
function slot_wood(w, t) = let(s = slot_rect(w, t),
  others = [for (o = WALLS, u = o[6]) if (!(o[0] == w[0] && u == t)) slot_rect(o, u)],
  same_side = [for (o = WALLS, u = o[6]) if (o[1] == w[1] && !(o[0] == w[0] && u == t)) slot_rect(o, u)]) [
  ["funnel: channel", rpath(s, PATH, CH_W / 2)],
  ["funnel: ball holes", minl([for (h = HOLES) rc(s, h, HOLE_D / 2)])],
  ["funnel: bolt holes", minl([for (b = concat(BEAM_BOLTS, PORT_BOLTS)) rc(s, b, M5 / 2)])],
  ["funnel: other slots", minl([for (o = others) rr(s, o)])],
  ["funnel: edges", min(s[0], s[1], W - s[2], H - s[3])],
  ["keeper: port", minl([for (p = port_rects(w[1] == "F")) rr(s, p)])],
  ["keeper: access holes", w[1] == "B" && ACCESS_D > 0 ? minl([for (b = BEAM_BOLTS) rc(s, b, ACCESS_D / 2)]) : 999],
  ["keeper: other slots", minl([for (o = same_side) rr(s, o)])],
  ["keeper: inner edge", s[0] - (w[1] == "F" ? fk_x0(s[1]) : BK_X0)]];

module report() {
  echo(str("CHECK feeder: T ", T, ", GAP ", r2(GAP), ", funnel ", W, " x ", H, ", bridge over the pocket ", r2(H - PORT_C[1] - CH_W / 2),
           ", channel to the port bolts ", r2(minl([for (b = PORT_BOLTS) min([for (p = PATH) norm(p - b)]) - CH_W / 2 - M5 / 2])),
           ", bolt head ", HEAD_H, " in a ", r2(GAP), " gap", HEAD_H < GAP ? "" : "  <-- WARN head taller than the gap"));
  for (w = WALLS) {
    b = wall_body(w);
    bad = [for (c = b) if (c[1] < 0) c];
    echo(str(len(bad) ? "WARN " : "ok   ", "wall ", w[0], " (", w[1], "): ", len(w[6]), " tabs; body clearance ",
             [for (c = b) if (c[1] < 900) str(c[0], " ", r2(c[1]))]));
    if (len(w[6]) == 0) echo(str("WARN wall ", w[0], " has no tabs"));
    for (t = w[6]) {
      s = slot_wood(w, t);
      thin = [for (c = s) if (c[1] < WEB - 1e-6) c];
      if (len(thin)) echo(str("WARN wall ", w[0], " tab at ", t, ": less than ", WEB, " mm of wood: ", [for (c = thin) str(c[0], " ", r2(c[1]))]));
      if (t < w[4] || t + TAB > w[5]) echo(str("WARN wall ", w[0], " tab at ", t, " is off the end of the wall"));
    }
  }
}

// ------------------------------------------------------------------ 2D parts (plate coordinates)
module rect2d(r) translate([r[0], r[1]]) square([r[2] - r[0], r[3] - r[1]]);
module channel2d() {
  for (i = [0 : len(PATH) - 2]) hull() { translate(PATH[i]) circle(d = CH_W); translate(PATH[i + 1]) circle(d = CH_W); }
  translate(PORT_C) circle(d = CH_W);
}
module m5s(pts) for (p = pts) translate(p) circle(d = M5, $fn = 48);
module slots2d(side) for (w = WALLS) if (side == "all" || w[1] == side) for (t = w[6]) rect2d(slot_rect(w, t));
module port2d(open) for (r = port_rects(open)) rect2d(r);

module funnel2d() difference() {
  square([W, H]);
  channel2d();
  for (h = HOLES) translate(h) circle(d = HOLE_D, $fn = 96);
  m5s(concat(BEAM_BOLTS, PORT_BOLTS));
  slots2d("all");
}
module front_keeper2d() difference() {
  offset(r = 2) offset(delta = -2) union() {
    translate([FK_X0_LOW, 0]) square([W - FK_X0_LOW, F_END]);
    translate([FK_X0_HIGH, F_END - 0.01]) square([W - FK_X0_HIGH, H - F_END + 0.01]);
  }
  port2d(true);
  m5s(PORT_BOLTS);
  slots2d("F");
}
module back_keeper2d() difference() {
  translate([BK_X0, 0]) square([W - BK_X0, H]);
  port2d(false);
  m5s(PORT_BOLTS);
  if (ACCESS_D > 0) for (b = BEAM_BOLTS) translate(b) circle(d = ACCESS_D);
  slots2d("B");
}
// a wall in its own (u, v): u along the wall (lo .. hi), v across the gap (0 = funnel face .. GAP = keeper face)
module wall2d(w) union() {
  translate([w[4], 0]) square([w[5] - w[4], GAP]);
  for (t = w[6]) { translate([t, -T]) square([TAB, T + 0.01]); translate([t, GAP - 0.01]) square([TAB, T + 0.01]); }
}

// ------------------------------------------------------------------ 3D assembly
// a 2D plate part laid in the XZ plane, occupying Y in [y0, y0 + T]
module plate3d(y0) translate([0, y0 + T, 0]) rotate([90, 0, 0]) linear_extrude(T) children();
Y_FUNNEL = 0;                          // funnel: Y 0 .. T (its front face touches F's back face at Y 0)
Y_FK = -GAP - T - explode;             // front keeper
Y_BK = T + GAP + explode;              // back keeper
module wall3d(w) {
  r = wall_rect(w);
  y0 = w[1] == "F" ? -GAP - explode / 2 : T + explode / 2;
  translate([r[0], y0, r[1]]) cube([r[2] - r[0], GAP, r[3] - r[1]]);
}
module beam2020(len) difference() {      // 20 x 20 with 4 slots, along Z
  cube([20, 20, len]);
  for (a = [0, 90, 180, 270]) translate([10, 10, -1]) rotate([0, 0, a]) translate([-3.1, 10 - 1.8, 0]) cube([6.2, 2, len + 2]);
}
module bolt(p, y_head_face, dir, shank) {   // head sits on the face at y_head_face, shank goes in direction dir (+1/-1 in Y)
  color("dimgray") {
    translate([p[0], y_head_face - dir * HEAD_H, p[1]]) rotate([-90, 0, 0]) cylinder(d = HEAD_D, h = HEAD_H);
    translate([p[0], y_head_face + (dir > 0 ? 0 : -shank), p[1]]) rotate([-90, 0, 0]) cylinder(d = M5, h = shank);
  }
}
module assembly() {
  color("sandybrown") plate3d(Y_FUNNEL) funnel2d();
  color("yellowgreen", 0.55) plate3d(Y_FK) front_keeper2d();
  color("yellowgreen", 0.55) plate3d(Y_BK) back_keeper2d();
  for (w = WALLS) color(w[1] == "F" ? "seagreen" : "darkolivegreen") wall3d(w);
  if (show_sieve) color("burlywood") translate([0, 0, H]) plate3d(0) difference() {
    square([COL_W, 90]);
    for (i = [0 : 2]) translate([HOLE_X, 15 + PITCH * i]) circle(d = HOLE_D);
  }
  if (show_beams) {
    color("lightsteelblue") translate([COL_W - 20, -20, F_END]) beam2020(H - F_END + 90);   // F: in front of the funnel
    color("rosybrown") translate([COL_W - 60, -8.4, -10]) beam2020(H + 100);                // M (moving)
  }
  if (show_bolts) {
    for (b = BEAM_BOLTS) bolt(b, T, -1, T + 8);                                  // head on the funnel's back face, into F
    for (b = PORT_BOLTS) bolt(b, Y_FK, 1, Y_BK + T - Y_FK + 4);                  // head on the front keeper, through all three
  }
  if (show_balls) color("steelblue") {
    for (i = [0 : 4]) translate([PATH[60 - i * 12][0], T / 2, PATH[60 - i * 12][1]]) sphere(d = BALL_D);
    translate([PORT_C[0], Y_FK - 14, PORT_C[1]]) sphere(d = BALL_D);           // one coming in through the port
  }
}

// ------------------------------------------------------------------ output
module out2d() if (laser) offset(delta = KERF / 2) children(); else children();
echo(parts = concat(["funnel", "front_keeper", "back_keeper"], [for (i = [0 : len(WALLS) - 1]) str("wall:", i, ":", WALLS[i][0])]));
report();
if (part == "assembly") assembly();
else if (part == "funnel") out2d() funnel2d();
else if (part == "front_keeper") out2d() front_keeper2d();
else if (part == "back_keeper") out2d() back_keeper2d();
else if (part == "wall") out2d() wall2d(WALLS[wall_i]);
