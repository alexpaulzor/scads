use <boxit.scad>

// CONSTANTS
$fn = 30;
wall_th = 2.0;
inside_dims = [90, 90, 90];
eparts_offset = [-10, 8, 04];

// MEASUREMENTS
ssr_w = 58;
ssr_h = 45;
ssr_d = 30;
ssr_screw_c_c = 47.5;

spool_od = 200;
spool_h = 80;
spool_id = 50;
spool_oid = 95;
spool_rim_h = 4;

filament_od = 1.75;

pidbox_h = 45;
pidbox_w = 45;
pidbox_d = 85;
pidbox_face_d = 6;
pidbox_hole_od = 3;

outlet_screw_c_c = 84;
outlet_w = 34;
outlet_h = 68;
outlet_center = 9;
outlet_screw_od = 3;
outlet_face_d = 5;
outlet_d = 18;

heater_grate_w = 220;
heater_grate_h = 43;

face_d = min(outlet_face_d, pidbox_face_d);

plug_h = (outlet_h - outlet_center) / 2;
module plug_face() {
    intersection() {
        cube([plug_h, outlet_w, outlet_face_d]);
        translate([plug_h / 2, outlet_w / 2, 0])
            cylinder(h=face_d, r=outlet_w / 2);
    }
}

module outlet() {
    translate([outlet_center / 2, -outlet_w / 2, 0])
        plug_face();
    translate([-outlet_center / 2 - plug_h, -outlet_w / 2, 0])
        plug_face();
    translate([-outlet_h/2, -outlet_w/2, -outlet_d])
        cube([outlet_h, outlet_w, outlet_d]);
    # cylinder(r=outlet_screw_od/2, h=face_d);
    # translate([outlet_screw_c_c / 2, 0, 0])
        cylinder(h=face_d, r=outlet_screw_od/2);
    # translate([-outlet_screw_c_c / 2, 0, 0])
        cylinder(h=face_d, r=outlet_screw_od/2);
}

module ssr() {
    difference() {
        translate([-ssr_h/2, -ssr_w/2])
            cube([ssr_h, ssr_w, ssr_d]);
        translate([0, -ssr_screw_c_c / 2, 0])
            cylinder(r=outlet_screw_od/2, h=ssr_d);
        translate([0, ssr_screw_c_c / 2,  0])
            cylinder(r=outlet_screw_od/2, h=ssr_d);
    }
    # translate([0, -ssr_screw_c_c / 2, ssr_d/2])
        cylinder(r=outlet_screw_od/2, h=2*ssr_d, center=true);
    # translate([0, ssr_screw_c_c / 2,  ssr_d/2])
        cylinder(r=outlet_screw_od/2, h=2*ssr_d, center=true);
    translate([-20, -20, -wall_th*2])
        cube([40, 40, wall_th*4]);
        
}

module pidbox() {
    cube([pidbox_h, pidbox_w, pidbox_d], center=true);
    translate([0, 0, pidbox_d / 2 + pidbox_face_d / 2])
        cube([pidbox_h + 5, pidbox_w + 5, pidbox_face_d], center=true); 
}

