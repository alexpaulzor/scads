$fn = 60;
nominal_sep = 25;
min_sep = 25;
idler_or = 10.0 / 2;
idler_ir = 3.0 / 2;
idler_wall_or = 13.0 / 2;
idler_depth = 9;
idler_wall = 1;
tensioner_wall = 3;

center_block = min_sep - idler_or * 2;

center_sep = nominal_sep + 2 * idler_or;
tensioner_len = center_sep + 2 * idler_or;
tensioner_slot_len = center_sep + 2 * idler_ir;

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

module holder_side() {
    difference() {
        translate([-tensioner_len / 2, -idler_or, 0])
            cube([tensioner_len, 2 * idler_or, tensioner_wall]);
        translate([-tensioner_slot_len / 2 + idler_ir, 0, 0])
            cylinder(tensioner_wall, idler_ir, idler_ir);
        translate([tensioner_slot_len / 2 - idler_ir, 0, 0])
            cylinder(tensioner_wall, idler_ir, idler_ir);
            //cube([tensioner_slot_len, 2 * idler_ir, tensioner_wall]);
        
    }
}

module holder() {
    translate([0, 0, -tensioner_wall]) holder_side();
    translate([0, 0, idler_depth]) holder_side();
    translate([-center_block / 2, -idler_or, -tensioner_wall])
        cube([center_block, 2 * idler_or, idler_depth + 2 * tensioner_wall]);
}

//translate([-center_sep / 2, 0, 0]) idler();
//translate([center_sep / 2, 0, 0]) idler();
holder();