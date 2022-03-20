use <lib/LEGO.scad>;
// font = "Helvetica:style=Bold";
font = "Menlo:style=Bold";

$fn = 60;
floor_height = 4;
font_height = 32;

module emblem_cube(emblem_text_x, emblem_text_y, emblem_text_z,
        font_height=font_height, emblem_x=font_height, emblem_y=font_height, emblem_z=font_height,
        z_text_scale=1, z_offset=[0, 0, 0], z_rot=0, 
        include_top=true, include_bottom=true,
        subtract_z=false) {
    module z_text() {
        scale(z_text_scale)
        rotate([0, 0, 90 + z_rot])
        translate([0, -font_height / 2, 0])
            linear_extrude(emblem_z)
                text(emblem_text_z, font_height, halign="center", font=font);
    }
    module z_plate() {
        
        difference() {
            translate([-emblem_x / 2, -emblem_y / 2, emblem_z / 2])
                cube([emblem_x, emblem_y, floor_height]);
            translate(z_offset + [0, 0, 3])
                z_text();
        }
    }
    difference() {
        union() {
            if (include_top)
                translate([0, 0, -1]) z_plate();
            if (include_bottom)
                translate([0, 0, -emblem_z - floor_height / 2]) z_plate();
       
       
            intersection() {
                translate([0, emblem_y / 2, 0])
                rotate([90, 0, 0])
                    translate([0, -font_height / 2, 0])
                    linear_extrude(emblem_y)
                        text(emblem_text_x, font_height, halign="center", font=font);
                   
                 translate([-emblem_x / 2, 0, 0])
                    rotate([90, 0, 90])
                    translate([0, -font_height / 2, 0])
                    linear_extrude(emblem_x)
                        text(emblem_text_y, font_height, halign="center", font=font);
            }
        }
        if (subtract_z)
            translate(z_offset + [0, 0, -emblem_z])
            scale([1, 1, 2])
            z_text();
    }
}

module lego_emblem_cube(emblem_text_x, emblem_text_y, emblem_text_z,
        font_height=32, emblem_x=32, emblem_y=32, emblem_z=32,
        z_text_scale=1, z_offset=[0, 0, 0], z_rot=0, 
        include_top=true, include_bottom=true, include_text=true,
        subtract_z=false) {
    module z_text() {
        scale(z_text_scale)
        rotate([0, 0, 90 + z_rot])
        translate([0, -font_height / 2, 0])
            linear_extrude(emblem_z)
                text(emblem_text_z, font_height, halign="center", font=font);
    }
    module z_plate() {
        
        difference() {
            translate([0, 0, emblem_z / 2])
                block(
                    width=emblem_x / 8,
                    length=emblem_y / 8,
                    height=2/3,
                    type="brick",
                    brand="lego",
                    stud_type="solid",
                    horizontal_holes=false,
                    vertical_axle_holes=false,
                    reinforcement=true,
                    wing_type="full",
                    wing_end_width=2,
                    wing_base_length=2,
                    stud_notches=false,
                    slope_stud_rows=1,
                    slope_end_height=0,
                    curve_stud_rows=1,
                    curve_type="concave",
                    curve_end_height=0,
                    roadway_width=0,
                    roadway_length=0,
                    roadway_x=0,
                    roadway_y=0,
                    stud_rescale=1,
                    dual_sided=false,
                    dual_bottom=false
                    );
                // translate([-emblem_x / 2, -emblem_y / 2, emblem_z / 2])
                // cube([emblem_x, emblem_y, floor_height]);
            translate(z_offset + [0, 0, 3])
                z_text();
        }
    }
    difference() {
        union() {
            if (include_top)
                translate([0, 0, -1]) z_plate();
            if (include_bottom)
                translate([0, 0, -emblem_z - floor_height / 2]) z_plate();
       
            if (include_text)
            intersection() {
                union() {
                    translate([0, 0, -emblem_z/2]) 
                        block(width=emblem_x/8, length=emblem_y/8, height=emblem_z/8-1);
                    translate([0, 0, 0])
                        cube([emblem_x, emblem_y, emblem_z-4], center=true);
                }
                translate([0, emblem_y / 2, 0])
                rotate([90, 0, 0])
                    translate([0, -font_height / 2, 0])
                    linear_extrude(emblem_y)
                        text(emblem_text_x, font_height, halign="center", font=font);
                   
                 translate([-emblem_x / 2, 0, 0])
                    rotate([90, 0, 90])
                    translate([0, -font_height / 2, 0])
                    linear_extrude(emblem_x)
                        text(emblem_text_y, font_height, halign="center", font=font);
            }
        }
        if (subtract_z)
            translate(z_offset + [0, 0, -emblem_z])
            scale([1, 1, 2])
            z_text();
    }
}

module design() {
    // pdxit();
    // translate([60, 0, 0])
    //     gkm_plate();
        gkm();
    // translate([0, 60, 0])
        // ojm();
    // translate([60, 60, 0])
    //     zpm();
    // hvu();

}

module test_block() {
    block(
        width=2,
        length=4,
        height=1,
        reinforcement=true
        // type=block_type,
        // brand=block_brand,
        // stud_type=stud_type,
        // horizontal_holes=(technic_holes=="yes"),
        // vertical_axle_holes=(vertical_axle_holes=="yes"),
        // wing_type=wing_type,
        // wing_end_width=wing_end_width,
        // wing_base_length=wing_base_length,
        // stud_notches=(wing_stud_notches=="yes"),
        // slope_stud_rows=slope_stud_rows,
        // slope_end_height=slope_end_height,
        // curve_stud_rows=curve_stud_rows,
        // curve_type=curve_type,
        // curve_end_height=curve_end_height,
        // roadway_width=roadway_width,
        // roadway_length=roadway_length,
        // roadway_x=roadway_x,
        // roadway_y=roadway_y,
        // stud_rescale=stud_rescale,
        // dual_sided=(dual_sided=="yes"),
        // dual_bottom=(dual_bottom=="yes")
    );
}

