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
part = "assembly";        // [assembly, funnel, front_keeper, back_keeper, spacer, trough_floor, trough_side_x2, trough_cap]
laser = false;            // grow 2D parts by kerf/2 (cut files)
explode = 0;              // [0:60] pull the layers apart in the assembly
show_beams = true;
show_balls = true;
show_bolts = true;
show_sieve = true;        // S_F stub above the funnel

/* [Material] */
T = 2.82;                 // sheet thickness (mdf3 profile: new batch 2.82; mdf3old 3.1; ply3 2.63)
KERF = 0.10;              // mdf3 profile
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
W = 101;                  // funnel / keeper width
F_END = 65;               // plate y of F's bottom end (no spacers inside F above this)
FK_X0_LOW = COL_W - 12;   // front keeper's inner edge below F's end (reaches under F)
FK_X0_HIGH = COL_W - 6;   // ... above F's end: 6 mm into F's far slot
BK_X0 = 6;                // back keeper's inner edge (clear of M's body at x < 6)

/* [Gap and spacers] */
SPACER_LAYERS = 3;        // laser-cut ring spacers per gap
GAP = SPACER_LAYERS * T;  // funnel face to each keeper (8.46 at T 2.82, 9.3 at 3.1); or set a standoff length here
SPACER_D = 10;            // laser-cut ring spacer outside diameter
SPACER_ROOM = 13;         // diameter kept clear around every spacer (fits 1/2" plastic spacers too)
SPACER_ID = 5.0;          // ring spacer hole (M5)
SPACER_CLR = 1;           // keep spacers this far from the channel, holes and F

/* [Channel] */
CH_W = HOLE_D + 1;        // channel width (ball 19.05)
PORT_C = [74, 108];       // pocket / port centre
CH_P1 = [PORT_C[0], 35];  // bezier control points of the channel centreline: pocket -> P1 -> P2 -> bottom hole
CH_P2 = [HOLE_X + 26, 41];

/* [Port] */
PORT = 20;                // square opening = inside of a standard duct
PORT_BOLT = 20;           // corner M5 offset from the port centre (x and y); mid-side bolts at the same offset

/* [Viewing slots] */
// 5 mm slots in both keepers along the ball channel (same rhythm as the plain keepers:
// 3/4" + 5 long, 3/4" - 5 solid). Far too narrow for a ball to catch in. A slot is dropped
// wherever it would come near a spacer, a bolt, the port or a keeper edge.
VIEW = true;
VS_W = 5;
VS_P = 19.05;             // centre-to-centre length of a slot (slot is VS_P + VS_W long)
VS_SOLID = VS_P - VS_W;   // wood between slots
VS_START = 6;             // first slot starts this far down the channel from the pocket centre

/* [Trough] */
// open-top trough on the port: floor + 2 side walls + end cap, tabbed into the front keeper's
// port notches. Length outside the front keeper, cap included (keeps bolts from the cap to the
// front keeper short):
TROUGH_OUT = 25;
NUT_H = 4.7;              // M5 nut height, for the bolt-length report

