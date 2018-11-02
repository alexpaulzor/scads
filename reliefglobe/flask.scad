$fn = 30;
cork_height = 20;
cork_id = 30;
cork_od = 60;
sphere_ir = 55;
cork_thickness = 10;

module globe() {
    import("n_hemisphere.stl");
    rotate([0, 180, 0])
        import("s_hemisphere.stl");
}

module cork() {
    intersection() {
        globe();
        cork_cone();
    }
}

module cork_cone() {
    # translate([0, 0, sphere_ir - cork_thickness])
        cylinder(cork_height, cork_id, cork_od);
}

module flask() {
    translate([0, 0, 67.5]) {
        difference() {
            globe();
            sphere(r=sphere_ir);
            cork_cone();
        }
        % cork();
    }
    # translate([-30, -30, 0])
        cube([60, 60, 5]);
}

translate([80, 0, -sphere_ir + cork_thickness]) 
    cork();
flask();
