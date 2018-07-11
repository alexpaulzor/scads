$fn = 60;
idler_or = 10.0 / 2;
idler_ir = 3.0 / 2;
idler_wall_or = 13.0 / 2;
idler_depth = 9;
idler_wall = 1;

min_height = 17; // from 20T drive pulley
tensioner_wall = 4;
tensioner_c_c = 30;
tensioner_width = idler_wall_or * 2;
min_span = idler_wall_or;
nominal_span = 30;
min_angle = 90 - atan2(tensioner_c_c, tensioner_width);
nominal_angle = 90 - atan2(tensioner_c_c, nominal_span);
echo("Min, nominal span angle", min_angle, nominal_angle);

// desired / measured actual
hole_tolerance = 10.0 / 9.60;

axle_hole_id = 5.3 * hole_tolerance;
idler_hole_id = 3.2 * hole_tolerance;

module idler() {
    difference() {
      union() {
          cylinder(idler_wall, idler_wall_or, idler_wall_or);
          cylinder(idler_depth, idler_or, idler_or);
          translate([0, 0, idler_depth - idler_wall])
            cylinder(idler_wall, idler_wall_or, idler_wall_or);
      }
    cylinder(idler_depth, idler_ir, idler_ir);
  }
}

module tensioner_arm_half() {
    difference() {
        union() {
            translate([0, -tensioner_width / 2, 0])
                cube([tensioner_c_c, tensioner_width, tensioner_wall]);
            cylinder(tensioner_wall, tensioner_width / 2, tensioner_width / 2);
            translate([tensioner_c_c, 0, 0])
                cylinder(tensioner_wall, tensioner_width / 2, tensioner_width / 2);
        }
        cylinder(tensioner_wall, axle_hole_id / 2, axle_hole_id / 2);
        translate([tensioner_c_c, 0, 0])
            cylinder(tensioner_wall, idler_hole_id / 2, idler_hole_id / 2);
        translate([0, 0, tensioner_wall / 2]) {
            cylinder(tensioner_wall / 2, tensioner_width / 2, tensioner_width / 2);
            rotate([0, 0, min_angle])
                translate([0, -tensioner_width / 2, 0])
                    cube([tensioner_c_c, tensioner_width, tensioner_wall / 2]);
        }
    }
}

partgap = tensioner_width + tensioner_wall;

tensioner_arm_half();
translate([0, partgap, 0]) tensioner_arm_half();
translate([0, partgap * 2, 0]) tensioner_arm_half();
translate([0, partgap * 3, 0]) tensioner_arm_half();

module tensioner_arm() {
    tensioner_arm_half();
    translate([tensioner_c_c, 0, tensioner_wall])
        idler();
    translate([0, 0, tensioner_wall + min_height]) 
        tensioner_arm_half();
}

*tensioner_arm();
* translate([0, 0, 2 * tensioner_wall + min_height])
    rotate([180, 0, nominal_angle]) tensioner_arm();
//translate([-center_sep / 2, 0, 0]) idler();
//translate([center_sep / 2, 0, 0]) idler();