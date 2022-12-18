use <purchased_parts.scad>;
use <chain_drive.scad>;
IN_MM = 25.4;

arm_c_h = get_arm_c_h();
arm_grip_angle = get_arm_grip_angle();
arm_grip_ir = get_arm_grip_ir();
sk8_c_h = get_sk8_c_h();
sk8_flange_w = get_sk8_flange_w();
sk8_l = get_sk8_l();
rod_r = get_rod_r();
shaft_l = get_shaft_l();

/////////////////////////////////////////////////
//////////// PURCHASED PARTS ////////////////////
/////////////////////////////////////////////////

openbeam_w = 15;
BEAM_IR = 3/2;

//TODO: remeasure after rebuild
arm_w = 33;
arm_l = 38;
arm_c_h = 154;

arm_hole_r = 5 / 2;
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
                # mower();
        }
}

gimbal_pivot_hole_ir = 5 / 2;
gimbal_w = 3 * openbeam_w;
gimbal_h = 2 * openbeam_w;
gimbal_l = openbeam_w;
gimbal_rod_c_c = gimbal_h/2 - 1.5 * gimbal_pivot_hole_ir;

module pivot_gimbal() {
    % rotate([0, 0, 45]) 
        shaft_traveller();
    difference() {
        translate([-gimbal_w / 2, -gimbal_h / 2, 0])
            cube([gimbal_w, gimbal_h, gimbal_l]);
        translate([0, 0, 0]) {
            cylinder(h=gimbal_l, r=traveller_collar_or);
            for (i=[1:traveller_num_holes])
                rotate([0, 0, 45 + i * traveller_hole_angle])
                    translate([traveller_hole_offset, 0, 0])
                        cylinder(h=gimbal_l, r=traveller_hole_ir);
            translate([0, 0, gimbal_l / 2 + traveller_flange_z / 2 + gimbal_shift_z])
                cylinder(h=gimbal_l, r=traveller_flange_or);
            translate([0, 0, gimbal_shift_z])
                cylinder(h=gimbal_l / 2 - traveller_flange_z/2, r=traveller_flange_or);
        }
        for (x=[-openbeam_w, openbeam_w]) {
            for (y=[-openbeam_w/2, openbeam_w/2]) {
                translate([x, y, 0]) {
                    cylinder(r=BEAM_IR, h=gimbal_h, center=true);
                }
                
            }
            translate([x, 0, openbeam_w/2])
                rotate([90, 0, 0])
                cylinder(r=BEAM_IR, h=gimbal_w, center=true);
        }
        * for (y=[-openbeam_w/2, openbeam_w/2]) {
            translate([0, y, openbeam_w/2])
                rotate([0, 90, 0])
                cylinder(r=BEAM_IR, h=gimbal_w, center=true);
        }
        % translate([-openbeam_w, 0, -openbeam_w/2])
            rotate([90, 0, 0]) 
            beam();
        %  translate([openbeam_w, 0, -openbeam_w/2])
            rotate([90, 0, 0]) 
            beam();
    }
}

/////////////////////////////////////////////////
//////////// LIMIT SWITCH ///////////////////////
/////////////////////////////////////////////////

switch_w = 20;
switch_l = 11;
switch_h = 7;
switch_hole_offset_w = 5;
switch_hole_offset_l = 3;
switch_hole_ir = 2.5 / 2;

switch_roller_offset = 3;
switch_roller_overhang = 2.3;
switch_roller_h = 5;
switch_roller_w = 19;
switch_roller_l = 5;
switch_roller_th = 0.2;

switch_pin_clearance = 1.5;
switch_pin_h = 5;

switch_holder_lip_l = 2;
switch_holder_h = 3 * rod_r;
switch_holder_w = switch_holder_h + switch_w + switch_roller_overhang;
switch_holder_l = switch_l + 2 * switch_holder_lip_l;

module switch() {
    translate([0, 0, -switch_h/2])
        cube([switch_l, switch_w, switch_h]);
    translate([-switch_roller_l, -switch_roller_overhang, -switch_roller_h/2])
        rotate([0, 0, -atan(switch_roller_l / switch_roller_w)])
            cube([switch_roller_th, switch_roller_w, switch_roller_h]);
    translate([switch_l, switch_pin_clearance, -switch_pin_h/2])
        cube([switch_pin_h, switch_w - 1 * switch_pin_clearance, switch_pin_h]);
    translate([switch_l - switch_hole_offset_l, switch_w - switch_hole_offset_w, -switch_h])
        cylinder(r=switch_hole_ir, h=2 * switch_h);
    
    translate([switch_l - switch_hole_offset_l, switch_hole_offset_w, -switch_h])
        cylinder(r=switch_hole_ir, h=2 * switch_h);
}

module limit_switch() {
    difference() {
        translate([0, -switch_holder_h/2, -switch_holder_h/2])
            cube([switch_holder_l, switch_holder_w, switch_holder_h]);
        # translate([switch_holder_lip_l, switch_holder_h / 2 + switch_roller_overhang, 0])
            switch();
        translate([0, 0, -switch_roller_h/2])
            cube([switch_holder_lip_l, switch_holder_w, switch_roller_h]);
        
        rotate([0, 90, 0])
            cylinder(r=rod_r+0.5, h=switch_holder_l);
    }
    
}

