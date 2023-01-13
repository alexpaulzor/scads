IN_MM = 25.4;

th = 3;
frame_l = 100;
flap_w = 20;
wing_l = frame_l / 2;
corner_r = 5;
hole_ir = 3/2;
FOLD_DEG = 90;

mesh_hole = 10;
mesh_wall = 3;
mesh_dx = 1.5 * mesh_hole + mesh_wall;
mesh_dy = mesh_hole * cos(30) + mesh_wall;

chain_h = 11; // at smallest point
chain_w = 15; 

num_frames = 18;

finger_d = 4;
finger_w = 6;

m3_d = 2.5;
m3_w = 5.5;
m3_or = 3/2;
screw_l = 10;

module mesh() {
    difference() {
        square([frame_l - finger_d*2, frame_l - finger_d*2], center=true);
        for (x=[
                -frame_l/2:
                mesh_dx:
                frame_l/2 + mesh_dx]) {
            for (y=[
                    -frame_l/2:
                    mesh_dy:
                    frame_l/2 + mesh_dy]) {
                translate([x, y, 0]) {
                    // % cube([mesh_hole, mesh_hole, 2*th], center=true);
                    circle(r=mesh_hole/2, $fn=6);
                }
                translate([
                        x + mesh_dx/2, 
                        y - mesh_dy/2, 0]) {
                    circle(r=mesh_hole/2, $fn=6);
                    // % cube([mesh_hole, mesh_hole, 2*th], center=true);
                }
            }
        }
        projection()
            offs_chain_holes();
    }
}

// ! mesh();

module evolution_1() {
    scale([0.175, 0.175, 1.1])
    linear_extrude(th, center=true)
        translate([-820, -500])
        import("evolution_1b.dxf");
}

// evolution_1();

module evolution_2() {
    scale([0.1, 0.08, 1.1])
    rotate([0, 0, 40])
    linear_extrude(th, center=true)
        translate([-700, -420])
        import("evolution_2c.dxf");
}

// evolution_2();

module evolution_3() {
    scale([0.125, 0.125, 1.1])
    linear_extrude(th+1, center=true)
        translate([-820, -480])
        import("evolution_3b.dxf");
}

// ! projection() evolution_3();

module evolution_4() {
    scale([0.175, 0.175, 1.1])
    linear_extrude(th, center=true)
        translate([-830, -480])
        import("evolution_4b.dxf");
}

// ! evolution_4();

module evolution_4_5() {
    scale([0.25, 0.25, 1.1])
    linear_extrude(th, center=true)
        translate([-230, -200])
        import("evolution_4_5.dxf");
}

// ! evolution_4_5();

module evolution_5() {
    scale([0.15, 0.15, 1.1])
    linear_extrude(th, center=true)
        translate([-830, -460])
        import("evolution_5b.dxf");
}

// ! evolution_5();

module evolution_5_5() {
    scale([0.2, 0.2, 1.1])
    linear_extrude(th, center=true)
        translate([-150, -260])
        import("evolution_5_5.dxf");
}

// ! evolution_5_5();

module evolution_6() {
    scale([0.09, 0.09, 1.1])
    linear_extrude(th, center=true)
        translate([-820, -500])
        import("evolution_6b.dxf");
}

// ! evolution_6();

module evolution_7() {
    scale([0.08, 0.08, 1.1])
    linear_extrude(th, center=true)
        translate([-850, -500])
        import("evolution_7b.dxf");
}

// ! evolution_7();

module evolution_7_5() {
    scale([0.115, 0.115, 1.1])
    linear_extrude(th, center=true)
        translate([-420, -200])
        import("evolution_7_5.dxf");
}

// ! evolution_7_5();

module evolution_8() {
    scale([0.07, 0.07, 1.1])
    linear_extrude(th, center=true)
        translate([-850, -500])
        import("evolution_8b.dxf");
}

// ! evolution_8();

module evolution_9() {
    scale([0.075, 0.075, 1.1])
    linear_extrude(th, center=true)
        translate([-800, -500])
        import("evolution_9.dxf");
}

// ! evolution_9();

module evolution_10() {
    scale([0.09, 0.09, 1.1])
    linear_extrude(th, center=true)
        translate([-820, -500])
        import("evolution_10b.dxf");
}

// ! evolution_10();

module evolution_10_5() {
    scale([0.12, 0.12, 1.1])
    linear_extrude(th, center=true)
        translate([-440, -250])
        import("evolution_10_5.dxf");
}

// ! evolution_10_5();

module evolution_11() {
    scale([0.125, 0.125, 1.1])
    linear_extrude(th, center=true)
        translate([-820, -550])
        import("evolution_11b.dxf");
}

// ! evolution_11();

