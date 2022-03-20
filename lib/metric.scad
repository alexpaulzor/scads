IN_MM = 25.4;
// PI = PI
phi = 1.61803398875;
e = 2.71828182846;

m3_nut_or = 6.5 / 2;
m3_nut_h = 2.6;

m4_nut_or = 7.7 / 2;
m4_nut_h = 3.2;

m5_nut_or = 8.8 / 2;
m5_nut_h = 4.7;
m5_washer_h = 1;

m6_nut_or = 11.1 / 2;
m6_nut_h = 5.2;

m8_nut_or = 14.5/2;
m8_nut_h = 6.3;

m10_nut_or = 18.3/2;
m10_nut_h = 7.9;

m12_nut_or = 20.3/2;
m12_nut_h = 9.75;

module m_nut(ir, or, h, core=false) {
	difference() {
		cylinder(r=or, h=h, center=true, $fn=6);
		if (core) cylinder(r=ir, h=h, center=true);
	}

}

module m3_nut(core=false) {
	m_nut(3/2, m3_nut_or, m3_nut_h+0.1, core);
}

module m4_nut(core=false) {
	m_nut(4/2, m4_nut_or, m4_nut_h+0.1, core);
}

module m5_nut(core=false) {
	m_nut(5/2, m5_nut_or, m5_nut_h+0.1, core);
}

module m6_nut(core=false) {
	m_nut(6/2, m6_nut_or, m6_nut_h+0.1, core);
}

module m8_nut(core=false) {
	m_nut(8/2, m8_nut_or, m8_nut_h+0.1, core);
}

module m10_nut(core=false) {
	m_nut(10/2, m10_nut_or, m10_nut_h+0.1, core);
}

module m12_nut(core=false) {
	m_nut(12/2, m12_nut_or, m12_nut_h+0.1, core);
}
