
acdc_w = 26;
acdc_h = 51;
acdc_d = 26;
acdc_clr = 3;
acdc_th = 2;
acdc_hole_c_c = [21, 46];
acdc_hole_ir = 3/2;

module acdc_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*acdc_hole_c_c[0],
			y*acdc_hole_c_c[1], 0])
		cylinder(h=60, r=acdc_hole_ir, center=true, $fn=32);
}

module acdc() {
	difference() {
		union() {
			translate([0, 0, acdc_th/2])
				cube([acdc_w, acdc_h, acdc_th], center=true);
			translate([0, 0, acdc_d/2])
				cube([acdc_w-3, acdc_h-3, acdc_d], center=true);
		}
		acdc_holes();
	}
}

// ! acdc();


tblock_w = 136;
tblock_h = 35;
tblock_d = 16;
tblock_clr = 0;
tblock_th = 16;
tblock_hole_c_c = [124, 13.25];
tblock_hole_ir = 5/2;

module tblock_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*tblock_hole_c_c[0],
			y*tblock_hole_c_c[1], 0])
		cylinder(h=60, r=tblock_hole_ir, center=true, $fn=32);
}

module tblock() {
	difference() {
		union() {
			translate([0, 0, tblock_th/2])
				cube([tblock_w, tblock_h, tblock_th], center=true);
			translate([0, 0, tblock_d/2])
				cube([tblock_w-3, tblock_h-3, tblock_d], center=true);
		}
		tblock_holes();
	}
}

// ! tblock();

arduino_w = 70;
arduino_h = 51;
arduino_d = 20;
arduino_clr = 3;
arduino_th = 2;
arduino_hole_c_c = [66, 46];
arduino_hole_ir = 3/2;

module arduino_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*arduino_hole_c_c[0],
			y*arduino_hole_c_c[1], 0])
		cylinder(h=60, r=arduino_hole_ir, center=true, $fn=32);
}

module arduino() {
	difference() {
		union() {
			translate([0, 0, arduino_th/2])
				cube([arduino_w, arduino_h, arduino_th], center=true);
			translate([0, 0, arduino_d/2])
				cube([arduino_w-3, arduino_h-3, arduino_d], center=true);
		}
		arduino_holes();
	}
}

// ! arduino();

relay2_w = 40;
relay2_h = 50;
relay2_d = 17;
relay2_clr = 3;
relay2_th = 2;
relay2_hole_c_c = [34, 45];
relay2_hole_ir = 3/2;

module relay2_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*relay2_hole_c_c[0],
			y*relay2_hole_c_c[1], 0])
		cylinder(h=50, r=relay2_hole_ir, center=true, $fn=32);
}

module relay2() {
	difference() {
		union() {
			translate([0, 0, relay2_th/2])
				cube([relay2_w, relay2_h, relay2_th], center=true);
			translate([0, 0, relay2_d/2])
				cube([relay2_w-3, relay2_h-3, relay2_d], center=true);
		}
		relay2_holes();
	}
}

// ! relay2();

relay4_w = 74;
relay4_h = 50;
relay4_d = 17;
relay4_clr = 3;
relay4_th = 2;
relay4_hole_c_c = [68, 45];
relay4_hole_ir = 3/2;

module relay4_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*relay4_hole_c_c[0],
			y*relay4_hole_c_c[1], 0])
		cylinder(h=50, r=relay4_hole_ir, center=true, $fn=32);
}

module relay4() {
	difference() {
		union() {
			translate([0, 0, relay4_th/2])
				cube([relay4_w, relay4_h, relay4_th], center=true);
			translate([0, 0, relay4_d/2])
				cube([relay4_w-3, relay4_h-3, relay4_d], center=true);
		}
		relay4_holes();
	}
}

// ! relay4();

lcd_2004_w = 99;
lcd_2004_h = 60;
lcd_2004_d = 10;
lcd_2004_clr = 15;
lcd_2004_th = 2;
lcd_2004_face_h = 40;
lcd_2004_hole_c_c = [93, 55];
lcd_2004_hole_ir = 3.5/2;

module lcd_2004_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*lcd_2004_hole_c_c[0],
			y*lcd_2004_hole_c_c[1], -10])
		cylinder(h=20, r=lcd_2004_hole_ir, center=false, $fn=20);
}

module lcd_2004() {
	difference() {
		union() {
			translate([0, 0, lcd_2004_th/2])
				cube([lcd_2004_w, lcd_2004_h, lcd_2004_th], center=true);
			translate([0, 0, lcd_2004_d/2])
				cube([lcd_2004_w, lcd_2004_face_h, lcd_2004_d], center=true);
		}
		lcd_2004_holes();
	}
}

// ! lcd_2004();