rotate([0, 0, $t*360])
    test_block();
    // design();


module gkm() {
    emblem_cube("G", "M", "K", emblem_x=48, emblem_z=30);
}

module ojm() {
    emblem_cube("O", "M", "J", emblem_x=48);
}

 ! ojm();
module zpm() {
    emblem_cube("Z", "M", "P", emblem_x=48);
}
module hvu() {
    emblem_cube("H", "U", "V", emblem_x=48);
}

module pdxit() {
    emblem_z = font_height - 2;
    z_text_scale = [0.5, 0.7, 1];
    emblem_text_x = "P";
    emblem_text_z = "X";
    emblem_text_y = "D";
    
    emblem_x = len(emblem_text_x) * font_height * 0.9;
    emblem_y = len(emblem_text_y) * font_height * 0.9;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale, z_rot=0, include_top=false,
        subtract_z=true);
}

module rlj() {
    emblem_z = font_height - 2;
    z_text_scale = [0.6, 0.7, 1];
    emblem_text_x = "R";
    emblem_text_z = "L";
    emblem_text_y = "J";
    
    emblem_x = font_height * 0.9;
    emblem_y = font_height * 0.9;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module rkj() {
    emblem_z = font_height - 2;
    z_text_scale = [0.6, 0.7, 1];
    emblem_text_x = "R";
    emblem_text_z = "K";
    emblem_text_y = "J";
    
    emblem_x = font_height * 0.9;
    emblem_y = font_height * 0.9;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}
module kvj() {
    emblem_z = font_height - 2;
    z_text_scale = [0.6, 0.7, 1];
    emblem_text_x = "K";
    emblem_text_z = "V";
    emblem_text_y = "J";
    
    emblem_x = font_height * 0.9;
    emblem_y = font_height * 0.9;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}
module jts() {
    emblem_z = font_height - 1;
    z_text_scale = [0.7, 0.7, 1];
    emblem_text_x = "J";
    emblem_text_z = "T";
    emblem_text_y = "S";
    
    emblem_x = font_height * 0.8;
    emblem_y = font_height * 0.8;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}
module jtp() {
    emblem_z = font_height;
    z_text_scale = [0.7, 0.7, 1];
    emblem_text_x = "J";
    emblem_text_z = "T";
    emblem_text_y = "P";
    
    emblem_x = font_height * 0.8;
    emblem_y = font_height * 0.8;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}
module ajp() {
    emblem_z = font_height;
    z_text_scale = [0.7, 0.7, 1];
    emblem_text_x = "A";
    emblem_text_z = "J";
    emblem_text_y = "P";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 0.8;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module dmw() {
    emblem_z = font_height;
    z_text_scale = [0.7, 1, 1];
    emblem_text_x = "D";
    emblem_text_z = "M";
    emblem_text_y = "W";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 1.1;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module apw() {
    emblem_z = font_height;
    z_text_scale = [0.7, 1, 1];
    emblem_text_x = "A";
    emblem_text_z = "P";
    emblem_text_y = "W";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 1.3;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module gcw() {
    emblem_z = font_height;
    z_text_scale = [0.7, 0.85, 1];
    emblem_text_x = "G";
    emblem_text_z = "$$";
    emblem_text_y = "W";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 1.3;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module rmk() {
    emblem_z = font_height;
    z_text_scale = [0.7, 0.7, 1];
    emblem_text_x = "R";
    emblem_text_z = "M";
    emblem_text_y = "K";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 0.8;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module bcp() {
    emblem_z = font_height;
    z_text_scale = [0.7, 0.7, 1];
    emblem_text_x = "B";
    emblem_text_z = "C";
    emblem_text_y = "P";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 0.8;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module kep() {
    emblem_z = font_height;
    z_text_scale = [0.7, 0.7, 1];
    emblem_text_x = "K";
    emblem_text_z = "E";
    emblem_text_y = "P";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 0.8;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module mab() {
    emblem_z = font_height;
    z_text_scale = [0.8, 0.7, 1];
    emblem_text_x = "M";
    emblem_text_z = "A";
    emblem_text_y = "B";
    
    emblem_x = font_height * 1.1;
    emblem_y = font_height * 1;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module vrt() {
    emblem_z = font_height - floor_height/2;
    z_text_scale = [0.8, 0.7, 1];
    emblem_text_x = "V";
    emblem_text_z = "R";
    emblem_text_y = "T";
    
    emblem_x = font_height * 1.1;
    emblem_y = font_height * 1;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module esh() {
    emblem_z = font_height - floor_height/2;
    z_text_scale = [0.8, 0.7, 1];
    emblem_text_x = "E";
    emblem_text_z = "S";
    emblem_text_y = "H";
    
    emblem_x = font_height * 1.1;
    emblem_y = font_height * 1;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module py23() {
    emblem_z = font_height - floor_height/2;
    z_text_scale = [0.8, 0.7, 1];
    emblem_text_x = "2";
    emblem_text_z = "py";
    emblem_text_y = "3";
    
    emblem_x = font_height * 1;
    emblem_y = font_height * 1.2;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale, z_offset=[-10, -3]);
}

module mcv1() {
    emblem_z = font_height;
    z_text_scale = [0.8, 0.7, 1];
    emblem_text_x = "M";
    emblem_text_z = "V1";
    emblem_text_y = "C";
    
    emblem_x = font_height * 1.1;
    emblem_y = font_height * 1.2;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}
