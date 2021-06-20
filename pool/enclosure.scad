
IN_MM = 25.4;

tall_standoff_h = 55;
tall_standoff_threads = 6;
tall_standoff_or = 3;

module tall_standoff() {
	cylinder(r=tall_standoff_or, h=tall_standoff_h);
	translate([0, 0, -tall_standoff_threads])
		cylinder(r=tall_standoff_or/2, h=tall_standoff_threads);
}

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

toggle_sw_body = [19, 34, 28];
toggle_or = 13/2;
toggle_thread_h = 13;
toggle_top_h = 30;
toggle_top_or = 3;

module toggle_switch() {
	translate([0, 0, -toggle_sw_body[2]/2])
		cube(toggle_sw_body, center=true);
	cylinder(r=toggle_or, h=toggle_thread_h);
	cylinder(r=toggle_top_or, h=toggle_top_h);
}

// ! toggle_switch();

module toggle_cage() {
	difference() {
		translate([-17/2, -6-8, 0])
			cube([17, 41, 2], center=false);
		* translate([-17/2, -6-8-6, 0])
			cube([17, 47, 30], center=false);
		toggle_switch();

	}
}

module stop_sw_face() {
	difference() {
		union() {
			translate([0, 0, relay4_th/2])
				cube([relay4_w, relay4_h, relay4_th], center=true);
			
		}
		translate([-13, 0, 0]) {
			# toggle_switch();
			% translate([0, 0, relay4_th])
				toggle_cage();
			translate([0, -15, -1])
				linear_extrude(4)
				text(
					"HEAT", 
					font="Helvetica:style=Negreta", 
					size=6, halign="center", valign="top");
			translate([-10, 10, -1])
				linear_extrude(4)
				text(
					"HIGH", 
					font="Helvetica:style=Negreta", 
					size=4, halign="right", valign="center");
			translate([-10, -10, -1])
				linear_extrude(4)
				text(
					"LOW", 
					font="Helvetica:style=Negreta", 
					size=4, halign="right", valign="center");
			translate([-10, 0, -1])
				linear_extrude(4)
				text(
					"OFF", 
					font="Helvetica:style=Negreta", 
					size=4, halign="right", valign="center");
		}
		translate([13, 0, 0]) {
			# toggle_switch();
			% translate([0, 0, relay4_th])
				toggle_cage();
			translate([0, -15, -1])
				linear_extrude(4)
				text(
					"PUMP", 
					font="Helvetica:style=Negreta", 
					size=6, halign="center", valign="top");
			translate([10, -10, -1])
				linear_extrude(4)
				text(
					"RUN", 
					font="Helvetica:style=Negreta", 
					size=4, halign="left", valign="center");
			translate([9, 10, -1])
				linear_extrude(4)
					text(
					"STOP", 
					font="Helvetica:style=Negreta", 
					size=4, halign="left", valign="center");
		}
		relay4_holes();
	}
	% translate([0, 0, -tall_standoff_h - tall_standoff_threads+1]) {
		relay4();
		electronics_mount(relay4_hole_c_c);
	}
}


module valve_sw_face() {
	difference() {
		union() {
			translate([0, 0, relay4_th/2])
				cube([relay4_w, relay4_h, relay4_th], center=true);
			
		}
		translate([-11, 0, 0]) {
			# toggle_switch();
			% translate([0, 0, relay4_th])
				toggle_cage();
			translate([0, -15, -1])
				linear_extrude(4)
				text(
					"IN", 
					font="Helvetica:style=Negreta", 
					size=6, halign="center", valign="top");
			translate([-10, 10, -1])
				linear_extrude(4)
				text(
					"SPA", 
					font="Helvetica:style=Negreta", 
					size=4, halign="right", valign="center");
			translate([-10, -10, -1])
				linear_extrude(4)
				text(
					"POOL", 
					font="Helvetica:style=Negreta", 
					size=4, halign="right", valign="center");
			translate([-10, 0, -1])
				linear_extrude(4)
				text(
					"AUTO", 
					font="Helvetica:style=Negreta", 
					size=4, halign="right", valign="center");
		}
		translate([11, 0, 0]) {
			# toggle_switch();
			% translate([0, 0, relay4_th])
				toggle_cage();
			translate([0, -15, -1])
				linear_extrude(4)
				text(
					"OUT", 
					font="Helvetica:style=Negreta", 
					size=6, halign="center", valign="top");
			translate([10, -10, -1])
				linear_extrude(4)
				text(
					"POOL", 
					font="Helvetica:style=Negreta", 
					size=4, halign="left", valign="center");
			translate([9, 10, -1])
				linear_extrude(4)
					text(
					"SPA", 
					font="Helvetica:style=Negreta", 
					size=4, halign="left", valign="center");
			translate([9, 0, -1])
				linear_extrude(4)
				text(
					"AUTO", 
					font="Helvetica:style=Negreta", 
					size=4, halign="left", valign="center");
		}
		relay4_holes();
	}
	% translate([0, 0, -tall_standoff_h - tall_standoff_threads+1]) {
		relay4();
		electronics_mount(relay4_hole_c_c);
	}
}

