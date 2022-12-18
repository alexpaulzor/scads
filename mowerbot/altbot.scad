$fn=24;
motor_shaft_or = 3;
motor_notched_w = 4.37;
motor_notch_h = 10;
motor_shaft_h = 14;
motor_shaft_offs = 15;
motor_w = 32;
motor_l = 80;
motor_h = 27;
motor_hole_sep = [18, 32];
motor_hole_ir = 3/2;
motor_hole_offs = 7;


module motor() {
    translate([-motor_shaft_offs, -motor_w/2, -motor_h]) {
        difference() {
            cube([motor_l, motor_w, motor_h]);
            translate([motor_hole_offs, motor_w / 2 + motor_hole_sep[0]/2, 2])
                cylinder(r=motor_hole_ir, h=motor_h);
            translate([motor_hole_offs, motor_w / 2 - motor_hole_sep[0]/2, 2])
                cylinder(r=motor_hole_ir, h=motor_h);
            translate([motor_hole_offs + motor_hole_sep[1], motor_w / 2 + motor_hole_sep[0]/2, 2])
                cylinder(r=motor_hole_ir, h=motor_h);
            translate([motor_hole_offs + motor_hole_sep[1], motor_w / 2 - motor_hole_sep[0]/2, 2])
                cylinder(r=motor_hole_ir, h=motor_h);
        }
    }
        
    difference() {
        cylinder(r=motor_shaft_or, h=motor_shaft_h);
        translate([2*motor_shaft_or - motor_notched_w, -motor_shaft_or, motor_shaft_h - motor_notch_h])
            cube([2*motor_shaft_or, 2*motor_shaft_or, motor_notch_h]);
    }
}

motor();