module evolution_12() {
    scale([0.07, 0.07, 1.1])
    linear_extrude(th, center=true)
        translate([-840, -500])
        import("evolution_12b.dxf");
}

// evolution_12();

module evolution_13() {
    scale([0.1, 0.1, 1.1])
    linear_extrude(th, center=true)
        translate([-820, -475])
        import("evolution_13d.dxf");
}

// evolution_13();

module evolution_14() {
    scale([0.12, 0.12, 1.1])
    linear_extrude(th, center=true)
        translate([-840, -450])
        import("evolution_14b.dxf");
}

// evolution_14();

module get_dxf(f=1) {
    if (f <= 1)
        evolution_1();
    else if (f <= 2)
        evolution_2();
    else if (f <= 3)
        evolution_3();
    else if (f <= 4)
        evolution_4();
    else if (f <= 4.5)
        evolution_4_5();
    else if (f <= 5)
        evolution_5();
    else if (f <= 5.5)
        evolution_5_5();
    else if (f <= 6)
        evolution_6();
    else if (f <= 7)
        evolution_7();
    else if (f <= 7.5)
        evolution_7_5();
    else if (f <= 8)
        evolution_8();
    else if (f <= 9)
        evolution_9();
    else if (f <= 10)
        evolution_10();
    else if (f <= 10.5)
        evolution_10_5();
    else if (f <= 11)
        evolution_11();
    else if (f <= 12)
        evolution_12();
    else if (f <= 13)
        evolution_13();
    else if (f <= 14)
        evolution_14();
    
}

// get_dxf();


module screws(l=frame_l - finger_w * 4) {
    for (y=[
            (l == 0 ? 0 : 4 * finger_w):
            4 * finger_w:
            (l == 0 ? finger_w : l/2 - finger_w)]) {
        for (i=[-1, 1])
            translate([0, i * y, -th/2]) {
                translate([0, 0, -th])
                    cylinder(
                    r=m3_or, h=screw_l + th, center=false, $fn=64);
                translate([0, 0, screw_l/2 + th/2])
                    cube([m3_w, m3_or * 2, screw_l - th], center=true);
                translate([0, 0, 2.5 * th])
                    cube([m3_w,  m3_w, m3_d], center=true);
                // translate([0, 0, -(finger_d - th)/2])
                //     cube([m3_w, m3_or * 2, finger_d - th], center=true);
            }
    }
}

// ! screws();

// module center_finger(include_screws=true, include_screw_hole=false) {
//     difference() {
//         // translate([(-finger_d/2 + th/2), 0, -(finger_d - th)/2]) {
//         //     cube([
//         //         finger_d, 
//         //         finger_w, 
//         //         finger_d], center=true);
//         // }
//         if (include_screw_hole) {
//             screws(0);
//         }
//     }
//     if (include_screws) {
//         screws(0);
//     }
// }

// ! finger();

module fingers(l=frame_l - finger_w * 4, include_screws=true) {
    difference() {
            for (y=[
                2 * finger_w:
                2 * finger_w:
                l/2]) {
            // if (y % (6 * finger_w) != 0)
            for (i=[-1, 1])
                translate([(-finger_d/2 + th/2), i * y, -(finger_d - th)/2]) {
                    cube([
                        finger_d, 
                        finger_w, 
                        finger_d], center=true);
                }
        }
        if (!include_screws) {
            screws(l);
        }
    }
    if (include_screws) {
        screws(l);
    }
}

// ! fingers();

module frame_fingers() {
    for (r=[0:90:90]) {
        rotate([0, 0, r]) {
            translate([frame_l/2 - finger_d + th/2, 0, 0])
                rotate([0, -90, 0])
                fingers();
            translate([frame_l/2 - finger_d + th/2, 0, 0])
                rotate([0, 0, 0])
                screws(0);
                // center_finger(true);
        }
    }
}

module frame_wing(include_screws=false) {
    difference() {
        union() {
            fingers(include_screws=include_screws);
            translate([
                    (frame_l - finger_d)/2 + th/2, -finger_d/2, 0])
                cube([
                    frame_l - finger_d, 
                    frame_l - finger_d, th], center=true);

            translate([
                    frame_l/2 - finger_d/2, 
                    frame_l / 2 - finger_d + th/2, 0])
                rotate([0, 0, -90])
                fingers(include_screws=include_screws);
        }
        translate([chain_w, -frame_l/2 + chain_h/2, 0])
            rotate([45, 0, 0])
            cube([chain_w, chain_h, 100], center=true);
        translate([0, 0, 0])
            rotate([0, 90, 0])
            screws(0);
            // center_finger();
        translate([
                frame_l/2 - finger_d/2, 
                frame_l / 2 - finger_d + th/2, 0])
            rotate([90, 90, 0])
            screws(0);
            // center_finger();
    }
    
}

