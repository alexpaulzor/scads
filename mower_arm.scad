$fn=60;

arm_w = 33;
arm_l = 38;
arm_c_h = 154;

arm_hole_r = 2.5;
arm_wall_w = 1;
arm_axle_l = 180;
arm_top_w = 65;
arm_top_h = 50;
arm_top_l = 50;
arm_top_clearance = 13;
arm_bottom_clearance = 8;
arm_h = arm_c_h + arm_top_clearance + arm_bottom_clearance;
arm_grip_ir = 25 / 2;
arm_grip_angle = 70;

arm_rom_deg = 50;
//arm_rom_x = 90;
arm_rom_x = arm_c_h * sin(arm_rom_deg);

echo("Arm ROM:",arm_rom_deg,arm_rom_x);

module arm() {
    difference() {
        translate([0, 0, -arm_bottom_clearance])
            cylinder(r=arm_w / 2, h=arm_h);
        translate([0, -arm_w / 2, arm_c_h])
            rotate([-90, 0, 0])
                cylinder(r=arm_hole_r, h=arm_w);
        translate([0, 0, -(arm_h - arm_c_h) / 2 - 1])
            cylinder(r=arm_w / 2 - 2 * arm_wall_w, h=arm_h + 2);
    }
    translate([0, -arm_axle_l/2, arm_c_h])
        rotate([-90, 0, 0])
            cylinder(r=arm_hole_r, h=arm_axle_l);
    translate([-arm_top_l/2, -arm_top_w/2, arm_c_h + arm_top_clearance - arm_l * cos(arm_grip_angle)])
        rotate([0, arm_grip_angle - 90, 0])
        difference() {
           cube([arm_top_l, arm_top_w, arm_top_h]);
            translate([0, arm_top_w/2, arm_top_h/2])
                rotate([0, 90, 0])
                # cylinder(r=arm_grip_ir, h=bot_frame_l);
        }
}

wheel_w = 50;
wheel_or = 90;
wheel_space = 8;

module wheel() {
    rotate([-90, 0, 0])
        cylinder(r=wheel_or, h=wheel_w);
}

bot_frame_l = 600;
bot_frame_gap_l = 100;
bot_frame_h = 40;
bot_frame_flange_h = 4;
bot_frame_arm_gap = 1;
bot_axle_or = 4;
bot_axle_l = 190;

module frame() {
    translate([-arm_w / 2, arm_w / 2 + bot_frame_arm_gap, -bot_frame_h/2])
        cube([bot_frame_l, bot_frame_flange_h, bot_frame_h]);
    translate([-arm_w / 2 + bot_frame_gap_l, arm_w / 2 + bot_frame_arm_gap - bot_frame_h + bot_frame_flange_h, -bot_frame_h/2])
        cube([bot_frame_l - bot_frame_gap_l, bot_frame_h, bot_frame_flange_h]);
    translate([0, -bot_axle_l/2, 0])
        rotate([-90, 0, 0])
            cylinder(r=bot_axle_or, h=bot_axle_l);
}

module bot_frame() {
    arm();
    translate([0, -arm_w/2 - wheel_w - wheel_space, 0])
        wheel();
    translate([0, arm_w/2 + bot_frame_arm_gap + wheel_space + bot_frame_flange_h, 0])
        wheel();
    frame();
    
}

rod_r = 8 / 2;
rod_l = 500;
rod_mount_c_h = 20;
rod_mount_flange_w = 42;
rod_mount_flange_h = 6.5;
rod_mount_w = 20;
rod_mount_l = 14;
rod_mount_h = 33.5;
rod_mount_hole_r = 5.5 / 2;
rod_mount_hole_c_c = 31.5;

module rod(l=rod_l) {
    rotate([0, 90, 0])
        cylinder(r=rod_r, h=l);
}

module rod_mount() {
    difference() {
        union() {
            translate([-rod_mount_l / 2, -rod_mount_w / 2, -rod_mount_c_h])
                cube([rod_mount_l, rod_mount_w, rod_mount_h]);
            translate([-rod_mount_l / 2, -rod_mount_flange_w / 2, -rod_mount_c_h]) 
                cube([rod_mount_l, rod_mount_flange_w, rod_mount_flange_h]);
        }
        translate([-rod_mount_l / 2, 0, 0])
            rod(rod_mount_l);
        translate([0, rod_mount_hole_c_c / 2, -rod_mount_c_h])
            cylinder(r=rod_mount_hole_r, h=rod_mount_flange_h);
        translate([0, -rod_mount_hole_c_c / 2, -rod_mount_c_h])
            cylinder(r=rod_mount_hole_r, h=rod_mount_flange_h);
    }
}

