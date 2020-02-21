IN_MM = 25.4;
pin_or = 1.25;
num_pins = 8;
pin_length = 15;

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
        // % import("stl/base_disc.flask.stl");
    }
}

module _base_disc() {
    difference() {
        cylinder(r=45, h=3);
        cylinder(r=35, h=8, center=true);
    }
    // linear_extrude(3)
    // projection(cut=true)
    // globe(true);
}
// ! base();
module base(use_stl=false) {
    if (use_stl) {
        import("stl/base.flask.stl");
    } else {
        _base();
    }
}

module _base() {    
    difference() {
        base_text(true);
        # translate(globe_offset)
            globe(true);
    }
    base_disc(false);
    // cylinder(r=45, h=2);
}


module globe_pins() {
    // cylinder(r=pin_or, h=80, center=true, $fn=32);
    sphere(r=sphere_ir);
    for (i=[1:num_pins]) {
        rotate([0, 0, i * 360 / num_pins])
        translate([41, 0, 0])
        globe_pin();
    }
}

module globe_pin() {
    cylinder(r=pin_or, h=pin_length, center=true, $fn=32);
}

module globe_bottom(use_stl=false) {
    if (use_stl) {
        import("stl/base.flask.stl");
    } else {
        difference() {
            _globe_bottom();
            globe_pins();
        }
    }
}

module _globe_bottom() {
    scale(globe_scale)
        translate([0.6, 0.6, 0])
        rotate([0, 180, 0])
        import("s_hemisphere.stl");
}

module globe_top(use_stl=false) {
    if (use_stl) {
        import("stl/globe_top.flask.stl");
    } else {
        difference() {
             _globe_top()
            globe_pins();
        }
    }
}

module _globe_top() {
    scale(globe_scale)
        import("n_hemisphere.stl");
}

module globe(use_stl=false) {
    if (use_stl) {
        import("stl/globe.flask.stl");
    } else {
        _globe();
    }
}
module _globe() {
    _globe_top();
    _globe_bottom();
}

module plate() {
    base(true);
    translate([100, 0, 0])
        rotate([0, 180, 0])
        globe_bottom();
    translate([0, 100, 0])
    globe_top();
    for (i=[1:num_pins]) {
        rotate([0, 0, 140 - i * 360 / 2 / num_pins])
        translate([-55, 0, pin_or])
        rotate([90, 0, 0])
        globe_pin();
    }
}

module scaled_plate() {
    scale(print_scale)
        plate();
}

module design() {
    // translate(globe_offset)
    _globe_bottom();
    # base_disc(true);
    // # base(false);
}
// design();
// base_disc(false);
scaled_plate();
// globe_top();
// globe_bottom();
// # globe_pins();
// plate();
// globe_top();

// plate();

// ! base_text(false);