IN_MM = 25.4;

bottom_id = 3;
top_id = 14.5;

metric_sizes = [
    3, 3.2, 3.5, 
    4, 4.5, 4.8, 
    5, 5.5, 
    6, 6.5, 
    7, 7.5, 
    8, 8.5, 
    9, 9.5, 
    10, 10.5,
    11, 11.5,
    12, 12.5,
    13, 13.5,
    14
];

inch_sizes = [
    // [1  / 16 * IN_MM, "1", "16"],
    // [1  /  8 * IN_MM, "1", "8"],
    // [9  / 64 * IN_MM, "9", "64"],
    // [5  / 32 * IN_MM, "5", "32"],
    // [11 / 64 * IN_MM, "11", "64"],
    // [3  / 16 * IN_MM, "3", "16"],
    // [13 / 64 * IN_MM, "13", "64"],
    // [7  / 32 * IN_MM, "7", "32"],
    // [15 / 64 * IN_MM, "15", "64"],
    // [2  / 8 * IN_MM, "2", "8"],
    // [17 / 64 * IN_MM, "17", "64"],
    
    // [5  / 16 * IN_MM, "5", "16"],
    // [3  / 8 * IN_MM, "3", "8"],
    // [7  / 16 * IN_MM, "7", "16"],
    // [4  / 8 * IN_MM, "4", "8"],
    // [9  / 16 * IN_MM, "9", "16"],
    // [5  / 8 * IN_MM, "5", "8"],
    // [11 / 16 * IN_MM, "11", "16"],
    // [6  / 8 * IN_MM, "6", "8"],
    // [13 / 16 * IN_MM, "13", "16"],
    // [7  / 8 * IN_MM, "7", "8"],
    // [15 / 16 * IN_MM, "15", "16"],
    // [8  / 8 * IN_MM, "8", "8"],

    // [4  / 64 * IN_MM, "1", "16"],
    [8  / 64 * IN_MM, "1", "8"],
    [9  / 64 * IN_MM, "9", "64"],
    [10 / 64 * IN_MM, "5", "32"],
    [11 / 64 * IN_MM, "11", "64"],
    [12 / 64 * IN_MM, "3", "16"],
    [13 / 64 * IN_MM, "13", "64"],
    [14 / 64 * IN_MM, "7", "32"],
    [15 / 64 * IN_MM, "15", "64"],
    [16 / 64 * IN_MM, "1", "4"],
    [17 / 64 * IN_MM, "17", "64"],
    [18 / 64 * IN_MM, "9", "32"],
    [19 / 64 * IN_MM, "19", "64"],
    [20 / 64 * IN_MM, "5", "16"],
    [21 / 64 * IN_MM, "21", "64"],
    [22 / 64 * IN_MM, "11", "32"],
    [23 / 64 * IN_MM, "23", "64"],
    [24 / 64 * IN_MM, "3", "8"],
    [25 / 64 * IN_MM, "25", "64"],
    [26 / 64 * IN_MM, "13", "32"],
    [27 / 64 * IN_MM, "27", "64"],
    [28 / 64 * IN_MM, "7", "16"],
    [29 / 64 * IN_MM, "29", "64"],
    [30 / 64 * IN_MM, "15", "32"],
    [31 / 64 * IN_MM, "31", "64"],
    [32 / 64 * IN_MM, "1", "2"],
    [33 / 64 * IN_MM, "33", "64"],
    [34 / 64 * IN_MM, "17", "32"],
    [35 / 64 * IN_MM, "35", "64"],
    [36 / 64 * IN_MM, "9", "16"],
    // [40 / 64 * IN_MM, "5", "8"],
    // [11 / 64 * IN_MM, "11", "16"],
    // [6  / 64 * IN_MM, "6", "8"],
    // [13 / 64 * IN_MM, "13", "16"],
    // [7  / 64 * IN_MM, "7", "8"],
    // [15 / 64 * IN_MM, "15", "16"],
    // [8  / 64 * IN_MM, "8", "8"],
];

text_size = 10;
// block_l = 200;
// block_w = 100;
block_th = 2;

block_or = 100;

gap = 2;

y_offs = 15;

// font = "Black Ops One:style=Regular";
font = ".Helvetica Neue DeskInterface:style=UltraLight";

// function xoffset(id) = 
//     -block_l / 2 + (id - bottom_id) / (top_id - bottom_id) * block_l;

function rzoffset(id) = 
    (id - bottom_id) / (top_id - bottom_id) * 360;

module metric_bits(use_txt=1) {
    for (i=[0:len(metric_sizes)-1]) {
        id = metric_sizes[i];
        rotate([0, 0, rzoffset(id)]) {
            translate([block_or - 2.75*top_id, 0, 0])
                cylinder(r=id/2, h=2*block_th, center=true, $fn=8*id);
            if (use_txt) {
                translate([block_or - 3.75 * top_id, 0, 0])
                    linear_extrude(2 * block_th, center=true)
                    text(str(id), size=3, font=font, valign="center", halign="right");
                translate([block_or - 3.75 * top_id + 1, -1, 0])
                    linear_extrude(2 * block_th, center=true)
                    text("mm", size=2, halign="left", valign="top", font=font);
                translate([block_or - 3.3 *top_id + 1, 0, 0])
                    cube([top_id - 2 , 0.1, 2*block_th], center=true);
            }
        }
    }
}

// ! metric_bits();

module inch_bits(use_txt=1) {
    for (i=[0:len(inch_sizes)-1]) {
        id = inch_sizes[i][0];
        txt = inch_sizes[i][1];
        txt2 = inch_sizes[i][2];
        rotate([0, 0, rzoffset(id)]) {
            translate([block_or - top_id, 0, 0])
                cylinder(r=id/2, h=2*block_th, center=true, $fn=8*id);
            if (use_txt) {
                translate([block_or - 2 * top_id, 1, 0])
                    linear_extrude(2 * block_th, center=true)
                    text(txt, size=3, halign="left", font=font);
                translate([block_or - 2 * top_id - 1, -1, 0])
                    linear_extrude(2 * block_th, center=true)
                    text(str(txt2, " in"), size=2, halign="left", valign="top", font=font);
                translate([block_or - 1.5 *top_id, 0, 0])
                    cube([top_id , 0.1, 2*block_th], center=true);
            }
        }
    }
}

// ! inch_bits();

module drillblock(use_txt=1) {
    difference() {
        cylinder(r=block_or, h=block_th, center=true);
        inch_bits(use_txt=use_txt);
        metric_bits(use_txt=use_txt);
        
    }
}

// drillblock();
// translate([0, 0, -block_th * 2])
//     drillblock(use_txt=0);


module plate_top() {
    projection() 
    drillblock();
}

plate_top();

module plate_bottom() {
    projection() 
    drillblock(false);
}
