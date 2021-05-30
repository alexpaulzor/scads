include <casting.scad>;
IN_MM = 25.4;
ortega_shaft_or = 13.3/2; //1/2 * IN_MM / 2;
ortega_set_screw_or = 4/2;

ortega_set_screw_offs = 7/32 * IN_MM;

jandy_or = 19/2;
jandy_ir = 15/2;
jandy_nub_arc_deg = 35;
jandy_small_nub_arc_deg = 12.5;
jandy_h = 13;
ortega_shaft_len = jandy_h + 1; //1/2 * IN_MM;

module ortega_set_screw() {
	translate([0, 0, ortega_set_screw_offs])
		rotate([90, 0, -45])
		cylinder(
			r=ortega_set_screw_or, 
			h=2*jandy_or, center=true, $fn=32);
	translate([0, 0, ortega_set_screw_offs/2])
		rotate([0, 0, -45])
		draft_cube(
			[2*ortega_set_screw_or, 
			2*jandy_or, 
			ortega_set_screw_offs]
			, center=true, draft_angle=-2, invert=true);
}

module ortega_shaft(h=ortega_shaft_len, set_screw=true) {
	difference() {
		// draft_cylinder(
		// 	r=ortega_shaft_or, 
		// 	h=h, $fn=64, draft_angle=0);
		cylinder(
			r=ortega_shaft_or, 
			h=h, $fn=64);
		if (set_screw)
			ortega_set_screw();
	}
}
// !ortega_shaft();

module jandy_shaft(h=25) {
	difference() {
		draft_cylinder(r=jandy_or, h=h, $fn=64);

		for (r=[0:90:360]) {
			rotate([0, 0, r])
			translate([jandy_ir, -1.5, 0])
			draft_cube([5, 3, h+1], draft_angle=-2);
		}
		for (r=[-jandy_nub_arc_deg/2:90:180]) {
			rotate([0, 0, r])
			translate([jandy_ir, 0, 0])
			draft_cube([5, 3, h+1], draft_angle=-2);
		}
		for (r=[jandy_nub_arc_deg/2:90:270]) {
			rotate([0, 0, r])
			translate([jandy_ir, -3, 0])
			draft_cube([5, 3, h+1], draft_angle=-2);
		}
		for (r=[270-jandy_small_nub_arc_deg]) {
			rotate([0, 0, r])
			translate([jandy_ir, 0, 0])
			draft_cube([5, 3, h+1], draft_angle=-2);
		}
		for (r=[270+jandy_small_nub_arc_deg]) {
			rotate([0, 0, r])
			translate([jandy_ir, -3, 0])
			draft_cube([5, 3, h+1], draft_angle=-2);
		}
		* rotate([0, 0, 270])
			translate([ortega_shaft_or-1, -0.2, 0])
			draft_cube([5, 0.4, h+1], draft_angle=-2);
	}
}

// ! jandy_shaft();

module jandy_inside(h=25, inside=13, set_screw=true) {
	difference() {
		jandy_shaft(h);
		if (set_screw()) {
			ortega_shaft(inside, false);
			ortega_set_screw();
		}
	}
}
// !jandy_inside();

module jandy_adapter() {
	difference() {
		jandy_inside();
		ortega_shaft();
	}
}

// !jandy_adapter();

// module jandy_adapter_slice_a() {
// 	intersection() {
// 		jandy_adapter();
// 		rotate([0, 0, 45])
// 		translate([0, -50, 0])
// 			cube([100, 100, 100]);
// 	}
// }

// module jandy_adapter_slice_b() {
// 	intersection() {
// 		jandy_adapter();
// 		# rotate([0, 0, 180+45])
// 			translate([0, -50, 0])
// 			cube([100, 100, 100]);
// 	}
// }

// jandy_adapter_slice_a();
// jandy_adapter_slice_b();

module sprue_cup(r=10, inside=true) {
	difference() {
		sphere(r=r);
		if (inside)
			sphere(r=r-1);
		translate([0, 0, -r])
			cube([2*r, 2*r, 2*r], center=true);
	}
}

module jandy_adapter_pattern() {
	scale(1.05)
		jandy_inside(set_screw=false);
	difference() {
		rotate([0, 0, 45])
			translate([-15, 0, 5])
			draft_cube(
				[30, 5, 10], center=true,
				draft_angle=20);
		translate([-20, -20, -0.1])
			sprue_cup(10, false);
	}
	difference() {
		rotate([0, 0, 45])
			translate([15, 0, 5/2])
			draft_cube(
				[30, 5, 5], center=true,
				draft_angle=20);
		translate([20, 20, -0.1])
			sprue_cup(5, false);
	}
	translate([-20, -20, 0])
		sprue_cup();
	translate([20, 20, 0])
		sprue_cup(5);
			
}
! jandy_adapter_pattern();

handle_width = jandy_or * 2 + 5;
handle_length = 100 - handle_width;
echo(handle_width=handle_width);
handle_height = 14;
handle_screw_or = 5;

