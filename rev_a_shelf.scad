
IN_MM = 25.4;
tray_bounds_w = 260;
tray_bounds_h = 90;
tray_bounds_d = 35;

tray_corner_r = 5;
tray_th = 2;

tray_w = tray_bounds_w - 2 * tray_corner_r - 2*tray_th;
tray_h = tray_bounds_h - 2 * tray_corner_r - 2*tray_th;
tray_d = tray_bounds_d - 2 * tray_corner_r - 2*tray_th;

module rev_a_tray() {
    difference() {
        minkowski() {
            cube([tray_w, tray_d, tray_h]);
            sphere(r=tray_corner_r + tray_th);
        }

        minkowski() {
            cube([tray_w, tray_d, tray_h*2]);
            sphere(r=tray_corner_r);
        }

        translate([-tray_w/2, tray_d*3/2, tray_h/4])
            rotate([30, 0, 0])
            cube([tray_w*2, tray_d*2, tray_h]);

        translate([tray_w - IN_MM, 0, tray_h- IN_MM])
            rotate([90, 0, 0])
            cylinder(r=tray_corner_r, h=2*tray_d, center=true);
        translate([IN_MM, 0, tray_h- IN_MM])
            rotate([90, 0, 0])
            cylinder(r=tray_corner_r, h=2*tray_d, center=true);
        for (dz=[0:5]) {
            translate([tray_w - IN_MM, 0, tray_h- IN_MM + dz*tray_corner_r/2])
                rotate([90, 0, 0])
                cylinder(r=tray_corner_r/2, h=2*tray_d, center=true);
            translate([IN_MM, 0, tray_h- IN_MM + dz*tray_corner_r/2])
                rotate([90, 0, 0])
                cylinder(r=tray_corner_r/2, h=2*tray_d, center=true);
        }
    }
}

// rev_a_tray();


bearing_h = 7;
bearing_ir = 4;
bearing_or = 11;
module bearing(clr=0.2) {
    // difference() {
        # cylinder(r2=bearing_or, r1=bearing_or + clr, h=bearing_h+1, center=true, $fn=128);
        // cylinder(r=bearing_ir, h=bearing_h*2, center=true);
    // }
}

roller_or = 25;

module roller() {
    difference() {
        union() {
            rotate_extrude($fn=64) {
                translate([roller_or - bearing_h/2, 0, 0])
                    circle(r=bearing_h/2, $fn=64);
            }
            translate([0, 0, -bearing_h/2 + 1])
                cylinder(r=roller_or - bearing_h/2, h=2, center=true);
            cylinder(r=bearing_or + 2, h=bearing_h, center=true);
        }
        bearing();
    }
}

// ! roller();
