use <lib/sprockets.scad>;
include <lib/metric.scad>;

drive_teeth = 11;
axle_od = 6;

straw_ir = 1;
curve_ir = 5;
straw_l = 30;
straw_fn = 5;
straw_dl = 10;
straw_dl1 = straw_dl;
straw_dl2 = straw_dl;
straw_dl3 = straw_dl;
straw_dr = 360 / 10 / 2;


rotor_arm_w = 2 * (straw_ir + 1);
rotor_pitch = 40;
bubbler_or = 15;
bubbler_ir = 10;
bubbler_h = 2;
bubbler_vane_w = 1;
bubbler_num_vanes = 24;
basin_th = 2;
basin_extrude_angle = 360;


rt = 180 * $t;

module bubbler_head() {
    difference() {
        cylinder(h=bubbler_h, r=bubbler_or, center=true);
        cylinder(h=bubbler_h*3, r=bubbler_ir, center=true);
    }
    for (r=[0:360/bubbler_num_vanes:360])
        rotate([0, 0, r])
        translate([bubbler_ir - bubbler_vane_w, 0, -rotor_arm_w/2])
        cube([
            bubbler_or-bubbler_ir + bubbler_vane_w, 
            bubbler_vane_w, 
            rotor_arm_w], center=false);
}


// ! bubbler_head();

/*

module rotor() {
   
    difference() {
        union() {
            for (i=[-1, 1])
                translate([
                        i*rotor_pitch, 
                        0, 0])
                    bubbler_head();

            // translate([0, 0, rotor_arm_w/2])
            cube([
                rotor_pitch*2 - bubbler_or*2 + rotor_arm_w*2, 
                rotor_arm_w, rotor_arm_w], center=true);
            rotate([90, 0, 0])
                cylinder(r=4, h=rotor_arm_w, center=true);
        }
        rotate([90, 0, 0])
            cylinder(r=axle_od/2, h=100, center=true, $fn=32);

    }
}

// ! rotor();

module drive_sprocket() {
    sprocket(1, drive_teeth, axle_od / IN_MM, 0, 0);
}

// ! drive_sprocket();


bearing_h = 7;
bearing_ir = 4;
bearing_or = 11;
module bearing(core=true) {
    difference() {
        cylinder(r=bearing_or, h=bearing_h, center=true, $fn=128);
        if (core)
            cylinder(r=bearing_ir, h=bearing_h, center=true);
    }
}

module bearing_collar() {
    difference() {
        cylinder(
            r=bearing_or + basin_th + bearing_h, 
            h=bearing_h, center=true);
        bearing(false);

        translate([0, 0, bearing_h/2])
            rotate_extrude(angle=basin_extrude_angle, convexity=10) {
            translate([bearing_or + basin_th + bearing_h, 0])
                circle(r=bearing_h);
        }
    }
}

module basin_shell() {
    % rotate([90, 0, 90 + rt])
        rotor();
    difference() {
        union() {
            difference() {
                union() {
                    rotate_extrude(angle=basin_extrude_angle, convexity=10) {
                        translate([rotor_pitch, 0])
                            circle(r=bubbler_or + bubbler_vane_w + basin_th);
                    }
                    cylinder(
                        r=rotor_pitch, 
                        h=2*bubbler_or + 2*basin_th, 
                        center=true);
                    // # translate([
                    //         0, 
                    //         rotor_pitch, 0])
                    //     sphere(r=bubbler_or + bubbler_vane_w + basin_th);
                    
                }

                // translate([bearing_or + basin_th, -60, -60])
                //     cube([120, 120, 120]);
                cylinder(
                    r=rotor_pitch, 
                    h=2*bubbler_or, 
                    center=true);
            }
            translate([
                    bearing_or + basin_th * 2, 0, 0])
                cube([
                    basin_th, rotor_pitch*2, 
                    bubbler_or*2 + 2*basin_th], center=true);
            // cylinder(
            //     r=rotor_pitch - bubbler_or, 
            //     h=bubbler_vane_w + 4*basin_th, 
            //     center=true);
            for (i=[-1, 1])
                translate([
                    0, 0, i * (
                        bearing_h/2 + bubbler_or + basin_th)])
                rotate([90 - i*90, 0, 0])
                bearing_collar();
        }
        cylinder(
            r=rotor_pitch, 
            h=rotor_arm_w + basin_th, 
            center=true);
        rotate_extrude(angle=basin_extrude_angle, convexity=10) {
            translate([rotor_pitch, 0])
                circle(r=bubbler_or + bubbler_vane_w);
            
        }
        
        cylinder(r=axle_od/2 + 0.5, h=100, center=true, $fn=32);

        translate([bearing_or + 2*basin_th, -60, -60])
            cube([120, 120, 120]);
    }
}

// ! basin_shell();

module basin() {
    rotate([-90, 0, 0])
        basin_shell();

    // translate([0, bubbler_or - rotor_arm_w/2, 0])
    //     difference() {
        
    //     intersection() {
    //         sphere(r=rotor_or + rotor_arm_w + basin_th);
    //         # cube([
    //             2*(rotor_or + 2*rotor_arm_w + basin_th), 
    //             bubbler_or*2 + 2*basin_th + rotor_arm_w, 
    //             2*(rotor_or + 2*rotor_arm_w + basin_th)
    //         ], center=true);
    //     }
    //     sphere(r=rotor_or + rotor_arm_w);
    // }
}

// ! basin();

module design() {
    rotate([0, rt, 0])
        rotor();
    translate([0, -30, 0])
        rotate([90, rt, 0])
        drive_sprocket();

    basin();
}

// design();
*/



