// Side-entry feeder box for the bottom of the rocking ball lift.
//
// Three laser-cut layers held apart by spacers on M5 bolts that pass through all three:
//   funnel        in S_F's plane, directly under S_F. Two M5 beam bolts go through the back
//                 keeper, a spacer stack in the back gap and the funnel into F's back slot,
//                 so both plates bolt to the beam together. Sieve column (ball holes continue S_F's line)
//                 + a J channel from a pocket (balls enter sideways) down to the bottom hole.
//   front keeper  GAP in front of the funnel; above F's end its inner edge rides in F's
//                 far slot. Carries the PORT.
//   back keeper   GAP behind the funnel; plain M5 holes for all bolts, no port pattern.
//   spacers       one stack per through-bolt in each gap (laser-cut rings, SPACER_LAYERS
//                 thick, or bought standoffs of length GAP).
//   port          standard interface: PORT x PORT opening, a TAB slot centred on each side
//                 (where a PORT-inside duct's walls land), 4 M5 at the corners. The port
//                 bolts are through-bolts too. The tab slots run into the opening (a
//                 duct's walls stand right at its edge), so the port reads as a notched
//                 square. Only the front keeper has a port; the back keeper is plain.
//
// Coordinates (all parts share them):
//   plate x  across: x = 0 is the sieve's 6 mm edge (toward M), x = COL_W is F's far face,
//            x grows outward away from the lift.
//   plate y  up: y = 0 is the funnel's bottom edge, y = H its top (S_F starts there).
//   3D: X = plate x, Z = plate y, Y = toward the BACK (front keeper at -Y, facing the
//       default OpenSCAD camera).
//
// Use:
//   part = "assembly"  3D (explode slider, show_* toggles)
//   part = "funnel" | "front_keeper" | "back_keeper" | "spacer"   2D shape
//   laser = true       2D shape grown by kerf/2 (what the G-code script cuts)
// The console prints a CHECK report: every through-bolt spacer's clearance from the
// channel, ball holes, F, other spacers and the keeper edges, and the wood
// around every hole. Lines starting "WARN" need fixing.
//
//   python3 marbles/clock/feeder_scad_gcode.py   # one G-code per part from this file

/* [View] */
part = "assembly";        // [assembly, funnel, front_keeper, back_keeper, spacer]
laser = false;            // grow 2D parts by kerf/2 (cut files)
explode = 0;              // [0:60] pull the layers apart in the assembly
show_beams = true;
show_balls = true;
show_bolts = true;
show_sieve = true;        // S_F stub above the funnel

/* [Material] */
T = 3.1;                  // sheet thickness (mdf_3mm profile; plywood 2.6)
KERF = 0.10;              // mdf_3mm profile
FIT = 0.0;                // extra slot width (port tab slots)
WEB = max(4, T);          // thinnest wood allowed between any cut and an edge or another cut
TAB = 10;                 // port tab slot length

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
W = 99;                   // funnel / keeper width
F_END = 65;               // plate y of F's bottom end (no spacers inside F above this)
FK_X0_LOW = COL_W - 12;   // front keeper's inner edge below F's end (reaches under F)
FK_X0_HIGH = COL_W - 6;   // ... above F's end: 6 mm into F's far slot
BK_X0 = 6;                // back keeper's inner edge (clear of M's body at x < 6)

/* [Gap and spacers] */
SPACER_LAYERS = 3;        // laser-cut ring spacers per gap
GAP = SPACER_LAYERS * T;  // funnel face to each keeper (9.3 at T 3.1); or set a standoff length here
SPACER_D = 10;            // laser-cut ring spacer outside diameter
SPACER_ROOM = 13;         // diameter kept clear around every spacer (fits 1/2" plastic spacers too)
SPACER_ID = 5.0;          // ring spacer hole (M5)
SPACER_CLR = 1;           // keep spacers this far from the channel, holes and F

/* [Channel] */
CH_W = HOLE_D + 1;        // channel width (ball 19.05)
PORT_C = [73, 108];       // pocket / port centre
CH_P1 = [PORT_C[0], 35];  // bezier control points of the channel centreline: pocket -> P1 -> P2 -> bottom hole
CH_P2 = [HOLE_X + 26, 41];

