//$fn = 30;
cork_height = 20;
cork_id = 30;
cork_od = 60;
sphere_ir = 45;
cork_thickness = 10;

base_height = 30;
magnet_or = 10 / 2;
magnet_h = 2;
num_magnets = 4;
globe_scale = 0.75;

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
            linear_extrude(base_height)
            text("PLANET", size=text_size, halign="center", valign="center");
        translate([0, -text_size/2, 0])
            linear_extrude(base_height)
            text("LABS", size=text_size, halign="center", valign="center");
        translate([0, 0, base_height/2])
            cube([100, 3, base_height], center=true);
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
    % translate([60, 60, -sphere_ir + cork_thickness]) 
        cork(use_stl);
    base();
    translate([0, 0, 0.4])
        flask(use_stl);
}

module globe_bottom() {
    difference() {
        scale([globe_scale, globe_scale, globe_scale])
        translate([0.6, 0.6, 0])
        rotate([0, 180, 0])
            import("s_hemisphere.stl");

        sphere(r=globe_scale * sphere_ir);
        for (i=[1:num_magnets]) {
            rotate([0, 0, i * 360 / num_magnets])
            translate([globe_scale * sphere_ir + magnet_or, 0, -magnet_h])
            # cylinder(r=magnet_or, h=magnet_h);
        }
    }
}

module globe_top() {
    difference() {
        scale([globe_scale, globe_scale, globe_scale])
            import("n_hemisphere.stl");
        sphere(r=globe_scale * sphere_ir);
        for (i=[1:num_magnets]) {
            rotate([0, 0, i * 360 / num_magnets])
            translate([globe_scale*sphere_ir + magnet_or, 0, 0])
            # cylinder(r=magnet_or, h=magnet_h);
        }
    }
}
* globe_top();
% globe_bottom();


//plate();

//! base_text();