module straw(l=50, center=true) {
    difference() {
        rotate([0, 0, -straw_dr])
            cylinder(h=l, r=straw_ir + 1, center=false, $fn=straw_fn);
        if (center)
            rotate([0, 0, -straw_dr])
            cylinder(h=l, r=straw_ir, center=false, $fn=straw_fn);
    }
}

// ! straw();
module straw_xsection() {
    difference() {
        union() {
            translate([curve_ir, 0, 0])
                rotate([0, 0, straw_dr])
                circle(r=straw_ir + 1, $fn=straw_fn);
            translate([0, -(straw_ir + 1) * cos(360 / 5 / 2), 0])
                square([curve_ir + straw_ir, 1]);
        }
        translate([curve_ir, 0, 0])
            rotate([0, 0, straw_dr])
            circle(r=straw_ir, $fn=straw_fn);
    }
}

// ! straw_xsection();

module straw_curve(th=180) {
    rotate_extrude(angle=th) {
        straw_xsection();
    }
    // % translate([0, 0, -straw_ir - 1])
    //     cylinder(r=curve_ir+1, h=2);
}

// ! straw_curve();

module siphon_straw() {
    // translate([
    //         -straw_l/sqrt(2),
    //         0,
    //         -straw_l/sqrt(2)
    //     ])
    //     rotate([90, -135, 0])
    //     straw_curve(th=45);
    translate([-curve_ir * 2, 0, -straw_l - straw_dl1])
            straw(straw_l + straw_dl1, center=true);
    translate([
            -curve_ir, 
            0, 0])
        rotate([90, 0, 0])
        straw_curve();
    translate([
            0, 
            0, -straw_l])
        straw(straw_l);
    translate([
            curve_ir * 2, 
            0, -straw_l])
        straw(straw_l + straw_dl2);
    translate([
            curve_ir, 
            0, -straw_l])
        rotate([90, 180, 0])
            straw_curve();
    translate([
            curve_ir * 3, 
            0, 
            straw_dl2])
        rotate([90, 0, 0])
            straw_curve();
    translate([
            curve_ir * 4, 
            0, -straw_l - straw_dl3 - straw_dl1])
        straw(straw_l + straw_dl1 + straw_dl2 + straw_dl3);
}

// ! siphon_straw();

module self_siphon() {
    * translate([
            -straw_l/sqrt(2) - curve_ir - straw_ir,
            0,
            -straw_l/sqrt(2) - bubbler_or
        ]) {
        rotate([90, 0, 0])
            bubbler_head();
        * % difference() {
            sphere(r=bubbler_or+1);
            sphere(r=bubbler_or);
            rotate([90, 0, 0])
                cylinder(r=bubbler_ir, h=bubbler_or * 3, center=true);

            rotate([0, 45, 0]) {
                straw(bubbler_or+1, center=false);
                
            }

            if ($preview)
                cube([100, 100, 100]);  // TODO: comment

        }
    }
    siphon_straw();
}

self_siphon();
