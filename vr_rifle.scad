IN_MM = 25.4;
$fn = 24;

RAIL_W = 1*IN_MM;
GROOVE_SIDE = 5;
TOUNGE_L = 20;
HOLE_OR = 3;
TOUNGE_H = 16;
CONTROLLER_H = 150;
MIN_SEP = 30;
MOUNT_L = 40;
CLEARANCE = 1;

module mount() {
    difference() {
        cube([
            MOUNT_L, 
            RAIL_W + 2 * GROOVE_SIDE,
            RAIL_W + 4 * GROOVE_SIDE], center=true);
        difference() {
            cube([MOUNT_L, RAIL_W + CLEARANCE, RAIL_W + 2 * GROOVE_SIDE], center=true);
            
            for (y=[-1,1]) {
                for (z=[-1, 0, 1]) {
                    
                    translate([0, y*(RAIL_W/2 + CLEARANCE), z * (RAIL_W/2 + GROOVE_SIDE)])
                        rotate([45, 0, 0])
                        cube([MOUNT_L, GROOVE_SIDE, GROOVE_SIDE], center=true);
                }
            }
        }
        rotate([90, 0, 0]) 
            cylinder(r=HOLE_OR, h=RAIL_W * 2, center=true);
    }
}

module cross_section(length) {
    difference() {
        cube([length, RAIL_W, RAIL_W], center=true);
        translate([0, RAIL_W/2, 0])
            rotate([45, 0, 0])
            cube([length, GROOVE_SIDE, GROOVE_SIDE], center=true);
        translate([0, -RAIL_W/2, 0])
            rotate([45, 0, 0])
            cube([length, GROOVE_SIDE, GROOVE_SIDE], center=true);
    }
}

module tounge() {
    difference() {
        intersection() {
            cross_section(TOUNGE_L + 1);
            cube([TOUNGE_L + 2, RAIL_W, TOUNGE_H - CLEARANCE], center=true);
        }
        cylinder(r=HOLE_OR, h=RAIL_W, center=true);
    }
}

module slot() {
    difference() {
        cross_section(TOUNGE_L + 1);
        cube([TOUNGE_L + 2, RAIL_W, TOUNGE_H + CLEARANCE], center=true);
        cylinder(r=HOLE_OR, h=RAIL_W, center=true);
    }
}

module straight_rail(length=3 * MIN_SEP) {
    difference() {
        union() {
            translate([length / 2 + TOUNGE_L / 2, 0, 0])
                tounge();
            translate([-length / 2 - TOUNGE_L / 2, 0, 0])
                slot();
            cross_section(length);
        }
    
        rail_holes(length);
    }
}
    
    
module rail_holes(length) {
    num_holes = ceil((length - TOUNGE_L) / MIN_SEP);
    for (i=[0:num_holes-1]) {
        tx = -(num_holes-1) * MIN_SEP / 2 + i * MIN_SEP;
        translate([tx, 0, 0])
            rotate([90, 0, 0])
            cylinder(r=HOLE_OR, h=RAIL_W, center=true);
    }
}

rail_bend = 45;

module bent_rail_stub() {
    difference() {
        cross_section(RAIL_W);
        rotate([0, rail_bend/2, 0])
            translate([0, -RAIL_W/2 - 1, -RAIL_W])
            cube([RAIL_W, RAIL_W+2, 2*RAIL_W]);
    }
}

module bent_rail() {
    translate([-3*RAIL_W/2 - TOUNGE_L/2, 0, 0])
        tounge();
    translate([-RAIL_W, 0, 0])
        cross_section(RAIL_W);
    bent_rail_stub();
    rotate([0, rail_bend, 0]) {
        mirror([1, 0, 0])
            bent_rail_stub();
        translate([RAIL_W, 0, 0])
            cross_section(RAIL_W);
        translate([3*RAIL_W/2 + TOUNGE_L/2, 0, 0])
        slot();
    }
    
}

module tee() {
    translate([MOUNT_L / 2 + TOUNGE_L / 2 + GROOVE_SIDE/2, 0, 0])
        tounge();
    rotate([0, 90, 0])
        mount();
}

module design() {
    translate([(3*RAIL_W + TOUNGE_L) / sqrt(2) + TOUNGE_L + RAIL_W + MOUNT_L, 0, -CONTROLLER_H/2])
        rotate([0, 90, 0])
        straight_rail(CONTROLLER_H);
    # bent_rail();
    * translate([(3*RAIL_W + TOUNGE_L) / sqrt(2), 0, -(3*RAIL_W + TOUNGE_L) / sqrt(2)])
        rotate([0, -135, 0])
        straight_rail((3*RAIL_W + TOUNGE_L)/2);
    translate([(3*RAIL_W + TOUNGE_L) / sqrt(2), 0, -(3*RAIL_W + TOUNGE_L) / sqrt(2)])
        rotate([0, 135, 180])
        bent_rail();
    
    translate([(3*RAIL_W + TOUNGE_L) / sqrt(2) + TOUNGE_L + RAIL_W + MOUNT_L, 0, -(3*RAIL_W + TOUNGE_L) / sqrt(2)])
        rotate([0, 180, 0])
        tee();
    
    * straight_rail();
    * mount();
}
//design();

straight_rail(MOUNT_L);