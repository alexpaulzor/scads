use <sprockets.scad>
IN_MM = 25.4;
PI = 3.14159;
$fn=60;
BEAM_W = 15;

CHAIN_SIZE = 40; 

CHAIN_STRANDS = CHAIN_SIZE == 40 ? 2 : 1;
CHAIN_GAP = 2 * BEAM_W;

CHAIN_PITCH = get_pitch(CHAIN_SIZE) * IN_MM;
ROLLER_OR = get_roller_diameter(CHAIN_SIZE) * IN_MM / 2;
ROLLER_W = get_thickness(CHAIN_SIZE) * IN_MM;


/**
returns [
    LINK_L,
    LINK_H,
    LINK_TH,
    LINK_SMALL_W,
    LINK_LARGE_W,
    LINK_PIN_W,
    LINK_PIN_OR,
] 
*/
function get_link_sizes(size=CHAIN_SIZE) =
    //bike chain
    size == 40 ? [
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
        8.6,
        // LINK_PIN_OR = 
        3.5/2
    ] :
    //motorcycle chain
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
    ] : [];

link_sizes = get_link_sizes(CHAIN_SIZE);
LINK_L = link_sizes[0];
LINK_H = link_sizes[1];
LINK_TH = link_sizes[2];
LINK_SMALL_W = link_sizes[3];
LINK_LARGE_W = link_sizes[4];
LINK_PIN_W = link_sizes[5];
LINK_PIN_OR = link_sizes[6];

CHAIN_LENGTH = 3 * 12 * IN_MM;
CHAIN_LINKS = CHAIN_LENGTH / CHAIN_PITCH; //60;
DRIVE_CLEARANCE = 120;
DRIVE_TEETH = 30;
//20; // Absolute minimum 20 for 520 chain or arm will collide with chain
IDLER_TEETH = 14;

DRIVE_PITCH_OR = CHAIN_PITCH * DRIVE_TEETH / PI / 2;
DRIVE_TEETH_DEG = 360/DRIVE_TEETH;
IDLER_TEETH_DEG = 360 / IDLER_TEETH;

IDLER_PITCH_OR = CHAIN_PITCH * IDLER_TEETH / PI / 2;

wall_th = 4;
pad_th = 4;
pad_w = BEAM_W * 2 + CHAIN_STRANDS * LINK_LARGE_W;
pad_hole_ir = 3/2;
pad_head_or = 3;
pad_l = LINK_L - 1.5;

links_per_clip = 4;

axle_spread_links = floor((CHAIN_LINKS - DRIVE_TEETH / 2 - IDLER_TEETH / 2) / 2);
axle_spread = axle_spread_links * CHAIN_PITCH;

echo("Axle spread mm, links", axle_spread, axle_spread_links);

spread_angle = atan2(DRIVE_PITCH_OR - IDLER_PITCH_OR, axle_spread);

arm_r = 35;
arm_hole_ir = 3;
num_holes = 6;
DRIVE_BORE = 14;
hub_h = 10;

module drive_arm() {
    
}

module drive_sprocket() {
    translate([0, 0, -ROLLER_W / 2])
    difference() {
        sprocket(size=CHAIN_SIZE, teeth=DRIVE_TEETH, bore=DRIVE_BORE/IN_MM, hub_diameter=1, hub_height=hub_h / IN_MM);
        for(j=[0:num_holes])  {
            rotate([0,0,j*360 / num_holes])
                translate([arm_r, 0, 0])
                    cylinder(h=hub_h*2, r=arm_hole_ir, center=true);
        }
    }
}

module idler_sprocket() {
    translate([0, 0, -ROLLER_W / 2])
    difference() {
        sprocket(size=CHAIN_SIZE, teeth=IDLER_TEETH, bore=DRIVE_BORE/IN_MM, hub_diameter=1, hub_height=hub_h / IN_MM);
        * for(j=[0:num_holes])  {
            rotate([0,0,j*360 / num_holes])
                translate([arm_r, 0, 0])
                    cylinder(h=hub_h*2, r=arm_hole_ir, center=true);
        }
    }
}

