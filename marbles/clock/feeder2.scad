// Two-lane feeder for the swinging lift (2026-11-07). Only the feeder: the bottom of both lanes, the
// level side channels into the bottom holes, and the fixed supply that hands each lane ONE ball per
// period, at that lane's end of the swing.
//
// Why: the old J channel stacked the queue above the bottom hole, so the ball being picked up slid
// out against the whole queue's weight (20 steel balls ~ 568 g). Here nothing queues on the rig:
//   * the heavy queue stays on the FIXED frame, on a track at SLOPE deg, held by a one-ball
//     escapement rocker (exit finger up, entry finger down; tipped: the reverse, one ball leaves);
//   * the rig's striker wedge tips that lane's rocker in the last few mm of the swing, where the
//     pendulum is nearly still; the ball DROPS into a wide open trough on the rig (no shear jam:
//     a rolling hand-off at the swing's end would get ~0.13 s of alignment, a 3 deg roll needs ~0.3 s);
//   * the trough and the funnel's straight channel run ACROSS (along x, the pivot axis), so they
//     keep their SLOPE at every swing angle, and lead straight into the bottom hole;
//   * lane B (back) is loaded at the back end of the swing, lane A (front) at the front end:
//     one ball per lane per period = 2 balls per stroke (1 per second with a 2 s pendulum).
// The lift itself is abstract here: each period the column steps up one hole (t 0.20..0.45), then the
// buffer refills the bottom hole (t 0.45..0.50).
//
// Axes (rig frame, at rest): x across (pivot axis), y front -> back (+y = back), z up.
// Lane A = the lift_full.scad lane (funnel plate at local y 0..T); lane B = its mirror about the shared
// middle 2040. The pivot is R above the bottom hole on the rig's centre plane (y = 0).
//
//   openscad feeder2.scad                       (View > Animate, FPS 12, Steps 48: one period)
//   openscad -D t_fixed=0.0 feeder2.scad        (one moment: 0 = back extreme, 0.5 = front extreme)

/* [Animation] */
t_fixed = -1;
t = t_fixed >= 0 ? t_fixed : $t;
show_rig = true;
show_fixed = true;

/* [Swing] */
R = 900;          // pivot height above the bottom hole (ESTIMATE until the pendulum is cut)
TH0 = 3;          // swing amplitude, +- deg (small: a seconds pendulum; the link arm makes the stroke)

/* [Feed] */
SLOPE = 3;        // deg, every feed track and channel
DROP = 24;        // ball centre fall from the fixed exit into the rig trough
TR_W = 50;        // trough width (y): catches a ball released up to +-15 mm from the trough centre
TR_L = 70;        // trough length (x) beyond the funnel box
XD_OFF = 45;      // drop point: this far out from the box edge
CATCH = 15;       // catch pocket centre: this far outward (away from the other lane) of the lane line
ENG = 19.4;       // the striker wedge engages over the last ENG mm of the swing
PHI = 24;         // rocker tip angle when engaged
TAIL = 25;        // rocker tail: this far toward the lift from the drop point

/* [Lane geometry, from lift_full.scad / feeder.scad] */
BALL = 19.05; r = BALL / 2;
T = 2.82; GAP = 8.46;
W = 101; H = 140; COL_W = 46; HOLE_X = 16; Z_HOLE = 35; PITCH = 30;
F_END = 65;
MID = 22.6;       // lane A local y of the shared 2040's centre (12.6 .. 32.6)
STUB = 110;       // lift drawn this far above the box