/* [Spider tunnel adapter (bolts on the port instead of the trough)] */
TUN_WIRE = 2.05;          // straight wire diameter (12 ga), as ring_jig_compact.py
TUN_BORE = 20;            // clear bore inside the straight wires (ring jig --bore)
TUN_ANGLES = [45, 135, 225, 315];   // straight-wire angles (ring jig --angles); 0 = +x, 90 = up
TUN_CLR = 0.3;            // clearance on the wire notches and the stitch holes
TUN_SEAT = 0.5;           // how deep each wire sits in its notch; the flange bore is opened out to just this much inside the wires' outer edges
TUN_STITCH = true;        // a stitch hole outboard of each notch: the wire passes through the notch, bends back and returns through it
TUN_STITCH_R = 0;         // stitch hole centre radius from the port centre; 0 = halfway between the notch and the corner bolt hole
port_fit = "trough";      // assembly shows "trough" or "tunnel" on the port
NUT_R = 4.7;              // M5 nut corner radius, for the clearance check

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
// mid-side bolts: trough cap -> front keeper only (nut in the front gap). One whose nut would sit
// over the ball channel is left out (the CHECK report says which).
MID_ALL = [PORT_C + [-PORT_BOLT, 0], PORT_C + [PORT_BOLT, 0], PORT_C + [0, PORT_BOLT], PORT_C + [0, -PORT_BOLT]];
function chan_d0(p) = min([for (i = [0 : 60]) norm(bez(PORT_C, CH_P1, CH_P2, [HOLE_X, BAND + 15], i / 60) - p)]) - (HOLE_D + 1) / 2;
PORT_MIDS = [for (p = MID_ALL) if (chan_d0(p) - NUT_R >= 1) p];
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

// ---- viewing slots along the channel centreline
function cumlen(i) = i == 0 ? 0 : cumlen(i - 1) + norm(PATH[i] - PATH[i - 1]);
CUM = [for (i = [0 : len(PATH) - 1]) cumlen(i)];
function seg_i(sv) = max([for (i = [0 : len(PATH) - 2]) if (CUM[i] <= sv) i]);
function path_at(sv) = let(i = seg_i(sv), f = (sv - CUM[i]) / (CUM[i + 1] - CUM[i])) PATH[i] + f * (PATH[i + 1] - PATH[i]);
N_VS = floor((CUM[len(CUM) - 1] - VS_START + VS_SOLID) / (VS_P + VS_W + VS_SOLID));
function vs_pts(k) = [for (j = [0 : 6]) path_at(VS_START + k * (VS_P + VS_W + VS_SOLID) + VS_W / 2 + j * VS_P / 6)];
function vs_ok(k, front) = let(pts = vs_pts(k), r = VS_W / 2,
    bolts = front ? THRU : concat(THRU, BEAM_BOLTS)) min([for (p = pts) min(
  minl([for (b = bolts) norm(b - p) - SPACER_ROOM / 2 - r]),
  front ? minl([for (q = port_rects(true)) rp(q, p) - WEB - r]) : 999,
  (front ? p[0] - fk_x0(p[1]) : p[0] - BK_X0) - WEB - r,
  W - p[0] - WEB - r, p[1] - WEB - r, H - p[1] - WEB - r)]) >= 0;
module view_slots2d(front) if (VIEW) for (k = [0 : N_VS - 1]) if (vs_ok(k, front)) {
  pts = vs_pts(k);
  for (j = [0 : len(pts) - 2]) hull() { translate(pts[j]) circle(d = VS_W, $fn = 24); translate(pts[j + 1]) circle(d = VS_W, $fn = 24); }
}
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
  m5s(concat(THRU, PORT_MIDS));
  view_slots2d(true);
}
module back_keeper2d() difference() {     // no port pattern: nothing attaches from behind
  translate([BK_X0, 0]) square([W - BK_X0, H]);
  m5s(concat(THRU, BEAM_BOLTS));
  view_slots2d(false);
}
module spacer2d() difference() { circle(d = SPACER_D); circle(d = SPACER_ID, $fn = 48); }