/* [Port] */
PORT = 20;                // square opening = inside of a standard duct
PORT_BOLT = 19;           // corner M5 offset from the port centre (x and y)

/* [Bolts] */
M5 = 5.0;                 // all M5 holes exactly 5.0
BEAM_BOLT_Y = [80, 110];  // funnel -> F's back slot, on BEAM_X, in the gaps between ball holes
HEAD_D = 9.5;             // M5 head diameter (button 9.5, socket 8.5), drawing only
HEAD_H = 5;               // head height, drawing only
// through-bolts besides the 4 port bolts (all through funnel + both keepers, a spacer in each gap)
EXTRA_BOLTS = [[42, 9], [70, 9], [W - 8, 9], [W - 8, 55]];

$fn = 64;

// ------------------------------------------------------------------ derived geometry
HOLES = [for (i = [0 : N_HOLES - 1]) [HOLE_X, BAND + 15 + PITCH * i]];
BEAM_BOLTS = [for (y = BEAM_BOLT_Y) [BEAM_X, y]];
PORT_BOLTS = [for (sx = [-1, 1], sy = [-1, 1]) PORT_C + [sx * PORT_BOLT, sy * PORT_BOLT]];
THRU = concat(PORT_BOLTS, EXTRA_BOLTS);
INSIDE = 2 * GAP + T;     // keeper to keeper, inside
function bez(p0, p1, p2, p3, t) = pow(1 - t, 3) * p0 + 3 * pow(1 - t, 2) * t * p1 + 3 * (1 - t) * t * t * p2 + pow(t, 3) * p3;
PATH = [for (i = [0 : 60]) bez(PORT_C, CH_P1, CH_P2, HOLES[0], i / 60)];
function port_rects(open) = let(e = open ? 0.01 : 0) concat(     // e: slots overlap the opening so they merge into one cut
  [[PORT_C[0] + PORT / 2 - e, PORT_C[1] - TAB / 2, PORT_C[0] + PORT / 2 + T + FIT, PORT_C[1] + TAB / 2],
   [PORT_C[0] - PORT / 2 - T - FIT, PORT_C[1] - TAB / 2, PORT_C[0] - PORT / 2 + e, PORT_C[1] + TAB / 2],
   [PORT_C[0] - TAB / 2, PORT_C[1] + PORT / 2 - e, PORT_C[0] + TAB / 2, PORT_C[1] + PORT / 2 + T + FIT],
   [PORT_C[0] - TAB / 2, PORT_C[1] - PORT / 2 - T - FIT, PORT_C[0] + TAB / 2, PORT_C[1] - PORT / 2 + e]],
  open ? [[PORT_C[0] - PORT / 2, PORT_C[1] - PORT / 2, PORT_C[0] + PORT / 2, PORT_C[1] + PORT / 2]] : []);

// ------------------------------------------------------------------ CHECK report
function rp(r, p) = let(dx = max(r[0] - p[0], 0, p[0] - r[2]), dy = max(r[1] - p[1], 0, p[1] - r[3])) sqrt(dx * dx + dy * dy);
function minl(l) = len(l) ? min(l) : 999;
function chan_d(p) = min([for (q = PATH) norm(q - p)]) - CH_W / 2;        // point to channel edge
function fk_x0(y) = y < F_END ? FK_X0_LOW : FK_X0_HIGH;
function r2(x) = round(x * 100) / 100;
// spacer (circle of SPACER_D at p): clearances in the gaps
function spacer_clear(p) = let(r = SPACER_ROOM / 2) [
  ["channel", chan_d(p) - r],
  ["ball holes", minl([for (h = HOLES) norm(h - p) - HOLE_D / 2 - r])],
  ["beam-bolt spacers (back gap)", minl([for (b = BEAM_BOLTS) if (b != p) norm(b - p) - SPACER_ROOM])],
  ["port opening (front gap)", minl([for (q = port_rects(true)) rp(q, p) - r])],
  ["F beam (front gap)", p[1] + r <= F_END || p[0] - r >= COL_W || p[0] + r <= COL_W - 20 ? 999
                          : max(COL_W - 20 - (p[0] + r), p[0] - r - COL_W, F_END - (p[1] + r))],
  ["other spacers", minl([for (q = THRU) if (q != p) norm(q - p) - SPACER_ROOM])]];
