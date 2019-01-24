/** Generic snap-together enclosure creator */

I_WALL_LEFT = 0;
I_WALL_RIGHT = 1;
I_WALL_BOTTOM = 2;
I_WALL_TOP = 3;
I_WALL_BACK = 4;
I_WALL_FRONT = 5;

WALL_TH = 2;

HOLE_OR = 3 / 2;

/*
wall_th - wall thickness
inside_dims - [length, width, height]
*/
module boxit(inside_dims, wall_th=WALL_TH, ofscale=1.0) {
    ofs = boxit_wall_offsets(inside_dims, wall_th);
    
    translate(ofs[I_WALL_LEFT] * ofscale) 
        boxit_wall_left(inside_dims, wall_th) {
            children(0);
            children(1);
        }
    translate(ofs[I_WALL_RIGHT] * ofscale) 
        boxit_wall_right(inside_dims, wall_th) {
            children(0);
            children(1);
        }
    translate(ofs[I_WALL_BOTTOM] * ofscale) 
        boxit_wall_bottom(inside_dims, wall_th) {
            children(0);
            children(1);
        }
    translate(ofs[I_WALL_TOP] * ofscale) 
        boxit_wall_top(inside_dims, wall_th) {
            children(0);
            children(1);
        }
    translate(ofs[I_WALL_BACK] * ofscale) 
        boxit_wall_back(inside_dims, wall_th) {
            children(0);
            children(1);
        }
    translate(ofs[I_WALL_FRONT] * ofscale) 
        boxit_wall_front(inside_dims, wall_th) {
            children(0);
            children(1);
        }
}
    
module boxit_wall_left(inside_dims, wall_th) {
    boxit_wall(inside_dims, wall_th, I_WALL_LEFT) {
        //intersection() {
            children(0);
        //    rotate([0, -90, 0])
         //       wall_mask(inside_dims[2], inside_dims[1], inside_dims[0]/2);
         //   }
        children(1);
    }
}

module boxit_wall_right(inside_dims, wall_th) {       
    boxit_wall(inside_dims, wall_th, I_WALL_RIGHT) {
        //intersection() {
            children(0);
        //    rotate([0, 90, 0])
        //        wall_mask(inside_dims[2], inside_dims[1], inside_dims[0]/2);
        //}
        children(1);
    }
}

module boxit_wall_bottom(inside_dims, wall_th) {        
    boxit_base(inside_dims, wall_th, I_WALL_BOTTOM) {
         //   intersection() {
                children(0);
        //        rotate([0, 180, 0])
        //            wall_mask(inside_dims[0], inside_dims[1], inside_dims[2]/2);
         //   }
            children(1);
        }
    }
    
module boxit_wall_top(inside_dims, wall_th) {        
    boxit_base(inside_dims, wall_th, I_WALL_TOP) {
        //intersection() {
            children(0);
        //    wall_mask(inside_dims[0], inside_dims[1], inside_dims[2]/2);
        //}
        children(1);
    }
}

module boxit_wall_back(inside_dims, wall_th) {        
    boxit_cap(inside_dims, wall_th, I_WALL_BACK) {
        //intersection() {
            children(0);
         //   rotate([90, 0, 0])
        //        wall_mask(inside_dims[0], inside_dims[2], inside_dims[1]/2);
        //}
        children(1);
    }
}

module boxit_wall_front(inside_dims, wall_th) {        
    boxit_cap(inside_dims, wall_th, I_WALL_FRONT) {
       //intersection() {
            children([0]);
       //     rotate([-90, 0, 0])
      //          wall_mask(inside_dims[0], inside_dims[2], inside_dims[1]/2);
      // }
       children(1);
    }
}