module pidbox_holes(width=pidbox_h + 20, height=pidbox_h + 20) {
    ofs_x = 2.3;
    ofs_y = 4.5;
    translate([-pidbox_h / 2, -pidbox_w / 2, 0])
        cube([pidbox_h, pidbox_w, face_d]);
    translate([-pidbox_h/2 + ofs_x, -pidbox_w/2 - ofs_y, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    translate([pidbox_h/2 - ofs_x, pidbox_w/2 + ofs_y, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    
    translate([pidbox_h/2 - ofs_x, -pidbox_w/2 - ofs_y, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    translate([-pidbox_h/2 + ofs_x, pidbox_w/2 + ofs_y, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    
    translate([-pidbox_h/2 - ofs_y, -pidbox_w/2 + ofs_x, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    translate([pidbox_h/2 + ofs_y, pidbox_w/2 - ofs_x, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    
    translate([pidbox_h/2 + ofs_y, -pidbox_w/2 + ofs_x, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
    translate([-pidbox_h/2 - ofs_y, pidbox_w/2 - ofs_x, pidbox_d / 2])
        cylinder(h=2 * face_d, r=pidbox_hole_od/2, center=true);
}

module pidbox_in_place(inside_dims, wall_th) { 
    translate([-5, 5, 0]) {
        rotate([0, 0, 0]) {
            pidbox_holes();
            # pidbox();
        }
    }
}
       
module outlet_in_place(inside_dims, wall_th) {
    translate([55, -15, -10]) {
        rotate([45, 0, 0]) { 
            rotate([0, 90, 0]) {  
                # outlet();
            }
        }
    }
}
            
module ssr_in_place(inside_dims, wall_th) {
    translate([10, -56, -15]) {
        rotate([90, 90, 0]) {
            # ssr();
        }   
    }
}

module tplug_in_place(inside_dims, wall_th, include_plug=true, include_holder=true) {
    # translate([0, -40, 38]) {
        rotate([0, -90, 90]) {
            if (include_holder)
                tplug_holder(inside_dims, wall_th, plug);
            if (include_plug)
                thermal_plug(true);
        }
    }
}

tplug_l = 23;
tplug_w = 18;
tplug_h = 10;
tine_l = 11;
tine_w = 3;
tine_h = 1.8;
tine_inside = 5.15;
tine_outside = 10.5;

module thermal_plug() {
    translate([tine_l / 2, tine_inside/2 + tine_w/2, 0])
        cube([tine_l, tine_w, tine_h], center=true);
    translate([tine_l / 2, -tine_inside/2 - tine_w/2, 0])
        cube([tine_l, tine_w, tine_h], center=true);
    translate([-tplug_l / 2, 0, 0])
        cube([tplug_l, tplug_w, tplug_h], center=true);
    translate([-tplug_l - wall_th / 2, 0, 0])
        cube([wall_th, tplug_w/2, tplug_h], center=true);
}

module tplug_holder(inside_dims, wall_th, include_plug=true) {
    difference() {
        translate([-tplug_l - wall_th, -tplug_w / 2 - wall_th, -tplug_h/2 - wall_th])
            cube([tplug_l + tine_l, tplug_w + 2 * wall_th , tplug_h + wall_th ]);
        thermal_plug();
    }
    if (include_plug)
        thermal_plug();
}

iec_l = 27;
iec_w = 19;
iec_h = 15;
iec_connector_h = 25;
iec_flange_l = 50;
iec_flange_w = 22;
iec_flange_h = 6;
iec_hole_c_c = 40;
iec_hole_or = 2;

module iec_plug() {
    difference() {
        union() {
            translate([0, 0, -iec_h / 2 ])
                cube([iec_l, iec_w, iec_h], center=true);
            % translate([0, 0, -iec_h - iec_connector_h / 2])
                cube([iec_l, iec_w, iec_connector_h], center=true);
            translate([0, 0, iec_flange_h / 2])
                cube([iec_flange_l, iec_flange_w, iec_flange_h], center=true);
        }
        translate([iec_hole_c_c/2, 0, 0])
            cylinder(r=iec_hole_or, h=iec_h, center=true);
        translate([-iec_hole_c_c/2, 0, 0])
            cylinder(r=iec_hole_or, h=iec_h, center=true);
        
    }
    translate([iec_hole_c_c/2, 0, 0])
        cylinder(r=iec_hole_or, h=iec_h, center=true);
    translate([-iec_hole_c_c/2, 0, 0])
        cylinder(r=iec_hole_or, h=iec_h, center=true);
    translate([0, 0, iec_h])
    cube([iec_l - 2, iec_w - 2, iec_h * 2], center=true);
}

module iec_plug_in_place(inside_dims, wall_th) {
    # translate([57, 10, 15]) {
            rotate([45, 0, 0])
            rotate([0, 90, 0]) {
                
                iec_plug();     
            }
    }
}

module eparts(inside_dims=inside_dims, wall_th=wall_th) {
    translate(eparts_offset) {
        pidbox_in_place(inside_dims, wall_th);
        outlet_in_place(inside_dims, wall_th);
        ssr_in_place(inside_dims, wall_th);
        
        # iec_plug_in_place(inside_dims, wall_th);
    }
    tplug_in_place(inside_dims, wall_th, include_plug=true, include_holder=false);
    save_plastic(inside_dims, wall_th);
}

//eparts(inside_dims, wall_th);

module save_plastic(inside_dims, wall_th) {
    rocker_or = 10;
    * translate([0, 0, inside_dims[2] / 2 - 1])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[0] * 2/3, inside_dims[1] * 2/3], center=true);
    
    translate([0, 0, -inside_dims[2] / 2 - wall_th - 1])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[0] * 2/3, inside_dims[1] * 2/3], center=true);
    
    translate([-inside_dims[0]/2 - wall_th - 1, 0, 0])
        rotate([0, 90, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[2] * 2/3, inside_dims[1] * 2/3], center=true);
    
    translate([0, inside_dims[1] / 2 + wall_th + 1, 0])
        rotate([90, 0, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[0] * 2/3, inside_dims[2] * 2/3], center=true);
        
    * translate([0, -inside_dims[1] / 2 - wall_th - 1, 0])
        rotate([-90, 0, 0])
        linear_extrude(height=wall_th*2)
        offset(r=rocker_or/2)
        square([inside_dims[0] * 2/3, inside_dims[2] * 2/3], center=true);
}

module wall_adds(inside_dims, wall_th) {
    tplug_in_place(inside_dims, wall_th, include_plug=false, include_holder=true);
}

 * boxit(inside_dims, wall_th, ofscale=1) {
    wall_adds(inside_dims, wall_th);
    # eparts(inside_dims, wall_th);
}

* boxit(inside_dims, wall_th, ofscale=5) {
    wall_adds(inside_dims, wall_th);
    //cube(0);
    # eparts(inside_dims, wall_th);
}

module export(face_i) {
    if (face_i == 0)
        translate([inside_dims[0]/2 + wall_th/2, 0, 0])
     boxit_wall_right(inside_dims, wall_th) {
        cube(0);
        eparts(inside_dims, wall_th);
    }
    if (face_i == 1)
        boxit_wall_left(inside_dims, wall_th) {
        cube(0);
        eparts(inside_dims, wall_th);
    }
    
    if (face_i == 2)
        boxit_wall_top(inside_dims, wall_th) {
        wall_adds(inside_dims, wall_th);
        eparts(inside_dims, wall_th);
    }

    if (face_i == 3)
        boxit_wall_bottom(inside_dims, wall_th) {
        cube(0); //wall_mods(inside_dims, wall_th);
        eparts(inside_dims, wall_th);
    }
    //* wall_mods();
    if (face_i == 4)
        translate([0, inside_dims[1]/2 + wall_th / 2, 0])
    boxit_wall_front(inside_dims, wall_th) {
        cube(0);
        # eparts(inside_dims, wall_th);
    }
    if (face_i == 5)
        boxit_wall_back(inside_dims, wall_th) {
        cube(0);
        eparts(inside_dims, wall_th);
    }
}

export(5);