// a beam-bolt spacer sits in the back gap only (in front of the funnel is F itself)
function beam_spacer_clear(p) = let(r = SPACER_ROOM / 2) [
  ["channel", chan_d(p) - r],
  ["ball holes", minl([for (h = HOLES) norm(h - p) - HOLE_D / 2 - r])],
  ["other spacers", minl([for (q = concat(THRU, BEAM_BOLTS)) if (q != p) norm(q - p) - SPACER_ROOM])],
  ["back keeper edge (hole wood)", min(p[0] - BK_X0, W - p[0], p[1], H - p[1]) - M5 / 2]];
// wood around a through-bolt hole in each plate
function hole_wood(p) = let(r = M5 / 2) [
  ["front keeper edge", min(p[0] - fk_x0(p[1]), W - p[0], p[1], H - p[1]) - r],
  ["back keeper edge", min(p[0] - BK_X0, W - p[0], p[1], H - p[1]) - r],
  ["funnel: channel", chan_d(p) - r],
  ["funnel: ball holes", minl([for (h = HOLES) norm(h - p) - HOLE_D / 2 - r])],
  ["funnel: beam bolts", minl([for (b = BEAM_BOLTS) norm(b - p) - M5])],
  ["keepers: port cuts", minl([for (q = port_rects(true)) rp(q, p) - r])]];

module report() {
  echo(str("CHECK feeder: T ", T, ", GAP ", r2(GAP), " (inside ", r2(INSIDE), "), funnel ", W, " x ", H,
           ", bridge over the pocket ", r2(H - PORT_C[1] - CH_W / 2), ", ", len(THRU), " through-bolts + ",
           len(BEAM_BOLTS), " beam bolts (back keeper + funnel into F)"));
  echo(str("ok   channel to beam bolts ", r2(minl([for (b = BEAM_BOLTS) chan_d(b) - M5 / 2])),
           ", ball holes to beam bolts ", r2(minl([for (b = BEAM_BOLTS, h = HOLES) norm(b - h) - HOLE_D / 2 - M5 / 2]))));
  for (p = BEAM_BOLTS) {
    s = beam_spacer_clear(p);
    bad = [for (c = s) if (c[1] < (c[0] == "back keeper edge (hole wood)" ? WEB : SPACER_CLR) - 1e-6) c];
    echo(str(len(bad) ? "WARN " : "ok   ", "beam bolt at ", p, ": back-gap spacer clear by ", [for (c = s) if (c[1] < 900) str(c[0], " ", r2(c[1]))]));
  }
  for (p = THRU) {
    s = spacer_clear(p);
    w = hole_wood(p);
    bad = concat([for (c = s) if (c[1] < SPACER_CLR - 1e-6) c], [for (c = w) if (c[1] < WEB - 1e-6) c]);
    echo(str(len(bad) ? "WARN " : "ok   ", "bolt at ", p, ": spacer clear by ",
             [for (c = s) if (c[1] < 900) str(c[0], " ", r2(c[1]))], "; hole wood ",
             [for (c = w) if (c[1] < 900) str(c[0], " ", r2(c[1]))]));
    if (len(bad)) echo(str("WARN   ^ too close: ", [for (c = bad) c[0]]));
  }
}

// ------------------------------------------------------------------ 2D parts (plate coordinates)
module rect2d(r) translate([r[0], r[1]]) square([r[2] - r[0], r[3] - r[1]]);
module channel2d() {
  for (i = [0 : len(PATH) - 2]) hull() { translate(PATH[i]) circle(d = CH_W); translate(PATH[i + 1]) circle(d = CH_W); }
  translate(PORT_C) circle(d = CH_W);
}
module m5s(pts) for (p = pts) translate(p) circle(d = M5, $fn = 48);
module port2d(open) for (r = port_rects(open)) rect2d(r);

