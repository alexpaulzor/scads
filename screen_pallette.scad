leds_x = 216;
leds_y = 376;
screen_x = 332;
screen_y = 420;


// generates aluminum L stock <length> along the X axis
module lstock(length) {
	cube([length, 19, 1.5]);
	cube([length, 1.5, 19]);
}

module leds() {
	//pcb
	#cube([leds_x, leds_y, 2]);

	//short side A
	translate([-1.5, -1.5, -1.5]) {
		difference() {
			lstock(leds_x + 3);
			translate([-1, -1, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
			translate([leds_x + 3, 0, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
		}
	}

	//long side B
	translate([-1.5, leds_y + 1.5, -1.5]) {
		rotate(-90, [0, 0, 1]) {
			difference() {
				lstock(leds_y + 3);
				translate([-1, -1, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
				translate([leds_y + 3, 0, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
			}
		}
	}

	//short side C
	translate([leds_x + 1.5, leds_y + 1.5, -1.5]) {
		rotate(180, [0, 0, 1]) {
			difference() {
				lstock(leds_x + 3);
				translate([-1, -1, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
				translate([leds_x + 3, 0, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
			}
		}
	}

	//long side D
       translate([leds_x + 1.5, -1.5, -1.5]) {
		rotate(90, [0, 0, 1]) {
			difference() {
				lstock(leds_y + 3);
				translate([-1, -1, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
				translate([leds_y + 3, 0, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
			}
		}
	}
}

leds();