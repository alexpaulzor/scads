include <arduino.scad>
use <boxit.scad>

IN_MM = 25.4;
$fn = 32;

bounds_upper_dims = [150, 170, 280];
bounds_cutout_or = 31;
bounds_cutout_h = 120;
bounds_cutout_trans = [0, 130, 55];
bar_or = 3;
bar_offs = [-42, 0, 110];

module bounds() {
    //difference() {
      //  cube(bounds_upper_dims);
        translate(bounds_cutout_trans)
            rotate([0, 90, 0]) 
            # cylinder(r=31, h=bounds_cutout_h);;
    //}
    translate(bar_offs) {
        rotate([-90, 0, 0])
        cylinder(r=bar_or, h=bounds_upper_dims[1], center=false);
    }
}

inside_dims = [
    bounds_upper_dims[0], bounds_cutout_trans[1] - bounds_cutout_or, bar_offs[2]];
echo(inside_dims);
wall_th = 2;

/////////////////////////////////////////////////
//////////// ELECTRONICS ////////////////////////
/////////////////////////////////////////////////
/*
psu_l = 130;
psu_w = 100;
psu_h = 40;
psu_hole_r = 1.5;
psu_hole_d = 18;

module psu_holes() {
    translate([6.7, -psu_hole_d/2, 32])
            rotate([-90, 0, 0])
            cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([32, -psu_hole_d/2, 20])
        rotate([-90, 0, 0])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([109, -psu_hole_d/2, 28])
        rotate([-90, 0, 0])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([109, -psu_hole_d/2, 10])
        rotate([-90, 0, 0])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    
    // TODO: these are approximate
    translate([4.5, 4.5, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([4.5, 94, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([36, 68, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([78, 68, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([78, 35, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([118, 90, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([118, 4.5, -psu_hole_d/2])
        cylinder(r=psu_hole_r, h=psu_hole_d);
}

module psu() {
    difference() {
        cube([psu_l, psu_w, psu_h]);
        psu_holes();
        translate([0, 0, psu_h / 2])
            cube([psu_h / 2, psu_w, psu_h / 2]);
    }
    psu_holes();
}
*/
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
        # cube([dcctl_l, dcctl_board_side_w, dcctl_h]);
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

stepctl_l = 106;
stepctl_w = 34;
stepctl_h = 77;
stepctl_notch_l = 7;
stepctl_notch_w = 22;
stepctl_flange_h = 4;
stepctl_hole_or = 5.5 / 2;
stepctl_hole_l = 9;
stepctl_hole_offset = 5;
stepctl_wire_w = 16;
stepctl_wire_l = 80;
stepctl_wire_h = 25;

module stepctl() {
    difference() {
        union() {
            cube([stepctl_l, stepctl_w, stepctl_h]);
            translate([(stepctl_l - stepctl_wire_l) / 2, 0, stepctl_h])
                cube([stepctl_wire_l, stepctl_wire_w, stepctl_wire_h]);
        }
        translate([stepctl_hole_l - stepctl_hole_or, stepctl_hole_offset + stepctl_hole_or, 0])
            cylinder(r=stepctl_hole_or, h=stepctl_flange_h);      
        translate([stepctl_l - stepctl_hole_l + stepctl_hole_or, stepctl_hole_offset + stepctl_hole_or, 0])
            cylinder(r=stepctl_hole_or, h=stepctl_flange_h);
        translate([stepctl_l - stepctl_hole_l + stepctl_hole_or, stepctl_hole_offset, 0])
            cube([stepctl_hole_l - stepctl_hole_or, 2 * stepctl_hole_or, stepctl_flange_h]);
        translate([0, stepctl_hole_offset, 0])
            cube([stepctl_hole_l - stepctl_hole_or, 2 * stepctl_hole_or, stepctl_flange_h]);
        stepctl_holes();
        translate([0, 0, stepctl_flange_h])
            cube([stepctl_notch_l, stepctl_notch_w, stepctl_h]);
        translate([stepctl_l - stepctl_notch_l, 0, stepctl_flange_h])
            cube([stepctl_notch_l, stepctl_notch_w, stepctl_h]);
    }
    stepctl_holes();
}

