
IN_MM = 25.4;
$fn = 32;

wall_th = 2;

beam_w = 15;
beam_notch_d = 5;
beam_notch_w = 3;
beam_hole_or = 3/2;

module beam(length=50) {
    translate([0, 0, -length/2])
    linear_extrude(length) {
        difference() {
            square([beam_w, beam_w], center=true);
            for (i=[0:3]) {
                rotate([0, 0, 90 * i]) {
                    translate([beam_w/2 - beam_notch_d / 2, 0, 0]) {
                        square([beam_notch_d, beam_notch_w], center=true);
                    }
                }
            }
            //circle(r=beam_hole_or);
        }
    }
}

module mount_block(ir) {
    block_outside = 2*ir + 2 * wall_th;
    difference() {
        union() {
            translate([0, 0, wall_th/2])
                cube([3 * beam_w, beam_w, wall_th], center=true);
            translate([0, 0, block_outside/4])
                cube([block_outside, beam_w, block_outside/2], center=true);
            translate([0, 0, ir + wall_th])
                rotate([90, 0, 0]) 
                cylinder(r=block_outside/2, h=beam_w, center=true);
            * translate([ir + wall_th, 0, sqrt(2)/4*block_brace_w + wall_th/2])
                rotate([0, 45, 0])
                cube([block_brace_w, beam_w, block_brace_w/2], center=true);
            * translate([-ir - wall_th, 0, sqrt(2)/4*block_brace_w + wall_th/2])
                rotate([0, -45, 0])
                cube([block_brace_w, beam_w, block_brace_w/2], center=true);
            translate([-ir - wall_th + 1, -beam_w/2 + block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, -45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
            * translate([-ir - wall_th + 1, beam_w/2 - block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, -45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
            translate([ir + wall_th - 1, -beam_w/2 + block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, 45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
            * translate([ir + wall_th - 1, beam_w/2 - block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, 45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
        }
        translate([0, 0, ir + wall_th])
            rotate([90, 0, 0]) 
            cylinder(r=ir, h=beam_w+1, center=true, $fn=64);
        translate([beam_w, 0, 0])
            cylinder(r=beam_hole_or, h=wall_th*2);
        translate([-beam_w, 0, 0])
            cylinder(r=beam_hole_or, h=wall_th*2);
        
        translate([0, 0, -beam_w/2])
            cube([3*beam_w + 1, beam_w + 1, beam_w], center=true);
    }
}

bearing_h = 7;
bearing_ir = 4;
bearing_or = 11;
block_brace_w = 5;
module pillow_block() {
   mount_block(bearing_or);
}

module corner_mount() {
    difference() {
        cube(2*beam_w, center=true);
        
        translate([0, 0, 0])
            beam(beam_w*2);
        * translate([0, 0, -beam_w])
            beam(beam_w);
        translate([0, 0, 0])
            rotate([90, 0, 0])
            beam(beam_w*2);
        * translate([0, -beam_w, 0])
            rotate([90, 0, 0])
            beam(beam_w);
        translate([0, 0, 0])
            rotate([0, 90, 0])
            beam(beam_w*2);
        * translate([-beam_w, 0, 0])
            rotate([0, 90, 0])
            beam(beam_w);
    }
}

corner_mount();