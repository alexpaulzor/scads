use <spur_generator.scad>;

use <parametric_involute_gear_v5.0.scad>;

$fn = 24;
plate_height = 10;
bearing_gap = 3;
exp_factor = 31.6 / 30;

stepper_size = 42.3;      // outside width of motor
motor_hole_gap = 31.0;    //c_c distance between screw holes
stepper_length = 48;
stepper_center = 22;

hole_ID = 3;
hole_offset = (stepper_size - motor_hole_gap) / 2;  // screw hole center to outside edge, nema17 = 5.5mm
stepper_tab_depth = stepper_length;
stepper_hole_depth = 6;

motor_shaft_od = 5;
motor_shaft_length = 22;

axle_bearing_id = 10;
axle_bearing_od = 22;
axle_bearing_height = 7;

final_bearing_od = 29;
final_bearing_id = 17;
final_bearing_height = 8;

//axle_distance = 41.6;
final_axle_distance = 2 * stepper_size;
    //axle_distance + 58.6; 
    //stepper_center / 2 + axle_bearing_od + final_bearing_od / 2 + 2 * bearing_gap;
final_axle_od = 12.7;

axle_distance = final_axle_distance / 2;
axle_od = 8;

// GEARING

min_pitch_depth = 3;
gear_pitch = 1;
gear_height = 10;
gear_spoke_height = gear_height / 2;

motor_gear_pd_in = 2 * min_pitch_depth + motor_shaft_od;
axle_large_gear_pd_in = axle_distance - motor_gear_pd_in / 2;
axle_small_gear_pd_in = 2 * min_pitch_depth + axle_od;
final_gear_pd_in = (final_axle_distance - axle_distance) - axle_small_gear_pd_in / 2;

motor_gear_teeth = floor(motor_gear_pd_in / gear_pitch);
axle_large_gear_teeth = floor(axle_large_gear_pd_in / gear_pitch);
axle_small_gear_teeth = floor(axle_small_gear_pd_in / gear_pitch);
final_gear_teeth = floor(final_gear_pd_in / gear_pitch);


motor_pitch = fit_spur_gears(motor_gear_teeth, axle_large_gear_teeth, axle_distance);

final_pitch = fit_spur_gears(axle_small_gear_teeth, final_gear_teeth, final_axle_distance - axle_distance);

motor_gear_pd = 2 * gear_outer_radius(motor_gear_teeth, motor_pitch);
axle_large_gear_pd = 2 * gear_outer_radius(axle_large_gear_teeth, motor_pitch);
axle_small_gear_pd = 2 * gear_outer_radius(axle_small_gear_teeth, final_pitch);
final_gear_pd = 2 * gear_outer_radius(final_gear_teeth, final_pitch);


gear_ratio = 1 / (motor_gear_teeth / axle_large_gear_teeth * axle_small_gear_teeth / final_gear_teeth);

echo("motor t/d: ", motor_gear_teeth, motor_gear_pd,
     "axle_large t/d: ", axle_large_gear_teeth, axle_large_gear_pd,
     "axle_small t/d: ", axle_small_gear_teeth, axle_small_gear_pd,
     "final t/d: ", final_gear_teeth, final_gear_pd,
     "ratio: 1:", gear_ratio);
         
// END GEARING

plate_gap = 3 * (gear_height + 2); //55; // Inside pulley area, between bearing plates
end_plate_height = plate_height / 2;

drive_wheel_od = 8 * 25.4; // TODO: measure
drive_wheel_width = 2 * 25.4; // TODO: measure

spacer_width = hole_offset * 1.5;
    //plate_height / 2;

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


part_sep = 5;

plate_length = stepper_size / 2
            + final_axle_distance + final_gear_pd / 2
            + spacer_width;
            
            
echo("SANITY CHECK:",
    "axle_bearing_skin", plate_height / 2 - axle_bearing_height / 2,
    "final_axle_bearing_skin", plate_height / 2 - final_bearing_height / 2,
    "gear_clearance", plate_gap - 3 * gear_height
    );

module set_screw_collar(od, id, height) {
    //ripped off http://www.thingiverse.com/thing:11256
    m3_dia = 3.2;		// 3mm hole diameter
    m3_nut_hex = 1;		// 1 for hex, 0 for square nut
    //m3_nut_flats = 6;	// normal M3 hex nut exact width = 5.5
    //m3_nut_depth = 3;	// normal M3 hex nut exact depth = 2.4, nyloc = 4
    no_of_nuts = 3;		// number of captive nuts required, standard = 1
    nut_angle = 120;		// angle between nuts, standard = 90
    
