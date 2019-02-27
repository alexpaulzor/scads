IN_MM = 25.4;
$fn=32;

wall_th = 2;
bowl_r = 3 * IN_MM; // TODO: measure
bowl_h = 3 * IN_MM; // TODO: measure
module food_bowl() {
    cylinder(r=bowl_r, h=bowl_h);
}

enclosure_th = 3;
enclosure_axle_r = 2;
sphere_r = sqrt(bowl_r * bowl_r + bowl_h * bowl_h) + enclosure_th;
enclosure_pivot_offset = 2 * sphere_r - enclosure_th - enclosure_axle_r;
enclosure_offset = [-enclosure_pivot_offset, 0, -sphere_r/4];
module enclosure() {
    difference() {
        union() {
            sphere(r=sphere_r + enclosure_th);
            translate([sphere_r, sphere_r/2, sphere_r/4])
                cube(
                    [2*sphere_r, enclosure_th, sphere_r/2],
                    center=true);
            translate([sphere_r, -sphere_r/2, sphere_r/4])
                cube(
                    [2*sphere_r, enclosure_th, sphere_r/2],
                    center=true);
        }
        sphere(r=sphere_r);
        translate([0, 0, -sphere_r / 2 - enclosure_th])
            cube([
                2 * (sphere_r + enclosure_th), 
                2 * (sphere_r + enclosure_th), 
                sphere_r + enclosure_th * 2], 
                center=true);
        translate([
            enclosure_pivot_offset,
            0,
            sphere_r / 4])
            rotate([90, 0, 0])
                cylinder(r=enclosure_axle_r, h=2*sphere_r, center=true);
    }
}

module servo() {
    
}

module rpi() {
    import("Raspberry_Pi_3_Light_Version.STL");
}

camera_l = 20; // parallel to ribbon
camera_w = 74;
camera_h = 30; // back of board to tip of lens
camera_lens_r = 16/2;
cam_board_th = 8;
ribbon_offset = 5;
ribbon_tab_w = 25;
ribbon_tab_l = 5;
ribbon_w = 16;
ribbon_l = 20;
ribbon_h = 2;
ir_h = 20;
ir_or = camera_l / 2;
sensor_or = 7 / 2;
sensor_h = 14;
tab_w = 5;

cam_enc_l = camera_l + ribbon_tab_l + 2 * wall_th;
cam_enc_w = camera_w + 2 * wall_th;

module camera() {
    translate([0, 0, cam_board_th/2])
        cube([camera_l, camera_w - camera_l, cam_board_th], center=true);
    translate([camera_l / 2 + ribbon_tab_l / 2, 0, cam_board_th/2])
        cube([ribbon_tab_l, ribbon_tab_w, cam_board_th], center=true);
    translate([0, 0, 0])
        cylinder(r=camera_lens_r, h=camera_h);
    translate([0, camera_w / 2 - camera_l / 2, 0])
        cylinder(r=camera_l/2, h=ir_h);
    translate([0, -camera_w / 2 + camera_l / 2, 0])
        cylinder(r=camera_l/2, h=ir_h);
    # translate([camera_l / 2 + ribbon_l / 2, 0, ribbon_offset])
        cube([ribbon_l, ribbon_w, ribbon_h], center=true);
    translate([camera_l / 2 - sensor_or, camera_w / 2 - ir_or - sqrt(4*ir_or*sensor_or), 0])
        cylinder(r=sensor_or, h=sensor_h);
    translate([-camera_l / 2 + sensor_or, -camera_w / 2 + ir_or + sqrt(4*ir_or*sensor_or), 0])
        cylinder(r=sensor_or, h=sensor_h);
    * camera_holes();
}
module camera_holes() {
    for (side=[1, -1]) {
        for (l=camera_hole_offsets_l) {
            translate([l - camera_l / 2, side * (camera_w / 2 - camera_hole_offset_w), 0]) {
                cylinder(r=camera_hole_or, h=2*camera_h, center=true);
            }
        }
    }
    
    translate([-camera_l / 2 - ribbon_l / 2, 0, ribbon_offset])
        cube([ribbon_l, ribbon_w, ribbon_h], center=true);
}

cam_hinge_or = 4/2;

module hinge_tab() {
    difference() {
        union() {
            cube([2 * tab_w, tab_w, 2 * cam_board_th]);
        }
        
        translate([tab_w, 0, cam_board_th])
            rotate([90, 0, 0])
            cylinder(r=cam_hinge_or, h=camera_w, center=true);
    }
}

module cam_enc_bottom() {
    difference() {
        translate([ribbon_tab_l / 2, 0, 0])
            cube([cam_enc_l, cam_enc_w, cam_board_th], center=true);
        
        # camera();
    }
    translate([cam_enc_l / 2 + ribbon_tab_l / 2, -cam_enc_w/2, -cam_board_th/2])
        hinge_tab();
    translate([cam_enc_l / 2 + ribbon_tab_l / 2, cam_enc_w/2 - 2 * tab_w, -cam_board_th/2])
        hinge_tab();
    translate([-cam_enc_l / 2 + ribbon_tab_l / 2 - 2*tab_w, -tab_w / 2, -cam_board_th/2])
        hinge_tab();
}

module cam_enc_top() {
    difference() {
        translate([ribbon_tab_l / 2, 0, cam_board_th])
            cube([cam_enc_l, cam_enc_w, cam_board_th], center=true);
        # camera();
    }
    translate([cam_enc_l / 2 + ribbon_tab_l / 2, -cam_enc_w/2 + tab_w, -cam_board_th/2])
        hinge_tab();
    translate([cam_enc_l / 2 + ribbon_tab_l / 2, cam_enc_w/2 - tab_w, -cam_board_th/2])
        hinge_tab();
    translate([-cam_enc_l / 2 + ribbon_tab_l / 2 - 2*tab_w, +tab_w / 2, -cam_board_th/2])
        hinge_tab();
}

module cam_enclosure() {
    cam_enc_bottom();
    cam_enc_top();
}

% translate([0, 0, 50])
    cam_enclosure();

translate([-40, 5, cam_board_th])
    rotate([0, 180, 0])
        cam_enc_top();
cam_enc_bottom();

module animated_enclosure() {
    % translate(enclosure_offset)
        food_bowl();
    rotate([0, abs(90 - $t * 180), 0])
        translate(enclosure_offset) {
            enclosure();
        }
}
* animated_enclosure();