// ---- trough: v = distance out from the front keeper's outer face
TR_L = TROUGH_OUT - T;                   // inside length outside the front keeper
TR_PB = PORT_C[1] - PORT / 2;            // floor top = port bottom
TR_HW = PORT / 2 + T + WEB;              // half width of floor and cap
module trough_floor2d() difference() {   // (x, v)
  union() {
    translate([PORT_C[0] - TR_HW, 0]) square([2 * TR_HW, TR_L]);
    translate([PORT_C[0] - TAB / 2, -T]) square([TAB, T + 0.01]);              // into the port's bottom notch
    translate([PORT_C[0] - TAB / 2, TR_L - 0.01]) square([TAB, T + 0.01]);    // into the cap
  }
  for (sx = [-1, 1]) translate([PORT_C[0] + sx * (PORT / 2 + T / 2) - T / 2 - FIT / 2, TR_L / 2 - TAB / 2])
    square([T + FIT, TAB]);                                                   // side walls' bottom tabs
}
module trough_side2d() union() {         // (v, z): z = plate y
  translate([0, TR_PB]) square([TR_L, PORT]);
  translate([-T, PORT_C[1] - TAB / 2]) square([T + 0.01, TAB]);              // into the port's side notch
  translate([TR_L - 0.01, PORT_C[1] - TAB / 2]) square([T + 0.01, TAB]);     // into the cap
  translate([TR_L / 2 - TAB / 2, TR_PB - T]) square([TAB, T + 0.01]);        // into the floor
}
CAP_HW = PORT_BOLT + M5 / 2 + WEB;        // cap reaches past every port bolt
module trough_cap2d() difference() {     // (x, z): 4-fold symmetric; carries holes for all 8 port bolts
  offset(r = 2) offset(delta = -2) translate(PORT_C - [CAP_HW, CAP_HW]) square([2 * CAP_HW, 2 * CAP_HW]);
  m5s(concat(PORT_BOLTS, MID_ALL));
  port2d(false);                         // the port's 4 tab slots, no opening: floor + side walls use 3, the top is spare
}

// spider tunnel adapter: one FLANGE against the front keeper: the bore plus a notch per straight wire,
// so the wires pass through into the port and can't rotate. The tunnel's last ring bears on the
// flange's outer face. Same outline and 8 port-bolt holes as the trough cap. (A ring-pocket collar
// was tried: only 3.25 of wood to the bolt holes, and the notches already locate the wires.)
TUN_RW = TUN_BORE / 2 + TUN_WIRE / 2;                // straight-wire centre radius
TUN_RING_OD = TUN_BORE + 4 * TUN_WIRE;               // ring OD (ring ID = bore + 2 wires)
TUN_HOLE = TUN_WIRE + TUN_CLR;                       // wire notch width and stitch hole diameter
TUN_NOTCH_OUT = TUN_RW + TUN_HOLE / 2;               // notch's outer end, from the port centre
TUN_FBORE = 2 * (TUN_RW + TUN_WIRE / 2 - TUN_SEAT);  // flange + relief bore: the ball clears the plates by much more than it clears the wires
TUN_SR = TUN_STITCH_R > 0 ? TUN_STITCH_R : (TUN_NOTCH_OUT + PORT_BOLT * sqrt(2) - M5 / 2) / 2;
TUN_STITCHES = [for (a = TUN_ANGLES) PORT_C + TUN_SR * [cos(a), sin(a)]];
module port_plate2d() difference() {
  offset(r = 2) offset(delta = -2) translate(PORT_C - [CAP_HW, CAP_HW]) square([2 * CAP_HW, 2 * CAP_HW]);
  m5s(concat(PORT_BOLTS, MID_ALL));
}
module tunnel_flange2d() difference() {
  port_plate2d();
  translate(PORT_C) {
    circle(d = TUN_FBORE, $fn = 128);
    for (a = TUN_ANGLES) rotate(a) translate([0, -TUN_HOLE / 2]) square([TUN_NOTCH_OUT, TUN_HOLE]);
  }
  if (TUN_STITCH) for (q = TUN_STITCHES) translate(q) circle(d = TUN_HOLE, $fn = 24);
}
// RELIEF: one sheet between the front keeper and the flange, so the stitched wires' U-bends (on the
// keeper side of the flange) have somewhere to go: the bore plus a slot from each notch out past its
// stitch hole. Order from the box: front keeper | relief | flange | tunnel rings.
TUN_SLOT_W = TUN_WIRE + 1;
module tunnel_relief2d() difference() {
  port_plate2d();
  translate(PORT_C) circle(d = TUN_FBORE, $fn = 128);
  for (a = TUN_ANGLES) hull() for (r = [TUN_RW, TUN_SR]) translate(PORT_C + r * [cos(a), sin(a)]) circle(d = TUN_SLOT_W, $fn = 24);
}

