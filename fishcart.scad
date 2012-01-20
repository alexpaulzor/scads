module cart() {
	union() {
		difference() {
			translate([-30, 2, 2]) rotate(90, [0, 1, 0]) cylinder(r=2,h=80);
			cube([20, 20, 20]);
		}
		difference() {
			cube([20, 20, 15]);
			translate([3, 3, 3]) cube([14, 14, 18]);
			translate([-2, 20, 0]) rotate(45, [1, 0, 0])  cube([30, 30, 30]);
		}
	}
}
cart();
translate([0, 22, 0]) cart();
translate([0, 43, 0]) cart();
translate([0, 64, 0]) cart();

module clip() {
	union() {
		difference() {
			cube([5, 100, 10]);
			translate([-1, 4, 4]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
		}
		translate([-5, 12, 0]) difference() {
			cube([5, 17, 10]);
			translate([-1, 12, 4]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
		}
	}
}

//translate([-8, 0, 0]) clip();
/*translate([12, 0, 0]) clip();
translate([24, 0, 0]) clip();
translate([0, 40, 0]) clip();
translate([12, 40, 0]) clip();
translate([24, 40, 0]) clip();
*/

module puller() {
	difference() {
		union() {
				difference() {
				translate([0, -7, 0]) cube([5, 68, 10]);
				translate([-1, 4, 4]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
				translate([-1, 26, 5]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
				translate([-1, 47, 5]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
			}
			translate([-5, 56, 0]) difference() {
				cube([5, 17, 10]);
				translate([-1, 12, 5]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
			}
			translate([60, 0, 0]) difference() {
				translate([0, -7, 0]) cube([5, 68, 10]);
				translate([-1, 5, 5]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
				translate([-1, 26, 5]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
				translate([-1, 47, 5]) rotate(90, [0, 1, 0]) cylinder(r=3, h=10);
			}
			translate([0, -12, 0]) cube([65, 5, 10]);
		}
		translate([55/2, -5, 5]) rotate(90, [1, 0, 0]) cylinder(r=2, h=10);
	}
}

translate([-16, 0, 0]) 
puller();
		