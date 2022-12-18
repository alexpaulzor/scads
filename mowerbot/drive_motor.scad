$fn=30;
PI = 3.14159;

MM_PER_INCH = 25.4;


motor_short_c_c = 56;
motor_short_offset = 0.9 * MM_PER_INCH;
motor_long_c_c = 72;
motor_long_offset = 1.75 * MM_PER_INCH;
motor_collar_or = 1 * MM_PER_INCH / 2;
motor_hole_ir = 3;
motor_post_or = 0.5 * MM_PER_INCH / 2;
motor_hole_depth = 0.8 * MM_PER_INCH;
motor_post_depth = 1.5 * MM_PER_INCH;
motor_collar_h = 1.4 * MM_PER_INCH;
motor_post_to_sprocket_h = 2.0 * MM_PER_INCH;
motor_shaft_or = 0.5 * MM_PER_INCH / 2;
motor_or = 2.4 * MM_PER_INCH / 2;
motor_depth = 4.5 * MM_PER_INCH;
motor_gearbox_w = 3 * MM_PER_INCH;
motor_gearbox_depth = 2 * MM_PER_INCH;
motor_gearbox_l = 3.4 * MM_PER_INCH;
motor_sprocket_h = 0.3 * MM_PER_INCH;
motor_sprocket_or = 1.8 * MM_PER_INCH / 2;

function get_motor_tall_rotation() = atan(motor_short_c_c/2 / (motor_short_offset + motor_long_offset));

module motor_post() {
    // difference() {
      //  cylinder(h=motor_post_depth, r=motor_post_or);
        translate([0, 0, motor_post_depth - motor_hole_depth])
            cylinder(r=motor_hole_ir, h=motor_hole_depth);
    //}
}

module drive_motor(use_stl=false) {
    if (use_stl) {
        import("drive_motor.stl");
    } else {
        translate([0, 0, -motor_post_to_sprocket_h]) {
            difference() {
                union() {
                    cylinder(r=motor_collar_or, h=motor_collar_h);
                    cylinder(r=motor_shaft_or, h=motor_post_to_sprocket_h);
            
                    translate([-motor_short_c_c/2, motor_or, -motor_or])
                    rotate([0, -90, 0])
                        cylinder(r=motor_or, h=motor_depth);
                    translate([-motor_short_c_c/2 - motor_post_or, motor_long_offset - motor_gearbox_l, -motor_gearbox_depth])
                    cube([motor_gearbox_w, motor_gearbox_l, motor_gearbox_depth]);
                    translate([0, motor_long_offset, -motor_post_depth])
                        cylinder(h=motor_post_depth, r=motor_post_or);
                }
                translate([0, motor_long_offset, -motor_post_depth])
                    motor_post();
                translate([-motor_short_c_c/2, -motor_short_offset, -motor_post_depth])
                    motor_post();
                translate([motor_short_c_c/2, -motor_short_offset, -motor_post_depth])
                    motor_post();
            }
        }
    }
}
drive_motor(false);