    nut_elevation = height/2;
    id = id * exp_factor;
    
    difference()
	 {	 
		cylinder(r=od/2,h=height);

		//hole for motor shaft
		cylinder(r=exp_factor*id/2,h=height,$fn=id*4);
				
		//captive nut and grub screw holes
        for(j=[1:no_of_nuts]) rotate([0,0,j*nut_angle])
			translate([0,0,nut_elevation]) 
                rotate([90,0,0])
                    set_screw_hole(od, id, height);		
	}
}
//! set_screw_hole(od=30, id=8, height=15);
module set_screw_hole(od, id, height, m3_nut_depth=3, m3_nut_flats=6, m3_dia=3, m3_nut_hex=1) {
    nut_shaft_distance = 1.2; //(od - id) / 4 - m3_nut_depth;	// distance between inner face of nut and shaft, can be negative.
    m3_nut_points = 2*((m3_nut_flats/2)/cos(30));
    union()
    {
        //entrance
        translate([0,-height/4-0.5,id/2+m3_nut_depth/2+nut_shaft_distance])
            cube([m3_nut_flats,height/2+1,m3_nut_depth],center=true);

        //nut
        if ( m3_nut_hex > 0 )
            {
                // hex nut
                translate([0,0.25,id/2+m3_nut_depth/2+nut_shaft_distance]) rotate([0,0,30]) cylinder(r=m3_nut_points/2,h=m3_nut_depth,center=true,$fn=6);
            } else {
                // square nut
                translate([0,0.25,id/2+m3_nut_depth/2+nut_shaft_distance]) cube([m3_nut_flats,m3_nut_flats,m3_nut_depth],center=true);
            }

        //grub screw hole
        rotate([0,0,22.5]) cylinder(r=exp_factor*m3_dia/2,h=od/2+1);
    }  
}

module model_axles() {
    translate([stepper_size / 2, stepper_size / 2 + axle_distance])
        cylinder(plate_gap + 2 * plate_height, axle_od/2, axle_od/2);
    translate([stepper_size / 2, stepper_size / 2 + final_axle_distance])
        cylinder(plate_gap + 2 * plate_height, final_axle_od/2, final_axle_od/2);
}

module simple_gear(height, or, ir) {
    difference() {
        cylinder(height, or, or);
        cylinder(height, ir, ir);
    }
}

module motor_gear() {
    translate([0, 0, 0])
        set_screw_collar(stepper_center - 4, motor_shaft_od, plate_height);
    translate([0, 0, plate_height])
    gear (circular_pitch=motor_pitch,
		gear_thickness = motor_shaft_length - plate_height,
		rim_thickness = motor_shaft_length - plate_height,
		hub_thickness = motor_shaft_length - plate_height,
		number_of_teeth = motor_gear_teeth,
        hub_diameter=2 * motor_shaft_od,
        bore_diameter=motor_shaft_od,
		rim_width = 2);
}

module gear_crosslink(od, id, height, num_splines=6) {
    spline_thickness = id / 4;
    spline_angle = 360 / num_splines;
    iod = od - 2 * spline_thickness;
    difference() {
        union() {
            cylinder(height, iod / 2, iod / 2);
            for(j=[1:num_splines / 2]) 
                rotate([0,0,j*spline_angle])
                    translate([-od / 2, -spline_thickness / 2, 0])
                        cube([od, spline_thickness, height]);
        }
        cylinder(height, id / 2, id / 2);
    }
    
}

module axle_crosslink() {
    gear_crosslink(axle_small_gear_pd - 6, axle_od * exp_factor, 2 * gear_height);
}

module axle_large_gear() {
    difference() {
        gear (circular_pitch=motor_pitch,
            gear_thickness = gear_height,
            rim_thickness = gear_height,
            hub_thickness = gear_height,
            number_of_teeth = axle_large_gear_teeth,
            hub_diameter=2 * axle_od,
            bore_diameter=axle_od + 1,
            rim_width = 2);
            
        scale([exp_factor, exp_factor, 1]) 
            axle_crosslink();
    }
}

