
finger_w = 10;

dw12v_iw = 36;
dw12v_full_h = 6.5;
dw12v_full_h_depth = 20;
dw12v_short_h = 5;
dw12v_short_h_depth = 32;


module snub_cylinder(r=5, h=3, $fn=32, corner_r=1) {
    minkowski() {
        cylinder(r=r-corner_r, h=h, $fn=32);
        sphere(r=corner_r);
    }
}

// !snub_cylinder();

module dw_mount(
        iw, full_h, full_h_depth, short_h, 
        short_h_depth, finger_w) {
    difference() {
        union() {
            translate([-iw/2 - finger_w, -20, 0])
                cube([
                    iw + 2 * finger_w, 
                    20, 
                    full_h]);
            translate([-iw/2 - finger_w, 0, 0])
                cube([
                    iw + 2 * finger_w, 
                    short_h_depth, 
                    short_h]);
            translate([-iw/2 - finger_w, -0.3, full_h/2])
                rotate([-3, 0, 0])
                    cube([
                        iw + 2 * finger_w, 
                        short_h_depth-1, 
                        full_h/2]);
        }
        translate([-iw/2, 0, -1])
            cube([
                iw, 
                short_h_depth + 1, 
                full_h+2]);
        for (i=[-1, 0, 1]) {
            translate([i * 20, -10, -0.1]) {
                cylinder(r=5/2, h=full_h+0.2, $fn=32);
                // cylinder(r=5, h=3, $fn=32);
                snub_cylinder(r=5, h=3, $fn=32);
            }
        }
    }
}

module dw12v_mount() {
    dw_mount(
        dw12v_iw, dw12v_full_h, dw12v_full_h_depth, 
        dw12v_short_h, dw12v_short_h_depth, finger_w);
}


dw12v_mount();
