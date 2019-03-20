include <arduino.scad>
//use <boxit.scad>

IN_MM = 25.4;
$fn = 32;

wall_th = 2;

beam_w = 15;
beam_notch_d = 5;
beam_notch_w = 3;
beam_hole_or = 3/2;

module beam(length=50) {
    translate([0, 0, -length/2])
    linear_extrude(length) {
        difference() {
            square([beam_w, beam_w], center=true);
            for (i=[0:3]) {
                rotate([0, 0, 90 * i]) {
                    translate([beam_w/2 - beam_notch_d / 2, 0, 0]) {
                        square([beam_notch_d, beam_notch_w], center=true);
                    }
                }
            }
            circle(r=beam_hole_or);
        }
    }
}

inside_dims = [100 + 2 * beam_w, 100, 100];
echo(inside_dims);

/////////////////////////////////////////////////
//////////// ELECTRONICS ////////////////////////
/////////////////////////////////////////////////

mega_l = 102;
mega_w = 55;
mega_h = 18;
mega_hole_r = 3.2 / 2;
mega_lift = 12;

module mega() {
    translate([0, mega_w, 0])
    rotate([0, 0, -90]) {
        % arduino(MEGA2560);
        % translate([0, 0, mega_h - 2])
            arduino(MEGA2560);
    }
    // mega_holes();
}

module mega_holes() {
    translate([0, mega_w, 0])
    rotate([0, 0, -90]) {
        for (xy=dueHoles) {
            translate([xy[0], xy[1], -mega_h])
                cylinder(r=mega_hole_r, h=mega_h * 3);
        }
        translate([8, -60, 0])
            cube([15, 60, 20]);
    }
}

// TODO: estimated
vreg_l = 55;
vreg_w = 40;
vreg_h = 20;  

module vreg() {
    cube([vreg_l, vreg_w, vreg_h]);
}

// TODO: estimated
rc_l = 20;
rc_w = 40;
rc_h = 50;  

module rc() {
    cube([rc_l, rc_w, rc_h]);
}

bat_l = 150;
bat_w = 90;
bat_h = 95;
module bat() {
    cube([bat_l, bat_w, bat_h]);
}


dcctl_l = 50;
dcctl_w = 42;
dcctl_h = 52;
dcctl_hs_l = 33;
dcctl_hs_w = 23;
dcctl_hs_h = dcctl_h;
dcctl_hole_r = 3/2;
dcctl_hole_offset = 5;
dcctl_hole_or = 6/2;
dcctl_board_th = 1.5;
dcctl_board_side_w = dcctl_w - dcctl_hs_w;

module dcctl_holes() {
    for (x=[dcctl_hole_offset, dcctl_l - dcctl_hole_offset]) {
        for (z=[dcctl_hole_offset, dcctl_l - dcctl_hole_offset]) {
            translate([x, 0, z]) {
                rotate([-90, 0, 0]) {
                    translate([0, 0, -dcctl_hs_w])
                        cylinder(r=dcctl_hole_r, h=dcctl_w);
                    translate([0, 0, dcctl_board_th]) 
                        cylinder(r=dcctl_hole_or, h=dcctl_board_side_w);
                }
            }
        }
    }
}

module dcctl() {
    difference() {
        cube([dcctl_l, dcctl_board_side_w, dcctl_h]);
        dcctl_holes();
    }    
    translate([(dcctl_l - dcctl_hs_l) / 2, -dcctl_hs_w, 0])
        cube([dcctl_hs_l, dcctl_hs_w, dcctl_hs_h]);
}

module dcctl_centered() {
    translate([-dcctl_l/2, 0, -dcctl_h/2]) {
        dcctl();
        dcctl_holes();
    }
}

rocker_or = 10;
rocker_h = 25;
rocker_lip_h = 3;
rocker_lip_or = 12;
num_rockers = 4;
iec_plug_l = 32;
iec_plug_w = 27;
iec_plug_h = 32;

module iec_plug() {
    translate([0, 0, wall_th - iec_plug_h/2])
    cube([iec_plug_l, iec_plug_w, iec_plug_h], center=true);
}

module rocker() {
    translate([0, 0, -rocker_h])
        cylinder(r=rocker_or, h=rocker_h + rocker_lip_h);
    cylinder(r=rocker_lip_or, h=rocker_lip_h);
}

outlet_flange_l = 93;
outlet_flange_w = 19;
outlet_flange_h = 17;
outlet_flange_th = 1.125;
outlet_hole_cc_l = 84;
outlet_hole_or = 3/2;
outlet_screw_c_c = 84;