module stepctl_holes() {
    translate([stepctl_l - stepctl_hole_l + stepctl_hole_or, stepctl_hole_offset + stepctl_hole_or, -mega_h])
        cylinder(r=stepctl_hole_or-1, h=2 * mega_h);
    translate([stepctl_hole_l - stepctl_hole_or, stepctl_hole_offset + stepctl_hole_or, -mega_h])
        cylinder(r=stepctl_hole_or-1, h=2 * mega_h);
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
    translate([0, 0, -iec_plug_h + 6])
    cube([iec_plug_l, iec_plug_w, iec_plug_h]);
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

ssr_l = 63;
ssr_w = 46;
ssr_h = 24;
ssr_hole_or = 4.5/2;
ssr_hole_cc = 47;

module ssr() {
    translate([-ssr_l / 2, -ssr_w / 2, 0])
        cube([ssr_l, ssr_w, ssr_h]);
    translate([-ssr_hole_cc/2, 0, -ssr_h/2])
        cylinder(r=ssr_hole_or, h=2*ssr_h);
    translate([ssr_hole_cc/2, 0, -ssr_h/2])
        cylinder(r=ssr_hole_or, h=2*ssr_h);
}

num_rockers = 2;

module eparts_switches(inside_dims, wall_th) {
    translate([inside_dims[0] / 2 - rocker_or * 2, 
                -num_rockers * rocker_or * 2 / 3, 
                inside_dims[2] / 2 + wall_th]) {
        for (i=[0:num_rockers - 1]) {
            translate([0, 
                3 * rocker_or * i,
                    wall_th])
                rocker();
            * translate([2 * rocker_or * (i % 2), 
                2 * rocker_or * i,
                    wall_th])
                rocker();
        }
    }
}


module eparts_dcctls(inside_dims, wall_th) {
    translate([inside_dims[0] / 2 - wall_th, -inside_dims[1] / 4, -inside_dims[2]/5]) {
        rotate([90, 0, 0])
        rotate([0, 90, 90])
        dcctl_centered();
        
    }
    translate([inside_dims[0] / 2 - wall_th, inside_dims[1] / 4, -inside_dims[2]/5]) {
        rotate([90, 0, 0])
        rotate([0, 90, 90])
        dcctl_centered();
        
    }
}

module eparts_mega(inside_dims, wall_th) {
    translate([0, 0, -inside_dims[2]/2 + mega_lift]) {
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
}

module eparts_stepctl(inside_dims, wall_th) {
    translate([-stepctl_l/2, inside_dims[1] / 2 - stepctl_notch_w + wall_th * 2, -inside_dims[2] / 2 + mega_lift]) 
        stepctl();
}
/*
module eparts_psu(inside_dims, wall_th) {
    translate([-psu_l / 2 - 5, psu_w / 2, -inside_dims[2] / 2 - psu_hole_d/2 + wall_th])
        rotate([180, 0, 0]) {
            * % psu();
            * psu_holes();
        }
}*/

module eparts_iec(inside_dims, wall_th) {
    translate([-inside_dims[0]/2 - iec_plug_h / 2, -iec_plug_w / 3, iec_plug_l/3])
        rotate([0, 0, 0])
        iec_plug();
}

module eparts_outlet(inside_dims, wall_th) {
    translate([- inside_dims[0] / 3.1, 0, inside_dims[2] / 2])
        rotate([0, 0, 90])
        outlet();
}

module ssr_holes() {
    translate([0, 0, -wall_th]) {
        cube([ssr_l / 2, ssr_w - 4 * wall_th, 2 * wall_th], center=true);
    }
}

module eparts_ssr(inside_dims, wall_th) {
    translate([0, -inside_dims[1] / 2 - wall_th, ssr_w/1.5])
        rotate([90, 0, 0]) {
            ssr();
            ssr_holes();
        }
}

module eparts_atx(inside_dims, wall_th) {
    translate([-inside_dims[0]/2, inside_dims[1]/3, -inside_dims[2] / 6])
        rotate([90, 0, 0])
        rotate([0, 0, 90])
        atx();
}

module eparts_disp(inside_dims, wall_th) {
    translate([3, 0, inside_dims[2] / 2 + wall_th])
        rotate([0, 0, 90])
        //rotate([0, -90, 0])
        disp();
}

module eparts(inside_dims, wall_th) {
    eparts_atx(inside_dims, wall_th);
    eparts_disp(inside_dims, wall_th);
    eparts_dcctls(inside_dims, wall_th);
    eparts_switches(inside_dims, wall_th);
    // eparts_ssr(inside_dims, wall_th);
    eparts_mega(inside_dims, wall_th);
//    eparts_psu(inside_dims, wall_th);
    eparts_iec(inside_dims, wall_th);
    eparts_outlet(inside_dims, wall_th);
    // eparts_stepctl(inside_dims, wall_th);
    save_plastic(inside_dims, wall_th);
}

module save_plastic(inside_dims, wall_th) {
    translate([0, -inside_dims[1]/2, 0])
        rotate([90, 0, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[0]/1.4, inside_dims[1] / 1.4], center=true);
    translate([0, inside_dims[1]/2 + wall_th*2, 0])
        rotate([90, 0, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[0]/1.4, inside_dims[1] / 1.4], center=true);
    