// ! 
//     // projection()
    // ! frame_wing();

module frame_cap(include_screws=false) {
    difference() {
        union() {
            rotate([0, 0, 90])
                fingers(include_screws=include_screws);
            translate([0, frame_l/2 + th/2 - finger_d/2, 0])
                cube([
                    frame_l, 
                    frame_l - finger_d, th], center=true);
        }
        translate([
                frame_l/2 - finger_d + th/2, 
                frame_l/2 - finger_d/2, 0])
            rotate([0, -90, 0])
                fingers(include_screws=true);
        translate([-frame_l/2 + chain_h/2, chain_w])
            rotate([0, -45, 0])
            cube([chain_h, chain_w, 100], center=true);
        translate([0, 0, 0])
            rotate([-90, -90, 0])
            screws(0);
            // center_finger();
        translate([
                frame_l/2 - finger_d + th/2, 
                frame_l / 2 - finger_d + th/2, 0])
            rotate([0, 0, 180])
            screws(0);
            // center_finger();
    }
}

// ! 
//     // projection()
//     // # 
    // ! frame_cap();

// module offs_chain_holes() {
//     translate([-frame_l/2 + flap_w, 0, 0])
//         chain_holes();
// }

module frame_base() {
    difference() {
        cube([frame_l, frame_l, th], center=true);
        frame_fingers();
        // offs_chain_holes();
    }
}

// ! frame_base();

module frame_folded(fold_deg=FOLD_DEG) {
    offs = fold_deg == 0 ? finger_d*2 : 0;
    color([1, 0, 0, 0.5])
        frame_base();
    // if (fold_deg != 0) {
    color([0, 1, 0, 0.5])
        translate([frame_l/2 - finger_d + th/2 + offs, 0, 0])
        rotate([0, -fold_deg, 0])
        frame_wing();
    color([0, 0, 1, 0.5])
        translate([0, frame_l/2 - finger_d + th/2 + offs, 0])
        rotate([fold_deg, 0, 0])
        frame_cap();
    // }
}


// frame_folded();
projection()
frame_folded(fold_deg=0);

module plate_base() {
    projection() 
        frame_base();
}

// ! plate_base();

module plate_wing() {
    projection() 
        frame_wing();
}

// ! plate_wing();

module plate_cap() {
    projection() 
        frame_cap();
}

// ! plate_cap();

module stock_panel() {
    % translate([-3 * IN_MM, -3 * IN_MM, -1/16 * IN_MM])
        cube([12 * IN_MM, 12 * IN_MM, 1/8 * IN_MM]);
}

// stock_panel();

module plate_frame(f=1) {
    difference() {
        projection()
            frame_folded(fold_deg=0);
        projection()
            get_dxf(f);
    }
    // projection()
        mesh();
}

// plate_frame(12);

// plate_frame($t * num_frames);

module plate_all() {
    plate_frame(1);
    translate([
            (frame_l + wing_l * 2 + 1), 0, 0])
        plate_frame(2);
    translate([
            2 * (frame_l + wing_l * 2 + 1), 0, 0])
        plate_frame(3);
    translate([
            3 * (frame_l + wing_l * 2 + 1), 0, 0])
        plate_frame(4);
    translate([0, 
            (frame_l + wing_l * 2 + 1), 0])
        plate_frame(4.5);
    translate([(frame_l + wing_l * 2 + 1), 
            (frame_l + wing_l * 2 + 1), 0])
        plate_frame(5);
    translate([2 * (frame_l + wing_l * 2 + 1), 
            (frame_l + wing_l * 2 + 1), 0])
        plate_frame(5.5);
    translate([3 * (frame_l + wing_l * 2 + 1), 
            (frame_l + wing_l * 2 + 1), 0])
        plate_frame(6);
    translate([0, 
            2 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(7);
    translate([(frame_l + wing_l * 2 + 1), 
            2 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(7.5);
    translate([2 * (frame_l + wing_l * 2 + 1), 
            2 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(8);
    translate([3 * (frame_l + wing_l * 2 + 1), 
            2 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(9);
    translate([0, 
            3 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(10);
    translate([(frame_l + wing_l * 2 + 1), 
            3 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(10.5);
    translate([2 * (frame_l + wing_l * 2 + 1), 
            3 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(11);
    translate([3 * (frame_l + wing_l * 2 + 1), 
            3 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(12);
    translate([0, 
            4 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(13);
    translate([(frame_l + wing_l * 2 + 1), 
            4 * (frame_l + wing_l * 2 + 1), 0])
        plate_frame(14);
    
    
    
}

// plate_all();