bbox_size = [250, 150, 100];

bbox_holes = [
	[-64, 10],
	[64, 10],
	[-197/2, 112],
	[197/2, 112],
	[-30, 112],
	[30, 112],
];
bbox_hole_r = 5/2;

module breaker_box_holes() {
	for (p=bbox_holes) {
		translate([p[0], bbox_size[1]/2-p[1], 0])
			cylinder(r=bbox_hole_r, h=bbox_size[2]*2, center=true, $fn=32);
	}
}

// breaker_box_holes();

module breaker_box() {
	% difference() {
		translate([0, 0, -bbox_size[2]/2-1]) 
			cube([bbox_size[0], bbox_size[1], 2], center=true);
		breaker_box_holes();
	}
}

// % breaker_box();

bbox_mount_th = 2;

module breaker_box_mount() {
	difference() {
		union() {
			for (p=bbox_holes) {
				translate([p[0], 150/2-p[1], 0])
					cylinder(r=bbox_hole_r*2, h=bbox_mount_th, center=false, $fn=32);
			}
			translate([-100, bbox_size[1]/2 - bbox_holes[2][1] - 5, 0])
				cube([200, 10, bbox_mount_th], center=false);
			translate([bbox_holes[0][0], bbox_size[1]/2 - bbox_holes[0][1] - 5, 0])
				cube([abs(bbox_holes[0][0]*2), 10, bbox_mount_th], center=false);
			translate([bbox_holes[0][0], bbox_size[1]/2 - bbox_holes[0][1], 0])
				rotate([0, 0, -108.5])
				translate([54, 0, bbox_mount_th/2])
				cube([108, 10, bbox_mount_th], center=true);
			translate([bbox_holes[0][0], bbox_size[1]/2 - bbox_holes[0][1], 0])
				rotate([0, 0, -71.5])
				translate([54, 0, bbox_mount_th/2])
				cube([108, 10, bbox_mount_th], center=true);
			translate([bbox_holes[1][0], bbox_size[1]/2 - bbox_holes[1][1], 0])
				rotate([0, 0, -108.5])
				translate([54, 0, bbox_mount_th/2])
				cube([108, 10, bbox_mount_th], center=true);
			translate([bbox_holes[1][0], bbox_size[1]/2 - bbox_holes[1][1], 0])
				rotate([0, 0, -71.5])
				translate([54, 0, bbox_mount_th/2])
				cube([108, 10, bbox_mount_th], center=true);
			translate([-85, 11.5, 0])
				cube([170, 10, bbox_mount_th], center=false);
			translate([-62, -50, bbox_mount_th/2])
				cube([10, 30, bbox_mount_th], center=true);
			translate([62, -50, bbox_mount_th/2])
				cube([10, 30, bbox_mount_th], center=true);
			
		}
		breaker_box_holes();
	}
}

// breaker_box_mount();

// intermatic_w = 123;
// intermatic_l = 150;
// intermatic_d = 30;
// intermatic_h = 70;
// intermatic_th = 2;
// notch_w = 5;
// notch_h = 20;

// module intermatic_face() {
// 	difference() {
// 		cube([intermatic_w, intermatic_l, intermatic_th]);
// 		for (x=[0, intermatic_w]) 
// 			for (y=[0, intermatic_l])
// 				translate([x, y, intermatic_th/2-1])
// 				rotate([0, 0, 45])
// 					cube([notch_h, notch_h, intermatic_th+3], center=true);
// 		translate([intermatic_w - notch_w, intermatic_l - 78 - notch_h, -1])
// 			cube([notch_w, notch_h, intermatic_th+2]);
// 		translate([0, intermatic_l - 78 - notch_h, -1])
// 			cube([notch_w, notch_h, intermatic_th+2]);
// 		translate([21, intermatic_l - notch_w, -1])
// 			cube([30, notch_w, intermatic_th+2]);
// 		// translate([intermatic_w/2, intermatic_l/2, intermatic_th/2-1])
// 		// 	cube([104, 130, intermatic_th+3], center=true);
// 	}
// }

// module front_face() {
// 	difference() {
// 		translate([-intermatic_w/2, -intermatic_l/2, 0])
// 		intermatic_face();
// 		translate([0, 40, -lcd_2004_th]) {
// 			# lcd_2004();
// 			lcd_2004_holes();
// 		}
// 	}
// }

