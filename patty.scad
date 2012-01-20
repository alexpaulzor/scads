casing_width = 24;
cartridge_width = 18.9;
cartridge_length = 83.3;
pin_needle_length = 15;
lever_foot_thickness = 4;
pin_middle_thickness = 6;

module pin() {
	difference () {
		union() {
			cylinder(h=15, r1=0, r2=3, $fn=24);
			translate([0, 0, 15]) cylinder(h=2, r=pin_middle_thickness / 2, $fn=12);
			translate([0, 0, 17]) cylinder(h=10, r1=3, r2=2, $fn=24);
		}
		cylinder(h=30, r=.5, $fn=12);
	}
}
pin();
/*
difference() {
	//cube([95, 23, 23]);
	#translate([-2, 23/2, 23/2]) rotate(90, [0, 1, 0]) cylinder(r=18.25/2, h=85);
	#translate([82, 23/2, 23/2]) rotate(90, [0, 1, 0]) cylinder(r=3.5, h=20);
	
}*/



module nozzle() {
	difference () {
	union () {
		cylinder(r=6.8/2, h=8);
		translate([0, 0, 8 - 3]) cylinder(r=7.8/2, h=3);
		translate([-6.10/2, 0, 8 - 1.62]) cube([6.10, 8, 1.62]);
	}
	translate([0, 0, -1]) cylinder(r=4.33/2, h=10);
	}
}

//nozzle();
//rotate(180, [1, 0, 0]) pin();

module cartridge() {
	cylinder(r=cartridge_width/2,h=cartridge_length);
}

//cartridge();

module casing_half() {
	union() {
		difference() {
			cube([2 + lever_foot_thickness + pin_needle_length + cartridge_length, casing_width / 2, casing_width]);
			translate([-1, (casing_width - cartridge_width) / 2, (casing_width - cartridge_width) / 2]) cube([lever_foot_thickness * 2, cartridge_width, casing_width]);
			translate([lever_foot_thickness, casing_width / 2, casing_width / 2]) rotate(90, [0, 1, 0]) cylinder(r=cartridge_width/2,h=(cartridge_length + pin_needle_length));
			translate([lever_foot_thickness + cartridge_length + pin_needle_length - 1, casing_width / 2, casing_width / 2]) rotate(90, [0, 1, 0]) cylinder(r=(pin_middle_thickness / 2), h=4, $fn=12);
			translate([2+1.5, -1, casing_width - 2 - 1.5]) rotate(-90, [1, 0, 0]) cylinder(r=1.5, h=10, $fn=12);
		}
	}
}

//mirror([0, 1, 0])
casing_half();

module lever() {
	union() {
		cube([lever_foot_thickness, 	cartridge_width / 2, 2/3 * cartridge_width + (casing_width - cartridge_width) / 2 + lever_foot_thickness]);
		translate([1.5 + 2, -(cartridge_width / 4), 2/3 * cartridge_width - 1.5]) rotate(-90, [1, 0, 0]) cylinder(r=5/2, h=cartridge_width);
		translate([1.5 + 2, - (casing_width - (cartridge_width / 2)) / 2, 2/3 * cartridge_width - 1.5]) rotate(-90, [1, 0, 0]) cylinder(r=1.5, h=casing_width, $fn=12);
		translate([0, 0, 2/3 * cartridge_width + (casing_width - cartridge_width) / 2]) cube([cartridge_length/2, cartridge_width / 2, lever_foot_thickness]);
	}
}

translate([0, (casing_width - (cartridge_width / 2)) / 2, (casing_width - cartridge_width) / 2 + 1/3 * cartridge_width]) 

lever();







