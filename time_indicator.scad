
wheel_or = 50;
th = 3;
text_size = 8;
ch_w = text_size;
ch_h = text_size - 2;

days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
module raised_text(t, size=text_size, h=th) {
    linear_extrude(h)
    text(t, size=size, halign="center", valign="center");
}


module wheel(labels, h=th) {
    num_sides = len(labels);
    side_angle = 360 / num_sides;
    difference() {
        cylinder(r=wheel_or, h=h, $fn=num_sides);
        for (i=[0:num_sides-1]) {
            rotate([0, 0, i * side_angle])
            translate([wheel_or - ch_w * len(labels[i]), 0, h/2])
            {
                raised_text(labels[i]);
                translate([ch_w, ch_h, 0])
                    raised_text("AM", text_size/2);
                translate([ch_w, -ch_h, 0])
                    raised_text("PM", text_size/2);
            }
        }
        center_bar();
    }
}

wheel(days);