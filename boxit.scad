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
module boxit(wall_th, inside_dims, notch_scale=NOTCH_SCALE, ofscale=1.0) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    
    translate(ofs[I_WALL_LEFT] * ofscale) 
        boxit_wall(wall_th, inside_dims, I_WALL_LEFT, notch_scale) {
            if ($children > 0) 
                intersection() {
                    children(0);
                    rotate([0, -90, 0])
                        wall_mask(inside_dims[2], inside_dims[1], inside_dims[0]/2);
                }
            if ($children > 1) children(1);
        }
    translate(ofs[I_WALL_RIGHT] * ofscale) 
        boxit_wall(wall_th, inside_dims, I_WALL_RIGHT, notch_scale) {
            if ($children > 0) 
                intersection() {
                    children(0);
                    rotate([0, 90, 0])
                        wall_mask(inside_dims[2], inside_dims[1], inside_dims[0]/2);
                }
            if ($children > 1) children(1);
        }
    translate(ofs[I_WALL_BOTTOM] * ofscale) 
        boxit_base(wall_th, inside_dims, I_WALL_BOTTOM, notch_scale) {
            if ($children > 0) 
                intersection() {
                    children(0);
                    rotate([0, 180, 0])
                        wall_mask(inside_dims[0], inside_dims[1], inside_dims[2]/2);
                }
            if ($children > 1) children(1);
        }
    translate(ofs[I_WALL_TOP] * ofscale) 
        //mirror([0, 0, 1])
        boxit_base(wall_th, inside_dims, I_WALL_TOP, notch_scale) {
            if ($children > 0) 
                intersection() {
                    children(0);
                    wall_mask(inside_dims[0], inside_dims[1], inside_dims[2]/2);
                }
            if ($children > 1) children(1);
        }
    translate(ofs[I_WALL_BACK] * ofscale) 
        boxit_cap(wall_th, inside_dims, I_WALL_BACK, notch_scale) {
            if ($children > 0) 
                intersection() {
                    children(0);
                    rotate([90, 0, 0])
                        wall_mask(inside_dims[0], inside_dims[2], inside_dims[1]/2);
                }
            if ($children > 1) children(1);
        }
    translate(ofs[I_WALL_FRONT] * ofscale) 
        //mirror([0, 1, 0])
        boxit_cap(wall_th, inside_dims, I_WALL_FRONT, notch_scale) {
           if ($children > 0) 
                intersection() {
                    children(0);
                    rotate([-90, 0, 0])
                        wall_mask(inside_dims[0], inside_dims[2], inside_dims[1]/2);
                }
           if ($children > 1) children(1);
        }
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

module wall_mask(l, w, h) {
    linear_extrude(height=h*2, scale=h*2)
        square([l/h, w/h], center=true);
}

module boxit_wall(wall_th, inside_dims, offs_index, notch_scale=NOTCH_SCALE) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    difference() {
        union() {
            cube([wall_th, inside_dims[1], inside_dims[2]], center=true);
           if ($children > 0) 
                translate(-1 * ofs[offs_index])
                children(0);
        }
        if ($children > 1) 
            translate(-1 * ofs[offs_index])
            children(1);
    }
}

module boxit_base(wall_th, inside_dims, offs_index, notch_scale=NOTCH_SCALE) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    difference() {
        union() {
            cube([inside_dims[0] + 4 * wall_th, inside_dims[1], wall_th], center=true);
            /*translate([inside_dims[0] / 2 + wall_th/2, 0, wall_th * (1 + notch_scale)/2])
                cube([3 * wall_th, inside_dims[1], notch_scale * wall_th], center=true);
            translate([-inside_dims[0] / 2 - wall_th/2, 0, wall_th * (1 + notch_scale)/2])
                cube([3 * wall_th, inside_dims[1], notch_scale * wall_th], center=true);*/
            if ($children > 0) 
                translate(-1 * ofs[offs_index])
                children(0);
        }
        translate(-1 * ofs[offs_index] + ofs[0])
            boxit_wall(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[offs_index] + ofs[1])
            boxit_wall(wall_th, inside_dims, notch_scale);
        if ($children > 1) 
            translate(-1 * ofs[offs_index])
            children(1);
    }
}

module boxit_cap(wall_th, inside_dims, offs_index, notch_scale=NOTCH_SCALE) {
    ofs = boxit_wall_offsets(wall_th, inside_dims);
    difference() {
        union() {
            cube([inside_dims[0] + 6 * wall_th, wall_th, inside_dims[2] + 4 * wall_th], center=true);
            /*translate([-inside_dims[0]/2 - 3*wall_th, wall_th / 2, -inside_dims[2]/2 - 2*wall_th])
                cube([inside_dims[0] + 6 * wall_th, wall_th * notch_scale, 3 * wall_th]);
            translate([-inside_dims[0]/2 - 3*wall_th, wall_th / 2, inside_dims[2]/2 -1*wall_th])
                cube([inside_dims[0] + 6 * wall_th, wall_th * notch_scale, 3 * wall_th]);
            translate([-inside_dims[0]/2 - 3*wall_th, wall_th / 2, -inside_dims[2]/2 - 2*wall_th])
                cube([5 * wall_th, wall_th * notch_scale, inside_dims[2] + 4*wall_th]);
            translate([inside_dims[0]/2 + -2*wall_th, wall_th / 2, -inside_dims[2]/2 - 2*wall_th])
                cube([5 * wall_th, wall_th * notch_scale, inside_dims[2] + 4*wall_th]);*/
            if ($children > 0) 
                translate(-1 * ofs[offs_index])
                children(0);
        }
        translate(-1 * ofs[offs_index] + ofs[0])
            boxit_wall(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[offs_index] + ofs[1])
            //mirror([1, 0, 0])
            boxit_wall(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[offs_index] + ofs[2])
            boxit_base(wall_th, inside_dims, notch_scale);
        translate(-1 * ofs[offs_index] + ofs[3])
            //mirror([0, 0, 1])
            boxit_base(wall_th, inside_dims, notch_scale);
        if ($children > 1) 
            translate(-1 * ofs[offs_index])
            children(1);
    }
}

module boxit_demo(wall_th, inside_dims) {
    boxit(wall_th, inside_dims) {
        if ($children > 0) children(0);
        if ($children > 1) children(1);
    }
    % boxit(wall_th, inside_dims, ofscale=3.0) {
        if ($children > 0) children(0);
        if ($children > 1) children(1);
    }
}

wall_th = 8 * 0.2;
inside_dims = [50, 100, 75];
module demo_contents() {
    sphere(r=45);
}

module demo_anticontents() {
    rotate([45, 45, 90])
        cube(60, center=true);
}
* demo_contents();
* demo_anticontents();
boxit_demo(wall_th, inside_dims) {
     demo_contents();
    demo_anticontents();
   
}