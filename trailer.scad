
MM_PER_INCH = 25.4;
INCH_PER_FOOT = 12;

trailer_l = 8 * INCH_PER_FOOT * MM_PER_INCH;
trailer_w = 5 * INCH_PER_FOOT * MM_PER_INCH;

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
    cube([trailer_l, trailer_w, decking_h]);
    translate([0, 0, decking_h]) 
        cube([trailer_l, rail_w, rail_h]);
    translate([0, trailer_w - rail_w, decking_h]) 
        cube([trailer_l, rail_w, rail_h]);
    translate([trailer_l, (trailer_w - tounge_w) / 2, 0])
        linear_extrude(decking_h)
        polygon([
            [0, 0],
            [0, tounge_w],
            [tounge_l, tounge_w / 2 + tounge_end_w / 2],
            [tounge_l, tounge_w / 2 - tounge_end_w / 2]]);
}

module tent_frame() {
    
}

module tent() {
    translate([0, (trailer_w - tent_w) / 2, tent_h])
        square([tent_l, tent_w]);
    
}

% trailer();
tent_frame();
tent();