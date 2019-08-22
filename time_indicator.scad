

center_or = 25 / 2;
center_h = 20;
center_num_nubs = 7;
center_nub_or = 1;

shell_th = 5;
finger_th = 1.5;
$fn = 32;

module center_bar(h=center_h) {
    nub_angle = 360 / center_num_nubs;
    
    difference() {
        cylinder(h=h, r=center_or);
        for (i=[0:center_num_nubs]) {
            rotate([0, 0, i * nub_angle])
            translate([center_or, 0, 0])
            cylinder(r=center_nub_or, h=h);
        }
    }
}
days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
module raised_text(t, h=2) {
    rotate([90, 0, 90])
    linear_extrude(h)
    text(t, size=8, halign="center", valign="center");
}

module wheel(labels, h=center_h) {
    num_sides = len(labels);
    side_angle = 360 / num_sides;
    difference() {
        rotate([0, 0, side_angle / 2])
            cylinder(r=center_or + shell_th, h=h, $fn=num_sides);
        for (i=[0:num_sides]) {
            rotate([0, 0, (i) * side_angle])
            translate([center_or + shell_th/2, 0, h/2])
            raised_text(labels[i]);
        }
        center_bar();
    }
}

wheel(days);