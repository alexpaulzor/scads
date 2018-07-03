$fn = 60;
large_fn = 90;
tolerance = 1.05;
height = 12;
bearing_height = 8 * tolerance;
axle_distance = 50;
stepper_size = 56;
stepper_center = 40;
bearing_OD = 29 * tolerance;
bearing_ID = 17;
hole_ID = 5.1 * tolerance;
hole_offset = 4;
stepper_tab_depth = 5;

length = stepper_size / 2 + bearing_OD / 2 + 
            axle_distance + hole_offset;

module hexagon(size, height) {
  boxWidth = size/1.75;
  for (r = [-60, 0, 60]) rotate([0,0,r]) cube([boxWidth, size, height], true);
}


stepper_length = 100 - stepper_tab_depth;

nut_depth = 5 * tolerance;
nut_width = 8 * tolerance;
connector_width = 9;
wall_thickness = (connector_width - nut_width) / 2;
screw_length = 35;
nut_hole_depth = screw_length - nut_width - height - stepper_tab_depth;
connector_plate_depth = 3;
connector_sep = stepper_size - 2 * hole_offset - connector_width;
wire_height = 5;
wire_width = 15;

wiggle = 1;
motor_surround = 4 + wiggle;

gap = 0.5;   


module bearing_plate() {
    difference() {
        translate([-motor_surround, -motor_surround, 0])
            cube([stepper_size + 2 * motor_surround, 
            length + 2 * motor_surround, height / 2]);
        translate([stepper_size/2, stepper_size/2+axle_distance,
                (height - bearing_height) / 2]) 
            cylinder(height, bearing_OD/2, bearing_OD/2);
        
        translate([stepper_size/2, stepper_size/2+axle_distance]) 
            cylinder(height, bearing_ID/2, bearing_ID/2);
    }
}

module half_holy_plate() {
    difference() {
        bearing_plate();
    
        translate([stepper_size-hole_offset, stepper_size - hole_offset]) 
            cylinder(height, hole_ID / 2, hole_ID / 2);
        translate([hole_offset, stepper_size - hole_offset]) 
            cylinder(height, hole_ID / 2, hole_ID / 2);
        translate([hole_offset, 
                    length - hole_offset]) 
            cylinder(height, hole_ID / 2, hole_ID / 2);
        translate([stepper_size - hole_offset, 
                    length - hole_offset]) 
            cylinder(height, hole_ID / 2, hole_ID / 2);
    }
}

module holy_plate() {
    difference() {
        half_holy_plate();
        translate([hole_offset, hole_offset]) 
            cylinder(height, hole_ID / 2, hole_ID / 2);
        translate([stepper_size - hole_offset, hole_offset]) 
            cylinder(height, hole_ID / 2, hole_ID / 2);
    }
}


module mount_plate() {

    difference() {
        holy_plate();
        translate([stepper_size / 2, stepper_size / 2]) 
            cylinder(height, stepper_center / 2, stepper_center / 2);
    }
}

module backing_plate() {
    difference() {
        holy_plate();
        difference() {
            translate([-wiggle, -wiggle]) cube([stepper_size + 2 * wiggle, stepper_size + 2 * wiggle, height / 2]);
            translate([hole_offset, hole_offset])
                cylinder(height, connector_width / 2, connector_width / 2);
            translate([-wiggle, -wiggle]) cube([connector_width / 2 + hole_offset + wiggle, connector_width / 2 + wiggle, height / 2]);
            translate([-wiggle, -wiggle]) cube([connector_width / 2 + wiggle, connector_width / 2 + hole_offset + wiggle, height / 2]);
            
            translate([stepper_size - hole_offset, hole_offset])
                cylinder(height, connector_width / 2, connector_width / 2);
            translate([stepper_size - (connector_width / 2 + hole_offset), -wiggle])
                cube([connector_width / 2 + hole_offset + wiggle, connector_width / 2 + wiggle, height / 2]);
            translate([stepper_size - connector_width / 2, -wiggle])
                cube([connector_width / 2 + wiggle, connector_width / 2 + hole_offset + wiggle, height / 2]);
            
            translate([hole_offset, stepper_size - hole_offset])
                cylinder(height, connector_width / 2, connector_width / 2);
            translate([-wiggle, stepper_size - connector_width / 2])
                cube([connector_width / 2 + hole_offset + wiggle, connector_width / 2 + wiggle, height / 2]);
            translate([-wiggle, stepper_size - connector_width / 2 - hole_offset])
                cube([connector_width / 2 + wiggle, connector_width / 2 + hole_offset + wiggle, height / 2]);
            
            translate([stepper_size - hole_offset, stepper_size - hole_offset])
                cylinder(height, connector_width / 2, connector_width / 2);
            translate([stepper_size - hole_offset - connector_width / 2, stepper_size - connector_width / 2])
                cube([connector_width / 2 + hole_offset + wiggle, connector_width / 2 + wiggle, height / 2]);
            translate([stepper_size - hole_offset, stepper_size - connector_width / 2 - hole_offset])
                cube([connector_width / 2 + wiggle, connector_width / 2 + hole_offset + wiggle, height / 2]);  
        }   
           
       translate([(stepper_size - wire_width) / 2, stepper_size])
            cube([wire_width, wire_height, height / 2]);
    }
}

//mount_plate(); 
v_gap = height / 2 + gap;
backing_plate();
/*translate([0, 0, v_gap]) 
    backing_plate();
translate([0, 0, 2 * v_gap]) backing_plate(); 
translate([0, 0, 3 * v_gap]) backing_plate();
/*
translate([stepper_size + gap, length + gap]) mount_plate();
translate([0, length + gap]) mount_plate(); // */
