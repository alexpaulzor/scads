include <arduino.scad>

IN_MM = 25.4;

/////////////////////////////////////////////////
//////////// ELECTRONICS ////////////////////////
/////////////////////////////////////////////////

psu_l = 130;
psu_w = 100;
psu_h = 40;
psu_hole_r = 1.5;
psu_hole_d = 18;

module psu_holes() {
    translate([6.7, 0, 32])
            rotate([-90, 0, 0])
            cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([32, 0, 20])
        rotate([-90, 0, 0])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([109, 0, 28])
        rotate([-90, 0, 0])
        cylinder(r=psu_hole_r, h=psu_hole_d);
    translate([109, 0, 10])
        rotate([-90, 0, 0])
        cylinder(r=psu_hole_r, h=psu_hole_d);
}

module psu() {
    difference() {
        cube([psu_l, psu_w, psu_h]);
        psu_holes();
    }
}

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
        mega_holes();
    }
    // cube([mega_l, mega_w, mega_h]);    
}

module mega_holes() {
    for (xy=dueHoles) {
        translate([xy[0], xy[1], -mega_h])
            cylinder(r=mega_hole_r, h=mega_h * 3);
    }
    translate([8, -60, 0])
        cube([15, 60, 15]);
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
dcctl_hs_l = 35;
dcctl_hs_w = 23;
dcctl_hs_h = dcctl_h;
dcctl_hole_r = 3/2;
dcctl_hole_offset = 5;
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
                        cylinder(r=dcctl_hole_offset, h=dcctl_board_side_w);
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

stepctl_l = 110;
stepctl_w = 34;
stepctl_h = 82;
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

eface_gap = 4;
eface_l = psu_l + 2 * eface_gap;
eface_w = eface_gap / 2;
eface_h = stepctl_h + 4 * eface_gap + stepctl_wire_h;
eface_spine_w = eface_gap * 3;
panel_h = eface_h;

module electronics_face() {
    psu_h = 0;
    difference() {
        union() {
            cube([eface_l, eface_w, eface_h]);
            translate([eface_l / 2 - eface_w / 2, 0, 0])
                cube([eface_w, eface_spine_w, eface_h]);
            * translate([0, 0, 0])
                cube([eface_l, eface_spine_w, eface_w]);
            
            translate([-eface_w, 0, 0])
                cube([eface_w, eface_spine_w, eface_h + eface_w]);
            translate([0, 0, eface_h - 3 * eface_w])
                cube([eface_l, eface_spine_w, 4 * eface_w]);
            translate([eface_l, 0, 0])
                cube([eface_w, eface_spine_w, eface_h + eface_w]);
            # translate([0, 0, 0])
                cube([eface_l, eface_spine_w, eface_w]);
            translate([0, 0, 2*eface_w])
                cube([eface_l, eface_spine_w, eface_w]);
            translate([0, 0, 2*eface_w])
                cube([4*eface_w, eface_spine_w, eface_h - eface_w]);
            translate([eface_l - eface_w*3, 0, 2*eface_w])
                cube([4*eface_w, eface_spine_w, eface_h - eface_w]);
        }
        * psu_holes();
        translate(eface_offset(-1)) {
            translate(eparts_offset()) eparts_dcctls();
            eshelf_attach_holes();
            ewall_left_in_place();
            ewall_right_in_place();
            eshelf_in_place();
            eceil_in_place();
        }   
    }
}

eshelf_w = psu_w + eface_gap;
eshelf_l = eface_l;

module eshelf_attach_holes() {
  translate([-eface_l / 2 - 4 * eface_w, -eshelf_w/2 + eface_spine_w/2, eface_w + eface_spine_w / 2])
    rotate([0, 90, 0])
        cylinder(r=psu_hole_r, h=eface_l + 8 * eface_w);
    
  translate([-eface_l / 2 - 4 * eface_w, -eshelf_w/2 + eface_spine_w/2, eface_h - eface_w - eface_spine_w / 2 ])
    rotate([0, 90, 0])
        cylinder(r=psu_hole_r, h=eface_l + 8 * eface_w);
    
  translate([-eface_l / 2 - 4 * eface_w, eshelf_w/2 - eface_spine_w/2 + eface_w, eface_w + eface_spine_w / 2])
    rotate([0, 90, 0])
        cylinder(r=psu_hole_r, h=eface_l + 8 * eface_w);
    
