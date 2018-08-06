$fn=30;
module sewcircle_end(id=10, h=3) {
    difference() {
        rotate_extrude()
            translate([id/2, 0, 0])
                circle(r=h/2);
        translate([-id, -id, -h])
            cube([2*id, id, 2*h]);
    }
}

module sewcircle(id=10, h=3, l=30) {
    sewcircle_end();
    translate([0, -l, 0])
        mirror([0, 1, 0])
        sewcircle_end();
    translate([0, -l/2, 0])
        rotate_extrude()
            translate([id/2, 0, 0])
                circle(r=h/2);
    translate([-id/2, 0, 0])
        rotate([90, 0, 0])
        cylinder(h=l, r=h/2);
    translate([id/2, 0, 0])
        rotate([90, 0, 0])
        cylinder(h=l, r=h/2);
}
sewcircle(10, 3);