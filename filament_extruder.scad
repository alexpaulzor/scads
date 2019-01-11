use <spur_generator.scad>;
use <parametric_involute_gear_v5.0.scad>;

$fn=30;
PI = 3.14159;

MM_PER_INCH = 25.4;

bearing_or = 1.125 * MM_PER_INCH / 2;
bearing_ir = 0.5 * MM_PER_INCH / 2;
bearing_h = 5/16 * MM_PER_INCH;
flange_or = 3 * MM_PER_INCH / 2;
flange_hole_offset = 1.5 * MM_PER_INCH / 2;
hole_ir = 0.25 * MM_PER_INCH / 2;
num_holes = 4;
hole_angle = 360 / num_holes;

hop_flange_or = 5.25 * MM_PER_INCH / 2;
hop_flange_hole_diag_offset = 2 * MM_PER_INCH;
hop_flange_ir = 1 * MM_PER_INCH;
hop_hole_ir = 0.32 * MM_PER_INCH / 2;
hop_flange_h = 0.3 * MM_PER_INCH;
hop_h = hop_flange_or / 3 * 2;


drive_flange_or = 4 * MM_PER_INCH / 2;
drive_flange_hole_offset = 2 * MM_PER_INCH / 2;
drive_flange_ir = 1 * MM_PER_INCH / 2;
drive_hole_ir = 0.3 * MM_PER_INCH / 2;
drive_flange_h = 0.3 * MM_PER_INCH;
drive_flange_collar_or = 42 / 2;
drive_flange_collar_h = 10;

drive_flange_rotation = -2;
z_error_margin = 2;

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

sprocket_num_holes = 5;
sprocket_hole_ir = 10 / 2;
sprocket_hole_offset = 55;
sprocket_ir = 13 / 2;
sprocket_or = 106;
sprocket_num_teeth = 9 * 5;
sprocket_clearance = 20;

// GEARING

//gear_ratio = 3;
auger_gear_teeth = sprocket_num_teeth;
motor_gear_teeth = 11; //sprocket_num_teeth / gear_ratio;
motor_gear_ir = 6 / 2;
motor_gear_or = 24;

axle_distance = sprocket_or + motor_gear_or;
auger_or = 7/16 * MM_PER_INCH / 2;

gear_height = 5;
motor_pitch = fit_spur_gears(motor_gear_teeth, auger_gear_teeth, axle_distance);

echo("Axle distance:", axle_distance);

module motor_post() {
    difference() {
        cylinder(h=motor_post_depth, r=motor_post_or);
        translate([0, 0, motor_post_depth - motor_hole_depth])
            cylinder(r=motor_hole_ir, h=motor_hole_depth);
    }
}

module motor() {
    cylinder(r=motor_sprocket_or, h=motor_sprocket_h);
    translate([0, 0, -motor_post_to_sprocket_h]) {
        cylinder(r=motor_collar_or, h=motor_collar_h);
        cylinder(r=motor_shaft_or, h=motor_post_to_sprocket_h);
        translate([0, motor_long_offset, -motor_post_depth])
            motor_post();
        translate([-motor_short_c_c/2, -motor_short_offset, -motor_post_depth])
            motor_post();
        translate([motor_short_c_c/2, -motor_short_offset, -motor_post_depth])
            motor_post();
        translate([-motor_short_c_c/2, motor_or, -motor_or])
        rotate([0, -90, 0])
            cylinder(r=motor_or, h=motor_depth);
        translate([-motor_short_c_c/2 - motor_post_or, motor_long_offset - motor_gearbox_l, -motor_gearbox_depth])
        cube([motor_gearbox_w, motor_gearbox_l, motor_gearbox_depth]);
    
    }
}

module flange_spacer(total_h) {
    difference() {
        cylinder(h=total_h, r=flange_or);
        cylinder(h=total_h, r=bearing_or);
        for (i=[0:num_holes-1]) {
            rotate([0, 0, i * hole_angle])
                translate([flange_hole_offset, flange_hole_offset, 0])
                    cylinder(h=total_h, r=hole_ir);
        }
    }
}

