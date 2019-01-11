// CONSTANTS
$fn = 30;

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
outlet_center = 10;
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

module pidbox_enclosure() {
    width = 110;
    height = 124;
    depth = 2 * outlet_d;
    
    difference() {
        translate([-height / 2, -width / 2, 0])
            cube([height, width, face_d]);
        translate([-22, -pidbox_w /2, 0])
            rotate([0, 0, 90]) {
                translate([-pidbox_h / 2, -pidbox_w / 2, 0])
                    cube([pidbox_h, pidbox_w, face_d]);
                % translate([0, 0, face_d])
                    import("mounting_bracket_v1.stl");
                translate([-pidbox_h/2 + 2.3, -pidbox_w/2 - 4.5, 0])
                    cylinder(h=2 * face_d, r=pidbox_hole_od/2);
                translate([pidbox_h/2 - 2.3, pidbox_w/2 + 4.5, 0])
                    cylinder(h=2 * face_d, r=pidbox_hole_od/2);
            }
        
        translate([-5, 32, 0]) {
            cylinder(r=outlet_screw_od/2, h=face_d);
            translate([outlet_center / 2, -outlet_w / 2, 0])
                plug_face();
            translate([-outlet_center / 2 - plug_h, -outlet_w / 2, 0])
                plug_face();
            translate([outlet_screw_c_c / 2, 0, 0])
                cylinder(h=face_d, r=outlet_screw_od/2);
            translate([-outlet_screw_c_c / 2, 0, 0])
                cylinder(h=face_d, r=outlet_screw_od/2);
        }
        translate([33, -20, 0]) {
            translate([0, -ssr_screw_c_c / 2, 0])
                cylinder(r=outlet_screw_od/2, h=ssr_d);
            translate([0, ssr_screw_c_c / 2,  0])
                cylinder(r=outlet_screw_od/2, h=ssr_d);
            translate([-20, -20, 0])
                cube([40, 40, ssr_d]);
        }
    }
    % translate([33, -20, 0])
        ssr();
    % translate([-5, 32, 0])
        mirror([0, 0, 1])
        outlet();
    % translate([-22, -pidbox_w /2, 0])
        pidbox();
    /*
    translate([-height/2, -width/2 - face_d, 0])
        cube([height, face_d, depth]);
    translate([-height/2, width/2, 0])
        cube([height, face_d, depth]);
    translate([-height/2, -width/2, 0])
        cube([face_d, width, depth]);
    translate([height/2, -width/2 - face_d, 0])
        cube([face_d, width + 2 * face_d, depth]);*/
}
  
    

pidbox_enclosure();

module outlet() {
    translate([outlet_center / 2, -outlet_w / 2, 0])
        plug_face();
    translate([-outlet_center / 2 - plug_h, -outlet_w / 2, 0])
        plug_face();
    translate([-outlet_h/2, -outlet_w/2, -outlet_d])
        cube([outlet_h, outlet_w, outlet_d]);
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
        
}

module pidbox() {
    translate([-pidbox_h / 2, -pidbox_w / 2, 0])
        cube([pidbox_h, pidbox_w, pidbox_d]);
}

module pidbox_plate(width=pidbox_h + 20, height=pidbox_h + 20) {
    difference() {
        translate([-height / 2, -width / 2])
            cube([height, width, face_d]);
        translate([-pidbox_h / 2, -pidbox_w / 2, 0])
            cube([pidbox_h, pidbox_w, face_d]);
        translate([-pidbox_h/2 + 2.3, -pidbox_w/2 - 4.5, 0])
            cylinder(h=2 * face_d, r=pidbox_hole_od/2);
        translate([pidbox_h/2 - 2.3, pidbox_w/2 + 4.5, 0])
            cylinder(h=2 * face_d, r=pidbox_hole_od/2);
    }
    *% translate([0, 0, face_d])
    import("mounting_bracket_v1.stl");
    
}


module outlet_plate(width=outlet_w + 10, height=outlet_screw_c_c + 10) {
    
    
    difference() {
        translate([-height / 2, -width / 2, 0]) 
            cube([height, width, face_d]);
        cylinder(r=outlet_screw_od/2, h=face_d);
        translate([outlet_center / 2, -outlet_w / 2, 0])
            plug();
        translate([-outlet_center / 2 - plug_h, -outlet_w / 2, 0])
            plug();
        translate([outlet_screw_c_c / 2, 0, 0])
            cylinder(h=face_d, r=outlet_screw_od/2);
        translate([-outlet_screw_c_c / 2, 0, 0])
            cylinder(h=face_d, r=outlet_screw_od/2);
    }
}

module spool() {
    difference() {
        union() {
            cylinder(h=spool_rim_h, r=spool_od / 2);
            cylinder(h=spool_h, r=spool_oid / 2);
            translate([0, 0, spool_h - spool_rim_h])
                cylinder(h=spool_rim_h, r=spool_od / 2);
        }
        cylinder(h=spool_h, r=spool_id / 2);
    }
}
