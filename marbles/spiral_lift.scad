/*

Spiral (rotating wire coil) marble lift, built on wire_track.scad.

How it works: a wire coil spins around a vertical rod. A marble sits on the
coil wire just outside the coil and leans outward against two fixed
vertical "channel" rails, so it can't ride around with the coil; as the coil
turns, the wire under the marble rises and carries it up. At the top the
channel rails bend over into the exit track and the marble rolls out.

  - left-hand coil, turned counter-clockwise seen from above (lift_ccw)
  - marble pickup is on the +x (east) side of the rod, arriving heading +y
  - the +y channel rail runs down into the pickup pocket as a stop; the
    coil drags the marble against it
  - pitch is chosen so the turn above clears the marble, yet the gap between
    turns is too small for a marble to fall into the coil

Printable parts (`lift_part`):
  mandrel      - grooved winding form; stack segments on the rod, pins align
  hub          - coil end hub (print 2): coil tail drops in the slot,
                 M3 set screw to the rod
  coupler      - N20 D-shaft to rod
  bushing      - flanged rod bushing through the board
  motor_mount  - hangs an N20 gear motor under the board
  top_arm      - top rod bearing, clamps to the lift post
  channel_clip - wire_track open2 saddle that threads onto the lift post
  foot         - board foot (print 4)

  openscad -o mandrel.stl -D 'lift_part="mandrel"' marbles/spiral_lift.scad

Motor/rod numbers below are typical N20 gear motor values -- measure yours.

*/

include <wire_track.scad>
part = "none";

lift_part = "assembly";

// Board
board_th = 6;
lift_c = [150, 150];

// Rod and coil
rod_d = 6;
coil_r = 14;
// Marble-on-coil contact angle from vertical: bigger pushes the marble
// outward harder against the channel rails
coil_beta = 40;
coil_pitch = 17;
lift_ccw = true;

// Lift path, marble center heights
z_entry = 45;
z_exit = 270;
// Coil carries the marble this far past z_exit before the top hub
exit_overrun = 3;

// Hubs, bushing
hub_h = 12;
hub_r = coil_r - wire_r - clr/2;
bushing_od = 10;
bushing_flange_d = 20;
bushing_flange_th = 3;

// Winding mandrel. The coil springs open after winding; mandrel_k scales
// the form down to compensate. Unverified starting guess: wind a test coil
// and adjust until the coil's free radius matches coil_r.
mandrel_k = 0.85;
mandrel_seg_turns = 5;
mandrel_pin_d = wire_od + 0.2;

// N20 gear motor (measure yours)
n20_w = 12;
n20_t = 10;
n20_l = 34;
n20_shaft_d = 3;
n20_shaft_flat = 2.5;
n20_shaft_l = 10;
coupler_l = 20;
coupler_od = rod_d + 6;
coupler_rod_depth = 12;
coupler_shaft_depth = 8;
m3_d = 3.2;

// Lift post (also the top bearing support) and channel clips
lift_post_d = 4;
channel_clip_pitch = 45;
arm_th = 6;

// --- derived ---
lift_m = coil_r + rail_r * sin(coil_beta);
lift_dz = rail_r * cos(coil_beta);
channel_r = lift_m + rail_r * cos(floor_a);
helix_a = atan(coil_pitch / (2 * PI * coil_r));
// gap from the turn above to the marble it is lifting
turn_clr = norm([lift_m - coil_r, coil_pitch - lift_dz]) - rail_r;
// clear opening between turns; must be too small for a marble
turn_gap = coil_pitch - wire_od;
z_coil0 = bushing_flange_th + hub_h;
z_coil1 = z_exit + exit_overrun - lift_dz + coil_pitch;
coil_turns = (z_coil1 - z_coil0) / coil_pitch;
coil_wire_l = coil_turns * norm([2 * PI * coil_r, coil_pitch]) + 2 * coil_r;
z_rails_top = z_exit - rail_r * cos(floor_a);
channel_ro = r_out_of(track_rails("open2"));
post_off = channel_ro + tab_l/2;
lift_post_xy = lift_c + [lift_m, post_off];
z_arm = z_coil1 + hub_h + 2;
rod_below = coupler_rod_depth - 1;
rod_l = board_th + rod_below + z_arm + arm_th;
// under the board: coupler, shaft stick-out, motor
motor_drop = 1 + coupler_l + (n20_shaft_l - coupler_shaft_depth) + n20_l;
foot_h = ceil(motor_drop + 5);
mandrel_r = coil_r * mandrel_k;
mandrel_seg_h = mandrel_seg_turns * coil_pitch;

echo(lift_m=lift_m, lift_dz=lift_dz, channel_r=channel_r, helix_a=helix_a);
echo(turn_clr=turn_clr, turn_gap=turn_gap, marble_od=marble_od);
echo(coil_turns=coil_turns, coil_wire_l=coil_wire_l, z_coil0=z_coil0, z_coil1=z_coil1);
echo(rod_l=rod_l, motor_drop=motor_drop, foot_h=foot_h, lift_post_xy=lift_post_xy,
    lift_post_h=z_arm + arm_th);