module axle_small_gear(gear_height=gear_height) {
    difference() {
        gear (circular_pitch=final_pitch,
            gear_thickness = gear_height,
            rim_thickness = gear_height,
            hub_thickness = gear_height,
            number_of_teeth = axle_small_gear_teeth,
            hub_diameter=2 * axle_od,
            bore_diameter=axle_od * exp_factor,
            rim_width = 2);
        scale([exp_factor, exp_factor, 1]) 
            axle_crosslink();
    }
        
}

module final_crosslink() {
    translate([0, 0, -gear_height]) 
            set_screw_collar(2.5 * final_axle_od, final_axle_od * exp_factor, plate_height);
    gear_crosslink(2.5 * final_axle_od, final_axle_od * exp_factor, gear_height);
}

module final_gear() {
    difference() {
        gear (circular_pitch=final_pitch,
            gear_thickness = gear_height,
            rim_thickness = gear_height,
            hub_thickness = gear_height,
            number_of_teeth = final_gear_teeth,
            hub_diameter=2 * final_axle_od,
            bore_diameter=final_axle_od * exp_factor,
            rim_width = 2);
        # final_crosslink();
    }
}
//final_gear();

//translate([final_gear_pd, 0, 0]) final_crosslink();

// GEARING
module model_gears() {
    % model_axles();
    
    translate([stepper_size / 2, stepper_size / 2, 1])
        //rotate([0, 0, 180 / motor_gear_teeth])
        motor_gear();
    translate([stepper_size / 2, stepper_size / 2 + axle_distance, plate_height + 1])
        axle_crosslink();
    translate([stepper_size / 2, stepper_size / 2 + axle_distance, plate_height + 1]) 
        axle_large_gear();
    translate([stepper_size / 2, stepper_size / 2 + axle_distance, plate_height + gear_height + 3]) 
         axle_small_gear();
    translate([stepper_size / 2, stepper_size / 2 + final_axle_distance, plate_height + gear_height + 3]) {
        final_gear();
        final_crosslink();
    }
}

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

module bearing_plate() {
    difference() {
        cube([stepper_size, plate_length, plate_height / 2]);
        # translate([stepper_size/2, stepper_size/2+axle_distance,
                (plate_height - axle_bearing_height) / 2]) 
            cylinder(axle_bearing_height, axle_bearing_od/2, axle_bearing_od/2);
        
        translate([stepper_size/2, stepper_size/2+axle_distance]) 
            cylinder(plate_height, axle_bearing_id/2, axle_bearing_id/2);
        
        # translate([stepper_size/2, stepper_size/2 + final_axle_distance,
                (plate_height - final_bearing_height) / 2]) 
            cylinder(final_bearing_height, final_bearing_od/2, final_bearing_od/2);
        
        translate([stepper_size/2, stepper_size/2+ final_axle_distance]) 
            cylinder(plate_height, final_bearing_id/2, final_bearing_id/2);
    }
}

module half_holy_plate() {
    difference() {
        bearing_plate();
    
        translate([stepper_size-hole_offset, stepper_size - hole_offset]) 
            cylinder(plate_height, hole_ID / 2, hole_ID / 2);
        translate([hole_offset, stepper_size - hole_offset]) 
            cylinder(plate_height, hole_ID / 2, hole_ID / 2);
        translate([hole_offset, 
                    plate_length - hole_offset]) 
            cylinder(plate_height, hole_ID / 2, hole_ID / 2);
        translate([stepper_size - hole_offset, 
                    plate_length - hole_offset]) 
            cylinder(plate_height, hole_ID / 2, hole_ID / 2);
    }
}

module holy_plate() {
    difference() {
        half_holy_plate();
        translate([hole_offset, hole_offset]) 
            cylinder(plate_height, hole_ID / 2, hole_ID / 2);
        translate([stepper_size - hole_offset, hole_offset]) 
            cylinder(plate_height, hole_ID / 2, hole_ID / 2);
    }
}


module mount_plate() {

    difference() {
        holy_plate();
        translate([stepper_size / 2, stepper_size / 2]) 
            cylinder(plate_height, stepper_center / 2, stepper_center / 2);
    }
}

module half_plate() {
    mount_plate();
}

module full_plate() {
    half_plate();
    % translate([0, 0, plate_height]) mirror([0, 0, 1])
        half_plate();
       
}