module hopper() {
    difference() {
        cylinder(h=hop_flange_h, r=hop_flange_or);
        cylinder(h=hop_flange_h, r=hop_flange_ir);
        for (i=[0:num_holes-1]) {
            rotate([0, 0, i * hole_angle])
                translate([hop_flange_hole_diag_offset, 0, 0])
                    cylinder(h=hop_flange_h, r=hop_hole_ir);
        }
    }
    translate([0, 0, hop_flange_h])
        difference() {
            cylinder(h=hop_h, r1=hop_flange_ir + hop_flange_h, r2=hop_flange_or);
            cylinder(h=hop_h, r1=hop_flange_ir, r2=hop_flange_or - hop_flange_h);
        }
}

module drive_flange() {
    difference() {
        union() {
            cylinder(h=drive_flange_h, r=drive_flange_or);
            translate([0, 0, drive_flange_h])
                cylinder(h=drive_flange_collar_h, r=drive_flange_collar_or);
        }
        cylinder(h=drive_flange_h, r=drive_flange_ir);
        for (i=[0:num_holes-1]) {
            rotate([0, 0, i * hole_angle])
                translate([drive_flange_hole_offset, drive_flange_hole_offset, 0])
                    cylinder(h=drive_flange_h, r=drive_hole_ir);
        }
    }
}

module sprocket() {
    relief_or = sprocket_hole_offset / 4;
    difference() {
        // Pitch diameter: Diameter of pitch circle.
        //	pitch_diameter  =  number_of_teeth * circular_pitch / 180;
        // cp = pd / number_of_teeth * 180
        gear (circular_pitch=2 * sprocket_or / sprocket_num_teeth * 180,
                gear_thickness = gear_height,
                rim_thickness = gear_height,
                hub_thickness = gear_height,
                number_of_teeth = sprocket_num_teeth,
                hub_diameter=8 * sprocket_ir,
                bore_diameter=2 * sprocket_ir,
                rim_width = 2);
        hole_angle = 360 / sprocket_num_holes;
        for (i=[0:sprocket_num_holes-1]) {
            rotate([0, 0, i * hole_angle])
                translate([sprocket_hole_offset, 0, 0])
                    cylinder(h=gear_height, r=sprocket_hole_ir);
            rotate([0, 0, (0.5 + i) * hole_angle])
                translate([2 * sprocket_hole_offset / 3, 0, 0])
                    cylinder(h=gear_height, r=relief_or);
            rotate([0, 0, (0.75 + i) * hole_angle])
                translate([4 * sprocket_hole_offset / 3, 0, 0])
                    cylinder(h=gear_height, r=relief_or);
            rotate([0, 0, (0.25 + i) * hole_angle])
                translate([4 * sprocket_hole_offset / 3, 0, 0])
                    cylinder(h=gear_height, r=relief_or);
        }
    }
}

module motor_gear() {
    gear (circular_pitch=motor_pitch,
            gear_thickness = gear_height,
            rim_thickness = gear_height,
            hub_thickness = gear_height,
            number_of_teeth = motor_gear_teeth,
            hub_diameter=4 * auger_or,
            bore_diameter=2 * motor_gear_ir,
            rim_width = 2);
}

module drive_gearing(sproc_angle=0, motor_angle=0) {
    rotate([0, 0, sproc_angle])
        sprocket();
    translate([axle_distance, 0, 0])
        rotate([0, 0, motor_angle])
        motor_gear();
}

module mount_plate() {
    stock_w = drive_flange_or * 2 - 15;
    stock_h = 0.125 * MM_PER_INCH;
    stock_l = axle_distance + drive_flange_or + motor_short_c_c - 35;
    post_length = 10; //motor_post_to_sprocket_h - drive_flange_h -z_error_margin;
    
