/*

Manual wire straightener + bender on one 2020 beam.

Wire runs +x along the beam, beside it (outboard on the +y side) at a fixed
height. From the coil end:

  entry guide -> VERTICAL straightener (side plate, 5 V-wheels, fixes bends
  in the vertical plane) -> HORIZONTAL straightener (top plate, 5 V-wheels,
  fixes bends in the horizontal plane) -> exit guide -> backup wheel ->
  BEND HEAD (mandrel on a pivot that slides to suit its radius, lever with a
  follower, angle stop disc) -> outfeed beam with a length stop.

In each straightener one row of wheels is fixed and the other row sits in
slots (coarse) on eccentric spacers (fine), so you set how hard the wire is
zig-zagged. Bends go one way; flip the part over to bend the other way.

Hardware: 2020 beam + M5 drop-in T-nuts and M5 bolts, 12 V-wheels on 625
bearings with spacers / eccentric spacers (from the 2040 laser), one M6
bolt + nut for the pivot, a short M5 bolt + sleeve as the small-radius
follower pin, an M3 bolt as the stop pin.

Plates (cut flat on the router or laser):
  side_plate, top_plate (12 mm: or two 6 mm), base_plate, stop_disc, lever
Printed: guide (x2), mandrels, pivot_tube, length_stop

  openscad -o bender.png marbles/wire_bender.scad
  openscad -o side_plate.dxf -D 'bend_part="side_plate"' marbles/wire_bender.scad
  openscad -o base_etch.svg  -D 'bend_part="base_etch"'  marbles/wire_bender.scad
  openscad -o mandrel.stl    -D 'bend_part="mandrel"' -D 'mandrel_i=4' marbles/wire_bender.scad

MEASURE YOUR V-WHEELS: vw_root_d (diameter at the bottom of the V, where
the wire sits) sets every wheel position. The values below are typical
OpenBuilds solid V-wheel numbers, not measurements.

*/

include <pegwall.scad>
wall_part = "none";

bend_part = "assembly";
mandrel_i = 0;

// --- V-wheels (measure yours) ---
vw_od = 24.39;
vw_w = 10.23;
vw_root_d = 19.5;
vw_bolt_d = 5.2;
spacer_h = 6.35;
// eccentric spacer throw, roughly; the plate slots give the coarse range
ecc_throw = 0.8;

// --- plates ---
side_th = 6;
top_th = 12;
base_th = 6;
disc_th = 6;
lever_th = 6;
m5 = 5.3;

// --- straighteners ---
n_wheels = 5;
wheel_pitch = 30;
// nominal zig-zag depth for the slotted row; slots allow +/- slot_travel
pinch = 0.6;
slot_travel = 3;

// --- layout along the beam ---
beam_l = 500;
outfeed_l = 300;
sx0 = 30;
side_l = (n_wheels - 1) * wheel_pitch + 40;
tx0 = sx0 + side_l + 20;
top_l = side_l;
x_b = tx0 + top_l + 85;

// --- wire line ---
y_w = 10 + side_th + spacer_h + vw_w / 2;
z_w = top_th + spacer_h + vw_w / 2;
// wheel center to wire center when the wire sits in the V
vw_off = vw_root_d / 2 + wire_r;

// --- bend head ---
pivot_d = 6.4;
tube_od = 10;
r_min = 4;
r_max = 36;
disc_r = 40;
stop_rings = [[30, 0], [36, 5]];
stop_pin_d = 3.2;
lever_w = 24;
lever_l = 230;
hub_r = 15;
backup_dx = 52;
base_y1 = y_w + wire_r + r_max + 30;

// Mandrel radii: small ones for tie corners, then the pegwall C-turn rails
// (rail centerline radius minus wire_r). Springback opens the bend back up,
// so start the C-turn mandrels mandrel_k smaller -- a guess; tune it.
springback_k = 0.9;
mandrels = [4, 6, 8, 12,
    (c_ri - wire_r) * springback_k,
    (c_ro - wire_r) * springback_k];
function pivot_y(r) = y_w + wire_r + r;
// follower distance from the pivot: a V-wheel above follower_switch, else
// the 5 mm pin
follower_switch = 10;
function follower_r(r) = r < follower_switch
    ? r + wire_od + 2.5
    : r + wire_od + vw_root_d / 2;

