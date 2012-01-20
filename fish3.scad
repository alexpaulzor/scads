



union () {
	difference() {
		cylinder(r=5,h=64);
		translate([1.25, 1.25, 56]) cube([10, 10, 10]);
		translate([1.25, -11.25, 56]) cube([10, 10, 10]);
		translate([-11.25, 1.25, 56]) cube([10, 10, 10]);
		translate([-11.25, -11.25, 56]) cube([10, 10, 10]);
	}
	
	translate([0, 0, 28])
		linear_extrude(height = 40, center = true, twist = 3*360)
			translate([4, 0, 0])
				square([8,8]);
	

}