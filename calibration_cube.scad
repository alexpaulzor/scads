module ccube(s=15) {
    difference() {
        cube([s, s, s], center=true);
        # rotate([0, 90, 0])
            cylinder(r1=s/3, r2=s/10, h=s+1, center=true, $fn=64);
        cylinder(r=s/3, h=2*s, center=true, $fn=64);
    }
}

ccube();
