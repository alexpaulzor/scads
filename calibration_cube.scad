module ccube(s=15) {
    difference() {
        cube([s, s, s], center=true);
        # rotate([0, 90, 0])
            cylinder(r1=s/3, r2=s/10, h=s+1, center=true, $fn=64);
        cylinder(r=s/3, h=2*s, center=true, $fn=64);
    }
}

// ccube();


module laser_test() {
    difference() {
        square([25.4, 25.4], center=true);
        square([10, 10], center=true);
        translate([0, 7, 0])
            text("1 cm", size=2.5, halign="center");
        translate([0, -11, 0])
            text("5em", size=5, halign="center");
        translate([-9, -10])
            square([1, 1], center=true);
        translate([-9, -5])
            square([1.5, 1.5], center=true);
        translate([-9, -8])
            square([2, 1], center=true);
        translate([-9, -1])
            square([2, 2], center=true);
        translate([-9, 3])
            square([3, 3], center=true);
        translate([-9, 8])
            square([4, 4], center=true);
    }
    difference() {
        square([5, 5], center=true);  
        translate([0, 0, 0])
            text("5 mm", size=1.25, halign="center"); 
    }
    
    // translate([15, 0])
    //     square([5, 5]);
    // translate([15, 7.5])
    //     square([5, 5]);
    translate([0, 15, 0])
        text("1 in", halign="center");
    translate([0, -21, 0])
        text("7 em", size=7, halign="center");
    
}

laser_test();