// ---------------------------------------------------------------- derived
yA = T / 2 - MID;                  // lane A ball / plate centre (rig frame)
YC = [yA, -yA];                    // lane centres: A (front, -y), B (back, +y)
SIDE = [-1, 1];                    // each lane's outer side
T_REL = [0.5, 0.0];                // release (= that lane's extreme): A at the front end, B at the back end
TH_EXT = [-TH0, TH0];              // tilt at those extremes
PV = [0, 0, Z_HOLE + R];           // pivot
X_D = W + XD_OFF;
function th(tt) = TH0 * cos(360 * tt);
function rotx(v, a) = [v[0], v[1] * cos(a) - v[2] * sin(a), v[1] * sin(a) + v[2] * cos(a)];
function wld(p, a) = PV + rotx(p - PV, a);                       // rig frame -> world at tilt a
function zc(x) = Z_HOLE + (x - HOLE_X) * tan(SLOPE);              // ball centre along the channel
function cl(x) = max(0, min(1, x));
function sm(e0, e1, x) = let(s = cl((x - e0) / (e1 - e0))) s * s * (3 - 2 * s);
function fr(x) = x - floor(x);
RS = R * sin(TH0);
function engage(L, tt) = let(u = fr(tt - T_REL[L] + 0.5) - 0.5, d = RS * (1 - cos(360 * u))) sm(0, 1, 1 - d / ENG);

// fixed dispenser exit (ball centre, world) for lane L: right above the trough at that lane's extreme
function yk(L) = YC[L] + SIDE[L] * CATCH;                          // catch pocket centre (rig y)
function q0(L) = wld([X_D, yk(L), zc(X_D)], TH_EXT[L]) + [0, 0, DROP];
function qk(L, k) = q0(L) + k * BALL * [cos(SLOPE), 0, sin(SLOPE)];
function floor_z(L) = q0(L)[2] - r;                                // track floor under the exit ball

// ---------------------------------------------------------------- ball path on the rig (per release)
BUF2 = HOLE_X + 2 * (BALL + 0.3); BUF1 = HOLE_X + BALL + 0.3;
SLOTS = [[BUF2, 0], [BUF1, 0], [HOLE_X, 0], [HOLE_X, 1], [HOLE_X, 2], [HOLE_X, 3], [HOLE_X, 4]];
function slot_p(L, s) = let(e = SLOTS[s]) [e[0], YC[L], e[1] == 0 ? zc(e[0]) : Z_HOLE + PITCH * e[1]];
// events after arrival: shift (buffer moves on) at n+0.45..n+0.50, lift (column steps) at n+0.20..n+0.45
function evs(ta) = [for (n = [floor(ta) : floor(ta) + 6]) for (e = [[n + 0.20, n + 0.45, 1], [n + 0.45, n + 0.50, 0]]) if (e[0] >= ta) e];
function walk(L, E, i, s, tt) =
  i >= len(E) || s >= 6 ? slot_p(L, s)
  : let(e = E[i], movable = e[2] == 0 ? s < 2 : s >= 2)
    tt >= e[1] ? walk(L, E, i + 1, movable ? s + 1 : s, tt)
    : tt > e[0] && movable ? slot_p(L, s) + sm(e[0], e[1], tt) * (slot_p(L, s + 1) - slot_p(L, s))
    : slot_p(L, s);
// world position of the ball released at tr, or undef while still in the dispenser
function ball_w(L, tr, tt) =
  tt < tr ? undef
  : let(a = tt - tr)
    a < 0.04 ? let(f = a / 0.04) q0(L) + (wld([X_D, yk(L), zc(X_D)], th(tt)) - q0(L)) * f * f
    : a < 0.30 ? let(f = sm(0.04, 0.30, a), x = X_D + (BUF2 - X_D) * f,
                     y = YC[L] + SIDE[L] * CATCH * sm(0, 1, (x - W - 10) / (X_D - W - 10)))   // the taper wall steers it in
                 wld([x, y, zc(x)], th(tt))
    : wld(walk(L, evs(tr + 0.30), 0, 0, tt), th(tt));

