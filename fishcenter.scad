difference() {
	cylinder(r=19,h=15);
	translate([11.5, 0, -1]) cylinder(r=13/2,h=17);
	translate([-1.25, -3, -1]) cube([2.5, 6, 17]);
	translate([-3, -1.25, -1]) cube([6,2.5, 17]);
}