echo(mandrel_r=mandrel_r, mandrel_seg_h=mandrel_seg_h);
assert(turn_clr > 1, "coil pitch too small: the next turn hits the marble");
assert(turn_gap < marble_od - escape_margin, "coil pitch too big: marbles fall into the coil");
assert(coil_r - wire_r > rod_d/2 + 3, "coil too small for the rod and hub");


// Coil wire position at turn angle t (deg); left-hand so it rises as t falls
function coil_pt(t, z0=z_coil0) =
    [coil_r * cos(t), coil_r * sin(t), z0 + (lift_ccw ? -t : t) * coil_pitch / 360];

module coil(spin=0) {
    n = ceil(coil_turns * 36);
    t_end = (lift_ccw ? -1 : 1) * coil_turns * 360;
    translate(lift_c)
        rotate([0, 0, spin])
        for (i=[0:n-1])
            hull() {
                translate(coil_pt(t_end * i / n)) sphere(r=wire_r, $fn=8);
                translate(coil_pt(t_end * (i + 1) / n)) sphere(r=wire_r, $fn=8);
            }
}

// ! coil();


module mandrel() {
    twist = 360 * mandrel_seg_h / coil_pitch;
    difference() {
        linear_extrude(height=mandrel_seg_h, twist=lift_ccw ? twist : -twist,
                slices=mandrel_seg_h * 2)
            difference() {
                circle(r=mandrel_r, $fn=base_fn);
                translate([mandrel_r, 0])
                    circle(r=wire_r + 0.15, $fn=base_fn/4);
            }
        translate([0, 0, -1])
            cylinder(d=rod_d + clr, h=mandrel_seg_h + 2, $fn=base_fn/2);
        // alignment pins between stacked segments (segments are whole turns)
        for (z=[0, mandrel_seg_h], a=[90, 270])
            rotate([0, 0, a])
                translate([(rod_d/2 + mandrel_r)/2, 0, z])
                cylinder(d=mandrel_pin_d, h=10, center=true, $fn=base_fn/4);
        // anchor hole for the wire end at the groove start
        translate([mandrel_r - 2, 0, 3])
            rotate([0, 90, 0])
            cylinder(d=wire_od + clr, h=mandrel_r, center=true, $fn=base_fn/4);
    }
}

// ! mandrel();


module hub() {
    difference() {
        cylinder(r=hub_r, h=hub_h, $fn=base_fn);
        translate([0, 0, -1])
            cylinder(d=rod_d + clr/2, h=hub_h + 2, $fn=base_fn/2);
        // coil tail, bent radially inward, drops into this slot
        translate([0, -(wire_od + clr)/2, hub_h - wire_od - 1])
            cube([hub_r + 1, wire_od + clr, wire_od + 2]);
        // M3 set screw
        translate([0, 0, hub_h/2 - 1])
            rotate([90, 0, 0])
            cylinder(d=2.5, h=hub_r + 1, $fn=base_fn/4);
    }
}

// ! hub();


module coupler() {
    difference() {
        cylinder(d=coupler_od, h=coupler_l, $fn=base_fn);
        translate([0, 0, coupler_l - coupler_rod_depth])
            cylinder(d=rod_d + clr/2, h=coupler_rod_depth + 1, $fn=base_fn/2);
        translate([0, 0, -1])
            linear_extrude(coupler_shaft_depth + 1)
            intersection() {
                circle(d=n20_shaft_d + 0.15, $fn=base_fn/2);
                translate([-n20_shaft_d, -n20_shaft_d/2 - 0.1])
                    square([2 * n20_shaft_d, n20_shaft_flat + 0.2]);
            }
        for (z=[coupler_shaft_depth/2, coupler_l - coupler_rod_depth/2])
            translate([0, 0, z])
                rotate([-90, 0, 0])
                cylinder(d=2.5, h=coupler_od, $fn=base_fn/4);
    }
}

// ! coupler();


module bushing() {
    difference() {
        union() {
            cylinder(d=bushing_od, h=board_th + bushing_flange_th, $fn=base_fn);
            translate([0, 0, board_th])
                cylinder(d=bushing_flange_d, h=bushing_flange_th, $fn=base_fn);
        }
        translate([0, 0, -1])
            cylinder(d=rod_d + clr, h=board_th + bushing_flange_th + 2, $fn=base_fn/2);
    }
}

// ! bushing();


motor_mount_w = n20_w + 10;
motor_mount_screw_x = motor_mount_w/2 + 5;