echo(wire_line_y=y_w, wire_line_z=z_w, vw_off=vw_off, x_bend=x_b);
echo(mandrel_radii=mandrels, c_turn_rail_radii=[c_ri, c_ro], springback_k=springback_k);
echo(follower_r=[for (r=mandrels) follower_r(r)]);
assert(norm([backup_dx, vw_off + wire_r + r_min]) > disc_r + 6,
    "backup wheel standoff hits the stop disc");
assert(max(mandrels) <= r_max && min(mandrels) >= r_min, "a mandrel doesn't fit the pivot slot");


// ===== 2D plates =====

module wheel_hole(p, slotted) {
    translate(p)
        if (slotted) hull() for (s=[-1, 1]) translate([0, s * slot_travel]) circle(d=vw_bolt_d, $fn=24);
        else circle(d=vw_bolt_d, $fn=24);
}

// fixed row on one side of the wire, slotted row on the other; wire at w
function fixed_wheels(w, side) = [for (i=[0:2:n_wheels-1]) [20 + i * wheel_pitch, w - side * vw_off]];
function slot_wheels(w, side) = [for (i=[1:2:n_wheels-1]) [20 + i * wheel_pitch, w + side * (vw_off - pinch)]];

// side plate, (x, z) with x from sx0; fixed row below the wire
module side_plate_2d() {
    h1 = z_w + vw_off + slot_travel + 10;
    difference() {
        translate([0, -20]) square([side_l, h1 + 20]);
        for (p=fixed_wheels(z_w, 1)) wheel_hole(p, false);
        for (p=slot_wheels(z_w, 1)) wheel_hole(p, true);
        for (x=[10 : 40 : side_l - 5]) translate([x, -10]) circle(d=m5, $fn=20);
    }
}

// top plate, (x, y) with x from tx0; fixed row toward the beam
module top_plate_2d() {
    y1 = y_w + vw_off + slot_travel + 10;
    difference() {
        translate([0, -10]) square([top_l, y1 + 10]);
        for (p=fixed_wheels(y_w, 1)) wheel_hole(p, false);
        for (p=slot_wheels(y_w, 1)) wheel_hole(p, true);
        for (x=[10 : 40 : top_l - 5]) translate([x, 0]) circle(d=m5, $fn=20);
    }
}

// base plate, (x, y) with the bend point at x = 0
module base_plate_2d() {
    difference() {
        translate([-backup_dx - 18, -10]) square([backup_dx + 18 + 70, base_y1 + 10]);
        // pivot slot: the pivot slides so every mandrel is tangent to the wire
        hull() for (r=[r_min, r_max]) translate([0, pivot_y(r)]) circle(d=pivot_d, $fn=20);
        // backup wheel, on an eccentric spacer
        translate([-backup_dx, y_w - vw_off]) circle(d=vw_bolt_d, $fn=24);
        for (x=[-backup_dx + 15, 45]) translate([x, 0]) circle(d=m5, $fn=20);
    }
}

module base_etch_2d() {
    for (i=[0:len(mandrels)-1])
        translate([0, pivot_y(mandrels[i])]) {
            translate([4, -0.15]) square([6, 0.3]);
            translate([11, -1.5]) text(str("R", round(mandrels[i] * 10) / 10), size=3);
        }
    // bend line
    translate([-0.15, y_w - 8]) square([0.3, 6]);
}

// stop disc: keyed into the pivot slot so it can't turn; pin holes every
// 10 deg on two rings (offset 5 deg), engraved with the bend angle each
// one stops the lever at
function stop_bend(ring, a) = a + 90 - asin((lever_w / 2) / ring[0]);
module stop_disc_2d(etch=false) {
    if (!etch)
        difference() {
            union() {
                circle(r=disc_r, $fn=96);
                // key: rides in the pivot slot toward the wire
                translate([-(pivot_d - 0.4) / 2, -disc_r]) square([pivot_d - 0.4, disc_r]);
            }
            circle(d=pivot_d, $fn=20);
            for (ring=stop_rings, a=[-90 + ring[1] : 10 : 260])
                if (stop_bend(ring, a) > 5 && stop_bend(ring, a) <= 185)
                    rotate([0, 0, a]) translate([ring[0], 0]) circle(d=stop_pin_d, $fn=12);
        }
    else
        for (ring=stop_rings, a=[-90 + ring[1] : 10 : 260])
            if (stop_bend(ring, a) > 5 && stop_bend(ring, a) <= 185)
                rotate([0, 0, a]) translate([ring[0] + (ring[1] == 0 ? -4 : 3.5), 0])
                    rotate([0, 0, -a]) text(str(round(stop_bend(ring, a))), size=1.8,
                        halign="center", valign="center");
}

