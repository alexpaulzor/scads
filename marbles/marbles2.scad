use <../lib/t2020beam.scad>;
/*
base_fn = 64;

marble_od = 16.2;
wire_od = 2.1;
// wire_pitch = 8.0;

// ring_od = 27;

th = 0.8;


// num_wires = 6;
// num_screws = 1;
// screw_od = 5;
// small_screw_od = 3;

// // screw_c_c = ring_id/2 - clr + wire_od + 10;

// // small_screw_c_c = (ring_id / 2 + screw_c_c) / 2 - th;
// small_screw_c_c = screw_c_c - screw_od - small_screw_od/2;



// wire_thetas = [0:90:360];
// echo(wire_thetas=wire_thetas);
// jig_inner_th = 5;
// jig_outer_th = 5;


jig_inner_or = marble_od/2 + wire_od * 1.5 - clr;
jig_outer_ir = jig_inner_or + clr; // marble_od/2 + wire_od/2;
jig_outer_or = jig_outer_ir + wire_od * 2; // marble_od/2 + wire_od * (1 + grip_ratio)

jig_loop_r = marble_od/2 + wire_od * 3/2;

// */

base_fn = 64;

marble_od = 16.2;
wire_od = 2.1;

// Ratio of height of circle to cover, leaving 1-grip_ratio of wire exposed
grip_ratio = 0.85;
// Total clearance between 2 parts (i.e. half each side if within)
clr = 0.4;

wire_thetas = [0:90:270];
ring_th = 4;

wire_pitch = marble_od/2 + wire_od;
out_ring_or = marble_od/2 + wire_od + ring_th;
out_ring_ir = wire_pitch - wire_od * grip_ratio/2 + clr;


/*

Design Criteria:
* Full circle (for strength)
* Use 4 wire holes
* Two main types: Outie and Innie


*/

module marble() {
    sphere(r=marble_od/2, $fn=base_fn*2);
}

// ! marble();


module wire(h=40) {
    cylinder(r=wire_od/2, h=h, $fn=base_fn/2, center=true);
}

// ! wire();



module wires(dr=0, h=40) {
    for (r=wire_thetas) {
        rotate([0, 0, r])
            translate([wire_pitch, 0, 0])
            wire(h=h);
    }
}

// ! wires();


module out_ring() {
    difference() {
        union() {
            cylinder(
                r=out_ring_or, 
                h=ring_th, center=true, $fn=base_fn);
        }
        wires();
        // for (r=wire_thetas) {
        //     rotate([0, 0, r + 45])
        //         translate([(out_ring_or + out_ring_ir) / 2, 0, 0])
        //         cylinder(r=3/2, h=ring_th + 1, center=true, $fn=base_fn/2);
        // }
        cylinder(
            r=out_ring_ir, 
            h=ring_th + 2, center=true, $fn=base_fn);
        // translate([jig_loop_r, 0, 0])
        //     cylinder(r=5/2, h=10, center=true, $fn=base_fn);
        // // translate([jig_loop_r + clr*2, 0, 0])
        // //     wire();
        // loop();
    }
}

// ! out_ring();


// module in_ring() {
//     difference() {
//         union() {
//             out_ring();
//         }
//         wires(h=50, dr=ring_th);
//         % wires(h=ring_th, dr=ring_th);
        
//     }
// }

// // ! in_ring();


// module rail() {
//     // % translate([marble_od/2 + wire_od/2, 0, 0]) 
//     //     in_ring();

//     difference() {
//         union() {
//             cylinder(r=wire_od/2, h=marble_od * 2.2, $fn=base_fn, center=true);
//             translate([-ring_th + wire_od / 1.25, 0, ring_th/2 + clr/2])
//                 cylinder(r1=wire_od, r2=wire_od/2, h=marble_od/2, $fn=base_fn/2, center=false);
//             translate([-ring_th + wire_od / 1.25, 0, -ring_th/2 - marble_od/2 - clr/2])
//                 cylinder(r2=wire_od, r1=wire_od/2, h=marble_od/2, $fn=base_fn/2, center=false);
//         }
//         translate([-ring_th, 0, ring_th/2])
//             rotate([0, 10, 0])
//             cylinder(r=wire_od/2, h=marble_od * 2 - ring_th/2, $fn=base_fn/2);


//         translate([-ring_th, 0, -ring_th/2])
//             rotate([0, 170, 0])
//             cylinder(r=wire_od/2, h=marble_od * 2 - ring_th/2, $fn=base_fn/2);
//     }

// }

// // ! rail();


// module rails(dr=0, h=40) {
//     for (r=wire_thetas) {
//         rotate([0, 0, r])
//             translate([-marble_od/2 - wire_od/2 - dr, 0, 0])
//             rail();
//     }
// }

