$fn = 60;
height = 12;

// desired / measured actual
hole_tolerance = 10.0 / 9.60;

stepper_size = 56;
stepper_length = 100;
stepper_center = 40 * hole_tolerance;

hole_ID = 5.1 * hole_tolerance;
hole_offset = 4;
stepper_tab_depth = 5;

// GEARING
// values pulled from https://www.bbman.com/belt-length-calculator/
// 40T, 25.5mm dia
motor_shaft_od = 10;
motor_pulley_teeth = 40;
motor_carveout_r = 7;

motor_pulley_od = 25.5;
motor_shaft_length = 25;

axle_large_pulley_teeth = 74;
axle_large_pulley_od = 47.1;
axle_distance = 41.6;

axle_od = 5;

axle_small_pulley_teeth = 20;
axle_small_pulley_od = 12.7;

final_axle_distance = 58.6;

final_pulley_teeth = 60;
final_pulley_od = 38.2;

final_axle_od = 12.7;

axle_bearing_id = 10 * hole_tolerance;
axle_bearing_od = 22 * hole_tolerance;
axle_bearing_height = 7;

final_bearing_od = 29 * hole_tolerance;
final_bearing_id = 17 * hole_tolerance;
final_bearing_height = 8;

bushing_id = 5.3 * hole_tolerance;
bushing_od = 8.0 / hole_tolerance;
bushing_flange_h = 3;
bushing_flange_od = 15;

plate_gap = 55; // Inside pulley area, between bearing plates
end_plate_height = height / 2;
pulley_height = 19;

spacer_width = 8;

drive_wheel_od = 8 * 25.4; // TODO: measure
drive_wheel_width = 2 * 25.4; // TODO: measure

// mower
mower_deck_height = 120;
mower_wheel_od = 140;
mower_deck_width = 280;
mower_wheel_outside_w = 370;
mower_axle_c_c = 400;
mower_rear_deck_l = 200;
mower_motor_width = 100;
mower_motor_l = 150;
mower_motor_h = 200;

module mower() {
    wheel_w = (mower_wheel_outside_w - mower_deck_width) / 2;
    wheel_or = mower_wheel_od / 2;
    
    module mower_wheel() {
        rotate([0, 90, 0])
            cylinder(wheel_w, wheel_or, wheel_or);
    }
    translate([-mower_wheel_outside_w / 2, wheel_or, wheel_or])
        mower_wheel();
    translate([mower_wheel_outside_w / 2 - wheel_w, wheel_or, wheel_or])
        mower_wheel();
    translate([-mower_wheel_outside_w / 2, wheel_or + mower_axle_c_c, wheel_or])
        mower_wheel();
    translate([mower_wheel_outside_w / 2 - wheel_w, wheel_or + mower_axle_c_c, wheel_or])
        mower_wheel();
    translate([-mower_deck_width / 2, 0, 0])
        cube([mower_deck_width, mower_axle_c_c + mower_wheel_od, mower_deck_height]);
    translate([-mower_motor_width / 2, mower_rear_deck_l, mower_deck_height])
        cube([mower_motor_width, mower_motor_l, mower_motor_h]);
}

part_sep = 5;

length = stepper_size / 2 + 
            axle_distance + hole_offset 
            + final_axle_distance + final_bearing_od / 2 ;



module pulley(od, id) {
    difference() {
        cylinder(pulley_height, od/2, od/2);
        cylinder(pulley_height, id/2, id/2);
    }
}

module motor_pulley() {
    pulley(motor_pulley_od, motor_shaft_od);
}

module axle_small_pulley() {
    // 20t, 12.7mm dia
    pulley(axle_small_pulley_od, axle_od);
}

module axle_large_pulley() {
//    pulley(axle_large_pulley_od, axle_od);
    //*translate([0, -axle_large_pulley_od / 2 - part_sep, 20])
    translate([0, 0, 21])  
    mirror([0, 0, 1])
        import("gt2_74t_5mm_bore.stl");
}

module final_pulley() {
    // 60t, 38.2mm dia
    pulley(final_pulley_od, final_axle_od);
}

module bushing() {
    ir = bushing_id * hole_tolerance / 2;
    or = bushing_od * hole_tolerance / 2;
    flange_r = bushing_flange_od / 2;
    flange_h = bushing_flange_h;
    h = height / 2 + flange_h;
    difference() {
        union() {
            cylinder(h, or, or);
            cylinder(flange_h, flange_r, flange_r);
        }
        cylinder(h, ir, ir);
    }
    
}

module hexagon(size, height) {
  boxWidth = size/1.75;
  for (r = [-60, 0, 60]) rotate([0,0,r]) cube([boxWidth, size, height], true);
}  

