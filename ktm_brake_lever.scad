height = 12;
hole_radius = 4;
hole_wall_thickness = 3.3;
pivot_gap = 10;
cup_radius = 5;
cup_in_height = 7.5;
cup_out_height = 16;
cup_width = 10;
spring_hole_gap = 8;
spring_hole_radius = 4;
spring_hole_depth = 3;
$fn = 60;

surround_radius = hole_radius + hole_wall_thickness;
surround_offset = hole_radius + pivot_gap + cup_in_height / 2 + cup_radius * 2 + hole_wall_thickness;

difference() {
    union() {
        translate([0, 0, -height / 2])
            cylinder(height, 
                surround_radius,
                surround_radius);
        translate([-surround_radius, -surround_offset, -height / 2])
            cube([surround_radius * 2, surround_offset + hole_radius + hole_wall_thickness, height]);         
        translate([-cup_radius,
            -hole_radius - pivot_gap - cup_radius,
            0])
            cylinder(cup_out_height, cup_radius + hole_wall_thickness, cup_radius + hole_wall_thickness);
            
    }
    translate([0, 0, -height / 2])
        cylinder(height, hole_radius, hole_radius);
    translate([
        -cup_radius, 
        -hole_radius - pivot_gap - cup_radius, 
        -cup_out_height / 2])
            cylinder(cup_out_height, cup_radius, cup_radius);
    translate([-cup_width / 2, -hole_radius - pivot_gap, 0])
            rotate([0, 90, 0]) 
                cylinder(cup_width, cup_radius, cup_radius);
    translate([-cup_width / 2, -surround_offset, -cup_radius])
        cube([cup_width, surround_offset - (-hole_radius - pivot_gap), -

}