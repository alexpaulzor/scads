module cart() {
	union() {
		difference() {
			translate([-20, 3, 3]) rotate(90, [0, 1, 0]) cylinder(r=3,h=60);
			cube([20, 20, 20]);
		}
		difference() {
			cube([20, 20, 15]);
			translate([3, 3, 3]) cube([14, 14, 18]);
			translate([-2, 20, 0]) rotate(45, [1, 0, 0])  cube([30, 20, 20]);
		}
	}
}
cart();
translate([0, 20, 0]) cart();
translate([0, 40, 0]) cart();

module clip() {
	union() {
		difference() {
			cube([5, 17, 10]);
			translate([-1, 5, 5]) rotate(90, [0, 1, 0]) cylinder(r=4, h=10);
		}
		translate([-5, 12, 0]) difference() {
			cube([5, 17, 10]);
			translate([-1, 12, 5]) rotate(90, [0, 1, 0]) cylinder(r=4, h=10);
		}
	}
}

translate([-6, -1 ,-2]) clip();