// ! stop_sw_face();

lcd_2004_w = 99;
lcd_2004_h = 60;
lcd_2004_d = 10;
lcd_2004_clr = 15;
lcd_2004_th = 2;
lcd_2004_face_h = 40;
lcd_2004_hole_c_c = [93, 55];
lcd_2004_hole_ir = 3/2; //3.5/2;

module lcd_2004_holes() {
	for (x=[-0.5, 0.5])
		for (y=[-0.5, 0.5])
		translate([
			x*lcd_2004_hole_c_c[0],
			y*lcd_2004_hole_c_c[1], -10])
		cylinder(h=60, r=lcd_2004_hole_ir, center=true, $fn=32);
}

module lcd_2004() {
	difference() {
		union() {
			translate([0, 0, lcd_2004_th/2])
				cube([lcd_2004_w, lcd_2004_h, lcd_2004_th], center=true);
			translate([0, 0, lcd_2004_d/2 + lcd_2004_th])
				cube([lcd_2004_w, lcd_2004_face_h, lcd_2004_d], center=true);
			translate([-lcd_2004_w/2+8, lcd_2004_h/2-20, -10])
				cube([47, 20, 10]);
			translate([-lcd_2004_w/2-10, lcd_2004_h/2-16, -10])
				cube([20, 12, 11]);
			// pins: 9mm to 49mm, 5mm tall, 1mm wide, 2.5mm in from long side
			translate([-lcd_2004_w/2+9, lcd_2004_h/2-3, 2])
				cube([40, 1, 6]);
				// TODO: pins are 5 mm, not 6 tall
		}
		lcd_2004_holes();
		// translate([0, 0, 20])
		// 	cube([76, 26, 20], center=true);
	}
}

// ! lcd_2004();

module cordgrip() {
	translate([-62, -30, 6])
		rotate([-90, 0, 0]) {
			cylinder(r=13/4, h=50, $fn=64, center=true);
			// cylinder(r=21/2, h=5, $fn=6);
	}
}

// module cordgrip_wrap() {
// 	difference() {
// 		translate([-62, -28, 0])
// 			rotate([-90, 0, 0])
// 			cylinder(r=22/2, h=8, $fn=64, center=true);
// 		// # cordgrip();	
// 		translate([-62, -25, -9])
// 			cube([24, 10, 20], center=true);
// 	}
// }

module display_seam() {
	intersection() {
		translate([-74, 31, 0])
			rotate([45, 0, 0])
			cube([125, 2, 2]);
		translate([-74, 30, 0])
			cube([125, 1, 1]);
	}
	intersection() {
		translate([-74, -31, 0])
			rotate([45, 0, 0])
			cube([125, 2, 2]);
		translate([-74, -31, 0])
			cube([125, 1, 1]);
	}
	intersection() {
		translate([50, -31, 1])
			rotate([0, 45, 0])
			cube([2, 62, 2]);
		translate([50, -31, 0])
			cube([1, 62, 1]);
	}
	intersection() {
		translate([-74, -31, 0])
			rotate([0, -45, 0])
			cube([2, 62, 2]);
		translate([-74, -31, 0])
			cube([1, 62, 1]);
	}
}

