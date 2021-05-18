
MM_PER_INCH = 25.4;
INCH_PER_FOOT = 12;

trailer_l = 8 * INCH_PER_FOOT * MM_PER_INCH;
trailer_w = 5 * INCH_PER_FOOT * MM_PER_INCH;


trailer_rail_w = 1.5 * MM_PER_INCH;
trailer_rail_h = 2.75 * MM_PER_INCH;

long_rail_l = 2440;
tounge_rail_l = 1950;
cross_rail_l = 1520;
tounge_end_gap = 5 * MM_PER_INCH;
tounge_angle = asin((trailer_w-tounge_end_gap) / 2 / tounge_rail_l);
tounge_rail_offset = 800;
axle_offset = 160;
axle_clearance = 200; // TODO: Measure
wheel_or = 180;  // TODO: Measure
wheel_w = 4 * MM_PER_INCH; //TODO: Measure
axle_l = 6 * INCH_PER_FOOT * MM_PER_INCH; // TODO: Measure
axle_or = 1 * MM_PER_INCH; // TODO: Measure

tounge_w = 36 * MM_PER_INCH;
tounge_end_w = 10 * MM_PER_INCH;
tounge_l = 32 * MM_PER_INCH;

rail_w = 1.5 * MM_PER_INCH;
rail_h = 5.5 * MM_PER_INCH;

decking_h = 3/4 * MM_PER_INCH;

tent_w = 46 * MM_PER_INCH;
tent_h = 6 * INCH_PER_FOOT * MM_PER_INCH;
tent_l = trailer_l;

pipe_or = 26.67 / 2;

module trailer() {
    color("brown")
    translate([0, 0, -decking_h/2]) 
        cube([trailer_l, trailer_w, decking_h], center=true);
    // * translate([0, 0, decking_h]) 
    //     cube([trailer_l, rail_w, rail_h]);
    // * translate([0, trailer_w - rail_w, decking_h]) 
    //     cube([trailer_l, rail_w, rail_h]);
    translate([trailer_l/2, -tounge_w / 2, -decking_h - trailer_rail_h])
        linear_extrude(decking_h)
        polygon([
            [0, 0],
            [0, tounge_w],
            [tounge_l, tounge_w / 2 + tounge_end_w / 2],
            [tounge_l, tounge_w / 2 - tounge_end_w / 2]]);
    trailer_frame();
}

module trailer_rail(l=cross_rail_l) {
    color("silver")
    cube([l, trailer_rail_w, trailer_rail_h], center=true);
}

module trailer_frame() {
    for (i=[-1, 1]) {
        translate([0, i * (trailer_w/2 - trailer_rail_w/2), -trailer_rail_h/2 - decking_h])
        trailer_rail(long_rail_l);
       
        for (x=[trailer_l/2 - trailer_rail_w/2, trailer_l/4, trailer_rail_w/2]) {
            translate([i*x, 0, -trailer_rail_h/2 - decking_h])
            rotate([0, 0, 90])
            trailer_rail(cross_rail_l);
        }   
        translate([trailer_l/2 - tounge_rail_offset, i * (trailer_w - trailer_rail_w) / 2, -3/2*trailer_rail_h - decking_h])
            rotate([0, 0, -i*tounge_angle])
            translate([tounge_rail_l/2, 0, 0])
            trailer_rail(tounge_rail_l);
        translate([-axle_offset, i * axle_l/2, -axle_clearance])
            rotate([90, 0, 0])
            cylinder(r=wheel_or, h=wheel_w, center=true);
    }
    translate([-axle_offset, 0, -axle_clearance])
        rotate([90, 0, 0])
        cylinder(r=axle_or, h=axle_l, center=true);

}

module tent_frame() {
    
}

module tent() {
    translate([0, (trailer_w - tent_w) / 2, tent_h])
        square([tent_l, tent_w]);
    
}

trailer();
// tent_frame();
// tent();