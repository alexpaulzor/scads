IN_MM = 25.4;

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
    
}

camera_l = 20; // TODO: measure
camera_w = 100; // TODO: measure
camera_h = 20; // TODO: measure
camera_r = 10; // TODO: measure
cam_board_th = 2;


module camera() {
    cube([camera_l, camera_w, cam_board_th], center=true);
    cylinder(r=camera_r, h=camera_h);
    translate([0, camera_w/2 - camera_r, 0])
        cylinder(r=camera_r, h=camera_h);
    translate([0, -camera_w/2 + camera_r, 0])
        cylinder(r=camera_r, h=camera_h);
}

module housing() {
    
}

% translate(enclosure_offset)
    food_bowl();

module animated_enclosure() {
    rotate([0, abs(90 - $t * 180), 0])
        translate(enclosure_offset) {
            enclosure();
        }
}
animated_enclosure();
rotate([0, -45, 0])
    translate([0, 0, camera_h])
    camera();