// // ! rails();

guide_l = 30;
track_inside_w = 10;

module t2020_guide() {
    difference() {
        union() {
            translate([-guide_l/2, -10, -1])
                cube([guide_l, 20, 2 * wire_od + 1]);
            # translate([-(guide_l - 20)/2, -3, -2.4])
                cube([guide_l - 20, 6, 2 * wire_od + 0.6]);
        }

        for (i=[-1, 1]) {
            translate([0, i * track_inside_w / 2, wire_od/2])
                rotate([0, 90, 0])
                cylinder(r=wire_od/2, h=3 * guide_l, center=true, $fn=base_fn);
            translate([0, i * 5, 0])
                rotate([0, 90, 0])
                cylinder(r=wire_od/2 * sqrt(2), h=3 * guide_l, center=true, $fn=4);
            translate([-guide_l/2 - 1, (i > 0 ? 3 : -11), -2])
                cube([guide_l + 2, 8, 2 + wire_od * (1 - grip_ratio)]);
        }

        for (i=[-1, 0, 1]) {
            translate([i * (guide_l / 2 - 5), 0, 0])
                cylinder(r=5/2, h=10, center=true, $fn=base_fn);
        }
        
        
    }
}

! t2020_guide();


module design() {
    color("gray")
        translate([0, 0, -10])
        rotate([0, 90, 0])
        t2020(150);
    rotate([0, 0, 90])
    t2020_guide();
}

design();



module plate() {
    t2020_guide();
}

// ! plate();