// ---------------------------------------------------------------- parts
module beam2020(len) difference() {
  cube([20, 20, len]);
  for (a = [0, 90, 180, 270]) translate([10, 10, -1]) rotate([0, 0, a]) translate([-3.1, 10 - 1.8, 0]) cube([6.2, 2, len + 2]);
}
module plate_xz(y0, th) translate([0, y0 + th, 0]) rotate([90, 0, 0]) linear_extrude(th) children();   // 2D (x, z) -> y0..y0+th
module funnel2d() difference() {
  square([W, H]);
  hull() { translate([HOLE_X, Z_HOLE]) circle(d = BALL + 1.5, $fn = 48); translate([W + 1, zc(W + 1)]) circle(d = BALL + 1.5, $fn = 48); }
  for (i = [1 : 3]) translate([HOLE_X, Z_HOLE + PITCH * i]) circle(d = 20, $fn = 48);
}
module sieve2d() difference() { square([COL_W, STUB]); for (i = [0 : 3]) translate([HOLE_X, PITCH / 2 + PITCH * i]) circle(d = 20, $fn = 48); }
// one lane in lane-local coords (lift_full's lane), shifted so the shared 2040 is centred on y = 0
module lane_local() translate([0, -MID, 0]) {
  color("sandybrown") plate_xz(0, T) funnel2d();
  color("burlywood") translate([0, 0, H]) plate_xz(0, T) sieve2d();
  color("lightcyan", 0.3) { plate_xz(-GAP - T, T) square([W, H]); plate_xz(T + GAP, T) square([W, H]); }
  color("lightsteelblue") translate([COL_W - 20, -20, F_END]) beam2020(H + STUB - F_END);   // F
  color("rosybrown") translate([COL_W - 60, -8.4, -10]) beam2020(H + STUB + 10);           // M (its stroke is not drawn)
}
// the rig trough for lane L (rig frame): open top; the catch pocket (TR_W wide) is offset CATCH outward so
// the two lanes' troughs clear each other, and its outer wall tapers into the channel at the box edge
module trough(L) {
  y = YC[L]; sd = SIDE[L]; zf = function (x) zc(x) - r - 0.5;
  inner = y - sd * (GAP + T / 2);                      // channel wall line, toward the other lane
  outer0 = y + sd * (GAP + T / 2);
  outer1 = yk(L) + sd * TR_W / 2;
  module wall(x0, y0, x1, y1) hull() { translate([x0, y0 - 1.5, zf(x0)]) cube([0.01, 3, 12]); translate([x1, y1 - 1.5, zf(x1)]) cube([0.01, 3, 12]); }
  color("peru") {
    hull() for (x = [W, W + TR_L]) translate([x, min(inner, outer1), zf(x) - 3]) cube([0.01, abs(outer1 - inner), 3]);   // floor
    wall(W, inner, W + TR_L, inner);
    wall(W, outer0, W + 10, outer0);
    wall(W + 10, outer0, W + 30, outer1);
    wall(W + 30, outer1, W + TR_L, outer1);
    wall(W + TR_L, inner, W + TR_L, outer1);
  }
  // striker wedge off the trough's end: rises toward the extreme, under that lane's rocker tail roller
  tip = wld(tail_tip(L, 0), -TH_EXT[L]);                       // the resting roller centre, rig frame, at the extreme
  hi = tip[2] - 3 + TAIL * sin(PHI);                           // wedge top where the roller is fully lifted
  xw = tip[0]; zb = zf(W + TR_L) - 2;
  color("darkorange") hull() {
    translate([xw - 4, tip[1] - SIDE[L] * 3 - (SIDE[L] < 0 ? 4 : 0), zb]) cube([8, 4, hi - zb]);
    translate([xw - 4, tip[1] + SIDE[L] * ENG - (SIDE[L] < 0 ? 1 : 0), zb]) cube([8, 1, tip[2] - 3 - zb]);
  }
  color("peru") hull() {                                       // arm from the trough's end wall to the wedge
    translate([W + TR_L - 3, yk(L) + SIDE[L] * (TR_W / 2 - 3), zb]) cube([3, 3, 4]);
    translate([xw - 4, tip[1] - SIDE[L] * 3, zb]) cube([8, 3, 4]);
  }
}
module rig() {
  lane_local();
  mirror([0, 1, 0]) lane_local();
  color("lightsteelblue") translate([COL_W - 60 + 20, -10, H]) cube([40, 20, STUB]);   // shared middle 2040 (sketch)
  for (L = [0, 1]) trough(L);
}