// ------------------------------------------------------------------ 3D assembly
module plate3d(y0) translate([0, y0 + T, 0]) rotate([90, 0, 0]) linear_extrude(T) children();   // occupies Y [y0, y0 + T]
Y_FK = -GAP - T - explode;             // front keeper
Y_BK = T + GAP + explode;              // back keeper (funnel is Y 0 .. T; its front face touches F)
module beam2020(len) difference() {
  cube([20, 20, len]);
  for (a = [0, 90, 180, 270]) translate([10, 10, -1]) rotate([0, 0, a]) translate([-3.1, 10 - 1.8, 0]) cube([6.2, 2, len + 2]);
}
module rodY(p, y0, y1, d) translate([p[0], min(y0, y1), p[1]]) rotate([-90, 0, 0]) cylinder(d = d, h = abs(y1 - y0));
module assembly(fit = port_fit, balls = show_balls) {   // fit: "trough", "tunnel" or "none" on the port
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
  if (fit == "tunnel") color("peru") {
    translate([0, Y_FK - T, 0]) plate3d(0) tunnel_relief2d();
    translate([0, Y_FK - 2 * T, 0]) plate3d(0) tunnel_flange2d();
  }
  if (fit == "tunnel") color("silver") translate([PORT_C[0], 0, PORT_C[1]]) {
    for (a = TUN_ANGLES) translate([TUN_RW * cos(a), Y_FK - 2 * T - 60, TUN_RW * sin(a)]) rotate([-90, 0, 0]) cylinder(d = TUN_WIRE, h = 60 + T + TUN_WIRE, $fn = 16);
    for (k = [0 : 2]) translate([0, Y_FK - 2 * T - TUN_WIRE / 2 - k * 25, 0]) rotate([90, 0, 0]) rotate_extrude($fn = 64) translate([(TUN_RING_OD - TUN_WIRE) / 2, 0]) circle(d = TUN_WIRE, $fn = 12);
  }
  // trough (v out from the front keeper's outer face, at Y = Y_FK)
  if (fit == "trough") color("peru") {
    translate([0, Y_FK, TR_PB - T]) mirror([0, 1, 0]) linear_extrude(T) trough_floor2d();
    for (sx = [-1, 1]) translate([PORT_C[0] + sx * (PORT / 2 + T / 2) - T / 2, Y_FK, 0])
      rotate([0, 0, 0]) multmatrix([[0, 0, 1, 0], [-1, 0, 0, 0], [0, 1, 0, 0]]) linear_extrude(T) trough_side2d();
    translate([0, Y_FK - TR_L - T, 0]) plate3d(0) trough_cap2d();
  }
  if (balls) color("steelblue") {
    for (i = [0 : 4]) translate([PATH[60 - i * 12][0], T / 2, PATH[60 - i * 12][1]]) sphere(d = BALL_D);
    translate([PORT_C[0], T / 2, PORT_C[1]]) sphere(d = BALL_D);                               // one in the pocket
    if (fit == "trough") for (k = [1 : max(1, floor(TR_L / BALL_D))]) translate([PORT_C[0], Y_FK - TR_L + BALL_D / 2 + (k - 1) * BALL_D + 0.2, TR_PB + BALL_D / 2]) sphere(d = BALL_D);   // two waiting
  }
}

// ------------------------------------------------------------------ output
module out2d() if (laser) offset(delta = KERF / 2) children(); else children();
echo(str("CHECK view slots: ", N_VS, " along the channel; front keeper uses ", len([for (k = [0 : N_VS - 1]) if (vs_ok(k, true)) k]),
         ", back keeper uses ", len([for (k = [0 : N_VS - 1]) if (vs_ok(k, false)) k])));
