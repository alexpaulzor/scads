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
	cube([leds_x, leds_y, 2]);
	difference() {
		lstock(leds_x);
		# translate([-1, -1, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
		 #translate([leds_x, 0, -1]) rotate(45, [0, 0, 1]) cube([30, 30, 30]);
	}
}

leds();