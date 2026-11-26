// Pendulum infeed tipper (escapement), all wire, the simple version: one straight 4-wire tipping section that
// continues the waiting track. Seen with x along the track (balls roll +x), y front to back (the fulcrum axis),
// z up. The floor (the balls' bottoms) is z = 0 at the tipping section's start, falling at rest_slope downstream.
//
// At rest: balls 1 and 0 sit in the tipping section against the FIXED PEG (frame-mounted, comes up between the
// lower wires 40 in from the section's start); the queue (2, 3, 4 ...) waits on the fixed waiting track behind them.
// Tripped: the pendulum's catcher pushes up under the exit end; the section turns on its pivot (downstream of the
// exit end, above the ball path) and its upstream end lifts most: the floor clears the fixed peg, balls 0 + 1 roll out
// of the exit end into the catcher (only while it's there), and the upstream ring + the HOLD-BACK PEG hanging below
// it come up in front of ball 2 and hold the queue.
//
// Customizer for the numbers; View > Animate (FPS 10, Steps 40) to rock it, or set tilt_fixed.
// Grey = fixed, blue = tipping wires, green = retaining rings, red = pegs.

/* [Motion] */
tilt_max = 8;            // deg the section turns when tripped (upstream end up)
tilt_fixed = -1;         // >= 0: freeze at this tilt; -1: animate 0 .. tilt_max
rest_slope = 2;          // deg, the track falls this much downstream at rest

/* [Tipping section] */
sec_len = 60;            // section length (2 balls + over the peg + out)
ring_in = 2.5;           // rings this far in from each end
tail = 20;               // wire tails past each end (for joining)
pivot_dx = 30;           // pivot this far downstream of the exit end
pivot_up = 16;           // pivot this far above the tube axis (over the ball path)

/* [Pegs] */
peg_x = 40;              // fixed peg: this far in from the section's start (in front of ball 0)
peg_h = 4;               // fixed peg stands this far above the floor (a ball needs ~54 deg of tilt to roll over 4)
hold_len = 10;           // hold-back peg hangs this far below the floor from the upstream ring

/* [Hidden] */
D = 19.05; R = D / 2;
WD = 2.05;               // wire
RW = 11.025;             // tube wire centre radius (20 bore)
RING_R = 13.075;         // ring wire centre radius (ring OD 28.2)
AXIS = R + 0.7;          // tube axis above the floor (the ball sits 0.7 below it on the two lower wires)
WIRE_A = [45, 135, 225, 315];
$fn = 24;

tilt = tilt_fixed >= 0 ? tilt_fixed : tilt_max * (0.5 - 0.5 * cos(360 * $t));
PIV = [sec_len + pivot_dx, 0, AXIS + pivot_up];

module wire_seg(a, b) { hull() { translate(a) sphere(d = WD); translate(b) sphere(d = WD); } }

// a straight 4-wire tube from x0 to x1 (tube axis at z = AXIS), with rings at the given x
module tube(x0, x1, rings, col) {
    color(col) for (a = WIRE_A) wire_seg([x0, RW * cos(a), AXIS + RW * sin(a)], [x1, RW * cos(a), AXIS + RW * sin(a)]);
    color("green") for (x = rings) translate([x, 0, AXIS]) rotate([0, 90, 0]) rotate_extrude() translate([RING_R, 0]) circle(d = WD);
}

module ball(c, col) { color(col, 0.6) translate(c) sphere(d = D, $fn = 32); }

// everything that tips: section tube + tails, two rings, hold-back peg, side hangers up to the pivot, balls 0 and 1
module tipping() {
    tube(-tail * 0 - 0.5, sec_len + tail, [ring_in, sec_len - ring_in], "royalblue");
    // hold-back peg: hangs from the upstream ring's bottom, below the floor
    color("red") wire_seg([ring_in, 0, AXIS - RING_R], [ring_in, 0, -hold_len]);
    // hangers: from the exit-end ring's top, front and back, up and along to the pivot
    color("royalblue") for (s = [-1, 1]) {
        wire_seg([sec_len - ring_in, s * RING_R * 0.7, AXIS + RING_R * 0.7], [PIV[0], s * (RING_R + 3), PIV[2]]);
        wire_seg([ring_in, s * RING_R * 0.7, AXIS + RING_R * 0.7], [PIV[0], s * (RING_R + 3), PIV[2]]);
    }
    if (tilt < 0.6 * tilt_max) { ball([R, 0, R], "seagreen"); ball([R + D, 0, R], "seagreen"); }
}

// fixed: waiting track (with its own tails into the joint), fixed peg, pivot axle
module fixed() {
    tube(-120, -1, [-100, -60, -20], "dimgray");
    color("red") wire_seg([peg_x, 0, -22], [peg_x, 0, peg_h]);                     // fixed peg, from the frame below
    color("dimgray") translate([PIV[0], -30, PIV[2]]) rotate([-90, 0, 0]) cylinder(d = 3, h = 60);   // pivot axle (M3)
    for (k = [2, 3, 4]) ball([-(k - 2) * D - R, 0, R], "steelblue");
}

// the catcher's push point (the pendulum, by hand): under the exit end
module catcher_hint() {
    // just under the lower wires at the exit end (it pushes up there, and catches what rolls out past it)
    color("peru", 0.5) translate([sec_len - 8, -16, AXIS - RW * sin(45) - WD / 2 - 3.2]) cube([16, 32, 3]);
}

rotate([0, rest_slope, 0]) {
    fixed();
    translate(PIV) rotate([0, tilt, 0]) translate(-PIV) tipping();
    catcher_hint();
}

// numbers (echo): floor lift at the fixed peg and at the section's start, push travel at the exit end
lift_peg = (PIV[0] - peg_x) * sin(tilt_max);
lift_start = PIV[0] * sin(tilt_max);
push = (PIV[0] - (sec_len - 4)) * sin(tilt_max);
echo(str("at tilt ", tilt_max, ": floor at the peg rises ", lift_peg, " (peg ", peg_h, "), section start rises ", lift_start,
         " -> hold-back peg tip ", lift_start - hold_len, " above the fixed floor (<= ~8 blocks ball 2); catcher pushes ", push));
echo(str("tilt needed just to clear the peg: ", asin(peg_h / (PIV[0] - peg_x)), " deg"));
