
filament_or = 3.0 / 2;

wall_th = 1;


battery_or = 21/2;
battery_h = 3.5;
wire_or = 1;

module battery() {
    cylinder(r=battery_or, h=battery_h, center=true);
}

bbox_l = 2 * battery_or + 2 * wall_th;
bbox_w = 2 * battery_or + 2 * wall_th;
bbox_h = battery_h + 2 * wall_th;

module battery_box() {
    difference() {
        translate([-bbox_l / 2, -bbox_w / 2, -bbox_h / 2])
            cube([bbox_l / 1.5, bbox_w, bbox_h]);
        for (a=[0:bbox_l / 2]) {
            translate([a, 0, 0])
                battery();
        }
        % battery();
        bbox_holes();
    }
}

module bbox_holes() {
    translate([0, battery_or / 1.5, -1])
        cylinder(r=wire_or, h=bbox_h*2, center=true);
    translate([0, -battery_or / 1.5, -1])
        cylinder(r=wire_or, h=bbox_h*2, center=true);
    translate([0, 0, -wire_or/1.5])
        rotate([90, 0, 0])
        cylinder(r=wire_or, h=bbox_w + 2, center=true);
}

switch_w = 21;
switch_l = 11;
switch_h = 7;
switch_hole_offset_w = 5;
switch_hole_offset_l = 3;
switch_hole_ir = 2.5 / 2;
switch_hole_c_c = 6.95 + 2 * switch_hole_ir;

switch_roller_offset = 3;
switch_roller_overhang = 2.3;
switch_roller_h = switch_h;
switch_roller_w = 22;
switch_roller_l = 6;
switch_roller_th = 0.2;
switch_roller_or = 5/2;
switch_roller_clearance = 1;

switch_pin_clearance = 1.5;
switch_pin_h = 5;

module roller() {
    cube([switch_roller_l/2, switch_roller_w,
 switch_roller_h]);
    translate([-switch_roller_or - switch_roller_clearance, switch_roller_or, 0])
        cylinder(r=switch_roller_or, h=switch_roller_h);
    translate([-switch_roller_or - switch_roller_clearance, 0, 0])
        cube([switch_roller_or + switch_roller_clearance, 2 * switch_roller_or, switch_roller_h]);
}

module switch() {
    translate([0, 0, -switch_h/2])
        cube([switch_l, switch_w, switch_h]);
    
    translate([-switch_roller_l, -switch_roller_overhang, -switch_roller_h/2]) {
        rotate([0, 0, -atan(switch_roller_l / switch_roller_w)]) {        
            roller();
        }
    }
    translate([-switch_roller_l/2, -switch_roller_overhang, -switch_roller_h/2]) {
        rotate([0, 0, -atan(switch_roller_l / switch_roller_w)/2]) {        
            roller();
        }
    }
    translate([0, -switch_roller_overhang, -switch_roller_h/2]) {
        roller();
    }
    translate([switch_l, switch_pin_clearance, -switch_pin_h/2])
        cube([switch_pin_h, switch_w - 1 * switch_pin_clearance, switch_pin_h]);
    
    translate([switch_l - switch_hole_offset_l, switch_hole_offset_w + switch_hole_c_c, -switch_h*1.5])
        cylinder(r=switch_hole_ir, h=4 * switch_h);
    translate([switch_l - switch_hole_offset_l, switch_hole_offset_w, -switch_h*1.5])
        cylinder(r=switch_hole_ir, h=4 * switch_h);
}

holder_l = switch_roller_offset + 2 * wall_th + switch_roller_w + switch_roller_or;
holder_w = switch_l + wall_th + switch_roller_l + switch_roller_clearance + switch_roller_or * 2 + 1;
holder_h = switch_h + 2 * wall_th;

switch_ofs_y = switch_roller_or * 2 + switch_roller_clearance + switch_roller_th + filament_or;

module filament(length=2 * holder_l) {
    rotate([0, 90, 0])
    cylinder(r=filament_or, h=length, center=true);
}

module filament_path() {
    filament();/*
    entry_angle = 15;
    translate([0, 2.5 * filament_or, 0]) {
        for (a=[0:entry_angle]) {
            rotate([0, a, 0])
                filament();
        }
    }
    for (a=[0:40]) {
        translate([0, 2.5 * filament_or -a/3, 0])
        rotate([0, entry_angle, 0])
            filament();
    }
    for (a=[0:2.5 * filament_or * 3]) {
        translate([0, 2.5 * filament_or -a/3, 0])
        rotate([0, 0, 0])
            filament();
    }*/
}

module filament_alarm() {
    difference() {
        union() {
             translate([-holder_l / 2, -filament_or - wall_th, -holder_h / 2])
                cube([holder_l, holder_w, holder_h]);
             translate([0, bbox_w / 2 - wall_th * 2.5, holder_h / 2 + bbox_h / 2 - wall_th])
                rotate([0, 0, 90])
                battery_box();
        }
        * translate([0, switch_ofs_y - wall_th, holder_h / 2 + bbox_h / 2 - wall_th])
            rotate([0, 0, 90])
            bbox_holes();
        # translate([switch_w /  2 - wall_th - 1, switch_ofs_y, 0])
            rotate([0, 0, 90])
            switch();
        translate([0, holder_w / 2 - wall_th * 2 - 1, 0]) {
            difference() {
                cube([switch_roller_offset + switch_roller_w + switch_roller_or, holder_w + wall_th + 1, switch_roller_h + 0], center=true);
                translate([-2, -16, -holder_h/2])
                    cube([4, 10, holder_h]);
            }
        }
        
        
        filament_path();
    }
}

$fn = 24;
filament_alarm();