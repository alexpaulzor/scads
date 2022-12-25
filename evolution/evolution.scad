th = 1;
frame_w = 120;
flap_w = 20;
frame_l = 120;
wing_l = frame_l / 2;
corner_r = 5;
hole_ir = 5/2;
FOLD_DEG = 45;

module evolution_1() {
    linear_extrude(th, center=true)
        translate([-820, -500])
        import("evolution_1.dxf");
}

// evolution_1();



module evolution_2() {
    rotate([0, 0, 40])
    linear_extrude(th, center=true)
        translate([-700, -420])
        import("evolution_2.dxf");
}

// evolution_2();

module evolution_3() {
    linear_extrude(th, center=true)
        translate([-840, -500])
        import("evolution_3.dxf");
}

// evolution_3();

module evolution_4() {
    linear_extrude(th, center=true)
        translate([-830, -500])
        import("evolution_4.dxf");
}

// evolution_4();

module evolution_5() {
    linear_extrude(th, center=true)
        translate([-830, -460])
        import("evolution_5.dxf");
}

// evolution_5();

module evolution_6() {
    linear_extrude(th, center=true)
        translate([-820, -500])
        import("evolution_6.dxf");
}

// evolution_6();

module evolution_7() {
    linear_extrude(th, center=true)
        translate([-850, -500])
        import("evolution_7.dxf");
}

// evolution_7();

module evolution_8() {
    linear_extrude(th, center=true)
        translate([-850, -500])
        import("evolution_8.dxf");
}

// evolution_8();

module evolution_9_mask() {
    translate([370, 144, 0])
        rotate([0, 0, 22])
        cube([100, 10, 10], center=true);
    translate([370, 144, 0])
        rotate([0, 0, -32])
        cube([100, 10, 10], center=true);
    translate([-370, -117, 0])
        rotate([0, 0, 25])
        cube([100, 10, 10], center=true);
    translate([-370, -117, 0])
        rotate([0, 0, 65])
        cube([100, 10, 10], center=true);
    translate([-370, -237, 0])
        rotate([0, 0, 0])
        cube([100, 10, 10], center=true);
    translate([-480, -260, 0])
        rotate([0, 0, 1])
        cube([300, 10, 10], center=true);

    translate([-170, -223, 0])
        rotate([0, 0, 5])
        cube([120, 10, 10], center=true);

    translate([-190, -245, 0])
        rotate([0, 0, 5])
        cube([100, 10, 10], center=true);

    translate([330, -210, 0])
        rotate([0, 0, 5])
        cube([120, 10, 10], center=true);

    translate([310, -233, 0])
        rotate([0, 0, 5])
        cube([100, 10, 10], center=true);

    translate([450, 10, 0])
        rotate([0, 0, -5])
        cube([100, 10, 10], center=true);
}

module evolution_9() {
    difference() {
        linear_extrude(th, center=true)
            translate([-840, -500])
            import("evolution_9.dxf");
        evolution_9_mask();
    }
}

// ! evolution_9();

module evolution_10() {
    linear_extrude(th, center=true)
        translate([-840, -500])
        import("evolution_10.dxf");
}

// ! evolution_10();

module evolution_11() {
    linear_extrude(th, center=true)
        translate([-840, -550])
        import("evolution_11.dxf");
}

// ! evolution_11();

module evolution_12() {
    linear_extrude(th, center=true)
        translate([-840, -500])
        import("evolution_12.dxf");
}

// evolution_12();

module evolution_13() {
    linear_extrude(th, center=true)
        translate([-840, -500])
        import("evolution_13.dxf");
}

// evolution_13();

module evolution_14() {
    linear_extrude(th, center=true)
        translate([-840, -450])
        import("evolution_14.dxf");
}

// evolution_14();

num_frames = 14;

module get_dxf(t=$t) {
    if (t <= 1/num_frames)
        evolution_1();
    else if (t <= 2/num_frames)
        evolution_2();
    else if (t <= 3/num_frames)
        evolution_3();
    else if (t <= 4/num_frames)
        evolution_4();
    else if (t <= 5/num_frames)
        evolution_5();
    else if (t <= 6/num_frames)
        evolution_6();
    else if (t <= 7/num_frames)
        evolution_7();
    else if (t <= 8/num_frames)
        evolution_8();
    else if (t <= 9/num_frames)
        evolution_9();
    else if (t <= 10/num_frames)
        evolution_10();
    else if (t <= 11/num_frames)
        evolution_11();
    else if (t <= 12/num_frames)
        evolution_12();
    else if (t <= 13/num_frames)
        evolution_13();
    else if (t <= 14/num_frames)
        evolution_14();
    
}

// get_dxf();

