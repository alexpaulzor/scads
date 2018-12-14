$fn=60;

arm_w = 33;
arm_l = 38;
arm_c_h = 154;
arm_h = arm_c_h + 20; //TODO: guess
arm_rom_x = 90;
arm_hole_r = 2.5;
arm_wall_w = 1;
arm_axle_l = 180;

module arm() {
    difference() {
        translate([0, 0, -(arm_h - arm_c_h) / 2])
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
}

wheel_w = 50;
wheel_or = 90;
wheel_space = 10;

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
rod_traveller_hole_c_c_w = 24.5;
rod_traveller_hole_c_c_l = 18;
rod_traveller_hole_r = 4 / 2;

module rod_traveller() {
    difference() {
        translate([-rod_traveller_l/2, -rod_traveller_w/2, -rod_traveller_h/2])
            cube([rod_traveller_l, rod_traveller_w, rod_traveller_h]);
        translate([-rod_traveller_l/2, 0, 0])
            rod(rod_traveller_l);
        
        translate([0, -rod_traveller_w/2, 0])
            rotate([-90, 0, 0])
                cylinder(r=arm_hole_r, h=rod_traveller_w);
        
        translate([-rod_traveller_hole_c_c_l/2, -rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
        translate([-rod_traveller_hole_c_c_l/2, rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
        translate([rod_traveller_hole_c_c_l/2, rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
        translate([rod_traveller_hole_c_c_l/2, -rod_traveller_hole_c_c_w/2, -rod_traveller_h/2])
            cylinder(r=rod_traveller_hole_r, h=rod_traveller_h);
    }
}

module rod_traveller_block() {
    translate([0, 0, rod_traveller_h])
        # rod_traveller();
    % rod_traveller();
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
nema_mount_slot_c_c = 30;
nema_slot_l = 35;
nema_slot_w = 4;
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
traveller_collar_or = 10.2 / 2;
traveller_flange_or = 22.3 / 2;
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
    
    # pivot_gimbal();
}

gimbal_pivot_hole_ir = 5 / 2;
gimbal_x = 3 * traveller_flange_or;
gimbal_y = gimbal_x / 2 + 1.5 * rod_traveller_h;
gimbal_z = traveller_h;

module pivot_gimbal() {
    difference() {
        translate([-gimbal_x/2, -gimbal_x/2, 0])
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
        translate([0, rod_traveller_h, gimbal_z / 2])
            rotate([0, 90, 0])
            cylinder(r=gimbal_pivot_hole_ir, h=gimbal_x);
    }
    
}


shaft_gap_z = arm_w + bot_frame_arm_gap * 2 + gimbal_x / 2 + rod_traveller_w / 2;
//shaft_gap_y = nema_mount_slot_c_c / 2 + rod_mount_hole_c_c / 2;
shaft_gap_zp = gimbal_x / 2 + rod_traveller_w / 2;


traveller_x = shaft_l - arm_w - arm_rom_x;
shaft_x = traveller_x - arm_rom_x;

shaft_offset_x = nema_collar_l / 2 + nema_mount_flange_h;

module design() {
    translate([-traveller_x, arm_w / 2 + gimbal_z + bot_frame_arm_gap, arm_c_h + rod_traveller_h])
        rotate([-90, 0, 0])
            hard_parts();
    rotate([0, 0, 180])
        % bot_frame();
}

module hard_parts() {
    % translate([-nema_collar_l - shaft_pillow_l/2, 0, 0]) {
        nema_mount();
        translate([shaft_offset_x, 0, 0])
            shaft();
    }
    % shaft_pillow();
    
    translate([traveller_x - traveller_h / 2, 0, 0])
        rotate([0, 90, 0])
             shaft_traveller();
    % translate([-nema_slot_l/2, 0, -shaft_gap_z])
        rotate([180, 0, 0])
        rod_mount();

    translate([traveller_x, 0, -shaft_gap_z])
        rotate([-90, 0, 0])
        rod_traveller_block();
    % translate([-nema_slot_l/2 - (rod_l - shaft_l), 0, -shaft_gap_z])
        rod();
    
    % translate([-nema_slot_l/2, 0, shaft_gap_zp])
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
}

design();