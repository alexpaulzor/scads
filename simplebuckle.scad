difference() {
	cube([26+8, 4+5+4+5+4, 4]);
	translate([4, 4, -1]) cube([26, 5, 6]);
	translate([4, 4+5+4, -1]) cube([26, 5, 6]);
}