// module back_face() {
// 	difference() {
// 		translate([-intermatic_w/2, -intermatic_l/2, 0])
// 		intermatic_face();
// 		translate([-relay4_h/2-1, -relay4_w/2-1, intermatic_th+relay4_clr])
// 			rotate([0, 0, 90]) {
// 				% relay4();
// 				relay4_holes();
// 			}
// 		translate([relay4_h/2+1, -8, intermatic_th+relay4_clr])
// 			rotate([0, 0, 90]) {
// 				% relay4();
// 				relay4_holes();
// 			}
// 		translate([-relay2_h/2-1, relay2_w/2+1, intermatic_th+relay2_clr])
// 			rotate([0, 0, 90]) {
// 				% relay2();
// 				relay2_holes();
// 			}
// 		// translate([acdc_h/2, acdc_w/2, intermatic_th])
// 		translate([acdc_h/2+1, -60, intermatic_th+acdc_clr])
// 			rotate([0, 0, 90]) {
// 				% acdc();
// 				acdc_holes();
// 			}
// 	}
// }

module electronics() {
	translate(valve_relay_offset)
		% relay4();
	translate(pump_relay_offset)
		% relay4();
	translate(clean_relay_offset)
		rotate(clean_relay_rotation)
		% relay2();
	translate(acdc_offset)
		% acdc();
	translate(tblock_offset)
		% tblock();
	translate(arduino_offset)
		% arduino();
}

// ! electronics();

electronics_holes = [
	relay2_hole_c_c,
	relay4_hole_c_c,
];
electronics_hole_r = 3/2;

module electronics_holes(p, ir=electronics_hole_r) {
	translate([p[0]/2, p[1]/2, 5/2])
		cylinder(r=ir, h=6, center=true, $fn=32);
	translate([p[0]/2, -p[1]/2, 5/2])
		cylinder(r=ir, h=6, center=true, $fn=32);
	translate([-p[0]/2, p[1]/2, 5/2])
		cylinder(r=ir, h=6, center=true, $fn=32);
	translate([-p[0]/2, -p[1]/2, 5/2])
		cylinder(r=ir, h=6, center=true, $fn=32);
}

module electronics_mount(p, ir=electronics_hole_r, or=5) {
	difference() {
		union() {
			translate([p[0]/2, p[1]/2, 5/2])
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			translate([-p[0]/2, p[1]/2, 5/2])
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			translate([p[0]/2, -p[1]/2, 5/2])
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			translate([-p[0]/2, -p[1]/2, 5/2])
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
		}
		# electronics_holes(p);
	}
}

acdc_offset = [0, -8, 0];
tblock_offset = [0, -57, 0];
arduino_offset = [-25, 46, 0];
pump_relay_offset = [52.5, -8, 0];
valve_relay_offset = [-52.5, -8, 0];
clean_relay_offset = [36, 40, 0];
clean_relay_rotation = [0, 0, 90];

module box_plate() {
	% translate([0, 0, -bbox_size[2]/2+5])
		electronics();
	difference() {
		union() {
			translate([0, 0, -bbox_size[2]/2]) {
				breaker_box_mount();
				translate(pump_relay_offset)
					electronics_mount(relay4_hole_c_c);	
				translate(valve_relay_offset)
					electronics_mount(relay4_hole_c_c);	
				translate(clean_relay_offset)
					rotate(clean_relay_rotation)
					electronics_mount(relay2_hole_c_c);	
				translate(acdc_offset)
					electronics_mount(acdc_hole_c_c);
				translate(tblock_offset)
					electronics_mount(tblock_hole_c_c);
				translate(arduino_offset)
					electronics_mount(arduino_hole_c_c);	
			}
		}
		translate([0, 0, -bbox_size[2]/2]) {
			translate(pump_relay_offset)
				electronics_holes(relay4_hole_c_c);
			translate(valve_relay_offset)
				electronics_holes(relay4_hole_c_c);	
			translate(clean_relay_offset)
				rotate(clean_relay_rotation)
				electronics_holes(relay2_hole_c_c);	
			translate(acdc_offset)
				electronics_holes(acdc_hole_c_c);
			translate(tblock_offset)
				electronics_holes(tblock_hole_c_c);
			translate(arduino_offset)
				electronics_holes(arduino_hole_c_c);
		}
	}
	// translate([-intermatic_w/2, -intermatic_l/2, 0])
	// 	intermatic_face();
	// translate([0, 0, intermatic_h/2])
	// 	front_face();
	// translate([0, 0, -intermatic_d])
	// 	back_face();
	// % translate([0, 0, -intermatic_d])
	// 	cube([intermatic_w, intermatic_l, intermatic_d]);
	// % translate([0, 0, 0])
	// 	cube([intermatic_w, intermatic_l, intermatic_h]);
}

box_plate();
// % breaker_box();

module box_plate_short() {
	intersection() {
		box_plate();
		translate([0, 0, -bbox_size[2]/2 + 1])
			cube([250, 250, 1], center=true);
	}
}

// box_plate_short();

// TODO: measure toggle switch
// TODO: model face plate