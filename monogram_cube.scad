font = "Helvetica:style=Bold";

$fn = 60;
floor_height = 5;
font_height = 50;

module emblem_cube(emblem_text_x, emblem_text_y, emblem_text_z,
        font_height, emblem_x, emblem_y, emblem_z,
        z_text_scale, z_offset=[0, 0]) {
    module z_text() {
        scale(z_text_scale)
        rotate([0, 0, 90])
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
    translate([0, 0, -1]) z_plate();
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
        z_text_scale, z_offset=[-10, 0]);
}
py23();

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

module design() {
    rlj();

    translate([1 * font_height, 1 * font_height, 1 * font_height])
        rkj();

    translate([2 * font_height, 2 * font_height, 2 * font_height])
        ajp();

    translate([3 * font_height, 3 * font_height, 3 * font_height])
        jts();

    translate([4 * font_height, 4 * font_height, 4 * font_height])
        bcp();

    translate([5 * font_height, 5 * font_height, 5 * font_height])
        kep();

    translate([6 * font_height, 6 * font_height, 6 * font_height])
        dmw();

    translate([7 * font_height, 7 * font_height, 7 * font_height])
        rmk();

}

//mcv1();