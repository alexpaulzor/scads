/** Generic snap-together enclosure creator */

I_WALL_LEFT = 0;
I_WALL_RIGHT = 1;
I_WALL_BOTTOM = 2;
I_WALL_TOP = 3;
I_WALL_BACK = 4;
I_WALL_FRONT = 5;

NOTCH_SCALE = 3.0;

/*
wall_th - wall thickness
inside_dims - [length, width, height]
*/
module boxit(wall_th, inside_dims, notch_scale=NOTCH_SCALE, ofscale=1.0, contents=union()) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    translate(ofs[I_WALL_LEFT] * ofscale) 
        boxit_wall(wall_th, inside_dims, notch_scale, contents);
    translate(ofs[I_WALL_RIGHT] * ofscale) 
        mirror([1, 0, 0])
        boxit_wall(wall_th, inside_dims, notch_scale, contents);
    translate(ofs[I_WALL_BOTTOM] * ofscale) 
        boxit_base(wall_th, inside_dims, notch_scale, contents);
    translate(ofs[I_WALL_TOP] * ofscale) 
        mirror([0, 0, 1])
        boxit_base(wall_th, inside_dims, notch_scale);
    translate(ofs[I_WALL_BACK] * ofscale) 
        boxit_cap(wall_th, inside_dims, notch_scale);
    translate(ofs[I_WALL_FRONT] * ofscale) 
        mirror([0, 1, 0])
        boxit_cap(wall_th, inside_dims, notch_scale);
}

function boxit_wall_offsets(wall_th, inside_dims) = [
    // left, right, bottom, top, back, front
    [-inside_dims[0]/2 - wall_th/2, 0, 0],
    [inside_dims[0]/2 + wall_th/2, 0, 0],
    [0, 0, -inside_dims[2]/2 - wall_th/2],
    [0, 0, inside_dims[2]/2 + wall_th/2],
    [0, -inside_dims[1]/2 - wall_th/2, 0],
    [0, inside_dims[1]/2 + wall_th/2, 0],
];

module boxit_wall(wall_th, inside_dims, notch_scale=NOTCH_SCALE) {
    cube([wall_th, inside_dims[1], inside_dims[2]], center=true);
}

module boxit_base(wall_th, inside_dims, notch_scale=NOTCH_SCALE) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    difference() {
        union() {
            cube([inside_dims[0] + 4 * wall_th, inside_dims[1], wall_th], center=true);
            translate([inside_dims[0] / 2 + wall_th/2, 0, wall_th * (1 + notch_scale)/2])
                cube([3 * wall_th, inside_dims[1], notch_scale * wall_th], center=true);
            translate([-inside_dims[0] / 2 - wall_th/2, 0, wall_th * (1 + notch_scale)/2])
                cube([3 * wall_th, inside_dims[1], notch_scale * wall_th], center=true);
        }
        translate(-1 * ofs[2] + ofs[0])
            boxit_wall(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[2] + ofs[1])
            mirror([1, 0, 0])
            boxit_wall(wall_th, inside_dims, notch_scale);
    }
}

module boxit_cap(wall_th, inside_dims, notch_scale=NOTCH_SCALE) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    difference() {
        union() {
            cube([inside_dims[0] + 6 * wall_th, wall_th, inside_dims[2] + 4 * wall_th], center=true);
            translate([-inside_dims[0]/2 - 3*wall_th, wall_th / 2, -inside_dims[2]/2 - 2*wall_th])
                cube([inside_dims[0] + 6 * wall_th, wall_th * notch_scale, 3 * wall_th]);
            translate([-inside_dims[0]/2 - 3*wall_th, wall_th / 2, inside_dims[2]/2 -1*wall_th])
                cube([inside_dims[0] + 6 * wall_th, wall_th * notch_scale, 3 * wall_th]);
            translate([-inside_dims[0]/2 - 3*wall_th, wall_th / 2, -inside_dims[2]/2 - 2*wall_th])
                cube([5 * wall_th, wall_th * notch_scale, inside_dims[2] + 4*wall_th]);
            translate([inside_dims[0]/2 + -2*wall_th, wall_th / 2, -inside_dims[2]/2 - 2*wall_th])
                cube([5 * wall_th, wall_th * notch_scale, inside_dims[2] + 4*wall_th]);
        }
        translate(-1 * ofs[4] + ofs[0])
            boxit_wall(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[4] + ofs[1])
            mirror([1, 0, 0])
            boxit_wall(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[4] + ofs[2])
            boxit_base(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[4] + ofs[3])
            mirror([0, 0, 1])
            boxit_base(wall_th, inside_dims, notch_scale);
    }
}
wall_th = 8 * 0.2;
inside_dims = [150, 100, 50];
# boxit(wall_th, inside_dims);
% boxit(wall_th, inside_dims, ofscale=3.0);