echo(parts = ["funnel", "front_keeper", "back_keeper", "spacer", "trough_floor", "trough_side_x2", "trough_cap", "tunnel_flange", "tunnel_relief"]);
// tunnel adapter checks: the straight wires must fit inside the port's square opening (corners at PORT / 2)
TUN_WIRE_REACH = max([for (a = TUN_ANGLES) max(abs(TUN_RW * cos(a)), abs(TUN_RW * sin(a)))]) + TUN_WIRE / 2;
echo(str(TUN_WIRE_REACH <= PORT / 2 ? "ok   " : "WARN ", "tunnel wires inside the ", PORT, " port opening: reach ", r2(TUN_WIRE_REACH), " of ", PORT / 2,
         "; bore ", TUN_BORE, " for a ", BALL_D, " ball"));
echo(str(TUN_RW + (TUN_WIRE + TUN_CLR) / 2 + WEB <= PORT_BOLT - M5 / 2 ? "ok   " : "WARN ", "tunnel flange: wood from the wire notches to the port bolt holes ",
         r2(PORT_BOLT - M5 / 2 - TUN_RW - (TUN_WIRE + TUN_CLR) / 2), " (need ", WEB, "); last ring OD ", r2(TUN_RING_OD), " bears on the flange"));
TUN_STITCH_WEB_NOTCH = TUN_SR - TUN_HOLE / 2 - TUN_NOTCH_OUT;
TUN_STITCH_WEB_BOLT = min([for (q = TUN_STITCHES, b = concat(PORT_BOLTS, MID_ALL)) norm(q - b) - M5 / 2 - TUN_HOLE / 2]);
TUN_STITCH_WEB_EDGE = CAP_HW - 2 - max([for (q = TUN_STITCHES) max(abs(q[0] - PORT_C[0]), abs(q[1] - PORT_C[1]))]) - TUN_HOLE / 2;
if (TUN_STITCH) echo(str(min(TUN_STITCH_WEB_NOTCH, TUN_STITCH_WEB_BOLT, TUN_STITCH_WEB_EDGE) >= WEB ? "ok   " : "WARN ",
         "tunnel stitch holes d", TUN_HOLE, " at r ", r2(TUN_SR), " (", r2(TUN_SR - TUN_RW), " out from the wire): wood to the notch ", r2(TUN_STITCH_WEB_NOTCH),
         ", to the nearest bolt hole ", r2(TUN_STITCH_WEB_BOLT), ", to the edge ", r2(TUN_STITCH_WEB_EDGE), " (need ", WEB, ")"));
TUN_RELIEF_WEB = min([for (a = TUN_ANGLES, b = concat(PORT_BOLTS, MID_ALL)) min([for (r = [TUN_RW : 0.5 : TUN_SR]) norm(PORT_C + r * [cos(a), sin(a)] - b)]) - M5 / 2 - TUN_SLOT_W / 2]);
echo(str(TUN_RELIEF_WEB >= WEB && T >= TUN_WIRE ? "ok   " : "WARN ", "tunnel relief: slots ", TUN_SLOT_W, " wide, wood to the nearest bolt hole ", r2(TUN_RELIEF_WEB),
         " (need ", WEB, "); sheet ", T, " for a ", TUN_WIRE, " wire bend"));
// ball resting on the two lowest wires (at +-45 deg below centre): how far its centre sits below the tunnel axis
TUN_BALL_DROP = TUN_RW * sin(45) - sqrt(pow(BALL_D / 2 + TUN_WIRE / 2, 2) - pow(TUN_RW * cos(45), 2));
echo(str(TUN_FBORE / 2 - BALL_D / 2 - TUN_BALL_DROP >= 1 ? "ok   " : "WARN ", "tunnel flange bore d", r2(TUN_FBORE), " (wires seated ", TUN_SEAT,
         " deep): resting ball clears the flange by ", r2(TUN_FBORE / 2 - BALL_D / 2 - TUN_BALL_DROP), " at the bottom; the wires leave ", r2(TUN_BORE - BALL_D), " of play"));