module motor_mount() {
    clamp_l = 12;
    h = motor_drop - n20_l + clamp_l;
    difference() {
        union() {
            translate([-motor_mount_w/2, -(n20_t + 10)/2, 0])
                cube([motor_mount_w, n20_t + 10, h]);
            // screw flange against the underside of the board
            translate([-motor_mount_screw_x - 5, -(n20_t + 10)/2, 0])
                cube([2 * motor_mount_screw_x + 10, n20_t + 10, 4]);
        }
        // room for the spinning coupler
        translate([0, 0, -1])
            cylinder(d=coupler_od + 3, h=h - clamp_l + 1, $fn=base_fn);
        // gear motor clamp pocket
        translate([-(n20_w + clr)/2, -(n20_t + clr)/2, h - clamp_l - 1])
            cube([n20_w + clr, n20_t + clr, clamp_l + 2]);
        // window to reach the coupler set screws
        translate([0, -n20_t, 6])
            cube([coupler_od, 2 * n20_t, h - clamp_l - 8]);
        for (s=[-1, 1])
            translate([s * motor_mount_screw_x, 0, -1])
                cylinder(d=m3_d, h=6, $fn=base_fn/4);
    }
}

// ! motor_mount();


module top_arm_2d() {
    d = lift_post_xy - lift_c;
    difference() {
        hull() {
            circle(d=rod_d + 2 * wall + 4, $fn=base_fn/2);
            translate(d)
                circle(d=lift_post_d + 2 * wall + 4, $fn=base_fn/2);
        }
        circle(d=rod_d + clr, $fn=base_fn/2);
        translate(d)
            circle(d=lift_post_d + clr, $fn=base_fn/2);
    }
}

module top_arm() {
    linear_extrude(arm_th)
        top_arm_2d();
}

// ! top_arm();


// Channel clip: an open2 saddle whose "down" points outward from the rod,
// tab toward +y with a hole that threads onto the lift post.
module channel_clip() {
    saddle("open2", 0, "screw", 90, lift_post_d + clr);
}

// ! channel_clip();

foot_d = 20;

module foot() {
    difference() {
        cylinder(d1=foot_d + 6, d2=foot_d, h=foot_h, $fn=base_fn);
        translate([0, 0, foot_h - 10])
            cylinder(d=2.5, h=11, $fn=base_fn/4);
    }
}

// ! foot();


// Clip-plane frame: clip x -> world +y (tab side), clip -y ("down") -> world
// +x (outward), clip z -> world z.
module channel_frame(z) {
    translate([lift_c[0] + lift_m, lift_c[1], z])
        rotate([0, 0, 90])
        children();
}

module channel_rails() {
    offs = rail_offsets("open2");
    for (o=offs) {
        // +y rail is the stop and runs down into the pickup pocket
        z0 = o[0] > 0 ? z_entry - marble_r : z_entry + marble_od;
        channel_frame(z0)
            translate(o)
            cylinder(r=wire_r, h=z_rails_top - z0, $fn=base_fn/4);
    }
}

module lift_assembly(spin=0) {
    color("silver") coil(spin);
    color("silver") channel_rails();
    color("dimgray")
        translate(concat(lift_c, -board_th - rod_below))
        cylinder(d=rod_d, h=rod_l, $fn=base_fn/2);
    color("dimgray")
        translate(lift_post_xy)
        cylinder(d=lift_post_d, h=z_arm + arm_th, $fn=base_fn/2);
    color("orange") {
        translate(concat(lift_c, -board_th)) bushing();
        translate(concat(lift_c, bushing_flange_th))
            rotate([0, 0, spin]) hub();
        translate(concat(lift_c, z_coil1 + hub_h))
            rotate([0, 0, spin]) mirror([0, 0, 1]) hub();
        translate(concat(lift_c, z_arm)) top_arm();
        for (z=[z_entry + marble_od + 5 : channel_clip_pitch : z_rails_top - 5])
            channel_frame(z - clip_th/2) channel_clip();
        translate(concat(lift_c, -board_th - 1 - coupler_l)) coupler();
        translate(concat(lift_c, -board_th)) mirror([0, 0, 1]) motor_mount();
    }
    color("black")
        translate(concat(lift_c, -board_th - motor_drop))
        translate([-n20_w/2, -n20_t/2, 0])
        cube([n20_w, n20_t, n20_l]);
    % translate(concat(lift_c + [lift_m, 0], z_entry + 60)) marble();
}

module lift_plate() {
    hub();
    translate([2 * hub_r + 5, 0, 0]) hub();
    translate([0, 2 * hub_r + 5, 0]) coupler();
    translate([2 * hub_r + 5, 2 * hub_r + 5, 0]) bushing();
}

if (lift_part == "assembly") lift_assembly();
else if (lift_part == "mandrel") mandrel();
else if (lift_part == "hub") hub();
else if (lift_part == "coupler") coupler();
else if (lift_part == "bushing") bushing();
else if (lift_part == "motor_mount") motor_mount();
else if (lift_part == "top_arm") top_arm();
else if (lift_part == "top_arm_laser") offset(delta=kerf/2) top_arm_2d();
else if (lift_part == "channel_clip") channel_clip();
else if (lift_part == "foot") foot();
else if (lift_part == "plate") lift_plate();
