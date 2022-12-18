use <sprockets.scad>
IN_MM = 25.4;
PI = 3.14159;
$fn=60;
openbeam_w = 15;

CHAIN_SIZE = 40;
BIKE_CHAIN = false;

CHAIN_STRANDS = CHAIN_SIZE == 40 ? 2 : 1;
CHAIN_GAP = 2 * openbeam_w;

CHAIN_PITCH = get_pitch(CHAIN_SIZE) * IN_MM;
ROLLER_OR = get_roller_diameter(CHAIN_SIZE) * IN_MM / 2;
ROLLER_W = get_thickness(CHAIN_SIZE) * IN_MM;

/**
returns 
LINK_L = link_sizes[0];
LINK_H = link_sizes[1];
LINK_TH = link_sizes[2];
LINK_SMALL_W = link_sizes[3];
LINK_LARGE_W = link_sizes[4];
LINK_PIN_W = link_sizes[5];
LINK_PIN_OR = link_sizes[6];
LINK_PIN_L = link_sizes[7];
*/
function get_link_sizes(size=CHAIN_SIZE) =
    //bike chain
    size == 40 ? (
        BIKE_CHAIN ?
        [
            // LINK_L = 
            21,
            // LINK_H = 
            8.3,
            // LINK_TH = 
            0.8,
            // LINK_SMALL_W
            5.5,
            // LINK_LARGE_W = 
            7.5,
            // LINK_PIN_W = 
            0.125 * IN_MM,
            // LINK_PIN_OR = 
            3.5/2,
            // LINK_PIN_L
            8,
        ] : [
            // LINK_L = 
            0.900 * IN_MM,
            // LINK_H = 
            0.472 * IN_MM,
            // LINK_TH = 
            0.059 * IN_MM,
            // LINK_SMALL_W
            0.427 * IN_MM,
            // LINK_LARGE_W = 
            0.560 * IN_MM,,
            // LINK_PIN_W = 
            0.309 * IN_MM,
            // LINK_PIN_OR = 
            0.156 * IN_MM / 2,
            // LINK_PIN_L
            0.650 * IN_MM,
            
        ]) :
    //motorcycle chain
    // TODO: remeasure
    size == 520 ? [
        // LINK_L = 
        1.125 * IN_MM,
        // LINK_H = 
        15,
        // LINK_TH = 
        0.075 * IN_MM,
        // LINK_SMALL_W = 
        11,
        // LINK_LARGE_W = 
        18,
        // LINK_PIN_W = 
        20,
        // LINK_PIN_OR = 
        5.5/2,
        // LINK_PIN_L
        20
    ] : [];

link_sizes = get_link_sizes(CHAIN_SIZE);
LINK_L = link_sizes[0];
LINK_H = link_sizes[1];
LINK_TH = link_sizes[2];
LINK_SMALL_W = link_sizes[3];
LINK_LARGE_W = link_sizes[4];
LINK_PIN_W = link_sizes[5];
LINK_PIN_OR = link_sizes[6];
LINK_PIN_L = link_sizes[7];

GEAR_TH = LINK_SMALL_W - 2 * LINK_TH;

CHAIN_LENGTH = 3 * 12 * IN_MM;
CHAIN_LINKS = CHAIN_LENGTH / CHAIN_PITCH; //60;
DRIVE_CLEARANCE = 120;
DRIVE_TEETH = 27;
//20; // Absolute minimum 20 for 520 chain, 25 for 40 chain or arm will collide with chain
IDLER_TEETH = 14;

DRIVE_PITCH_OR = CHAIN_PITCH * DRIVE_TEETH / PI / 2;
DRIVE_TEETH_DEG = 360/DRIVE_TEETH;
IDLER_TEETH_DEG = 360 / IDLER_TEETH;

IDLER_PITCH_OR = CHAIN_PITCH * IDLER_TEETH / PI / 2;

