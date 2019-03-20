axle_ground = 120;
roller_or = 25;

hub_or = axle_ground - roller_or;

num_rollers = 12;
$fn = num_rollers*3;

hub_h = 10;
hub_ir = 2;

bearing_h = hub_h*2;
bearing_ir = 6/2;
bearing_or = 14/2;



roller_h = 5;

roller_axle_or = 2;
roller_axle_l = 2;
roller_axle_head_or = 2 * roller_axle_or;
roller_axle_head_h = 2 * roller_axle_or;
roller_clearance = 12;
slot_clearance = 2;

arm_r = 35;
arm_hole_ir = 3;


roller_angle = 360 / num_rollers;
slot_offset = hub_or - roller_or - roller_clearance;
slot_width = roller_h + slot_clearance;

module slot() {
    translate([slot_offset, -slot_width/2, 0]) 
        cube([roller_or + roller_clearance, 
              slot_width,
              hub_h]);
    translate([hub_or - roller_axle_or / 2 - roller_clearance / 2,
               roller_axle_l + slot_width / 2,
               hub_h / 2])
        rotate([90, 0, 0]) {
            cylinder(h=slot_width + 2 * roller_axle_l, r=roller_axle_or);
            translate([0, 0, -roller_axle_l - roller_axle_head_h + slot_clearance/2])
                cylinder(h=roller_axle_head_h + slot_clearance/2, r=roller_axle_head_or);
            translate([0, 0, 2 * roller_axle_l + slot_width])
                cylinder(h=roller_axle_head_h + slot_clearance/2, r=roller_axle_head_or);
        }
    % translate([hub_or - roller_axle_or / 2 - roller_clearance / 2,
               roller_h / 2,
               hub_h / 2])
               roller();
    
}

module roller_disc() {
    difference() {
        cylinder(h=roller_h, r=roller_or);
        cylinder(h=roller_h, r=roller_axle_or);
    }
}

module roller() {
    rotate([90, 0, 0])
    roller_disc();
}

module hub() {
    difference() {
        cylinder(h=hub_h/2, r=hub_or);
        for(j=[1:num_rollers])  {
            rotate([0,0,j*roller_angle]) {
                slot();
                if (j % 2 == 0)
                    translate([arm_r, 0, 0])
                        cylinder(h=hub_h*2, r=arm_hole_ir, center=true);
            }
            rotate([0,0,(j + 0.5)*roller_angle])
                translate([4 * hub_or / 5, 0, 0])
                        cylinder(h=hub_h * 2, r=hub_ir, center=true);
                
        }
        translate([0, 0, (hub_h - bearing_h)/2])
            cylinder(h=hub_h*2+1, r=bearing_or, $fn=60, center=true);
        cylinder(h=hub_h*2, r=bearing_ir, center=true);
         
    }
}

module plate() {
    hub();
    * translate([2 * hub_or + roller_clearance, 0, 0])
        hub();
    * for(i=[0:4]) {
        for (j=[0:1]) {
            translate([-hub_or + roller_or + i * (2 * roller_or + roller_clearance/2), 
                    hub_or + roller_or + roller_clearance/2 + j * (2 * roller_or + roller_clearance / 2), 0])
                roller_disc();
        }   
        }
}
//plate();
//!slot();
roller_disc();