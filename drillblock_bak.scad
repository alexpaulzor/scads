IN_MM = 25.4;

bottom_id = 2.5;
top_id = 14;

metric_sizes = [
    3, 3.2, 3.5, 4, 4.5, 4.8, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10
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
    
    [5  / 16 * IN_MM, "5", "16"],
    [3  / 8 * IN_MM, "3", "8"],
    [7  / 16 * IN_MM, "7", "16"],
    [4  / 8 * IN_MM, "4", "8"],
    [9  / 16 * IN_MM, "9", "16"],
    [5  / 8 * IN_MM, "5", "8"],
    [11 / 16 * IN_MM, "11", "16"],
    [6  / 8 * IN_MM, "6", "8"],
    [13 / 16 * IN_MM, "13", "16"],
    [7  / 8 * IN_MM, "7", "8"],
    [15 / 16 * IN_MM, "15", "16"],
    [8  / 8 * IN_MM, "8", "8"],

    [4  / 64 * IN_MM, "1", "16"],
    [8  / 64 * IN_MM, "1", "8"],
    [9  / 64 * IN_MM, "9", "64"],
    [10 / 64 * IN_MM, "5", "32"],
    [11 / 64 * IN_MM, "11", "64"],
    [12 / 64 * IN_MM, "3", "16"],
    [13 / 64 * IN_MM, "13", "64"],
    [14 / 64 * IN_MM, "7", "32"],
    [15 / 64 * IN_MM, "15", "64"],
    [16 / 16 * IN_MM, "1", "4"],
    [17 / 64 * IN_MM, "17", "64"],
    [20 / 64 * IN_MM, "5", "16"],
    [24 / 64 * IN_MM, "3", "8"],
    [28 / 64 * IN_MM, "7", "16"],
    [32 / 64 * IN_MM, "1", "2"],
    [36 / 64 * IN_MM, "9", "16"],
    [40 / 64 * IN_MM, "5", "8"],
    [11 / 64 * IN_MM, "11", "16"],
    [6  / 64 * IN_MM, "6", "8"],
    [13 / 64 * IN_MM, "13", "16"],
    [7  / 64 * IN_MM, "7", "8"],
    [15 / 64 * IN_MM, "15", "16"],
    [8  / 64 * IN_MM, "8", "8"],
];

text_size = 10;
block_l = 200;
block_w = 100;
block_th = 2;

gap = 2;

y_offs = 15;

font = "Black Ops One:style=Regular";

function xoffset(id) = 
    -block_l / 2 + (id - bottom_id) / (top_id - bottom_id) * block_l;

module metric_bits() {
    for (i=[0:len(metric_sizes)-1]) {
        id = metric_sizes[i];
        y_offs2 = (i % 2 == 0 ? y_offs : 2 * y_offs);
        translate([xoffset(id), -y_offs2, 0])
            cylinder(r=id/2, h=2*block_th, center=true, $fn=128);
        translate([xoffset(id), -y_offs2/2, 0])
            cube([0.1, y_offs, 2*block_th], center=true);
        translate([xoffset(id) - 1/2, -1, 0])
            rotate([0, 0, 90])
            linear_extrude(2 * block_th, center=true)
            text(str(id), size=3, halign="right", font=font);
        translate([xoffset(id) + 1/2, -1, 0])
            rotate([0, 0, 90])
            linear_extrude(2 * block_th, center=true)
            text("mm", size=2, halign="right", valign="top", font=font);
    }
}

// ! metric_bits();

module inch_bits() {
    for (i=[0:len(inch_sizes)-1]) {
        id = inch_sizes[i][0];
        txt = inch_sizes[i][1];
        txt2 = inch_sizes[i][2];
        translate([xoffset(id), y_offs, 0])
            cylinder(r=id/2, h=2*block_th, center=true, $fn=128);
        translate([xoffset(id), y_offs/2, 0])
            cube([0.1, y_offs, 2*block_th], center=true);
        translate([xoffset(id) - 1/2, 1, 0])
            rotate([0, 0, 90])
            linear_extrude(2 * block_th, center=true)
            text(txt, size=3, halign="left", font=font);
        translate([xoffset(id) + 1/2, 1, 0])
            rotate([0, 0, 90])
            linear_extrude(2 * block_th, center=true)
            text(str(txt2, " in"), size=2, halign="left", valign="top", font=font);
    }
}

// ! inch_bits();

module drillblock() {
    difference() {
        cube([block_l, block_w, block_th], center=true);
        cube([block_l - 10, 0.1, 2*block_th], center=true);
        metric_bits();
        # inch_bits();
    }
}

drillblock();
