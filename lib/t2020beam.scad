t2020_w = 20;
t2020_notch_w = 6;
t2020_notch_d = 6;
t2020_hole_ir = 5/2;

module t2020(length=100) {
    translate([0, 0, -length/2])
    linear_extrude(length) {
        difference() {
            square([t2020_w, t2020_w], center=true);
            for (i=[0:3]) {
                rotate([0, 0, 90 * i]) {
                    translate([t2020_w/2 - t2020_notch_d / 2, 0, 0]) {
                        square([t2020_notch_d, t2020_notch_w], center=true);
                    }
                }
            }
            circle(r=t2020_hole_ir);
        }
    }
}

module t2020_hole(length) {
    t2020(length);
    cube([t2020_w - 2, t2020_w - 2, length+1], center=true);
}