rod_traveller_w = 34;
rod_traveller_l = 30;
rod_traveller_h = 21.7;
rod_traveller_step_h = 17;
rod_traveller_step_w = 17;
rod_traveller_hole_c_c_w = 24.5;
rod_traveller_hole_c_c_l = 18;
rod_traveller_hole_r = 6 / 2;

rod_traveller_mount_h = 4 * rod_traveller_hole_r;

module rod_traveller() {
    difference() {
        translate([-rod_traveller_l/2, -rod_traveller_w/2, -rod_traveller_h/2])
            cube([rod_traveller_l, rod_traveller_w, rod_traveller_h]);
        translate([-rod_traveller_l/2, 0, 0])
            rod(rod_traveller_l);
        
        translate([-rod_traveller_hole_c_c_l/2, -rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
        translate([-rod_traveller_hole_c_c_l/2, rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
        translate([rod_traveller_hole_c_c_l/2, rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
        translate([rod_traveller_hole_c_c_l/2, -rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
         translate([-rod_traveller_l/2, -rod_traveller_w / 2, -rod_traveller_h / 2 + rod_traveller_step_h])
            cube([rod_traveller_l, (rod_traveller_w - rod_traveller_step_w) / 2, rod_traveller_h - rod_traveller_step_h]);
        translate([-rod_traveller_l/2, (rod_traveller_w - rod_traveller_step_w) / 2, -rod_traveller_h / 2 + rod_traveller_step_h])
            cube([rod_traveller_l, (rod_traveller_w - rod_traveller_step_w) / 2, rod_traveller_h - rod_traveller_step_h]);
    }
}

module rod_traveller_mount() {
    difference() {
        translate([-rod_traveller_l/2, -rod_traveller_w/2, -rod_traveller_mount_h/2])
            cube([rod_traveller_l, rod_traveller_w, rod_traveller_mount_h]);
        * translate([-rod_traveller_l/2, 0, 0])
            rod(rod_traveller_l);
        
        translate([0, -rod_traveller_w/2, 0])
            rotate([-90, 0, 0])
                cylinder(r=arm_hole_r, h=rod_traveller_w);
        
        translate([-rod_traveller_hole_c_c_l/2, -rod_traveller_hole_c_c_w/2, -rod_traveller_mount_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_mount_h);
        translate([-rod_traveller_hole_c_c_l/2, rod_traveller_hole_c_c_w/2, -rod_traveller_mount_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_mount_h);
        translate([rod_traveller_hole_c_c_l/2, rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_mount_h);
        translate([rod_traveller_hole_c_c_l/2, -rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_mount_h);
    }
}

module rod_traveller_block() {
    translate([0, 0, (
        rod_traveller_h + rod_traveller_mount_h) / 2])
        # rod_traveller_mount();
    % rotate([180, 0, 0]) rod_traveller();
}

shaft_r = 8 / 2;
shaft_l = 400;
shaft_pillow_l = 13;
shaft_pillow_c_h = 14.5;
shaft_pillow_h = 30;
shaft_pillow_w = 2 * shaft_pillow_c_h;
shaft_pillow_flange_w = 55;
shaft_pillow_hole_r = 5 / 2;
shaft_pillow_hole_c_c = 42;
shaft_pillow_flange_h = 5;

module shaft(l=shaft_l) {
    rod(l);
}

module shaft_pillow() {
    difference() {
        union() {
            translate([-shaft_pillow_l/2, 0, 0])
                rotate([0, 90, 0])
                    cylinder(r=shaft_pillow_w/2, h=shaft_pillow_l);
            translate([-shaft_pillow_l/2, -shaft_pillow_flange_w/2, -shaft_pillow_c_h])
                cube([shaft_pillow_l, shaft_pillow_flange_w, shaft_pillow_flange_h]);
        }
        shaft(shaft_pillow_l);
        translate([0, shaft_pillow_hole_c_c/2, -shaft_pillow_c_h])
            cylinder(r=shaft_pillow_hole_r, h=shaft_pillow_flange_h);
        translate([0, - shaft_pillow_hole_c_c/2, -shaft_pillow_c_h])
            cylinder(r=shaft_pillow_hole_r, h=shaft_pillow_flange_h);
    }
}

nema_mount_w = 50;
nema_mount_l = 55;
nema_mount_h = 50;
nema_mount_c_h = 30;
nema_slot_l = 35;
nema_slot_iw = 25.6;
nema_slot_ow = 34.4;
nema_mount_slot_c_c = (nema_slot_iw + nema_slot_ow) / 2;
nema_slot_w = (nema_slot_ow - nema_slot_iw) / 2;
nema_collar_l = 35;
nema_mount_flange_h = 3;
nema_collar_l = 35;
nema_collar_or = 19 / 2;
nema_l = 48;
nema_w = 43;

module nema_mount() {
    difference() {
        union() {
            translate([0, -nema_mount_w / 2, -nema_mount_c_h]) {
                cube([nema_mount_flange_h, nema_mount_w, nema_mount_h]);
                cube([nema_mount_l, nema_mount_w, nema_mount_flange_h]);
            }
            rotate([0, 90, 0])
                cylinder(r=nema_collar_or, h=nema_collar_l);
        }
        shaft(nema_mount_flange_h);
        translate([(nema_mount_l - nema_slot_l)/2, nema_mount_slot_c_c/2 - nema_slot_w/2, -nema_mount_c_h])
            cube([nema_slot_l, nema_slot_w, nema_mount_flange_h]);
        translate([(nema_mount_l - nema_slot_l)/2, -nema_mount_slot_c_c/2 - nema_slot_w/2, -nema_mount_c_h])
            cube([nema_slot_l, nema_slot_w, nema_mount_flange_h]);
    }
    translate([-nema_l, -nema_w/2, -nema_w/2])
        cube([nema_l, nema_w, nema_w]);
}

// LINEAR MOTION PARAMS
traveller_h = 16;
traveller_collar_or = 11 / 2;
traveller_flange_or = 23 / 2;
traveller_flange_h = 3.75;
traveller_flange_z = 10.2;
traveller_hole_ir = 3.7 / 2;
traveller_hole_offset = 8;
traveller_num_holes = 4;
traveller_hole_angle = 360 / traveller_num_holes;
traveller_ir = 7 / 2;

module shaft_traveller() {
    
    % difference() {
        union() {
            cylinder(h=traveller_h, r=traveller_collar_or);
            translate([0, 0, traveller_flange_z]) {
                difference() {
                    cylinder(h=traveller_flange_h, r=traveller_flange_or);
                    for (i=[1:traveller_num_holes])
                        rotate([0, 0, i * traveller_hole_angle])
                            translate([traveller_hole_offset, 0, 0])
                                cylinder(h=traveller_flange_h, r=traveller_hole_ir);
                }
            }
        }
        cylinder(h=traveller_h, r=traveller_ir);
    }
    
    pivot_gimbal();
}

gimbal_pivot_hole_ir = 5 / 2;
gimbal_x = 3 * traveller_flange_or;
gimbal_y = rod_traveller_h/2 + rod_traveller_mount_h + 1.5 * traveller_flange_or;
gimbal_z = rod_traveller_l; //traveller_h;

module pivot_gimbal() {
    difference() {
        translate([-gimbal_x/2, -1.5 * traveller_flange_or, 0])
            cube([gimbal_x, gimbal_y, gimbal_z]);
        translate([0, 0, 0]) {
            cylinder(h=gimbal_z, r=traveller_collar_or);
            for (i=[1:traveller_num_holes])
                rotate([0, 0, (0.5 + i) * traveller_hole_angle])
                    translate([traveller_hole_offset, 0, 0])
                        cylinder(h=gimbal_z, r=traveller_hole_ir);
            translate([0, 0, traveller_flange_z]) 
                cylinder(h=gimbal_z - traveller_flange_z, r=traveller_flange_or);
        }
        translate([-gimbal_x/2, rod_traveller_h/2 + rod_traveller_mount_h/2, gimbal_z / 2])
            rotate([0, 90, 0])
            cylinder(r=gimbal_pivot_hole_ir, h=gimbal_x);
    }
    
}


shaft_gap_z = arm_w + bot_frame_arm_gap * 2 + gimbal_x / 2 + rod_traveller_w / 2;
//shaft_gap_y = nema_mount_slot_c_c / 2 + rod_mount_hole_c_c / 2;
shaft_gap_zp = gimbal_x / 2 + rod_traveller_w / 2;


traveller_x = shaft_l - arm_w - arm_rom_x / 2;
shaft_x = traveller_x - arm_rom_x / 2;

shaft_offset_x = nema_collar_l / 2 + nema_mount_flange_h;

block_gap = 1;
block_l = rod_mount_l + shaft_pillow_l + block_gap;
block_w = max(rod_mount_flange_w, shaft_pillow_flange_w);
block_h = shaft_gap_z + shaft_gap_zp - 2 * rod_mount_c_h;
block_ledge_h = shaft_pillow_l;

module spacer_block() {
    difference() {
        translate([0, -block_w/2, shaft_gap_zp - rod_mount_c_h - block_h])
            cube([block_l, block_w, block_h]);
        translate([rod_mount_l, -block_w/2, -shaft_pillow_c_h])
            cube([block_l, block_w, block_h]);
        translate([rod_mount_l, -block_w/2, shaft_gap_zp - rod_mount_c_h - block_h])
            cube([block_l, block_w, (-shaft_pillow_c_h - block_ledge_h) - (shaft_gap_zp - rod_mount_c_h - block_h) ]);
        translate([rod_mount_l/2, rod_mount_hole_c_c / 2, -block_h])
            cylinder(r=rod_mount_hole_r, h=2*block_h);
        translate([rod_mount_l/2, -rod_mount_hole_c_c / 2, -block_h])
            cylinder(r=rod_mount_hole_r, h=2*block_h);
        translate([block_l - shaft_pillow_l/2, shaft_pillow_hole_c_c/2, -block_h])
            cylinder(r=shaft_pillow_hole_r, h=2*block_h);
        translate([block_l - shaft_pillow_l/2, - shaft_pillow_hole_c_c/2, -block_h])
            cylinder(r=shaft_pillow_hole_r, h=2*block_h);
        rotate([0, 90, 0])
            cylinder(r=nema_collar_or, h=block_l);
        translate([block_l / 2, -block_w / 2, -shaft_pillow_c_h - block_ledge_h / 2])
            rotate([-90, 0, 0])
            cylinder(r=rod_mount_hole_r, h=block_w);
    }   
}

module nema_spacer_block() {
    difference() {
        spacer_block();
        translate([0, -nema_mount_w / 2, -nema_mount_c_h])
            cube([nema_mount_l, nema_mount_w, nema_mount_flange_h]);
    }
}

module design() {
    translate([-traveller_x, arm_w / 2 + gimbal_z + bot_frame_arm_gap, arm_c_h + rod_traveller_h])
        rotate([-90, 0, 0])
            hard_parts();
    rotate([0, 0, 180])
        % bot_frame();
}

module hard_parts() {    
    translate([-nema_collar_l - shaft_pillow_l/2, 0, 0]) {
        # translate([nema_collar_l, 0, 0])
            nema_spacer_block();
        % nema_mount();
        % translate([shaft_offset_x, 0, 0])
            shaft();
    }
    % translate([shaft_pillow_l + block_gap, 0, 0])
        shaft_pillow();
    
    translate([traveller_x - traveller_h / 2, 0, 0])
        rotate([0, 90, 0])
             shaft_traveller();
    % translate([0, 0, -shaft_gap_z])
        rotate([180, 0, 0])
        rod_mount();

    translate([traveller_x, 0, -shaft_gap_z])
        rotate([-90, 0, 0])
        rod_traveller_block();
    % translate([shaft_l - rod_l, 0, -shaft_gap_z])
        rod();
    
    % translate([0, 0, shaft_gap_zp])
        rod_mount();

    translate([traveller_x, 0, shaft_gap_zp])
        rotate([-90, 0, 0])
        rod_traveller_block();
    % translate([-nema_slot_l/2 - (rod_l - shaft_l), 0, shaft_gap_zp])
        rod();
    
    % translate([shaft_x - shaft_pillow_l, 0, 0])
        shaft_pillow();
    % translate([shaft_x, 0, -shaft_gap_z])
        rotate([180, 0, 0])
        rod_mount();
    % translate([shaft_x, 0, shaft_gap_zp])
        rod_mount();
    # translate([shaft_x + rod_mount_l / 2, 0, 0])
        mirror([1, 0, 0])
        spacer_block();
}
//!hard_parts();
design();

module layout() {
    * translate([20, 0, 0]) nema_spacer_block();
    * translate([20, 70, 0]) spacer_block();
    * translate([-50, 0, 0]) rod_traveller();
    
    translate([0, 0, 0]) rod_traveller();
    translate([gimbal_z/2, rod_traveller_w/2 + gimbal_x/2, rod_traveller_h/2])
        rotate([-90, 0, 90]) pivot_gimbal();
}
!layout();