wall_th = 2;
pad_th = 4;
pad_w = (CHAIN_STRANDS-1) * (CHAIN_GAP + LINK_LARGE_W) + LINK_LARGE_W + 2 * wall_th;
pad_hole_ir = 3/2;
pad_head_or = 3;
pad_l = LINK_L - 1.5;

links_per_clip = 3;

axle_spread_links = floor((CHAIN_LINKS - DRIVE_TEETH / 2 - IDLER_TEETH / 2) / 2);
axle_spread = axle_spread_links * CHAIN_PITCH;

echo("Axle spread mm, links", axle_spread, axle_spread_links);

spread_angle = atan2(DRIVE_PITCH_OR - IDLER_PITCH_OR, axle_spread);

bearing_h = 7;
bearing_ir = 4;
bearing_or = 11;

arm_r = 35;
arm_hole_ir = 3;
num_holes = 6;
DRIVE_BORE = 6;

arm_w = 22;
arm_l = 52;
arm_h = 11;
arm_drive_offs = 11;
arm_clear_r = 25;
arm_clear_h = 5;
hub_h = arm_clear_h + LINK_PIN_W;

function get_gear_space() = LINK_LARGE_W + CHAIN_GAP;
function get_idler_pitch_or() = IDLER_PITCH_OR;
function get_idler_teeth() = IDLER_TEETH;

function get_drive_pitch_or() = DRIVE_PITCH_OR;
function get_drive_teeth() = DRIVE_TEETH;
function get_link_pin_w() = LINK_PIN_W;

module bearing() {
    difference() {
        cylinder(r=bearing_or, h=bearing_h, center=true);
        cylinder(r=bearing_ir, h=bearing_h, center=true);
    }
}

module drive_arm() {
    difference() {
        translate([-arm_drive_offs, -arm_w/2, 0])
            cube([arm_l, arm_w, arm_h]);
        translate([arm_clear_r, -arm_w/2, 0])
            cube([arm_l-arm_clear_r, arm_w, arm_clear_h]);
        translate([-arm_drive_offs, -arm_w/2, arm_h - arm_clear_h])
            cube([arm_clear_r + arm_drive_offs, arm_w, arm_clear_h]);
        translate([0, 0, arm_h/2])
            cylinder(r=arm_hole_ir, h=arm_h*2, center=true);
        translate([arm_r, 0, arm_h/2])
            cylinder(r=arm_hole_ir, h=arm_h*2, center=true);
    }
}

module driven_sprocket(bore, hub_d, hub_h) {
    zratio = LINK_PIN_W / (IN_MM * get_thickness(CHAIN_SIZE));
    difference() {
        scale([1, 1, zratio])
            sprocket(size=CHAIN_SIZE, teeth=DRIVE_TEETH, bore=bore/ IN_MM, hub_diameter=hub_d / IN_MM, hub_height=hub_h / IN_MM / zratio);
        for(j=[0:num_holes])  {
            rotate([0,0,j*360 / num_holes])
                translate([arm_r, 0, 0]) {
                    cylinder(h=hub_h*2, r=arm_hole_ir);
                }
        }
    }
}

module drive_sprocket(use_stl=false) {
    if (use_stl) {
        import("drive_sprocket.stl");
    } else {
        translate([0, 0, -ROLLER_W / 2]) {
            difference() {
                driven_sprocket(DRIVE_BORE, (arm_l - arm_drive_offs) * 2, ROLLER_W);
                
                translate([0, 0, LINK_PIN_W])
                    cylinder(r=arm_clear_r, h=arm_h);
            }
        }
    }
}

! drive_sprocket();

module idle_drive_sprocket(use_stl=false) {
    if (use_stl) {
        import("idle_drive_sprocket.stl");
    } else {
        translate([0, 0, -ROLLER_W / 2]) {
            difference() {
                driven_sprocket(bearing_ir*2, (bearing_or*2 + 2*wall_th), bearing_h);
                
                // translate([0, 0, bearing_h/2]) bearing();
            }
        }
    }
}

// ! idle_drive_sprocket();

