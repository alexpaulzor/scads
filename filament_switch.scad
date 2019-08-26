
filament_or = 2.0 / 2;

wall_th = 1;
wire_or = 1;

switch_w = 21;
switch_l = 11;
switch_h = 7;
switch_hole_offset_w = 5;
switch_hole_offset_l = 3;
switch_hole_ir = 2.5 / 2;
switch_hole_c_c = 6.95 + 2 * switch_hole_ir;

// edge of switch to far side of roller, resting
switch_roller_rest_h = 10;

switch_roller_offset = 3;
switch_roller_overhang = 2.3;
switch_roller_h = 6;
switch_roller_w = 20;
switch_roller_l = 6.5;
switch_roller_th = 0.2;
switch_roller_or = 5/2;
switch_roller_clearance = 6;

switch_pin_clearance = 1.5;
switch_pin_h = 5;

module roller(rotation=0) {
    rotate([0, 0, rotation]) {
        translate([-2, 0, -switch_roller_h/2])
            cube([2, switch_roller_w,
     switch_roller_h]);
        translate([-switch_roller_clearance + switch_roller_or, switch_roller_w-switch_roller_or, -switch_roller_h/2])
            cylinder(r=switch_roller_or, h=switch_roller_h);
    }
}
switch_max_angle = 12;
module switch() {
    translate([switch_roller_rest_h, 0, -switch_h/2])
        cube([switch_l, switch_w, switch_h]);      
    
    translate([switch_roller_rest_h, switch_roller_offset, 0]) {     for (i=[0:switch_max_angle/4:switch_max_angle])
            roller(i);
        % roller(switch_max_angle);
    }
    translate([switch_roller_rest_h + switch_l, switch_pin_clearance, -switch_pin_h/2])
        cube([switch_pin_h, switch_w - 1 * switch_pin_clearance, switch_pin_h]);
    
    for (dx=[0:0.5:2]) {
        translate([
            switch_roller_rest_h + switch_l - switch_hole_offset_l, 
            dx + switch_hole_offset_w + switch_hole_c_c, -switch_h*1.5])
            cylinder(r=switch_hole_ir, h=4 * switch_h);
        translate([
            switch_roller_rest_h + switch_l - switch_hole_offset_l, 
            dx + switch_hole_offset_w, -switch_h*1.5])
            cylinder(r=switch_hole_ir, h=4 * switch_h);
    }
}

holder_l = 25;
holder_w = 22;
holder_h = 11;

module filament(length=2 * holder_w) {
    rotate([0, 90, 0])
    cylinder(r=filament_or, h=length, center=true);
}

module filament_path() {
    translate([2*filament_or, 0, 0])
    rotate([0, 0, 90])
        filament();
}

module filament_alarm() {
    difference() {
        # translate([-2, -2, -holder_h/2])
            cube([holder_l, holder_w, holder_h], center=false);
        switch();
        
        filament_path();
    }
    % filament_path();
}

$fn = 24;
filament_alarm();