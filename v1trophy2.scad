font = "Monaco:style=Bold";

floor_height = 5;
font_height = 50;

module emblem_cube(emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale) {
    filler_cube_z = 6;
   
    module z_text() {
        scale(z_text_scale)
        rotate([0, 0, 90])
        translate([0, -font_height / 2, 0])
            linear_extrude(emblem_z)
                text(emblem_text_z, font_height, halign="center", font=font);
    }
    module v1_plate() {
        
        difference() {
            translate([-emblem_x / 2, -emblem_y / 2, emblem_z / 2])
                cube([emblem_x, emblem_y, floor_height]);
            translate([0, 0, 0])
                z_text();
        }
    }
    
    translate([0, 0, 0]) v1_plate();
    translate([0, 0, -emblem_z - floor_height / 2]) v1_plate();
   
   
    intersection() {
        union() {
            translate([0, emblem_y / 2, 0])
            rotate([90, 0, 0])
                translate([0, -font_height / 2, 0])
                linear_extrude(emblem_y)
                    text(emblem_text_x, font_height, halign="center", font=font);
            translate([-1, -emblem_y / 2, -filler_cube_z / 2])
        cube([filler_cube_z, emblem_y, filler_cube_z]);
        }
        translate([-emblem_x / 2, 0, 0])
            rotate([90, 0, 90])
            translate([0, -font_height / 2, 0])
            linear_extrude(emblem_y)
                text(emblem_text_y, font_height, halign="center", font=font);
    }
}

module mc_api_v1() {
    emblem_z = font_height + floor_height;
    z_text_scale = [1.2, 1.3, 1];
    emblem_text_x = "MC";
    emblem_text_y = "API";
    emblem_text_z = "V1";
    emblem_x = 75;
    emblem_y = 118;
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}

module emblem_cube_sq(emblem_text, font_height) {
    filler_cube_z = 6;
   
    emblem_z = font_height + floor_height;
    z_text_scale = [1, 0.9, 1];
    emblem_text_x = emblem_text;
    emblem_text_y = emblem_text;
    emblem_text_z = emblem_text;
    emblem_x = 1.5 * font_height;
    emblem_y = 1.5 * font_height;
   
    emblem_cube(
        emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale);
}
/*
    
    module z_text() {
        scale(z_text_scale)
        rotate([0, 0, 90])
        translate([0, -font_height / 2, 0])
            linear_extrude(emblem_z)
                text(emblem_text_z, font_height, halign="center", font=font);
    }
    module v1_plate() {
        
        difference() {
            translate([-emblem_x / 2, -emblem_y / 2, emblem_z / 2])
                cube([emblem_x, emblem_y, floor_height]);
            translate([0, 0, 0])
                z_text();
        }
    }
    
    translate([0, 0, 0]) v1_plate();
    translate([0, 0, -emblem_z - floor_height / 2]) v1_plate();
   
   
    intersection() {
        union() {
            translate([0, emblem_y / 2, 0])
            rotate([90, 0, 0])
                translate([0, -font_height / 2, 0])
                linear_extrude(emblem_y)
                    text(emblem_text_x, font_height, halign="center", font=font);
            translate([-1, -emblem_y / 2, -filler_cube_z / 2])
        cube([filler_cube_z, emblem_y, filler_cube_z]);
        }
        translate([-emblem_x / 2, 0, 0])
            rotate([90, 0, 90])
            translate([0, -font_height / 2, 0])
            linear_extrude(emblem_y)
                text(emblem_text_y, font_height, halign="center", font=font);
    }
}
*/
module mc_mc_mc() {
    emblem_text = "MC";
    emblem_cube_sq(emblem_text, font_height);
}

! mc_mc_mc();


# translate([100, 100, 0]) 
    rotate([0, -90, 0]) 
        mc_api_v1();