  translate([-eface_l / 2 - 4 * eface_w, eshelf_w/2 - eface_spine_w/2 + eface_w, eface_h - eface_w - eface_spine_w / 2])
    rotate([0, 90, 0])
        cylinder(r=psu_hole_r, h=eface_l + 8 * eface_w);
}

module electronics_shelf() {
    difference() {
        union() {
            translate([eface_w, 0, 0])
                cube([eshelf_l - 2 * eface_w, eshelf_w, eface_w]);
            translate([0, 0, 0])
                cube([eface_w, eshelf_w, eface_spine_w]);
            translate([eshelf_l - eface_w, 0, 0])
                cube([eface_w, eshelf_w, eface_spine_w]);
            translate([2 * eface_w, eface_spine_w, 0])
                cube([eface_w, eshelf_w - eface_spine_w, eface_spine_w]);
            translate([eshelf_l - 3 * eface_w, eface_spine_w, 0])
                cube([eface_w, eshelf_w - eface_spine_w, eface_spine_w]);
        }
        translate(eshelf_offset(-1)) {
            translate(eparts_offset()) {
                eparts_mega();
                eparts_stepctl();
            }
            eshelf_attach_holes();
        }   
    }
}

module electronics_wall_left() {
    eslot_h = 7;
    eslot_w = 40;
    difference() {
        cube([eface_w, eshelf_w, panel_h - 3 * eface_w]);
        translate(ewall_left_offset(-1)) {
            eshelf_attach_holes();
            translate(eparts_offset())
                eparts_mega();
        }
        # translate([0, eshelf_w / 2, panel_h / 2])
            rotate([90, 0, 0])
            rotate([0, -90, 0])
            ssr();
        translate([0, (eshelf_w - eslot_w) / 2, panel_h / 2 + ssr_w / 2 + eface_gap])  
            cube([eface_w, eslot_w, eslot_h]);
    }
}

module electronics_wall_right() {
    panel_h = panel_h - 3 * eface_w;
    difference() {
        cube([eface_w, eshelf_w, panel_h]);
        translate(ewall_left_offset(-1))
         eshelf_attach_holes();
         # translate([0, eshelf_w / 2, panel_h / 2])
            rotate([-45, 0, 0])
            rotate([0, 90, 0])
            outlet();
        * translate([0, 75, 40])
            rotate([0, 045, -90]) 
            iec_plug();
    }
}
module electronics_wall_back() {
    difference() {
        union() {
            cube([eshelf_l + 2 * eface_w, eface_w, panel_h]);
            translate([0, -eface_spine_w + eface_w, 0]) {
                cube([eshelf_l + 2 * eface_w, eface_spine_w, 3 * eface_w]);
                cube([eface_w * 4, eface_spine_w, panel_h]);
                translate([0, 0, panel_h - 2 * eface_w])
                    cube([eshelf_l + 2 * eface_w, eface_spine_w, 3 * eface_w]);
                translate([eshelf_l - 2* eface_w, 0, 0])
                    cube([4 * eface_w, eface_spine_w, panel_h]);
            }
        }
        translate(ewall_back_offset(-1)) {
            # translate(eparts_offset())
                eparts_stepctl();
             eshelf_attach_holes();
            ewall_left_in_place();
            ewall_right_in_place();
            eceil_in_place();
            eshelf_in_place();
        }
    }
}

rocker_or = 10;
rocker_h = 25;
rocker_lip_h = 3;
rocker_lip_or = 12;
num_rockers = 5;
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
    # cylinder(r=rocker_lip_or, h=rocker_lip_h);
}


module electronics_ceil() {
    difference() {
        union() {
            cube([eshelf_l, eshelf_w, eface_w]);
            translate([0, 0, -eface_spine_w]) {
                cube([3 * eface_w, eshelf_w, eface_spine_w]);
                
                translate([eshelf_l - 3 * eface_w, 0, 0])
                    cube([3 * eface_w, eshelf_w, eface_spine_w]);
                translate([3 * eface_w, eshelf_w / 2 - eface_w/2, 0])
                    cube([eface_l - 6 * eface_w, eface_w, eface_spine_w]);
            }
        }
        # translate([eshelf_l / 2 - iec_plug_l / 2, eshelf_w - eface_spine_w - 2 * eface_gap - iec_plug_w , 0])
            iec_plug();
        for (i=[0:num_rockers - 1]) {
            translate([eface_spine_w + eface_gap + rocker_or + i * (2.5 * rocker_or - eface_gap), eface_spine_w + 2* eface_gap + 2 * eface_w + 1.5 * rocker_or * (i % 2), eface_w])
                # rocker();
        }
        translate(eceil_offset(-1)) {
            eshelf_attach_holes();
            ewall_left_in_place();
            ewall_right_in_place();
        }
    }
}

//outlet_l = 72;
//outlet_w = 35;
//outlet_h = 23;
outlet_flange_l = 93;
outlet_flange_w = 19;
outlet_flange_h = 17;
outlet_flange_th = 1.125;
outlet_hole_cc_l = 84;
outlet_hole_or = 3/2;
outlet_screw_c_c = 84;