module handle() {
	cylinder(r=handle_width/2, h=handle_height);
	translate([0, handle_length, 0])
		cylinder(r=handle_width/2, h=handle_height);
	translate([-handle_width/2, 0, 0])
		cube([handle_width, handle_length, handle_height]);
}

module jandy_handle(r=0) {
	difference() {
		handle();
		translate([0, 0, 4])
			rotate([0, 0, r])
			jandy_shaft(handle_height);
		cylinder(r=handle_screw_or, h=handle_height+1, $fn=32);
		translate([0, handle_length/2, handle_height + 4])
			rotate([-7, 0, 0])
			cube([handle_width+1, handle_length+handle_width + 4, handle_height], center=true);
		linear_extrude(2)
			translate([0, handle_width/2, 0])
			rotate([180, 0, 90])
			text("FLOW ->", size=handle_width/2, halign="left", valign="center");
	}
}

// jandy_handle();

module jandy_handle_ortega() {
	jandy_handle(45);
}

module jandy_handle_short() {
	intersection() {
		jandy_handle(45);
		translate([0, 0, 4])
			cube([handle_length*3, handle_length*3, 5], center=true);
	}
}

// jandy_handle_short();

ortega_tee_od = 61;
ortega_tee_l = 125;
ortega_tee_face_od = 75;
ortega_tee_face_depth = 13;

ortega_mount_clr = 10;

module ortega_tee_holes() {
	for (r=[45:90:360]) {
		rotate([r, 0, 0])
			translate([ortega_tee_od/2, 2.5*IN_MM/2, 0])
			rotate([0, 90, 0])
			cylinder(r=2, h=50, $fn=32);
	}

}

module ortega_tee() {
	rotate([90, 0, 0])
		cylinder(r=ortega_tee_od/2, h=ortega_tee_l, center=true, $fn=128);
	rotate([0, -90, 0])
		cylinder(r=ortega_tee_od/2, h=ortega_tee_l/2, center=false, $fn=128);
	rotate([0, 90, 0])
		cylinder(r=ortega_tee_od/2, h=ortega_tee_od/2+1, center=false, $fn=128);
	translate([ortega_tee_od/2 - 5, 0, 0])
		rotate([0, 90, 0])
		cylinder(
			r=ortega_tee_face_od/2, 
			h=ortega_tee_face_depth+5, 
			center=false, $fn=128);
	ortega_tee_holes();
}

// !ortega_tee();

tpe24va_hole_offs = 50;
tpe24va_hole_or = 5/2;
tpe24va_hole_thetas = [-45/2:45:360]; // [-45/2, 45/2, -45/2-90, 45/2+90];
tpe24va_hole_h = 35;

module tpe24va_holes() {
	for (r=tpe24va_hole_thetas) {
		rotate([0, 0, r])
		translate([tpe24va_hole_offs, 0, 0])
		cylinder(
			r=tpe24va_hole_or, 
			h=tpe24va_hole_h*2, center=true, $fn=36);
	}
	translate([0, 0, 20])
		cylinder(r=jandy_ir, h=130, center=true);
}

module tpe24va() {
	tpe24va_holes();
	translate([-110, -40, 15])
		cube([150, 80, 60]);
	for (r=tpe24va_hole_thetas) {
		rotate([0, 0, r])
		translate([tpe24va_hole_offs, 0, 0])
		cylinder(
			r=14/2, 
			h=tpe24va_hole_h, center=false, $fn=36);
	}
}

// ! tpe24va();

module ortega_mount() {
	difference() {
		// translate([0, -50, -50])
		// 	cube([41, 100, 100], center=false);
		translate([ortega_tee_od/2+ortega_tee_face_depth+5, 0, 0])
			rotate([0, -90, 0])
			cylinder(
				r=55, 
				h=ortega_tee_face_depth+5);
		rotate([0, 90, 0])
			cylinder(r=25, h=60);
		# ortega_tee();
		# for (r=[45:90:360]) {
			rotate([r, 0, 0])
				translate([ortega_tee_od/2+ortega_tee_face_depth-1, 2.5*IN_MM/2, 0])
				rotate([0, 90, 0])
				cylinder(r=5, h=6.2, $fn=32);
		}
		translate([ortega_tee_od/2 + ortega_mount_clr, 0, 0])
			rotate([-90, 0, -90])
			tpe24va();
		for (y=[-ortega_tee_od/2-3, ortega_tee_od/2+3])
			for (z=[-ortega_tee_od/2, ortega_tee_od/2])
				translate([0, y, z])
				cube([120, 10, 2], center=true);
		
	}
}

// ortega_mount();

module ortega_mount_short() {
	intersection() {
		ortega_mount();
		# cube([100, 100, 100]);
		union() {
			// translate([40, -50, -50])
			// 	cube([4, 100, 100], center=false);
			// translate([20, -50, -2.5])
			// 	cube([20, 5, 5], center=false);
			// translate([20, 40, -2.5])
			// 	cube([20, 5, 5], center=false);
		}
	}
}

// ! ortega_mount_short();