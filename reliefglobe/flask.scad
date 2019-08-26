$fn = 30;
cork_height = 20;
cork_id = 30;
cork_od = 60;
sphere_ir = 55;
cork_thickness = 10;

globe_offset = [0, 0, 67.5];

use_stl = true;

text_size = 19;
module globe(use_stl=false) {
    if (use_stl) {
        import("stl/globe.flask.stl");
    } else {
    import("n_hemisphere.stl");
    translate([0.6, 0.6, 0])
    rotate([0, 180, 0])
        import("s_hemisphere.stl");
    }
}

module cork(use_stl=false) {
    if (use_stl) {
        import("stl/cork.flask.stl");
    } else {
        intersection() {
            globe(use_stl);
            cork_cone();
        }
    }
}

module cork_cone() {
    translate([0, 0, sphere_ir - cork_thickness])
        cylinder(cork_height, cork_id, cork_od, $fn=8 );
}

module flask(use_stl=false) {
    if (use_stl) {
        import("stl/flask.flask.stl");
    } else {
        translate(globe_offset) {
            difference() {
                globe(use_stl);
                sphere(r=sphere_ir);
                cork_cone();
            }
            % cork(use_stl);
        }
    }
}

module base_text(use_stl=false) {
    if (use_stl) {
        import("stl/base_text.flask.stl");
    } else {
        translate([0, text_size/2, 0])
            linear_extrude(30)
            text("PLANET", size=text_size, halign="center", valign="center");
        translate([0, -text_size/2, 0])
            linear_extrude(30)
            text("LABS", size=text_size, halign="center", valign="center");
        translate([0, 0, 15])
            cube([100, 3, 30], center=true);
    }
}
module base() {
    difference() {
        base_text(use_stl);
        translate(globe_offset)
            globe(use_stl);
    }
}



module plate() {
    translate([60, 60, -sphere_ir + cork_thickness]) 
        cork(use_stl);
    base();
    translate([0, 0, 0.2])
        flask(use_stl);
}

plate();

//! base_text();