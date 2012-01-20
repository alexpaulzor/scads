intersection() {
//translate([5, -7, -1]) rotate(45, [0, 0, 1]) cube([100, 100, 100]);
//#translate([-1, -1, -1]) cube([30, 200, 50]);

#difference() {
union () {
 cube([6, 102, 13]);
 translate([6, 0, 0]) cube([131-6, 102, 13]);


translate([0, 102, 0]) {
	difference () {
		cube([120, 25, 6]);
		translate([120, 0, -1]) rotate(45, [0, 0, 1]) cube([35, 35, 8]);
	}
}
#translate([6, 102, 6]) difference() {
	cube([16, 3, 7]);	
	translate([7, 0, 3]) cube([5, 4, 5]);
}
translate([131, 54, 4]) cube([5, 7, 3]);
}

translate([131 - 12, -1, -1]) cube([13, 42, 15]);

#translate([0, -1, 8]) rotate(-50, [0, 1, 0]) cube([8, 104, 5]);
}
//# translate([-1, -1, -1]) cube([110, 110, 40]);
}
//# rotate(45, [0, 0, 1]) cube([100, 100, 100]);
