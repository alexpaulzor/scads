IN_MM = 25.4;
$fn=90;


stem_ir = 11/32 * IN_MM / 2;
stem_cutout_ir = (15/64 - 11/32/2) * IN_MM;
stem_or = 7/8 * IN_MM / 2;
stem_length = 1/2 * IN_MM;
knob_h = 13;
knob_or = 43/2;
knob_max = 12;
knob_deg_per_num = 18;
draft_dr = stem_ir * 0.1;
t_h = 2;
shaft_length = 7/8 * IN_MM;

knob_texts = [
	["Lo", 180],
	["2", 144],
	["4", 108],
	["6", 72],
	["8", 36],
	["Hi", 0],
	["Lt", -36],
	["Off", -90],
];

module stove_knob() {
	* translate([stem_cutout_ir + stem_ir/2, 0, (knob_h+stem_length)/2])
		cube([stem_ir, 2*stem_ir, knob_h+stem_length], center=true);
	difference() {
		# union() {
			cylinder(r=knob_or, h=knob_h);
			cylinder(r=stem_or, h=knob_h+stem_length);
		}
	
		shaft();
	}
	
	for (i=knob_texts) {
		knob_text(i[0], i[1]);
	}
}

module shaft() {
	difference() {
		translate([0, 0, knob_h+stem_length - shaft_length])
			cylinder(r1=stem_ir, r2=stem_ir+draft_dr, h=shaft_length+1);
		translate([stem_cutout_ir + stem_ir/2, 0, (knob_h+stem_length)/2])
			cube([stem_ir, 2*stem_ir, knob_h+stem_length+3], center=true);
	
	}
}

module knob_text(t, theta) {
	rotate([0, 0, theta])
	translate([0, -knob_or+t_h, 0])
	rotate([90, 0, 0])
		linear_extrude(t_h*2)
			text(str(t), halign="center", size=12);
}

// stove_knob();

grill_knob_shaft_od = 1/4 * IN_MM;
grill_knob_shaft_notch_d = 3/16 * IN_MM;
grill_knob_h = 1/2 * IN_MM;
grill_knob_or = 3/4 * IN_MM;


module grill_shaft() {
	difference() {
		translate([0, 0, 0])
			cylinder(r=grill_knob_shaft_od/2, h=grill_knob_h);
		translate([grill_knob_shaft_notch_d, 0, grill_knob_h/2])
			cube([grill_knob_shaft_od, grill_knob_shaft_od, grill_knob_h+1], center=true);
	
	}
}

module grill_knob() {
	difference() {
		union() {
			// cylinder(r1=grill_knob_or, r2=grill_knob_or-5, h=grill_knob_h + 2);
			sphere(r=grill_knob_or);
			translate([0, -2, 0])
				cube([grill_knob_or + 4, 4, grill_knob_h + 2]);
		}
		difference() {
			// cylinder(r=grill_knob_or - 2, h=grill_knob_h);
			sphere(r=grill_knob_or-2);
			cylinder(r=grill_knob_shaft_od, h=grill_knob_or);
			cube([2*grill_knob_or, 3, 2*grill_knob_or], center=true);
			cube([3, 2*grill_knob_or, 2*grill_knob_or], center=true);
		}
		grill_shaft();
		translate([0, 0, -30])
			cube([60, 60, 60], center=true);
	}

}

// grill_knob();


cu_spacer_od = 7/8 * IN_MM;
cu_spacer_id = 5/8 * IN_MM + 0.4;
cu_spacer_h = 3/4 * IN_MM;

module copper_hinge_spacer() {
	difference() {
		cylinder(r=cu_spacer_od/2, h=cu_spacer_h, $fn=128);
		cylinder(r=cu_spacer_id/2, h=cu_spacer_h+1, $fn=128);
	}
}

copper_hinge_spacer();