function boxit_wall_offsets(inside_dims, wall_th) = [
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

module boxit_wall(inside_dims, wall_th, offs_index) {
    ofs = boxit_wall_offsets(inside_dims, wall_th);
    difference() {
        union() {
            cube([wall_th, inside_dims[1], inside_dims[2]], center=true);
            translate([0, inside_dims[1] / 4, 0])
                cube([wall_th, inside_dims[1] / 8, inside_dims[2] + 4 * wall_th], center=true);
           translate([0, -inside_dims[1] / 4, 0])
                cube([wall_th, inside_dims[1] / 8, inside_dims[2] + 4 * wall_th], center=true);
            translate([0, 0, inside_dims[2] / 4])
                cube([wall_th, inside_dims[1] + 4 * wall_th, inside_dims[2] / 8], center=true);
            translate([0, 0, -inside_dims[2] / 4])
                cube([wall_th, inside_dims[1] + 4 * wall_th, inside_dims[2] / 8], center=true);
           translate(-1 * ofs[offs_index])
                children(0);
        }
        translate(-1 * ofs[offs_index])
            children(1);
    }
}

module boxit_base(inside_dims, wall_th, offs_index) {
    ofs = boxit_wall_offsets(inside_dims, wall_th);
    difference() {
        union() {
            cube([inside_dims[0] + 6 * wall_th, inside_dims[1], wall_th], center=true);
            
            translate([inside_dims[0] / 4, 0, 0])
                cube([inside_dims[0] / 8, inside_dims[1] + 4 * wall_th, wall_th], center=true);
            translate([-inside_dims[0] / 4, 0, 0])
                cube([inside_dims[0] / 8, inside_dims[1] + 4 * wall_th, wall_th], center=true);
       
            translate(-1 * ofs[offs_index])
                children(0);
        }
        translate(-1 * ofs[offs_index] + ofs[I_WALL_LEFT])
            boxit_wall(inside_dims, wall_th, I_WALL_LEFT) {
                cube(0); //children(0);
                cube(0); //children(1);
            }
        translate(-1 * ofs[offs_index] + ofs[I_WALL_RIGHT])
            boxit_wall(inside_dims, wall_th, I_WALL_RIGHT) {
                cube(0); //children(0);
                cube(0); //children(1);
            }
        translate(-1 * ofs[offs_index])
            children(1);
    }
}

module boxit_cap(inside_dims, wall_th, offs_index) {
    ofs = boxit_wall_offsets(inside_dims, wall_th);
    difference() {
        union() {
            translate(-1 * ofs[offs_index]) {
                children([0]);
            }
            cube([inside_dims[0] + 6 * wall_th, wall_th, inside_dims[2] + 6 * wall_th], center=true);
            
        }
        
        translate(-1 * ofs[offs_index]) {
            children(1); 
            translate(ofs[I_WALL_LEFT])
                boxit_wall(inside_dims, wall_th, I_WALL_LEFT) {
                    cube(0); //children(0);
                    cube(0);
                }
            translate(ofs[I_WALL_RIGHT])
                boxit_wall(inside_dims, wall_th, I_WALL_RIGHT) {
                    cube(0); //children(0);
                    cube(0);
                }
            translate(ofs[I_WALL_TOP])
                boxit_base(inside_dims, wall_th, I_WALL_TOP) {
                    cube(0); //children(0);
                    cube(0);
                }
            translate(ofs[I_WALL_BOTTOM])
                boxit_base(inside_dims, wall_th, I_WALL_BOTTOM) {
                    cube(0); //children(0);
                    cube(0);
                }
            
            # through_holes(inside_dims, wall_th);
        }
    }
}

module through_holes(inside_dims, wall_th) {
    for (x=[-1,1]) {
        for (z=[-1,1]) {
            translate([x * (inside_dims[0] / 2 - 3 * wall_th - HOLE_OR), 0, z * (inside_dims[2] / 2 - 3 * wall_th - HOLE_OR)]) {
                rotate([90, 0, 0]) {
                    cylinder(r=HOLE_OR, h=1.5 * inside_dims[1], center=true);
            }
            }
        }
    }
}

module boxit_demo(inside_dims, wall_th, ofscale=5.0) {
    boxit(inside_dims, wall_th) {
        children(0);
        children(1);
    }
    % boxit(inside_dims, wall_th, ofscale=ofscale) {
        children(0);
        children(1);
    }
}


module demo_contents() {
    sphere(r=45);
}

module demo_anticontents() {
    rotate([45, 45, 90])
        cube(60, center=true);
}
* demo_contents();
* demo_anticontents();
wall_th = 8 * 0.2;
inside_dims = [100, 50, 75];
boxit_demo(inside_dims, wall_th) {
     demo_contents();
    demo_anticontents();
   
} 
* boxit_wall_front(inside_dims, wall_th) {
     demo_contents();
    # demo_anticontents();
   
}