// where the resting ball dips below the port's bottom edge, it must be inside the floor-tab notch (TAB wide) or it meets a lip
TUN_DIP = BALL_D / 2 + TUN_BALL_DROP - PORT / 2;
TUN_DIP_HW = TUN_DIP > 0 ? sqrt(pow(BALL_D / 2, 2) - pow(PORT / 2 - TUN_BALL_DROP, 2)) : 0;
echo(str(TUN_DIP_HW <= TAB / 2 ? "ok   " : "WARN ", "tunnel -> port: the resting ball dips ", r2(max(0, TUN_DIP)), " below the port's bottom edge within +-",
         r2(TUN_DIP_HW), " of centre, inside the ", TAB, "-wide floor-tab notch, so no lip"));
echo(str(PORT_C[0] - TUN_RING_OD / 2 - COL_W >= 3 ? "ok   " : "WARN ", "tunnel rings clear beam F (x ", COL_W - 20, "..", COL_W, ") by ", r2(PORT_C[0] - TUN_RING_OD / 2 - COL_W)));
echo(str("CHECK tunnel bolt lengths (plates + spacers + nut ", NUT_H, "): flange -> back keeper ", r2(5 * T + 2 * GAP + NUT_H),
         ", flange -> front keeper (mid-side) ", r2(3 * T + NUT_H), "; each straight wire runs on past the last ring through its notch, bends back in the relief slot and returns through its stitch hole: ~",
         round(2 * T + 2 * (TUN_SR - TUN_RW) + 10), " mm of wire past the ring"));
echo(str("CHECK trough: back keeper inner face to cap inner face ", r2(2 * GAP + 2 * T + TR_L), "; outside the front keeper ",
         r2(TR_L + T), " (inside ", r2(TR_L), "), ", PORT, " wide inside, ", PORT, " tall walls, open top; cap ", 2 * CAP_HW, " square"));
echo(str("CHECK bolt lengths (plates + spacers + nut ", NUT_H, "): front keeper -> back keeper ", r2(3 * T + 2 * GAP + NUT_H),
         ", cap -> front keeper ", r2(T + TR_L + T + NUT_H), ", cap -> back keeper ", r2(T + TR_L + 3 * T + 2 * GAP + NUT_H)));
echo(str(len(PORT_MIDS) == len(MID_ALL) ? "ok   " : "note ", "mid-side port bolts on the front keeper: ", PORT_MIDS,
         len(PORT_MIDS) == len(MID_ALL) ? "" : str("; left out (nut would sit over the channel): ", [for (p = MID_ALL) if (chan_d0(p) - NUT_R < 1) p], " (the cap keeps its hole)")));
echo(str("CHECK mid-side holes, wood to the port notches: ", [for (p = PORT_MIDS) r2(minl([for (q = port_rects(true)) rp(q, p)]) - M5 / 2)]));
echo(spacer_qty = (len(THRU) * 2 + len(BEAM_BOLTS)) * SPACER_LAYERS);
report();
if (part == "assembly") assembly();
else if (part == "funnel") out2d() funnel2d();
else if (part == "front_keeper") out2d() front_keeper2d();
else if (part == "back_keeper") out2d() back_keeper2d();
else if (part == "spacer") out2d() spacer2d();
else if (part == "trough_floor") out2d() trough_floor2d();
else if (part == "trough_side_x2") out2d() trough_side2d();
else if (part == "trough_cap") out2d() trough_cap2d();
else if (part == "tunnel_flange") out2d() tunnel_flange2d();
else if (part == "tunnel_relief") out2d() tunnel_relief2d();