module bearing_plate() {
    difference() {
        cube([stepper_size, length, height / 2]);
        translate([stepper_size/2, stepper_size/2+axle_distance,
                (height - axle_bearing_height) / 2]) 
            cylinder(height, axle_bearing_od/2, axle_bearing_od/2);
        
        translate([stepper_size/2, stepper_size/2+axle_distance]) 
            cylinder(height, axle_bearing_id/2, axle_bearing_id/2);
        
        translate([stepper_size/2, stepper_size/2+axle_distance + final_axle_distance,
                (height - final_bearing_height) / 2]) 
            cylinder(height, final_bearing_od/2, final_bearing_od/2);
        
        translate([stepper_size/2, stepper_size/2+axle_distance + final_axle_distance]) 
            cylinder(height, final_bearing_id/2, final_bearing_id/2);
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

module half_plate() {
    mount_plate();
    * translate([stepper_size/2, stepper_size/2, 0]) 
        bushing();
}

module full_plate() {
     half_plate();
     translate([0, 0, height]) mirror([0, 0, 1]) half_plate();
       
}

module placeholder_pulleys() {
    # translate([stepper_size/2, stepper_size/2+axle_distance, height + plate_gap - pulley_height])
    axle_small_pulley();
    translate([stepper_size/2, stepper_size/2+axle_distance, height])
        axle_large_pulley();

    # translate([stepper_size / 2, stepper_size / 2, motor_shaft_length - pulley_height])
        motor_pulley();

    # translate([stepper_size/2, stepper_size/2+axle_distance + final_axle_distance, height + plate_gap - pulley_height]) 
        final_pulley();
}

module spacer() {
    difference() {
        cube([spacer_width, spacer_width, plate_gap]);
        translate([spacer_width / 2, spacer_width / 2])
            # cylinder(plate_gap, hole_ID/2, hole_ID/2);
    }
}

module plate_end() {
    difference() {
        cube([stepper_size, end_plate_height, plate_gap]);
        translate([spacer_width + hole_offset, 0, height + hole_offset])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
        translate([stepper_size - spacer_width - hole_offset, 0, height + hole_offset])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
        translate([spacer_width + hole_offset, 0, plate_gap - hole_offset - height])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
        translate([stepper_size - spacer_width - hole_offset, 0, plate_gap - hole_offset - height])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
    }
    translate([0, end_plate_height, 0]) spacer();
    translate([stepper_size - spacer_width, end_plate_height, 0]) spacer();
    
    
}


module motor() {
   translate([stepper_size / 2, stepper_size / 2, stepper_length])
        cylinder(motor_shaft_length, motor_shaft_od / 2, motor_shaft_od / 2);
   difference() {
       cube([stepper_size, stepper_size, stepper_length]);
       
       translate([hole_offset, hole_offset]) 
            cylinder(stepper_length, hole_ID / 2, hole_ID / 2);
       translate([stepper_size - hole_offset, hole_offset]) 
            cylinder(stepper_length, hole_ID / 2, hole_ID / 2);
       translate([stepper_size - hole_offset, stepper_size - hole_offset]) 
            cylinder(stepper_length, hole_ID / 2, hole_ID / 2);
       translate([hole_offset, stepper_size - hole_offset]) 
            cylinder(stepper_length, hole_ID / 2, hole_ID / 2);
       
       translate([hole_offset, hole_offset]) 
            cylinder(stepper_length - stepper_tab_depth, motor_carveout_r, motor_carveout_r);
       translate([stepper_size - hole_offset, hole_offset]) 
            cylinder(stepper_length - stepper_tab_depth, motor_carveout_r, motor_carveout_r);
       translate([stepper_size - hole_offset, stepper_size - hole_offset]) 
            cylinder(stepper_length - stepper_tab_depth, motor_carveout_r, motor_carveout_r);
       translate([hole_offset, stepper_size - hole_offset]) 
            cylinder(stepper_length - stepper_tab_depth, motor_carveout_r, motor_carveout_r);
   }
}

module model() {
    full_plate();
    translate([0, 0, plate_gap + height]) full_plate();
    translate([0, -end_plate_height, height]) plate_end();
    translate([0, length + end_plate_height, height])
        mirror([0, 1, 0]) plate_end();
    placeholder_pulleys();
    # translate([0, 0, -stepper_length]) motor();
    
    * translate([0, stepper_size - spacer_width, height]) spacer();
    * translate([stepper_size - spacer_width, stepper_size - spacer_width, height]) spacer();
    
    # translate([stepper_size/2, stepper_size/2+axle_distance + final_axle_distance, 2 * height + plate_gap])
        cylinder(drive_wheel_width, drive_wheel_od / 2, drive_wheel_od / 2);
        
}

module layout() { 
    ! plate_end();

    % translate([0, height * 2 + part_sep, 0])
        plate_end();
    
    % translate([part_sep + spacer_width, part_sep +spacer_width, 0])  
        spacer();
    % translate([2 * (part_sep + spacer_width), part_sep + spacer_width, 0]) 
        spacer();
}
% mower();
model_z = stepper_size/2+axle_distance + final_axle_distance + drive_wheel_od / 2;
translate([mower_wheel_outside_w / 2 - height * 2 - plate_gap, 0, model_z])
    rotate([-90, 0, -90]) model();
translate([-mower_wheel_outside_w / 2 + height * 2 + plate_gap, -stepper_size, model_z])
    rotate([-90, 0, 90]) model();
//layout();