// lever: pivot hub, slot for the follower, handle
module lever_2d() {
    difference() {
        union() {
            circle(r=hub_r, $fn=64);
            translate([-lever_w / 2, -lever_l]) square([lever_w, lever_l]);
            translate([0, -lever_l]) circle(r=lever_w / 2 + 4, $fn=48);
        }
        circle(d=tube_od + 0.3, $fn=32);
        // follower slot: covers every mandrel's follower radius
        hull() for (r=[follower_r(r_min), follower_r(r_max)])
            translate([0, -r]) circle(d=vw_bolt_d, $fn=20);
        translate([0, -lever_l]) circle(d=12, $fn=32);
    }
}


// ===== printed parts =====

// Mandrel: contact band of radius r at the wire's height, hub 1 mm smaller
// above and below so the follower wheel's flanges clear it.
mandrel_h = z_w + 4 - (base_th + disc_th + lever_th + 0.3);
module mandrel(r) {
    z_band = z_w - (base_th + disc_th + lever_th + 0.3);
    difference() {
        union() {
            cylinder(r=max(r - 1, tube_od / 2), h=mandrel_h, $fn=96);
            translate([0, 0, z_band - 1.5]) cylinder(r=r, h=3, $fn=96);
        }
        translate([0, 0, -1]) cylinder(d=pivot_d, h=mandrel_h + 2, $fn=24);
    }
}

// pivot tube: lever turns on it; stack clamps disc + tube + mandrel
module pivot_tube() {
    difference() {
        cylinder(d=tube_od, h=lever_th + 0.3, $fn=32);
        translate([0, 0, -1]) cylinder(d=pivot_d, h=lever_th + 2, $fn=24);
    }
}

// wire guide: bolts to the beam's top slot, flared hole on the wire line
module guide() {
    difference() {
        union() {
            translate([-6, -10, 0]) cube([12, y_w + 16, 6]);
            translate([-6, y_w - 7, 0]) cube([12, 14, z_w + 7]);
        }
        translate([0, 0, -1]) cylinder(d=m5, h=8, $fn=20);
        translate([0, y_w, z_w]) rotate([0, 90, 0]) {
            cylinder(d=wire_od + 0.6, h=20, center=true, $fn=16);
            translate([0, 0, -6.01]) cylinder(d1=6, d2=wire_od + 0.6, h=4, $fn=16);
        }
    }
}

// length stop: slides on the outfeed beam, V notch catches the wire end
module length_stop() {
    difference() {
        union() {
            translate([-6, -10, 0]) cube([12, y_w + 12, 6]);
            translate([-6, y_w - 8, 0]) cube([12, 16, z_w + 6]);
        }
        translate([0, 0, -1]) cylinder(d=m5, h=8, $fn=20);
        translate([-7, y_w, z_w]) rotate([45, 0, 0]) cube([14, 3, 3], center=true);
    }
}


// ===== assembly =====

module beam(l) {
    color("silver") linear_extrude(l) t2020_2d();
}
module t2020_2d() {
    difference() {
        square(20, center=true);
        for (a=[0:90:270]) rotate([0, 0, a]) translate([7, 0]) square([6.2, 6.2], center=true);
        circle(d=4.2, $fn=16);
    }
}

module vwheel() {
    color("dimgray") rotate_extrude($fn=48)
        polygon([[2.5, -vw_w / 2], [vw_od / 2, -vw_w / 2], [vw_od / 2, -1.6],
            [vw_root_d / 2, -0.3], [vw_root_d / 2, 0.3], [vw_od / 2, 1.6],
            [vw_od / 2, vw_w / 2], [2.5, vw_w / 2]]);
}