/*

module loop() {
    rotate_extrude($fn=base_fn) {
        translate([jig_loop_r, 0, 0])
        circle(r=wire_od/2, $fn=base_fn/2);
    }
    // % translate([jig_loop_r, 0, 0])
    //     rotate([90, 0, 0])
    //     cylinder(r1=wire_od/2, r2=wire_od/2 + clr, h=marble_od, $fn=base_fn/2);
    // translate([-wire_od*2.5, 0, 0])
    //     rotate_extrude(angle=90, $fn=base_fn) {
    //     translate([jig_loop_r + wire_od * 2.5, 0, 0])
    //     circle(r=wire_od/2 + clr, $fn=base_fn/2);
    // }
}

// ! loop();

// module jig_inner() {
//     difference() {
//         union() {
//             cylinder(
//                 r=jig_inner_or - jig_inner_th/2, 
//                 h=jig_inner_th, center=true, $fn=base_fn);
//             rotate_extrude($fn=base_fn) {
//                 translate([jig_inner_or - jig_inner_th/2, 0, 0])
//                 circle(r=jig_inner_th/2, $fn=base_fn/2);
//             }
//         }
//         wires();
//         wires(dr=wire_od * grip_ratio);
//         loop();
//         cylinder(r=5/2, h=jig_inner_th + 1, center=true, $fn=base_fn/2);
//         translate([-clr/2, 0, -jig_inner_th/2-1])
//             cube([clr, jig_inner_or, jig_inner_th + 2]);
//     }
// }

// // ! jig_inner();





// module design2() {
//     // color([1, 0, 0, 0.75])
//         jig_inner();
//     // color([0, 1, 0, 0.75])
//         jig_outer();
//     *% marble();
// }

// design2();

// module cutaway() {
//     difference() {
//         design2();
//         cube([100, 100, 100]);
//     }
// }

// // ! cutaway();

// module plate() {
//     translate([0, 0, jig_inner_th/2])
//         jig_inner();
//     translate([marble_od * 1.5 + wire_od * 2, 0, jig_outer_th/2])
//         jig_outer();
// }

// ! plate();

module wire3(h=40) {
    cylinder(r=wire_od/2, h=h, $fn=base_fn/2, center=true);
}

// module jig_inner3() {
//     difference() {
//         union() {
//             cylinder(
//                 r=jig_inner_or - jig_inner_th/2, 
//                 h=jig_inner_th, center=true, $fn=base_fn);
//             rotate_extrude($fn=base_fn) {
//                 translate([jig_inner_or - jig_inner_th/2, 0, 0])
//                 circle(r=jig_inner_th/2, $fn=base_fn/2);
//             }
//         }
//         wires();
//         wires(dr=wire_od * grip_ratio);
//         loop();
//         cylinder(r=5/2, h=jig_inner_th + 1, center=true, $fn=base_fn/2);
//         * translate([-clr/2, 0, -jig_inner_th/2-1])
//             cube([clr, jig_inner_or, jig_inner_th + 2]);
//     }
// }

// // ! jig_inner3();

spacer_th = 2;
spacer_ir = marble_od/2 + clr;
spacer_or = spacer_ir + 5; // marble_od/2 + wire_od/2;
wire_bend_r = 10;

module spacer_outside() {
    difference() {
        cylinder(h=spacer_th, r=spacer_or, center=true, $fn=base_fn);
        cylinder(h=spacer_th + 1, r=spacer_ir, center=true, $fn=base_fn);
        wires();
    }
}
// ! spacer_outside();


module spacer_inside() {
    difference() {
        cylinder(h=spacer_th, r=spacer_ir + 1, center=true, $fn=base_fn);
        cylinder(h=spacer_th + 1, r=spacer_ir, center=true, $fn=base_fn);
        wires();
    }
}
// ! spacer_inside();


module design3() {
    for (i=[-1, 1]) {
        translate([0, 0, i * marble_od])
            spacer_outside();
    }
    spacer_inside();
    % marble();
    % wires();
}

// design3();

module cutaway() {
    difference() {
        design2();
        cube([100, 100, 100]);
    }
}

// ! cutaway();

module plate() {
    translate([0, 0, jig_inner_th/2])
        jig_inner();
    translate([marble_od * 1.5 + wire_od * 2, 0, jig_outer_th/2])
        jig_outer();
}

// ! plate();



// // module ring() {
// //     difference() {
// //         union() {
// //             cylinder(r=ring_od/2, h=ring_th, center=true, $fn=base_fn);
// //             for (r=[0:360/num_wires:360 * num_screws / num_wires - 1]) {
// //                 rotate([0, 0, r + 180/num_wires]) {
// //                     translate([screw_c_c, 0, 0]) {
// //                         cylinder(r=5, h=ring_th, center=true, $fn=base_fn);    
// //                     }
// //                     translate([small_screw_c_c, 0, 0]) {
// //                         cylinder(r=5, h=ring_th, center=true, $fn=base_fn);    
// //                     }
// //                 }
// //             }
// //         }
// //         cylinder(r=ring_id/2, h=ring_th + 1, center=true, $fn=base_fn);
// //         cylinder(r1=ring_id/2, r2=ring_id/2 + th, h=ring_th/2 + 0.01, center=false, $fn=base_fn);
// //         union() {
// //             for (r=[0:360/num_wires:360]) {
// //                 rotate([0, 0, r])
// //                     translate([ring_id/2 + wire_od/2 + th, 0, -ring_th - 1])
// //                     cylinder(r=wire_od/2, h=10, $fn=base_fn);

// //                 rotate([0, 0, r + 7])
// //                     translate([ring_id/2 + wire_od/2 + th + clr/2, 0, -ring_th - 1])
// //                     cylinder(r=wire_od/2 + clr/2, h=10, $fn=base_fn);
// //                 rotate([0, 0, r + 14])
// //                     translate([ring_id/2 + th, 0, -ring_th - 1])
// //                     cylinder(r=wire_od/2 + clr/2, h=10, $fn=base_fn);
// //             }
            
// //             for (r=[0:360/num_wires:360]) {
// //                  rotate([0, 0, r])
// //                 translate([ring_id/2, 0, 0])
// //                     rotate([0, 0, 2])
// //                         translate([-marble_od/2, 0, 0])
// //                         cylinder(r=marble_od/2, h=ring_th*3, center=true, $fn=base_fn);
            
// //             }
// //             for (r=[0:360/num_wires:360 * num_screws / num_wires - 1]) {
// //                 rotate([0, 0, r + 180/num_wires]) {
// //                     translate([screw_c_c, 0, 0]) {
// //                         cylinder(r=screw_od/2, h=ring_th + 1, center=true, $fn=base_fn);    
// //                     }
// //                     translate([small_screw_c_c, 0, 0]) {
// //                         cylinder(r=small_screw_od/2, h=ring_th + 1, center=true, $fn=base_fn);    
// //                     }
// //                 }
// //             }
// //         }
// //     }

// // }

// // ! ring();

// module beam(l) {
//     translate([0, -l/2, 0])
//         cube([10, l, 10]);
//     translate([-10, -l/2, -10])
//         cube([10, l, 10]);
//     cube([20, l, 20], center=true);
// }

// // module design() {
// //     // % marble();
// //     color([0, 0, 1, 1])
// //         ring();
// //     % color([0, 1, 0, 0.5])
// //         translate([0, 0, -ring_th])
// //         rotate([180, 0, 360/num_wires])
// //         ring();

// //     % translate([ring_id/2 - marble_od/2, ring_id/2 - marble_od/2, 0])
// //         marble();
// //     // * translate([-3, 0, marble_od/2])
// //         // marble();
    

// //     * % rotate([0, 0, 180/num_wires])
// //         translate([screw_c_c, 0, 0])
// //         beam(60);
// // }

// // design();

// */