module roller() {
    cylinder(r=ROLLER_OR, h=ROLLER_W, center=true);
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

module small_link() {
    translate([0, 0, -LINK_SMALL_W /  2])
        chain_link_wall();
    translate([0, 0, LINK_SMALL_W /  2 - LINK_TH])
        chain_link_wall();
    roller();
    translate([0, CHAIN_PITCH])
        roller();
}

module link_pins(length=LINK_PIN_W) {
    cylinder(r=LINK_PIN_OR, h=length, center=true);
    translate([0, CHAIN_PITCH, 0])
        cylinder(r=LINK_PIN_OR, h=length, center=true);
}

module large_link() {
    translate([0, 0, -LINK_LARGE_W /  2])
        chain_link_wall();
    translate([0, 0, LINK_LARGE_W /  2 - LINK_TH])
        chain_link_wall();
    link_pins();
}

module chain(num_links=10, bend_deg=0, offs=0, include_clips=true) {
    for (i=[0:CHAIN_STRANDS-1]) {
        translate([0, 0, i * (LINK_LARGE_W + CHAIN_GAP)]) {
            if ((num_links + offs) % 2 == 0) {
                large_link();
                if (i == 0 && (num_links + offs) % links_per_clip == 0) {
                    link_clip();
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

module link_clip() {
    link_or = (LINK_L - CHAIN_PITCH) / 2;
    difference() {
        union() {
            translate([pad_th / 2 - (LINK_H + pad_th * 2) / 2, CHAIN_PITCH/2 - pad_l /2, -(LINK_LARGE_W + 2 * wall_th)/2])
                cube([LINK_H + pad_th * 2, pad_l, LINK_LARGE_W * CHAIN_STRANDS + 2 * wall_th]);
            translate([LINK_H/2 + pad_th / 2, CHAIN_PITCH/2 - pad_l / 2, -LINK_LARGE_W / 2 - BEAM_W])
                cube([pad_th, pad_l, pad_w]);
        }
        for (i=[0:0.5:CHAIN_STRANDS - 1]) {
            translate([0, 0, i * LINK_LARGE_W]) {
                translate([0, 0, -LINK_LARGE_W/2])
                    chain_link_wall(LINK_LARGE_W);
                gap_w = LINK_SMALL_W;  
                translate([-LINK_H/2, 0, -gap_w/2])
                    chain_link_wall(gap_w);
                large_link();
                link_pins(LINK_LARGE_W + 3 * wall_th);
            }
        }
        
        for (z=concat([-LINK_LARGE_W / 2 - BEAM_W / 2, CHAIN_STRANDS * (LINK_LARGE_W + CHAIN_GAP) - LINK_LARGE_W/2 + BEAM_W / 2], [for (i=[0:CHAIN_STRANDS-1]) i*(LINK_LARGE_W + CHAIN_GAP)])) {
            translate([LINK_H/2 + pad_th, CHAIN_PITCH/2, z])
                rotate([0, 90, 0])
                # cylinder(r=pad_hole_ir, h=pad_th*2, center=true);
        }
        for (i=[0:CHAIN_STRANDS-1]) {
            z = i*LINK_LARGE_W;
            translate([LINK_H/2, CHAIN_PITCH/2, z])
                rotate([0, 90, 0])
                cylinder(r=pad_head_or, h=pad_th/2);
        }
   }
}

//! rotate([90, 0, 0]) link_clip();

module design() {   
   
    translate([-DRIVE_PITCH_OR, 0, 0])
        rotate([0, 0, 180 + DRIVE_TEETH_DEG / 2])
        chain(DRIVE_TEETH / 2, DRIVE_TEETH_DEG, offs=5);
    
    translate([-DRIVE_PITCH_OR, 0, 0])
        rotate([0, 0, -spread_angle])
        mirror([1, 0, 0])
        chain(axle_spread_links, offs=5);
    
    translate([DRIVE_PITCH_OR, 0, 0])
        rotate([0, 0, spread_angle])
        chain(axle_spread_links, offs=3);
    
    translate([IDLER_PITCH_OR, axle_spread, 0])
        rotate([0, 0, IDLER_TEETH_DEG / 2])
        chain(IDLER_TEETH / 2, IDLER_TEETH_DEG, offs=2);
    % translate([0, axle_spread])
        idler_sprocket();
    % drive_sprocket();
}
design();