module spacer() {
    difference() {
        cube([spacer_width, spacer_width, plate_gap]);
         translate([spacer_width / 2, spacer_width / 2])
            cylinder(plate_gap, hole_ID/2, hole_ID/2);
         translate([spacer_width / 2, spacer_width / 2, end_plate_height])
            rotate([0, 0, 180])
            set_screw_hole(od=spacer_width, id=0, height=plate_height);
        translate([spacer_width / 2, spacer_width / 2, plate_gap - end_plate_height - 3])
            rotate([0, 0, 180])
            set_screw_hole(od=spacer_width, id=0, height=plate_height);
    }
}

module plate_end() {
    difference() {
        cube([stepper_size, end_plate_height, plate_gap]);
        translate([spacer_width + hole_offset, 0, hole_offset])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
        translate([spacer_width + hole_offset, 0, plate_gap - hole_offset])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
        translate([stepper_size - spacer_width - hole_offset, 0, plate_gap - hole_offset])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
        translate([stepper_size - spacer_width - hole_offset, 0, hole_offset])
            rotate([-90, 0, 0])
                cylinder(end_plate_height, hole_ID/2, hole_ID/2);
    }
    translate([0, end_plate_height, 0]) 
        spacer();
    translate([stepper_size - spacer_width, end_plate_height, 0]) 
        spacer();
    
    
}

module motor() {
   translate([stepper_size / 2, stepper_size / 2, stepper_length])
        cylinder(motor_shaft_length, motor_shaft_od / 2, motor_shaft_od / 2);
   difference() {
       cube([stepper_size, stepper_size, stepper_length]);
       
       translate([hole_offset, hole_offset, stepper_length - stepper_hole_depth]) 
            cylinder(stepper_hole_depth, hole_ID / 2, hole_ID / 2);
       translate([stepper_size - hole_offset, hole_offset, stepper_length - stepper_hole_depth]) 
            cylinder(stepper_hole_depth, hole_ID / 2, hole_ID / 2);
       translate([stepper_size - hole_offset, stepper_size - hole_offset, stepper_length - stepper_hole_depth]) 
            cylinder(stepper_hole_depth, hole_ID / 2, hole_ID / 2);
       translate([hole_offset, stepper_size - hole_offset, stepper_length - stepper_hole_depth]) 
            cylinder(stepper_hole_depth, hole_ID / 2, hole_ID / 2);
   }
}

module model() {
    full_plate();
    translate([0, 0, plate_gap + plate_height]) full_plate();
    translate([0, -end_plate_height, plate_height]) plate_end();
    translate([0, plate_length - spacer_width, plate_height])
        spacer();
    translate([stepper_size - spacer_width, plate_length - spacer_width, plate_height])
        spacer();
    
    % translate([0, 0, -stepper_length]) motor();
    
    % translate([stepper_size/2, stepper_size/2 + final_axle_distance, 2 * plate_height + plate_gap])
        cylinder(drive_wheel_width, drive_wheel_od / 2, drive_wheel_od / 2);
    model_gears();
          
}

module design() {
    % mower();
    model_z = stepper_size/2 + final_axle_distance + drive_wheel_od / 2;
    translate([mower_wheel_outside_w / 2 - plate_height * 2 - plate_gap, 0, model_z])
        rotate([-90, 0, -90]) model();
    translate([-mower_wheel_outside_w / 2 + plate_height * 2 + plate_gap, -stepper_size, model_z])
        rotate([-90, 0, 90]) 
            model();
}

module layout_gears() { 
    translate([0, 0, motor_shaft_length])
        rotate([180, 0, 0])
            motor_gear();
    translate([0, -motor_gear_pd / 2 - axle_large_gear_pd / 2- part_sep, 0])
        rotate([0, 0, 0])
            axle_large_gear();
    translate([1.2 * motor_gear_pd, 0, 0])
        axle_crosslink();
    translate([-1.5 * motor_gear_pd, 0, gear_height])
        rotate([0, 0, 0])
            final_crosslink();
    translate([0, final_gear_pd/2 + motor_gear_pd / 2 + part_sep, 0])
        rotate([0, 0, 0])
            final_gear();
}

module layout() {
    translate([- axle_large_gear_pd / 2 - part_sep, axle_large_gear_pd + part_sep, 0]) 
        layout_gears();
    
    translate([0, -end_plate_height - spacer_width - part_sep, 0])
        plate_end();
    * translate([stepper_size + part_sep, -end_plate_height - spacer_width - part_sep, 0])
        plate_end();
    
    translate([0, 0, 0])
        half_plate();
    translate([stepper_size + part_sep, 0, 0])
        half_plate();
    
}
//! model_gears();

//model();
design();
//layout();