trav_position = shaft_l / 2;
shaft_sep_y = 100;
rod_shaft_sep_y = 30;

module lin_act() {
    shaft_offset_x = nema_collar_l / 2 + nema_mount_flange_h;
    translate([-shaft_offset_x, 0, 0])
        nema_mount();
    shaft();
    
    translate([trav_position, 0, 0])
        rotate([180, 0, 0]) rotate([0, 90, 0])
             pivot_gimbal();
    
    * translate([front_kp08_x + kp08_l + switch_holder_l * 3 / 2, 0, gimbal_w / 2 + rod_traveller_h/2])
        rotate([0, 0, 180])
        limit_switch();
    
    
    % translate([0, -rod_shaft_sep_y, 0])
        rod();
    % translate([0, -rod_shaft_sep_y + shaft_sep_y, 0])
        rod();
}

bar_w = 1.0 * IN_MM;

module bar(length) {
    cube([length, bar_w, bar_w], center=true);
}

tread_width = 100;
bot_length = 300;
bot_width = 300;
fork_length = 100;

module tread() {
    for (i=[-1, 1]) {
        translate([0, i* (tread_width/2), 0])
            rotate()
            bar(bot_length + sk8_flange_w);
        
        for (j=[-1, 1]) {
            % translate([i * (bot_length / 2), j * (tread_width/2 - sk8_l/2), -sk8_c_h - bar_w/2])
                rotate([180, 0, 90])
                sk8();
            
            translate([i * (bot_length / 2), j*get_gear_space()/2, -sk8_c_h - bar_w/2])
                rotate([j*90, 0, 0])
                idler_sprocket(use_stl=true);
        }
        
        % translate([i * (bot_length / 2), -tread_width/2, -sk8_c_h - bar_w/2])
            rotate([0, 0, 90])
            rod(tread_width);
    }
    
    translate(motor_offs)
        driven_sprockets();
    translate([bot_length/2, tread_width/2 + angle_iron_w/2, bar_w / 2])
        rotate([0, 0, 180])
        angle_iron(100);
    
    translate([0, bot_width / 2 - tread_width - bar_w, bar_w])
            rotate([0, 0, 90])
            bar(bot_width/2 + bar_w);
}

module normchain(num_links=10, bend_deg=0, offs=0, include_clips=true) {
    * rotate([0, 90, 90])
        chain(num_links=num_links, bend_deg=bend_deg, offs=offs, include_clips=include_clips);
}

module driven_sprockets() {
    translate([0, get_gear_space()/2 - get_link_pin_w()/2, 0]) {
        % rotate([90, 90 + get_motor_tall_rotation(), 0])
            drive_motor(use_stl=true);
        translate([0, get_link_pin_w()/2, 0])
            rotate([90, 0, 0]) {
                drive_sprocket(use_stl=true);
                translate([0, 0, get_gear_space()])
                    idle_drive_sprocket(use_stl=true);
        }
//        rotate([0, 150, 0])
            translate([0, -get_gear_space() + get_link_pin_w()/2, -sk8_c_h - bar_w/2 - get_idler_pitch_or()])
                normchain(num_links=get_drive_teeth(), bend_deg=360/get_drive_teeth(), offs=0, include_clips=true);
    }
    translate([0, -tread_width/2, 0])
        rotate([0, 0, 90])
        rod(tread_width);
}


angle_iron_w = 40;
angle_iron_flange_h = 4;

module angle_iron(length) {
    cube([length, angle_iron_w, angle_iron_flange_h]);
    cube([length, angle_iron_flange_h, angle_iron_w]);
}

motor_offs = [bot_length / 2 - get_drive_pitch_or(), 0, get_drive_pitch_or()];

module bot_frame() {
    
    *translate([bot_length / 2, -get_gear_space()/2, -sk8_c_h - bar_w/2 + get_idler_pitch_or()])
        rotate([0, 180, 0])
        normchain(num_links=6, bend_deg=360/get_idler_teeth(), offs=0, include_clips=true);
    for (i=[-1, 1]) {
        % translate([0, i*(bot_width / 2 - tread_width / 2), 0]) {
            rotate([0, 0, i*90+90])
                tread();
            translate([bot_length / 2, -get_gear_space()/2, -sk8_c_h - bar_w/2 - get_idler_pitch_or()])
                normchain(num_links=24, bend_deg=0, offs=0, include_clips=true);
        }
        translate([-(bot_length + sk8_flange_w + fork_length) / 2, i*(bot_width / 2 - tread_width), 0])
            bar(fork_length);
     }
    
    //TODO: add axle
    % translate([-bot_length / 2 - fork_length, 0, 0])
        arm();
    
}


// !lin_act();

/////////////////////////////////////////////////
//////////// RENDER /////////////////////////////
/////////////////////////////////////////////////
$fn = 8;

module design() {
    bot_frame();
}

module layout() {
    //* shaft_traveller();
    //hard_parts_rect(false, 10 * sk8_l + shaft_offset_x);
}
//layout();
design();