module flap_holes() {
    // for (x=[flap_w:flap_w:wing_l - flap_w]) {
    translate([wing_l - flap_w/2, flap_w/2, 0])
        cylinder(r=hole_ir, h=2*th, center=true, $fn=64);
    // }
}

module frame_wing_flap(fold_deg=FOLD_DEG) {
    flap_deg = fold_deg == 0 ? 0 : 35;
    difference() {
        translate([0, 0, -th/2])
            cube([wing_l, frame_w, th], center=false);
        translate([0, 0, -th])
            rotate([0, 0, 60])
            cube([wing_l*2, frame_w, th*2], center=false);
        translate([wing_l, 0, -th])
            rotate([0, 0, 30])
            cube([wing_l*2, frame_w*2, th*2], center=false);
    }
    rotate([flap_deg, 0, 60])
        difference() {
            translate([0, 0, -th/2])
                cube([wing_l, flap_w, th], center=false);
            rotate([0, 0, 30])
                translate([0, -1, -th])
                cube([wing_l, flap_w, 2*th], center=false);
            
            for (x=[20:20:wing_l]) {
                translate([x, 0, -th])
                cube([5, 1, th * 2]);
            }
            flap_holes();
        }
    
}

// ! frame_wing_flap();
// ! frame_wing_flap(fold_deg=0);

module frame_wing_folded(fold_deg=FOLD_DEG) {
    wing_deg = fold_deg == 0 ? 0 : 35;
    difference() {
        translate([0, 0, -th/2])
            cube([wing_l, frame_w, th], center=false);
        flap_holes();
        for (y=[20:20:frame_w]) {
            translate([0, y, -th])
            cube([1, 5, th * 2]);
        }
        for (x=[20:20:wing_l]) {
            // translate([x, 0, -th])
            //     cube([5, 1, th * 2]);
            translate([x, frame_w - 1, -th])
                cube([5, 1, th * 2]);
        }
    }
    translate([0, frame_w, 0])
        rotate([wing_deg, 0, 0])
        frame_wing_flap(fold_deg=fold_deg);
    // rotate([180 - wing_deg, 0, 0])
    //     difference() {
    //         translate([0, 0, -th/2])
    //             cube([frame_l, frame_w, th], center=false);
    //         translate([0, 0, -th])
    //             rotate([0, 0, 30])
    //             cube([frame_l*2, frame_w, th*2], center=false);
    //         translate([frame_l, 0, -th])
    //             rotate([0, 0, 30])
    //             cube([frame_l, frame_w, th*2], center=false);
    //     }
}

// ! frame_wing_folded();
// ! frame_wing_folded(fold_deg=0);

module frame_folded(fold_deg=FOLD_DEG) {
    cube([frame_l, frame_w, th], center=true);
    for (r=[0:90:360]) {
        rotate([0, 0, r]) {
            translate([frame_l/2, -frame_w/2, 0])
                rotate([0, -fold_deg, 0])
                frame_wing_folded(fold_deg=fold_deg);
        }
    }
}

// ! frame_folded();
// ! frame_folded(fold_deg=0);

// module frame() {
//     difference() {
//         minkowski() {
//             cube([frame_l + 0.1, frame_w + 0.1, th], center=true);
//             cylinder(r=corner_r, h=0.001);
//         }
//         minkowski() {
//             cube([frame_l, frame_w, 2*th], center=true);
//             cylinder(r=corner_r, h=0.001);
//         }
//     }
// }

// frame();


module framed_frame(f=1, scl=0.25) {
    difference() {
        frame_folded(fold_deg=0);
        scale([scl, scl, 1])
            get_dxf(f/num_frames);
    }
}

// framed_frame(f=9, scl=0.095);

module plate_frame(f=1, scl=0.25) {
    projection() {
        framed_frame(f=f, scl=scl);
    }
}

module ev_frame_1() {
    plate_frame(1, 0.25);
}
// ev_frame_1();
module ev_frame_2() {
    plate_frame(2, 0.1);
}
// ev_frame_9();
module ev_frame_3() {
    plate_frame(3, 0.15);
}
module ev_frame_4() {
    plate_frame(4, 0.2);
}
module ev_frame_5() {
    plate_frame(5, 0.2);
}
module ev_frame_6() {
    plate_frame(6, 0.12);
}
module ev_frame_7() {
    plate_frame(7, 0.1);
}
module ev_frame_8() {
    plate_frame(8, 0.095);
}
module ev_frame_9() {
    plate_frame(9, 0.095);
}

! ev_frame_9();

module ev_frame_10() {
    plate_frame(10, 0.1);
}
module ev_frame_11() {
    plate_frame(11, 0.15);
}
module ev_frame_12() {
    plate_frame(12, 0.1);
}
module ev_frame_13() {
    plate_frame(13, 0.12);
}
module ev_frame_14() {
    plate_frame(14, 0.15);
}