    translate([0, 0, -inside_dims[2]/2 - wall_th*1.4]) {
        translate([-10, 0, 0])
            linear_extrude(height=wall_th*2)
            offset(r=rocker_or/2)
            square([30, 60], center=true);
        translate([45, 0, 0])
            linear_extrude(height=wall_th*2)
            offset(r=rocker_or/2)
            square([40, 30], center=true);
        translate([-35, 0, 0])
            linear_extrude(height=wall_th*2)
            offset(r=rocker_or/2)
            square([50, 30], center=true);
    }
    
    # translate([inside_dims[0]/2 - wall_th, 0, inside_dims[2]/4])
        rotate([0, 90, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[2]/5, inside_dims[1] / 1.4], center=true);
    
    translate([-inside_dims[0]/2 - wall_th, 0, inside_dims[2]/3])
        rotate([0, 90, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[2]/9, inside_dims[1] / 1.4], center=true);
    
    translate([-inside_dims[0]/2 - wall_th*1.5, -inside_dims[1]/3.5, -inside_dims[2]/8])
        rotate([0, 90, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[2]/2, inside_dims[1] / 6], center=true);
}

module wall_mods(inside_dims, wall_th) {
}
/*
    //ofs = boxit_wall_offsets(inside_dims, wall_th);
    //front_ofs = ofs[5];
    //# translate(front_ofs + [-stepctl_l / 2, -stepctl_notch_w - wall_th, -inside_dims[2] / 2 + mega_lift])
    union() {
        translate([-stepctl_l/2, inside_dims[1] / 2 - stepctl_notch_w, -inside_dims[2] / 2 + mega_lift - 2 * wall_th])
            cube([stepctl_l, stepctl_notch_w, 2 * wall_th]);
        translate([-stepctl_l/2, inside_dims[1] / 2 - stepctl_notch_w, -inside_dims[2] / 2])
            cube([wall_th, stepctl_notch_w, mega_lift - wall_th]);
        translate([-stepctl_l/2 + stepctl_l - wall_th, inside_dims[1] / 2 - stepctl_notch_w, -inside_dims[2] / 2])
            cube([wall_th, stepctl_notch_w, mega_lift - wall_th]);
    }
}*/

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

/////////////////////////////////////////////////
//////////// RENDER /////////////////////////////
/////////////////////////////////////////////////

module print(render_wall=0) {
    // left, right, bottom, top, back, front
    if (render_wall == 0) {
        rotate([0, 90, 0])
        boxit_wall_left(inside_dims, wall_th) {
            cube(0);
            eparts(inside_dims, wall_th);
        }
    }
    if (render_wall == 1) 
        rotate([0, 90, 0])
        boxit_wall_right(inside_dims, wall_th) {
            cube(0);
            eparts(inside_dims, wall_th);
        }
    if (render_wall == 2) boxit_wall_bottom(inside_dims, wall_th) {
        cube(0); //wall_mods(inside_dims, wall_th);
        eparts(inside_dims, wall_th);
    }
    if (render_wall == 3) 
        rotate([0, 180, 0])
        boxit_wall_top(inside_dims, wall_th) {
            cube(0);
            eparts(inside_dims, wall_th);
        }
    if (render_wall == 4) 
        rotate([90, 0, 0])
        boxit_wall_back(inside_dims, wall_th) {
            cube(0);
            eparts(inside_dims, wall_th);
        }
    if (render_wall == 5) 
        rotate([-90, 0, 0])
        boxit_wall_front(inside_dims, wall_th) {
            cube(0);
            eparts(inside_dims, wall_th);
        }
    
}

if (render_wall || render_wall == 0) {
    echo("Rendering wall ", render_wall);
    print(render_wall);
} else {
    echo("define render_wall to print");
    /*boxit(inside_dims, wall_th, ofscale=3.5) {
        wall_mods(inside_dims, wall_th);
        eparts(inside_dims, wall_th);
    }
    % eparts(inside_dims, wall_th);*/
}

/*% translate(-inside_dims/2) bounds();
// 
*/