
module bat(r, h) {
	cylinder(r=r, h=h, $fn=48);
}

bat_18650_d = 18;
bat_18650_h = 65;

module bat_18650() {
	bat(r=bat_18650_d/2, h=bat_18650_h);
}

bat_aaa_d = 10.5;
bat_aaa_h = 44.5;

module bat_aaa() {
	bat(r=bat_aaa_d/2, h=bat_aaa_h);
}

bat_aa_d = 14.5;
bat_aa_h = 50.5;

module bat_aa() {
	bat(r=bat_aa_d/2, h=bat_aa_h);
}


bat_c_d = 26.2;
bat_c_h = 50;

module bat_c() {
	bat(r=bat_c_d/2, h=bat_c_h);
}

module bat_adapter() {
	difference() {
		translate([0, 0, -15])
			bat(bat_18650_d/2, 30);
		translate([0, 0, -20])
			bat(bat_aa_d/2, 40);
		# translate([0, 0, -25])
			bat(bat_aaa_d/2, 50);
	}
}

module design() {
	translate([30, 0, 0])
		bat_18650();
	translate([0, 30, 0])
		bat_aaa();
	translate([-30, 0, 0])
		bat_aa();
	// translate([0, -30, 0])
	// 	bat_c();

	bat_adapter();
}

design();