    difference() {
        union() {
            * rotate([0, 0, drive_flange_rotation])
                translate([-drive_flange_or+15, -drive_flange_or, -drive_flange_h - stock_h])
                    cube([stock_l, stock_w, stock_h]);
            translate([axle_distance + motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                cylinder(h=post_length, r=drive_hole_ir*2);
            translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                cylinder(h=post_length, r=drive_hole_ir*2);
            translate([axle_distance, -motor_long_offset, -drive_flange_h - stock_h - post_length])
                cylinder(h=post_length, r=drive_hole_ir*2);
            translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                cube([motor_short_c_c, stock_h, post_length]);
            translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                rotate([0, 0, atan2(-motor_long_c_c, motor_short_c_c/2)])
                    cube([motor_long_c_c, stock_h, post_length]);
            translate([axle_distance + motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                rotate([0, 0, atan2(-motor_long_c_c, -motor_short_c_c/2)])
                    cube([motor_long_c_c, stock_h, post_length]);
            
            rotate([0, 0, drive_flange_rotation])
                translate([-drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([0, -stock_h/2, 0])
                        cube([axle_distance, stock_h, post_length]);
                }
            rotate([0, 0, drive_flange_rotation])
                translate([drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([0, -stock_h/2, 0])
                        rotate([0, 0, -31])
                        cube([axle_distance, stock_h, post_length]);
                }
            rotate([0, 0, drive_flange_rotation])
                translate([drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([-stock_h/2, 0, 0])
                        cube([stock_h, 2*drive_flange_hole_offset, post_length]);
                    translate([0, -stock_h/2, 0])
                        rotate([0, 0, 33])
                        cube([axle_distance-40, stock_h, post_length]);
                }
            rotate([0, 0, drive_flange_rotation])
                translate([-drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([0, -stock_h/2, 0])
                        rotate([0, 0, -5])
                        cube([axle_distance + 34, stock_h, post_length]);
                    translate([-stock_h/2, 0, 0])
                        cube([stock_h, 2*drive_flange_hole_offset, post_length]);
                }
                    
            
        }
        rotate([0, 0, drive_flange_rotation])
            translate([-drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - 2*stock_h-post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        rotate([0, 0, drive_flange_rotation])
            translate([drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - 2*stock_h-post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        rotate([0, 0, drive_flange_rotation])
            translate([drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - 2*stock_h - post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        rotate([0, 0, drive_flange_rotation])
            translate([-drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - 2*stock_h - post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        translate([axle_distance, -motor_long_offset, -motor_post_to_sprocket_h - stock_h])
            cylinder(h=motor_post_to_sprocket_h, r=drive_hole_ir);
        translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -motor_post_to_sprocket_h - stock_h])
            cylinder(h=motor_post_to_sprocket_h, r=drive_hole_ir);
        translate([axle_distance + motor_short_c_c / 2, motor_short_offset, -motor_post_to_sprocket_h - stock_h])
            cylinder(h=motor_post_to_sprocket_h, r=drive_hole_ir);

        translate([0, 0, -drive_flange_h - stock_h])
            cylinder(h=drive_flange_collar_h, r=drive_flange_collar_or);
        # translate([axle_distance, 0, -motor_post_to_sprocket_h])
            cylinder(h=motor_post_to_sprocket_h, r=motor_collar_or);
    }
}

module mount_plate_backing() {
    stock_w = drive_flange_or * 2 - 15;
    stock_h = 0.125 * MM_PER_INCH;
    stock_l = axle_distance + drive_flange_or + motor_short_c_c - 35;
    post_length = 5; //motor_post_to_sprocket_h - drive_flange_h -z_error_margin;
    bearing_or = 23 / 2;
    bearing_ir = 8 / 2;
    bearing_h = 7;
    bearing_z = (post_length * 2 - bearing_h) / 2;
    
    difference() {
        union() {
            rotate([0, 0, drive_flange_rotation])
                translate([-drive_flange_or/2, -drive_flange_or/2 - drive_hole_ir, -drive_flange_h - post_length - stock_h])
                    cube([drive_flange_or, drive_flange_or + drive_hole_ir, post_length]);
            translate([axle_distance + motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                cylinder(h=post_length, r=drive_hole_ir*2);
            translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                cylinder(h=post_length, r=drive_hole_ir*2);
            translate([axle_distance, -motor_long_offset, -drive_flange_h - stock_h - post_length])
                cylinder(h=post_length, r=drive_hole_ir*2);
            translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                cube([motor_short_c_c, stock_h, post_length]);
            translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                rotate([0, 0, atan2(-motor_long_c_c, motor_short_c_c/2)])
                    cube([motor_long_c_c, stock_h, post_length]);
            translate([axle_distance + motor_short_c_c / 2, motor_short_offset, -drive_flange_h - stock_h - post_length])
                rotate([0, 0, atan2(-motor_long_c_c, -motor_short_c_c/2)])
                    cube([motor_long_c_c, stock_h, post_length]);
            
            rotate([0, 0, drive_flange_rotation])
                translate([-drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([0, -stock_h/2, 0])
                        cube([axle_distance, stock_h, post_length]);
                }
            rotate([0, 0, drive_flange_rotation])
                translate([drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([0, -stock_h/2, 0])
                        rotate([0, 0, -31])
                        cube([axle_distance, stock_h, post_length]);
                }
            rotate([0, 0, drive_flange_rotation])
                translate([drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([-stock_h/2, 0, 0])
                        cube([stock_h, 2*drive_flange_hole_offset, post_length]);
                    translate([0, -stock_h/2, 0])
                        rotate([0, 0, 33])
                        cube([axle_distance-40, stock_h, post_length]);
                }
            rotate([0, 0, drive_flange_rotation])
                translate([-drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - stock_h - post_length]) {
                    cylinder(h=post_length, r=2*drive_hole_ir);
                    translate([0, -stock_h/2, 0])
                        rotate([0, 0, -5])
                        cube([axle_distance + 34, stock_h, post_length]);
                    translate([-stock_h/2, 0, 0])
                        cube([stock_h, 2*drive_flange_hole_offset, post_length]);
                }
                    
            
        }
        rotate([0, 0, drive_flange_rotation])
            translate([-drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - 2*stock_h-post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        rotate([0, 0, drive_flange_rotation])
            translate([drive_flange_hole_offset, drive_flange_hole_offset, -drive_flange_h - 2*stock_h-post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        rotate([0, 0, drive_flange_rotation])
            translate([drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - 2*stock_h - post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        rotate([0, 0, drive_flange_rotation])
            translate([-drive_flange_hole_offset, -drive_flange_hole_offset, -drive_flange_h - 2*stock_h - post_length])
                cylinder(h=post_length+drive_flange_h, r=drive_hole_ir);
        translate([axle_distance, -motor_long_offset, -motor_post_to_sprocket_h - stock_h])
            cylinder(h=motor_post_to_sprocket_h, r=drive_hole_ir);
        translate([axle_distance - motor_short_c_c / 2, motor_short_offset, -motor_post_to_sprocket_h - stock_h])
            cylinder(h=motor_post_to_sprocket_h, r=drive_hole_ir);
        translate([axle_distance + motor_short_c_c / 2, motor_short_offset, -motor_post_to_sprocket_h - stock_h])
            cylinder(h=motor_post_to_sprocket_h, r=drive_hole_ir);

        translate([0, 0, -drive_flange_h - stock_h - post_length + bearing_z])
            cylinder(h=bearing_h, r=bearing_or);
         
        # translate([0, 0, -drive_flange_h - stock_h - post_length])
            cylinder(h=bearing_h+bearing_z, r=bearing_ir);
        # translate([axle_distance, 0, -motor_post_to_sprocket_h])
            cylinder(h=motor_post_to_sprocket_h, r=motor_collar_or);
    }
}

module design() {
    % rotate([0, 0, drive_flange_rotation])
        mirror([0, 0, 1])
            drive_flange();
    % cylinder(h=sprocket_clearance, r=auger_or);
    % translate([0, 0, sprocket_clearance]) 
        sprocket();
    translate([0, 0, sprocket_clearance - gear_height])
        drive_gearing();
    translate([0, 0, sprocket_clearance - 2*gear_height])
        drive_gearing(180/sprocket_num_teeth, 180/motor_gear_teeth);
    % translate([axle_distance, 0, z_error_margin])
        rotate([0, 0, -180])
        motor();
    mount_plate();
}

module plate() {
    * sprocket();
    * translate([axle_distance + 10, 0, 0])
        motor_gear();
    
    mount_plate_backing();
    
}

//!design();

plate();

//hopper();


//flange_spacer(bearing_h);