module display_front_face() {
	difference() {
		union() {
			translate([-11.5, 0, 7])
				cube([125, 62, 12], center=true);
			// cordgrip_wrap();
			display_seam();
		}
		lcd_2004();
		translate([0, 0, 20])
			cube([76, 26, 20], center=true);
		lcd_2004_holes();
		translate([-62, 0, 0])
			cube([22, 60, 20], center=true);
		translate([0, -25, 5])
			cube([99, 8, 10], center=true);
		translate([0, 25, 5])
			cube([99, 8, 10], center=true);
		// % translate([-63, 0, 0])
		// 	cube([19, 27, 11], center=true);
		translate([-62, 0, 0])
			cylinder(r=7/2, h=60, center=true, $fn=64);
		cordgrip();
	}
}

// ! display_front_face();

module display_back_face() {
	difference() {
		union() {
			translate([-11.5, 0, -5])
				cube([125, 62, 12], center=true);
		
		}
		mirror([0, 1, 0])
			display_seam();
		lcd_2004();
		lcd_2004_holes();
		translate([0, 0, -5])
			cube([96, 56, 10], center=true);
		translate([-62, 2, 0])
			cube([22, 56, 20], center=true);
		// cordgrip_wrap();
		// cordgrip();


	}
}

// ! display_back_face();

module display_design(explode=15) {
	// color(alpha=0.2)
	translate([0, 0, explode]) 
		display_front_face();
	// display_front_face_short();
	// color(alpha=0.2) 
	translate([0, 0, -explode])
		display_back_face();
	// display_back_face_short();
	// % lcd_2004();
}

! display_design();

module display_front_face_short() {
	intersection() {
		display_front_face();
		translate([0, 0, 10])
			cube([200, 200, 1], center=true);
	}
}

// ! display_front_face_short();

module display_back_face_short() {
	intersection() {
		display_back_face();
		translate([0, 0, 0])
			cube([200, 200, 1], center=true);
	}
}

// ! display_back_face_short();

bbox_size = [250, 150, 100];

// bbox_holes = [
// 	[-64, 10],
// 	[64, 10],
// 	[-197/2, 112],
// 	[197/2, 112],
// 	[-30, 112],
// 	[30, 112],
// ];

bbox_holes = [
	[-64, 1/2 * IN_MM],
	[64, 1/2 * IN_MM],
	[-7.75*IN_MM/2, 4.5 * IN_MM],
	[7.75*IN_MM/2, 4.5 * IN_MM],
	[-(2+3/8)*IN_MM/2, 4.5 * IN_MM],
	[(2+3/8)*IN_MM/2, 4.5 * IN_MM],
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
				cube([10, 35, bbox_mount_th], center=true);
			translate([62, -50, bbox_mount_th/2])
				cube([10, 35, bbox_mount_th], center=true);
			
		}
		breaker_box_holes();
	}
}

// breaker_box_mount();

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
	translate([p[0]/2, p[1]/2, 5/2]) {
		cylinder(r=ir, h=6, center=true, $fn=32);
	}
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
			translate([p[0]/2, p[1]/2, 5/2]) {
				% translate([0, 0, 2.5])
					tall_standoff();
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			}
			translate([-p[0]/2, p[1]/2, 5/2]) {
				% translate([0, 0, 2.5])
					tall_standoff();
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			}
			translate([p[0]/2, -p[1]/2, 5/2]) {
				% translate([0, 0, 2.5])
					tall_standoff();
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			}
			translate([-p[0]/2, -p[1]/2, 5/2]) {
				% translate([0, 0, 2.5])
					tall_standoff();
				cylinder(r1=or, r2=ir+1, h=5, center=true, $fn=32);
			}
		}
		electronics_holes(p);
	}
}

acdc_offset = [0, -10, 0];
tblock_offset = [0, -60, 0];
arduino_offset = [-25, 44, 0];
valve_relay_offset = [52.5, -10, 0];
pump_relay_offset = [-52.5, -10, 0];
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

module design() {
	box_plate();
	// % breaker_box();
	translate(pump_relay_offset + [0, 0, 10])
		stop_sw_face();
	translate(valve_relay_offset + [0, 0, 10])
		valve_sw_face();
}

design();

module box_plate_short() {
	intersection() {
		box_plate();
		translate([0, 0, -bbox_size[2]/2 + 1])
			cube([250, 250, 1], center=true);
	}
}

// box_plate_short();
