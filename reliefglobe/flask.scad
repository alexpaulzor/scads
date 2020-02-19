IN_MM = 25.4;
pin_or = 3 / 32 * IN_MM / 2;
num_pins = 8;

base_height = 30;
sphere_ir = 39;
globe_scale = 0.75;
print_scale = 0.75;


globe_offset = [0, 0, 55];

use_stl = true;

text_size = 19;
font = "Helvetica:style=Negreta";

module base_text(use_stl=false) {
    if (use_stl) {
        import("stl/base_text.flask.stl");
    } else {
        _base_text();
    }
}
module _base_text() {
    translate([0, text_size/2, 0])
        linear_extrude(base_height)
        text("PLANET", size=text_size, font=font, halign="center", valign="center");
    translate([-0.5, -text_size/2 + 7, 0])
        linear_extrude(base_height)
        text("LABS", size=text_size, font=font, halign="center", valign="center", direction="ttb");
    translate([0, 0, base_height/4])
        cube([100, 3, base_height/2], center=true);
    translate([-16, -2, base_height/4])
        cube([3, 90, base_height/2], center=true);

}

module base_disc(use_stl=false) {
    if (use_stl) {
        import("stl/base_disc.flask.stl");
    } else {
        _base_disc();
    }
}

module _base_disc() {
    // cylinder(r=45, h=2);
    linear_extrude(2)
    projection(cut=true)
    globe();
}

module base(use_stl=false) {
    difference() {
        base_text(use_stl);
        translate(globe_offset)
            _globe_bottom();
    }
    base_disc(true);
    // cylinder(r=45, h=2);
}


module globe_pins() {
    // cylinder(r=pin_or, h=80, center=true, $fn=32);
    pin_or_scaled = pin_or / print_scale ;
    sphere(r=sphere_ir);
    for (i=[1:num_pins]) {
        rotate([0, 0, i * 360 / num_pins])
        translate([41, 0, 0])
        cylinder(r=pin_or_scaled, h=25, center=true, $fn=32);
    }
}

module globe_bottom() {
    difference() {
        _globe_bottom();
        globe_pins();
    }
}

module _globe_bottom() {
    scale(globe_scale)
        translate([0.6, 0.6, 0])
        rotate([0, 180, 0])
        import("s_hemisphere.stl");
}

module globe_top() {
    difference() {
        scale(globe_scale)
            import("n_hemisphere.stl");
        globe_pins();
    }
}

module globe(use_stl=false) {
    if (use_stl) {
        import("stl/globe.flask.stl");
    } else {
        _globe();
    }
}
module _globe() {
    globe_top();
    globe_bottom();
}

module plate() {
    base(true);
    translate([100, 0, 0])
        rotate([0, 180, 0])
        globe_bottom();
    translate([0, 100, 0])
    globe_top();
}

module scaled_plate() {
    scale(print_scale)
        plate();
}

module design() {
    globe(true);
    # base_disc(true);
}
// design();
// base_disc(false);
// scaled_plate();
// globe_top();
// globe_bottom();
// # globe_pins();
// plate();
// globe_top();

// plate();

// ! base_text(false);