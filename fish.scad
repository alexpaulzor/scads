difference () {
	translate([-28, -28,0]) cube ([56, 56,12]);
	translate([0, 0, 4]) cylinder (r=20,h=15);
	translate([-23.5, -23.5, -1]) cylinder(r=3,h=17);
	translate([23.5, -23.5, -1]) cylinder(r=3,h=17);
	translate([-23.5, 23.5, -1]) cylinder(r=3,h=17);
	translate([23.5, 23.5, -1]) cylinder(r=3,h=17);
	translate([0, 0, -1]) cylinder(r=3,h=17);
	translate([11.5, 0, -1]) cylinder(r=13/2,h=17);
}