outlet_w = 34;
outlet_h = 70;
outlet_l = outlet_h;
outlet_center = 10;
outlet_screw_od = 3;
outlet_face_d = 5;
outlet_d = 18;
face_d = outlet_face_d;

plug_h = (outlet_h - outlet_center) / 2;
module plug_face() {
    intersection() {
        cube([plug_h, outlet_w, outlet_face_d]);
        translate([plug_h / 2, outlet_w / 2, 0])
            cylinder(h=face_d, r=outlet_w / 2);
    }
}

module outlet() {
    translate([-outlet_flange_l / 2, - outlet_flange_w / 2, -outlet_flange_th])
        cube([outlet_flange_l, outlet_flange_w, outlet_flange_th]);
    for (x=[1, 0, -1]) {
        translate([x * outlet_hole_cc_l/2, 0, -outlet_flange_h])
            cylinder(r=outlet_hole_or, h=outlet_w);
        
    translate([outlet_center / 2, -outlet_w / 2, 0])
        plug_face();
    translate([-outlet_center / 2 - plug_h, -outlet_w / 2, 0])
        plug_face();
    translate([-outlet_h/2, -outlet_w/2, -outlet_d])
        cube([outlet_h, outlet_w, outlet_d]);
    }
}


atx_l = 55;
atx_w = 24;
atx_h = 10;
atx_nub_l = 4;
atx_nub_w = 8;
atx_nub_h = 2;

module atx() {
    cube([atx_l, atx_w, atx_h], true);
    translate([0, 0, atx_h / 2 + atx_nub_h / 2])
        cube([atx_nub_l, atx_w, atx_nub_h], true);
}

disp_l = 58;;
disp_w = 28;
disp_h = 12;
disp_flange_l = 62;
disp_flange_w = 34;
disp_flange_h = 2;

module disp() {
    translate([0, 0, -disp_h/2])
        cube([disp_l, disp_w, disp_h], true);
    translate([0, 0, disp_flange_h/2])
        cube([disp_flange_l, disp_flange_w, disp_flange_h], true);
}

num_rockers = 2;

module eparts_switches() {
    translate([
        -rocker_or/2,
        -(inside_dims[1] / 2 - beam_w)/2, 
        0])
            rocker();
    translate([
        rocker_or*2 + wall_th,
        -(inside_dims[1] / 2 - beam_w)/2, 0])
            rocker();
}


module eparts_dcctls() {
    translate([inside_dims[0] * 0, inside_dims[1] * 1, wall_th/2])
        rotate([0, 0, 0])
        rotate([-90, 0, 0])
        dcctl_centered();
    translate([inside_dims[0] * 1, inside_dims[1] * 1, wall_th/2])
        rotate([0, 0, 90])
        rotate([-90, 0, 0])
        dcctl_centered();
}
/*
module eparts_mega() {
    translate([-10, 0, -inside_dims[2]/2 + mega_lift]) {
        translate([-mega_l / 2, -mega_w / 2, 0]) 
        {
            % color("gray", 0.05) mega();
            mega_holes();
        }
        translate([-mega_l / 2 + 13, -vreg_w / 2, mega_h]) 
            vreg();
        translate([mega_l / 2 - 13 - rc_l, -rc_w / 2, mega_h]) 
            rc();
    }
}*/
module eparts_iec() {
    translate([-inside_dims[0] / 2 + beam_w + wall_th + iec_plug_w / 2, -inside_dims[1] / 2 + beam_w + wall_th + iec_plug_h/2, wall_th])
        rotate([0, 0, 0])
        rotate([0, 0, 90])
        iec_plug();
}

module eparts_outlet() {
    translate([inside_dims[0] * 0, inside_dims[1] /4 - beam_w/2, -wall_th])
        rotate([0, 0, 0])
        rotate([0, 0, 0])
        outlet();
}

module eparts_atx() {
    translate([inside_dims[0] / 2 - atx_h / 2 - wall_th - beam_w, inside_dims[1] * 0, -wall_th])
        rotate([0, 0, -90])
        rotate([90, 0, 0])
        atx();
}

module eparts_disp() {
    translate([0, (inside_dims[1] - beam_w) / 4 - wall_th, 0])
        rotate([0, 0, 0])
        rotate([0, 0, 0])
        disp();
}

module eparts() {
    eparts_atx();
    eparts_disp();
    eparts_dcctls();
    eparts_switches();
    // eparts_ssr();
    //eparts_mega();
//    eparts_psu();
    eparts_iec();
    // eparts_outlet();
    // eparts_stepctl();
    //save_plastic();
}