module funnel2d() difference() {
  square([W, H]);
  channel2d();
  for (h = HOLES) translate(h) circle(d = HOLE_D, $fn = 96);
  m5s(concat(BEAM_BOLTS, THRU));
}
module front_keeper2d() difference() {
  offset(r = 2) offset(delta = -2) union() {
    translate([FK_X0_LOW, 0]) square([W - FK_X0_LOW, F_END]);
    translate([FK_X0_HIGH, F_END - 0.01]) square([W - FK_X0_HIGH, H - F_END + 0.01]);
  }
  port2d(true);
  m5s(THRU);
}
module back_keeper2d() difference() {     // no port pattern: nothing attaches from behind
  translate([BK_X0, 0]) square([W - BK_X0, H]);
  m5s(concat(THRU, BEAM_BOLTS));
}
module spacer2d() difference() { circle(d = SPACER_D); circle(d = SPACER_ID, $fn = 48); }

// ------------------------------------------------------------------ 3D assembly
module plate3d(y0) translate([0, y0 + T, 0]) rotate([90, 0, 0]) linear_extrude(T) children();   // occupies Y [y0, y0 + T]
Y_FK = -GAP - T - explode;             // front keeper
Y_BK = T + GAP + explode;              // back keeper (funnel is Y 0 .. T; its front face touches F)
module beam2020(len) difference() {
  cube([20, 20, len]);
  for (a = [0, 90, 180, 270]) translate([10, 10, -1]) rotate([0, 0, a]) translate([-3.1, 10 - 1.8, 0]) cube([6.2, 2, len + 2]);
}
module rodY(p, y0, y1, d) translate([p[0], min(y0, y1), p[1]]) rotate([-90, 0, 0]) cylinder(d = d, h = abs(y1 - y0));
module assembly() {
  color("sandybrown") plate3d(0) funnel2d();
  color("yellowgreen", 0.55) plate3d(Y_FK) front_keeper2d();
  color("yellowgreen", 0.55) plate3d(Y_BK) back_keeper2d();
  color("tan") for (p = THRU) { rodY(p, -GAP - explode / 2, -explode / 2, SPACER_D); rodY(p, T + explode / 2, T + GAP + explode / 2, SPACER_D); }
  color("tan") for (b = BEAM_BOLTS) rodY(b, T + explode / 2, T + GAP + explode / 2, SPACER_D);
  if (show_sieve) color("burlywood") translate([0, 0, H]) plate3d(0) difference() {
    square([COL_W, 90]);
    for (i = [0 : 2]) translate([HOLE_X, 15 + PITCH * i]) circle(d = HOLE_D);
  }
  if (show_beams) {
    color("lightsteelblue") translate([COL_W - 20, -20, F_END]) beam2020(H - F_END + 90);   // F, in front of the funnel
    color("rosybrown") translate([COL_W - 60, -8.4, -10]) beam2020(H + 100);                // M (moving)
  }
  if (show_bolts) color("dimgray") {
    for (b = BEAM_BOLTS) { rodY(b, Y_BK + T, Y_BK + T + HEAD_H, HEAD_D); rodY(b, -8, Y_BK + T, M5); }   // head on the back keeper, into F
    for (p = THRU) { rodY(p, Y_FK - HEAD_H, Y_FK, HEAD_D); rodY(p, Y_FK, Y_BK + T + 5, M5); rodY(p, Y_BK + T, Y_BK + T + 4.7, 9); }
  }
  if (show_balls) color("steelblue") {
    for (i = [0 : 4]) translate([PATH[60 - i * 12][0], T / 2, PATH[60 - i * 12][1]]) sphere(d = BALL_D);
    translate([PORT_C[0], Y_FK - 14, PORT_C[1]]) sphere(d = BALL_D);                          // one coming in through the port
  }
}

// ------------------------------------------------------------------ output
module out2d() if (laser) offset(delta = KERF / 2) children(); else children();
echo(parts = ["funnel", "front_keeper", "back_keeper", "spacer"]);
echo(spacer_qty = (len(THRU) * 2 + len(BEAM_BOLTS)) * SPACER_LAYERS);
report();
if (part == "assembly") assembly();
else if (part == "funnel") out2d() funnel2d();
else if (part == "front_keeper") out2d() front_keeper2d();
else if (part == "back_keeper") out2d() back_keeper2d();
else if (part == "spacer") out2d() spacer2d();