outlet_w = 34;
outlet_h = 70;
outlet_center = 10;
outlet_screw_od = 3;
outlet_face_d = 5;
outlet_d = 18;
face_d = eface_w;

plug_h = (outlet_h - outlet_center) / 2;
module plug_face() {
    intersection() {
        cube([plug_h, outlet_w, outlet_face_d]);
        translate([plug_h / 2, outlet_w / 2, 0])
            cylinder(h=face_d, r=outlet_w / 2);
    }
}

module outlet() {
    * translate([-outlet_h / 2, -outlet_w / 2, -outlet_flange_h])
        cube([outlet_h, outlet_w, outlet_d]);
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
//!outlet();

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

//!electronics_wall_right();

module eparts_dcctls() {
    translate([-eshelf_l/2 + 2 * eface_gap, -psu_w/2, (eface_h - dcctl_h) / 2]) {
        # dcctl();
        dcctl_holes();
    }
    translate([eshelf_l/2 - dcctl_l - 2 * eface_gap, -psu_w/2, (eface_h - dcctl_h) / 2]) {
        # dcctl();
        dcctl_holes();
    }
}

module eparts_mega() {
    translate([-mega_l / 2, -mega_w / 2, eface_gap + eface_w + mega_lift]) 
    {
        mega();
    }
    translate([-mega_l / 2 + 13, -vreg_w / 2, mega_h]) 
        vreg();
    translate([mega_l / 2 - 13 - rc_l, -rc_w / 2, mega_h]) 
        rc();
}

module eparts_stepctl() {
    translate([-stepctl_l/2, eshelf_w / 2 - stepctl_notch_w + 2.5*eface_w, eface_w]) 
        stepctl();
}

module eparts() {
    eparts_dcctls();
    eparts_mega();
    eparts_stepctl();
}

module electronics_box() {
     psu_in_place();
    * eparts_in_place();
     eface_in_place();
     eshelf_in_place();
     ewall_right_in_place();
    * ewall_left_in_place();
     ewall_back_in_place();
     % eceil_in_place();
     * bat_in_place();
}

module bat_in_place() {
    translate([-bat_l/2, -bat_h/2, -psu_h - eface_gap]) 
        rotate([-90, 0, 0])
        bat();
}

module psu_in_place() {
    translate([- psu_l / 2, -psu_w / 2, -psu_h - eface_gap]) {
        psu();  
    }
}

function eparts_offset(dir=1) = dir * [0, 0, eface_w];

module eparts_in_place() {
    translate(eparts_offset()) eparts();
}
    
function eface_offset(dir=1) = dir * [-eface_l / 2, -psu_w / 2 - eface_w, 0];

module eface_in_place() {
    translate(eface_offset())
        electronics_face();
}

function eshelf_offset(dir=1) = dir * [-eshelf_l / 2, -eshelf_w / 2 + eface_w, eface_w];

module eshelf_in_place() {
    translate(eshelf_offset())
        electronics_shelf();
}

function ewall_left_offset(dir=1) = dir * [-eshelf_l/2 + eface_w, -eshelf_w/2 + eface_w, eface_w * 2];

module ewall_left_in_place() {
    translate(ewall_left_offset())
        electronics_wall_left();
}
    
function ewall_right_offset(dir=1) = dir * [eshelf_l / 2 - 2 * eface_w, -eshelf_w / 2 + eface_w, 2 * eface_w];

module ewall_right_in_place() {
    translate(ewall_right_offset())
        electronics_wall_right();
}
    
function ewall_back_offset(dir=1) = dir * [-eshelf_l/2 - eface_w, eshelf_w / 2 + eface_w, 0];

module ewall_back_in_place() {
    translate(ewall_back_offset())
        electronics_wall_back();
}

function eceil_offset(dir=1) = dir * [-eshelf_l/2, -eshelf_w/2 + eface_w, panel_h - eface_w];

module eceil_in_place() {
    translate(eceil_offset())
        electronics_ceil();
}

/////////////////////////////////////////////////
//////////// RENDER /////////////////////////////
/////////////////////////////////////////////////
$fn = 24;

module layout() {
    % translate([250, 250, 0])
        electronics_box();
    
    * translate([0, 1, 0])
        electronics_shelf();
    
    * translate([eface_w + 1, 125, 0])
        rotate([90, 0, 0])
        electronics_face();
    
    translate([-1, -eshelf_l - eface_w * 2 - 1, eface_w])
        rotate([-90, 0, 90])
        electronics_wall_back();
    
    * translate([0, 0, 0]) 
        rotate([0, -90, 0])
        electronics_wall_left();
    
     translate([-1, 1, 0]) 
        rotate([0, -90, 0])
        electronics_wall_right();
        
     * translate([1, -1, 0])
        rotate([180, 0, 0]) 
        electronics_ceil();
    
    
}
layout();
//electronics_box();