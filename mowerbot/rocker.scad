IN_MM = 25.4;
$fn = 60;
wall_th = 2;

rocker_or = 10;
rocker_h = 25;
rocker_lip_h = 3;
rocker_lip_or = 12;

module rocker() {
    translate([0, 0, -rocker_h])
        cylinder(r=rocker_or, h=rocker_h + rocker_lip_h);
    cylinder(r=rocker_lip_or, h=rocker_lip_h);
}

bar_or = 7 / 8 * IN_MM / 2;
bar_length = 4 * rocker_or;

module handlebar() {
    rotate([0, 90, 0])
        cylinder(r=bar_or, h=bar_length, center=true);
}

wire_hole_or = 4;
screw_hole_or = 4/2;

module mount_top() {
    difference() {
        union() {
            cube([2 * (rocker_or + wall_th), 2*bar_or + 2 * wall_th, bar_or * 2 + 2 * rocker_or + 6 * wall_th + 2 * screw_hole_or], center=true);
            for (z=[-1, 1]) {
                translate([0, 0, z * (rocker_or + bar_or + 3*wall_th + 2 * screw_hole_or)])
                    rotate([90, 0, 0])
                    cylinder(r=rocker_or + wall_th, h=2*bar_or + 2 * wall_th, center=true);
            }
        }
        for (z=[-1, 1]) {
            translate([0, wall_th/2, z * (rocker_or + bar_or + 3*wall_th + 2 * screw_hole_or)])
                rotate([90, 0, 0]) {
                    cylinder(r=rocker_or, h=rocker_h + 3 * wall_th, center=true);
                    cylinder(r=wire_hole_or, h=2*rocker_h, center=true);
                }
           translate([0, 0, z * (bar_or + wall_th + screw_hole_or)])
               rotate([90, 0, 0])
               cylinder(r=screw_hole_or, h=2*rocker_h, center=true);
        }
    }    
}

module mount_bottom() {
    translate([0, -bar_or/2 - wall_th/2, 0])
        cube([2*rocker_or + 2*wall_th, bar_or + wall_th, 4*rocker_or + 2*bar_or + 8*wall_th + 4 * screw_hole_or], center=true);
}

module mount() {
    difference() {
        mount_top();
        handlebar();
        # mount_bottom();
    }

}

//mount();

//rocker();