module wire_line(x0, x1) {
    color("gold") translate([x0, y_w, z_w]) rotate([0, 90, 0]) cylinder(d=wire_od, h=x1 - x0, $fn=12);
}

module bend_head(r, bend) {
    // base plate on the beam
    color("burlywood") translate([x_b, 0, 0]) linear_extrude(base_th) base_plate_2d();
    // backup wheel
    translate([x_b - backup_dx, y_w - vw_off, z_w]) vwheel();
    translate([x_b, pivot_y(r), 0]) {
        color("tan") translate([0, 0, base_th]) linear_extrude(disc_th) stop_disc_2d();
        color("gray") translate([0, 0, base_th + disc_th]) pivot_tube();
        color("orange") translate([0, 0, base_th + disc_th + lever_th + 0.3]) mandrel(r);
        // lever, swung to `bend`, with its follower
        rotate([0, 0, bend]) {
            color("peru") translate([0, 0, base_th + disc_th]) linear_extrude(lever_th) lever_2d();
            translate([0, -follower_r(r), z_w])
                if (r < follower_switch) color("gray") cylinder(d=5, h=12, center=true, $fn=16);
                else vwheel();
        }
        color("gray") translate([0, 0, base_th + disc_th]) cylinder(d=stop_pin_d, h=lever_th, $fn=12);
    }
    // bent wire: straight in, wrapped around the mandrel, straight out
    color("gold") {
        translate([x_b - 60, y_w, z_w]) rotate([0, 90, 0]) cylinder(d=wire_od, h=60, $fn=12);
        translate([x_b, pivot_y(r), z_w])
            rotate([0, 0, -90]) rotate_extrude(angle=bend, $fn=48)
            translate([r + wire_r, 0]) circle(d=wire_od, $fn=12);
        translate([x_b, pivot_y(r), z_w]) rotate([0, 0, bend - 90]) translate([r + wire_r, 0, 0])
            rotate([-90, 0, 0]) cylinder(d=wire_od, h=50, $fn=12);
    }
}

module assembly(r=mandrels[4], bend=120) {
    translate([0, 0, -10]) rotate([0, 90, 0]) beam(beam_l);
    translate([beam_l, 0, -10]) rotate([0, 90, 0]) beam(outfeed_l);
    // feet
    for (x=[60, beam_l + outfeed_l - 60])
        translate([x, 0, -30]) rotate([90, 0, 0]) translate([0, 0, -80]) beam(160);
    // vertical straightener on the side
    color("burlywood") translate([sx0, 10 + side_th, 0]) rotate([90, 0, 0]) linear_extrude(side_th) side_plate_2d();
    for (p=concat(fixed_wheels(z_w, 1), slot_wheels(z_w, 1)))
        translate([sx0 + p[0], y_w, p[1]]) rotate([90, 0, 0]) vwheel();
    // horizontal straightener on top
    color("burlywood") translate([tx0, 0, 0]) linear_extrude(top_th) top_plate_2d();
    for (p=concat(fixed_wheels(y_w, 1), slot_wheels(y_w, 1)))
        translate([tx0 + p[0], p[1], z_w]) vwheel();
    color("orange") for (x=[sx0 - 12, tx0 + top_l + 12]) translate([x, 0, 0]) guide();
    color("orange") translate([beam_l + 120, 0, 0]) length_stop();
    wire_line(-80, x_b);
    bend_head(r, bend);
}

if (bend_part == "assembly") assembly();
else if (bend_part == "side_plate") offset(delta=kerf / 2) side_plate_2d();
else if (bend_part == "top_plate") offset(delta=kerf / 2) top_plate_2d();
else if (bend_part == "base_plate") offset(delta=kerf / 2) base_plate_2d();
else if (bend_part == "base_etch") base_etch_2d();
else if (bend_part == "stop_disc") offset(delta=kerf / 2) stop_disc_2d();
else if (bend_part == "stop_disc_etch") stop_disc_2d(etch=true);
else if (bend_part == "lever") offset(delta=kerf / 2) lever_2d();
else if (bend_part == "mandrel") mandrel(mandrels[mandrel_i]);
else if (bend_part == "pivot_tube") pivot_tube();
else if (bend_part == "guide") guide();
else if (bend_part == "length_stop") length_stop();