module idler_sprocket(use_stl=false) {
    if (use_stl) {
        import("idler_sprocket.stl");
    } else {
        zratio = LINK_PIN_W / (IN_MM * get_thickness(CHAIN_SIZE));
        hole_offs = (IDLER_PITCH_OR - ROLLER_OR + bearing_or) / 2;
        translate([0, 0, -ROLLER_W / 2])
        difference() {
            scale([1, 1, zratio]) {
                sprocket(size=CHAIN_SIZE, teeth=IDLER_TEETH, bore=2*arm_hole_ir/IN_MM, hub_diameter=(bearing_or*2 + 2*wall_th) / IN_MM, hub_height=(bearing_h)/IN_MM / zratio);
            }
            for(j=[0:num_holes])  {
                rotate([0,0,j*360 / num_holes])
                    translate([hole_offs, 0, 0])
                        cylinder(h=hub_h*2, r=arm_hole_ir);
            }
            // translate([0, 0, bearing_h/2]) bearing();
        }
    }
}

// ! idler_sprocket();

module idle_sprocket_spacer() {
    gap = CHAIN_GAP + bearing_h;
    difference() {
        cylinder(r=bearing_ir + wall_th/2, h=gap);
        cylinder(r=bearing_ir, h=gap);
    }
}

module roller(h=ROLLER_W) {
    cylinder(r=ROLLER_OR, h=h, center=true);
}

module chain_link_wall(th=LINK_TH) {
    link_or = (LINK_L - CHAIN_PITCH) / 2;
    linear_extrude(th) {
        resize([LINK_H, link_or*2])
            circle(r=link_or);
        translate([-LINK_H/2, 0])
            square([LINK_H, CHAIN_PITCH]);
        translate([0, CHAIN_PITCH])
            resize([LINK_H, link_or*2])
            circle(r=link_or);
    }
}

module small_link(roller_h=ROLLER_W) {
    translate([0, 0, -LINK_SMALL_W /  2])
        chain_link_wall();
    translate([0, 0, LINK_SMALL_W /  2 - LINK_TH])
        chain_link_wall();
    roller(roller_h);
    translate([0, CHAIN_PITCH])
        roller(roller_h);
}

module link_pins(length=LINK_PIN_L) {
    cylinder(r=LINK_PIN_OR, h=length, center=true);
    translate([0, CHAIN_PITCH, 0])
        cylinder(r=LINK_PIN_OR, h=length, center=true);
}

module large_link(include_pins=true) {
    translate([0, 0, -LINK_LARGE_W /  2])
        chain_link_wall();
    translate([0, 0, LINK_LARGE_W /  2 - LINK_TH])
        chain_link_wall();
    if (include_pins) link_pins();
}

module half_link() {
    difference() {
        large_link(false);
        cube([LINK_H + 1, CHAIN_PITCH - LINK_TH, LINK_PIN_L + 1], center=true);
        link_pins();
    }
    difference() {
        small_link(LINK_SMALL_W);
        translate([0, CHAIN_PITCH, 0])
            cube([LINK_H + 1, CHAIN_PITCH - LINK_TH, LINK_PIN_L + 1], center=true);
        link_pins();
    }
    for (i=[-1, 1]) {
        translate([0, CHAIN_PITCH / 2, i*-LINK_SMALL_W/2])
            cube([LINK_H, LINK_TH, 2*LINK_TH], center=true);
    }
    
}

module chain(num_links=10, bend_deg=0, offs=0, include_clips=true, use_stl=false) {
    for (i=[0:CHAIN_STRANDS-1]) {
        translate([0, 0, i * (LINK_LARGE_W + CHAIN_GAP)]) {
            if ((num_links + offs) % 2 == 0) {
                large_link();
                if (i == 0 && (num_links + offs) % links_per_clip == 0) {
                    link_clip(use_stl=use_stl);
                }
            } else {
                small_link();
            }
        }
    }
    if (num_links > 1) {
        translate([0, CHAIN_PITCH, 0])
            rotate([0, 0, bend_deg])
            chain(num_links=num_links - 1, bend_deg=bend_deg, offs=offs);
    }
}