module beams() {
    translate([0, inside_dims[1]/2 - beam_w/2, -beam_w/2 - wall_th])
        rotate([0, 90, 0])
        beam(inside_dims[0] - 2 * beam_w);
    translate([0, -(inside_dims[1]/2 - beam_w/2), -beam_w/2 - wall_th])
        rotate([0, 90, 0])
        beam(inside_dims[0] - 2 * beam_w);
    translate([-(inside_dims[0]/2 - beam_w/2), 0, -beam_w/2 - wall_th])
        rotate([90, 0, 0])
        beam(inside_dims[1]);
    translate([inside_dims[0]/2 - beam_w/2, 0, -beam_w/2 - wall_th])
        rotate([90, 0, 0])
        beam(inside_dims[1]);
}

module mount_holes() {
    hole_gap = beam_w * 2;
    for (x=[-inside_dims[0]/2 + beam_w / 2 : hole_gap : inside_dims[0]/2 - beam_w / 2]) {
        translate([x, -inside_dims[1]/2 + beam_w/2])
            cylinder(r=beam_hole_or, h=2*wall_th, center=true);
        translate([x, inside_dims[1]/2 - beam_w/2])
            cylinder(r=beam_hole_or, h=2*wall_th, center=true);
    }
    
    for (y=[-inside_dims[1]/2 + beam_w / 2 : hole_gap : inside_dims[1]/2 - beam_w / 2]) {
        translate([-inside_dims[0]/2 + beam_w/2, y])
            cylinder(r=beam_hole_or, h=2*wall_th, center=true);
        translate([inside_dims[0]/2 - beam_w/2, y])
            cylinder(r=beam_hole_or, h=2*wall_th, center=true);
    }
    
    translate([inside_dims[0]/2 - beam_w/2, inside_dims[1]/2 - beam_w/2])
            cylinder(r=beam_hole_or, h=2*wall_th, center=true);
}

module mountplate() { 
    difference() {
        translate([0, 0, -wall_th/2])
            cube([inside_dims[0], inside_dims[1], wall_th], center=true);
        eparts();
        mount_holes();
    }
    % beams();
    % eparts();
}

module mount_block(ir) {
    block_outside = 2*ir + 2 * wall_th;
    difference() {
        union() {
            translate([0, 0, wall_th/2])
                cube([3 * beam_w, beam_w, wall_th], center=true);
            translate([0, 0, block_outside/4])
                cube([block_outside, beam_w, block_outside/2], center=true);
            translate([0, 0, ir + wall_th])
                rotate([90, 0, 0]) 
                cylinder(r=block_outside/2, h=beam_w, center=true);
            * translate([ir + wall_th, 0, sqrt(2)/4*block_brace_w + wall_th/2])
                rotate([0, 45, 0])
                cube([block_brace_w, beam_w, block_brace_w/2], center=true);
            * translate([-ir - wall_th, 0, sqrt(2)/4*block_brace_w + wall_th/2])
                rotate([0, -45, 0])
                cube([block_brace_w, beam_w, block_brace_w/2], center=true);
            translate([-ir - wall_th + 1, -beam_w/2 + block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, -45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
            * translate([-ir - wall_th + 1, beam_w/2 - block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, -45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
            translate([ir + wall_th - 1, -beam_w/2 + block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, 45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
            * translate([ir + wall_th - 1, beam_w/2 - block_brace_w/4, sqrt(2)/4*block_brace_w])
                rotate([0, 45, 0])
                cube([beam_w, block_brace_w/2, beam_w], center=true);
        }
        translate([0, 0, ir + wall_th])
            rotate([90, 0, 0]) 
            cylinder(r=ir, h=beam_w+1, center=true, $fn=64);
        translate([beam_w, 0, 0])
            cylinder(r=beam_hole_or, h=wall_th*2);
        translate([-beam_w, 0, 0])
            cylinder(r=beam_hole_or, h=wall_th*2);
        
        translate([0, 0, -beam_w/2])
            cube([3*beam_w + 1, beam_w + 1, beam_w], center=true);
    }
}

bearing_h = 7;
bearing_ir = 4;
bearing_or = 11;
block_brace_w = 5;
module pillow_block() {
   mount_block(bearing_or);
}



module rocker_mount() {
    % translate([0, -beam_w/2, rocker_or + wall_th])
        rotate([90]) 
        rocker();
    mount_block(rocker_or);
}
rotate([90, 0, 0]) rocker_mount();
* translate([4 * beam_w, 0, 0]) pillow_block();
/////////////////////////////////////////////////
//////////// RENDER /////////////////////////////
/////////////////////////////////////////////////
