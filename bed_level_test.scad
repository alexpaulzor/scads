
s = 280;
w = 0.8;
h = 0.4;

inside_dims = [s/2 - w, s/2 - w, h];

difference() {
    cube([s+w, s+w, h]);
    translate([w, w, 0])
        cube(inside_dims);
    translate([s/2 + w, w, 0])
        cube(inside_dims);
    translate([w, s/2 + w, 0])
        cube(inside_dims);
    translate([s/2 + w, s/2 + w, 0])
        cube(inside_dims);
}