// ---------------------------------------------------------------- fixed supply: track + one-ball rocker per lane
// tail: out along +x past the queue's first balls, then sideways beyond the trough wall; the rig's wedge
// pushes its roller UP, which tips the exit finger down and the entry finger up
function tail_tip(L, ph) = let(p = [q0(L)[0], q0(L)[1], floor_z(L) - 5]) p + [TAIL * cos(ph), SIDE[L] * (TR_W / 2 + 6), TAIL * sin(ph) - 4];
module track(L) {
  q = q0(L); fz = floor_z(L); n = 6;
  color("silver") translate([q[0], q[1], fz]) rotate([0, -SLOPE, 0]) {
    difference() {
      translate([-r + 0.5, -10.5, -2]) cube([n * BALL + r, 21, 2]);
      translate([-r + 0.5 - 2.5, -1.5, -3]) cube([3, 3, 4]);                       // exit finger slot
      translate([r - 1.5, -1.5, -3]) cube([3, 3, 4]);                              // entry finger slot
    }
    for (s = [-1, 1]) translate([-r + 0.5, s * 10.5 - (s < 0 ? 2 : 0), -2]) cube([n * BALL + r, 2, 12]);
  }
  // rocker: pivot under the exit ball, axis along y; fingers one ball apart; tail toward the lift, then out sideways
  ph = PHI * engage(L, t);
  color("dimgray") translate([q[0], q[1], fz - 5]) rotate([0, -ph, 0]) {
    rotate([90, 0, 0]) cylinder(d = 4, h = 24, center = true, $fn = 16);
    translate([-r - 1, -1.5, -1.5]) cube([BALL + 2, 3, 3]);                           // lever
    translate([-(r - 0.5) - 1.5, -1.5, 0]) cube([3, 3, 5 + 3]);                       // exit finger: 3 above the floor at rest
    translate([r - 1.5, -1.5, 0]) cube([3, 3, 5 - 0.5]);                              // entry finger: just below it
    translate([r + 6, -6, -6]) cube([8, 12, 8]);                                      // counterweight (holds the rest position)
    hull() { cube([1, 3, 3], center = true); translate([TAIL, 0, -4]) cube([1, 3, 3], center = true); }
    hull() { translate([TAIL, 0, -4]) cube([3, 3, 3], center = true); translate([TAIL, SIDE[L] * (TR_W / 2 + 6), -4]) cube([3, 3, 3], center = true); }
    translate([TAIL, SIDE[L] * (TR_W / 2 + 6), -4]) rotate([90, 0, 0]) cylinder(d = 6, h = 4, center = true, $fn = 16);   // roller on the striker
  }
}
module supply() {
  for (L = [0, 1]) track(L);
  // the common supply splits into the two tracks further out (+x): drawn as a stub
  color("silver", 0.5) hull() for (L = [0, 1]) translate(qk(L, 6) + [0, -11, -r - 2]) cube([2, 22, 2]);
}

// ---------------------------------------------------------------- balls
module ball(p) if (!is_undef(p)) translate(p) color("steelblue") sphere(d = BALL, $fn = 28);
module balls() for (L = [0, 1]) {
  base = t >= T_REL[L] ? T_REL[L] : T_REL[L] - 1;            // the latest release
  for (k = [-6 : 0]) ball(ball_w(L, base + k, t));
  // the dispenser queue: the head ball reaches the exit finger 0.15..0.30 after each release
  u = fr(t - T_REL[L]);
  for (j = [0 : 4]) ball(u < 0.15 ? qk(L, j + 1) : u < 0.30 ? qk(L, j + 1) + sm(0.15, 0.30, u) * (qk(L, j) - qk(L, j + 1)) : qk(L, j));
}

// ---------------------------------------------------------------- scene
if (show_rig) translate(PV) rotate([th(t), 0, 0]) translate(-PV) rig();
if (show_fixed) supply();
balls();
// the pivot is R above; a thin line shows where
color("gray") translate(PV) sphere(d = 12, $fn = 16);

echo(str("FEEDER2: swing +-", TH0, " deg at R ", R, " -> bottom travel +-", round(RS * 10) / 10, " mm; lanes ", round(-2 * yA * 10) / 10,
         " mm apart; drop points ", round(q0(0)[1] * 10) / 10, " / ", round(q0(1)[1] * 10) / 10, " (y); slope ", SLOPE, " deg; t = ", t));