module link_clip(use_stl=false) {
    if (use_stl) {
        import("link_clip.stl");
    } else {
        link_or = (LINK_L - CHAIN_PITCH) / 2;
        difference() {
            union() {
                for (i=[0:CHAIN_STRANDS - 1]) {
                    translate([pad_th / 2 - (LINK_H + pad_th * 2) / 2, CHAIN_PITCH/2 - pad_l /2, -(LINK_LARGE_W + 2 * wall_th)/2 + i * (LINK_LARGE_W + CHAIN_GAP)])
                        cube([LINK_H + pad_th * 2, pad_l, LINK_LARGE_W + 2 * wall_th]);
                    if (i > 0)
                        translate([LINK_H/2 + wall_th, CHAIN_PITCH / 2, LINK_LARGE_W / 2 + CHAIN_GAP/2])
                            rotate([0, 0, 45])
                            cube([LINK_H, LINK_H, pad_w], center=true);
                }
                translate([LINK_H/2 + pad_th / 2, CHAIN_PITCH/2 - pad_l / 2, -LINK_LARGE_W / 2 - wall_th])
                    cube([pad_th, pad_l, pad_w]);
                    
            }
            // translate([LINK_H/2 + 3*pad_th / 2, CHAIN_PITCH/2 - pad_l / 2, 0])
             //       cube([pad_th, pad_l, pad_w]);
            for (i=[0:CHAIN_STRANDS - 1]) {
                translate([0, 0, i * (CHAIN_GAP + LINK_LARGE_W)]) {
                    translate([0, 0, -LINK_LARGE_W/2])
                        chain_link_wall(LINK_LARGE_W);
                    gap_w = LINK_SMALL_W;  
                    translate([-LINK_H/2, 0, -gap_w/2])
                        chain_link_wall(gap_w);
                    large_link();
                    link_pins(LINK_LARGE_W);
                }
            }
       }
   }
}

module bearing_spacer() {
    difference() {
        cylinder(r=bearing_ir, h=bearing_h, center=true);
        cylinder(r=arm_hole_ir, h=bearing_h, center=true);
    }
}

module plate(part=0) {
    if (part == 1) {
        rotate([180, 0, 0])
            idler_sprocket();
    } else if (part == 2) {
        drive_sprocket();
    } else if (part == 3) {
        rotate([180, 0, 0])
        idle_drive_sprocket();
    } else if (part == 4) {
        rotate([90, 0, 0])
            link_clip();
    } else if (part == 5) {
        bearing_spacer();
    } else if (part == 6) {
        idle_sprocket_spacer();
    }
}

module design_chain_drive() {   
   
    translate([-DRIVE_PITCH_OR, 0, 0])
        rotate([0, 0, 180 + DRIVE_TEETH_DEG / 2])
        chain(floor(DRIVE_TEETH / 2), DRIVE_TEETH_DEG);
    
    * translate([-DRIVE_PITCH_OR, 0, 0])
        rotate([0, 0, -spread_angle])
        mirror([1, 0, 0])
        chain(axle_spread_links, offs=5);
    
    * translate([DRIVE_PITCH_OR, 0, 0])
        rotate([0, 0, spread_angle])
        chain(axle_spread_links, offs=3);
    
    * translate([IDLER_PITCH_OR, axle_spread, 0])
        rotate([0, 0, IDLER_TEETH_DEG / 2])
        chain(floor(IDLER_TEETH / 2), IDLER_TEETH_DEG, offs=2);
    * translate([0, axle_spread])
        idler_sprocket();
    * drive_sprocket();
    * translate([0, 0, LINK_LARGE_W + CHAIN_GAP])
        idle_drive_sprocket();
    translate([0, 0, LINK_LARGE_W + CHAIN_GAP])
        idler_sprocket();
    idler_sprocket();
    * translate([0, 0, bearing_h/2])
        idle_sprocket_spacer();
}

plate_obj_id=0;
if (plate_obj_id) plate(plate_obj_id);
else design_chain_drive();
