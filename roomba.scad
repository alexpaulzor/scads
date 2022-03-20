
min_fn = 16;

door_w = 24;
door_th = 2;
tab_th = 2; 
door_ir = 3/2;
door_or = 7/2;
door_l = 198 - door_ir;

tab_clr = 10;
tab_h = 8;

tab_x = door_l - tab_clr * 3;

spring_th = 0.8;

module spring_half(r=tab_clr/3) {
    difference() {
        cylinder(r=r, h=tab_h, $fn=min_fn);
        cylinder(r=r-spring_th, h=tab_h+1, $fn=min_fn);
        translate([-r, 0, 0])
            cube([r, r, tab_h+1]);
    }
}

// ! spring_half();

module spring(r=tab_clr/3) {
    spring_half();
    translate([0, r*2 - spring_th, 0])
        rotate([0, 0, 180])
        spring_half(r=r);
    // translate([tab_clr/4, tab_clr/2 - 2*spring_th, 0])
    //     spring_half(tab_clr/4-spring_th);
    // # translate([tab_clr/4, tab_clr/2 + spring_th, 0])
    //     rotate([0, 0, 180])
    //     spring_half(tab_clr/4-spring_th);
    
}

// ! spring();

module tab_spring_core() {
    // rotate([0, 4, 0])
    //     cube([tab_clr/2, l, tab_h + door_or]);
    // translate([tab_clr/4, 0, 0])
    //     cube([tab_clr/2, l, tab_h + door_or]);
    // translate([tab_clr/2 + 1/2, 0, 0])
    //     rotate([0, -4, 0])
    //     cube([tab_clr/3, l, tab_h + door_or]);
    // translate([tab_clr/2, 0, door_or + tab_h])
    //     rotate([-90, 0, 0])
    //     cylinder(h=l, r=tab_clr/4, center=false, $fn=min_fn);
    difference() {
        // % cube([tab_clr * 2, door_w, tab_h]);
        translate([door_th, 0, 0])
            cube([tab_clr - 2*spring_th, door_w, tab_h+1]);
        for (y=[tab_clr/3:tab_clr + spring_th*2:door_w])
            translate([tab_clr/2 - spring_th/2, y, 0])
            rotate([0, 0, -30])
                spring();
        // difference() {
        //     translate([tab_clr, tab_clr, 0])
        //         cylinder(r=tab_clr/4+1, h=tab_h+1, $fn=min_fn);
        //     translate([tab_clr, tab_clr, 0])
        //         cylinder(r=tab_clr/4, h=tab_h+1, $fn=min_fn);
        // }
    }
    
}

// ! tab_spring_core();

module tab_spring() {
    cube([tab_clr + door_th, door_w, tab_h]);
    translate([-.5, door_w/2, door_th+.5])
        rotate([0, 45, 0])
        cube([door_th, door_w, 2*door_th], center=true);
    translate([tab_clr + door_th + 0.5, door_w/2, door_th+.5])
        rotate([0, -45, 0])
        cube([door_th, door_w, 2*door_th], center=true);
    // translate([tab_clr + door_th, 0, tab_h/2])
    //     rotate([-90, 0, 0])
    //     cylinder(r=tab_h/2, h=door_w, $fn=min_fn);
    // % tab_spring_core();
    // minkowski() {
    //     tab_spring_core(door_w - 1);
    //     // translate([-door_th, 0, 0])
    //         // cube([2*door_th, 0.01, door_th]);
    //     translate([0, 0, door_th + 1.1])
    //         rotate([-90, 0, 0])
    //             cylinder(h=1, r=door_th, center=false, $fn=min_fn);
    // }
    // translate([-door_th, 0, door_th])
    //     rotate([-90, 0, 0])
    //     cylinder(h=door_w, r=door_th, center=false, $fn=min_fn);
    // translate([tab_clr + door_th, 0, door_th])
    //     rotate([-90, 0, 0])
    //     cylinder(h=door_w, r=door_th, center=false, $fn=min_fn);
    // % translate([-tab_x, 0, 0])
    //     cube([door_l, door_w, door_th]);
}


// ! tab_spring();

module roomba_door() {
    difference() {
        union() {
            cube([door_l, door_w, door_th]);
            translate([0, door_w/2 - door_th/2, 0])
                cube([tab_x, door_th, tab_h]);
            translate([0, 0, door_or])
                rotate([-90, 0, 0])
                cylinder(h=door_w, r=door_or, center=false, $fn=min_fn);
            translate([tab_x, 0, 0])
                tab_spring();
        }
        translate([0, 0, door_or])
            rotate([-90, 0, 0])
                cylinder(h=door_w*3, r=door_ir, center=true, $fn=min_fn);
        translate([tab_x, 0, 0])
            tab_spring_core();
        // translate([tab_x, -door_w/2, door_th])
        //     tab_spring_core(door_w*2);
        # translate([door_l - tab_clr/4, door_w/2, door_th/2])
            cube([
                tab_clr/2, door_w - 2*tab_h, door_th],
                center=true);       
    }
}

module hinge_joint() {
    translate([100, 0, 0])
        cube([25, door_w, tab_h]);
}

// ! hinge_joint();

module clip_joint(clr=0) {
    // translate([100, 0, 0])
    //     cube([30, door_w, tab_h+door_th]);
    // translate([90, 0, door_th])
    //     cube([30, door_w, door_th]);
    translate([80, 0, 0])
        cube([20, door_w, tab_h]);
    for (y=[door_w/4, 3*door_w/4])
        translate([80, y, -1])
        intersection() {
            rotate([45, 0, 0])
                cube([40, 2*door_or + clr, 2*door_or + clr]);
            translate([0, -door_or, 1])
                cube([40, 2*door_or + clr, 2*door_or + clr]);
        }
            
}

// ! clip_joint();

module screws() {
    for (x=[105, 115])
        for (y=[door_w/4, 3*door_w/4])
        translate([x, y, 0])
            cylinder(r=3/2, h=30, center=true, $fn=min_fn);
}


module door_clip(screws=true, clr=0) {
    difference() {
        union() {
            difference() {
                // union() {
                    roomba_door();
                    // clip_joint();
                // }
                // # translate([100, -1, 0])
                //     cube([door_l, door_w+2, door_th]); 
                translate([100, -1, -1])
                    cube([door_l, door_w+2, door_w+2]);   
            }
            clip_joint(clr=clr);
        }
        if (screws)
            screws();
    }
}

// ! door_clip();

module door_hinge() {
    difference() {
        union() {
            roomba_door();
            hinge_joint();
        }
        // # translate([0, -1, 0])
        //     cube([100, door_w+2, door_th]); 
        translate([-10, -1, -1])
            cube([110, door_w+2, door_w+2]);
        door_clip(false);
        screws();
        // clip_joint();
        // translate([120, -1, -1])
        //     cube([door_l, door_w+2, door_w+2]);
    }
}

// ! door_hinge();

module design() {
    roomba_door();
    // translate([0, 0, 0])
    //     door_hinge();
    // translate([0, 30, 0])
    //     door_clip(clr=-0.5);

    // % translate([0, -30, 0])
    //     roomba_door();
    // % cube(150);
}

design();

// module test () {
//     % clip_joint(clr=0);
//     clip_joint(clr=-.5);
// }

// ! test();
