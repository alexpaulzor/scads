include <lib/t2020beam.scad>;
include <lib/motors.scad>;
include <lib/roller_chain.scad>;

IN_MM = 25.4;

frame_ir = 500 / sqrt(3);
chain_ir = frame_ir + 10;
num_links = chain_ir * 2 * PI / (0.5 * IN_MM);
bend_deg = 360/num_links;
arm_angle = 23;
echo(frame_ir=frame_ir);

module frame() {
    translate([frame_ir + 20, 0, 0])
        rotate([90, 0, 0])
        t2020(1000);
    rotate([0, 0, 120])
        translate([frame_ir + 20, 0, 0])
        rotate([90, 0, 0])
        t2020(1000);
    rotate([0, 0, -120])
        translate([frame_ir + 20, 0, 0])
        rotate([90, 0, 0])
        t2020(1000);
}

module plate() {
    difference() {
        hull()
            frame();
        cylinder(r=chain_ir-5, h=100, center=true);
        translate([0, 0, 5])
            cube([1200, 1200, 20], center=true);
    }
    translate([chain_ir, 0, 3])
        swivel();
}

module swivel() {
    rotate([0, 0, bend_deg/2])
        chain(num_links=floor(num_links), bend_deg=bend_deg);
}

// ! swivel();

module wheel() {
    rotate([90, 0, 0])
        cylinder(
            r=5 * IN_MM, 
            h=4 * IN_MM, center=true);
}

module drive_arm() {
    translate([
            -frame_ir - 5 * IN_MM, 
            0, 
            -400])
        wheel();
    translate([
            -frame_ir - 5 * IN_MM, 
            -30, 
            -400])
        rotate([-90, 90-arm_angle, 0])
        drive_motor();
    translate([
            -frame_ir - 5 * IN_MM, 
            -70, 
            -400])
        rotate([0, -arm_angle, 0])
        translate([30, 0, 200])
        t2020(500);
    translate([
            -frame_ir - 5 * IN_MM, 
            70, 
            -400])
        rotate([0, -arm_angle, 0])
        translate([30, 0, 200])
        t2020(500);
}

module drive() {
    drive_arm();
    rotate([0, 0, 120])
        drive_arm();
    rotate([0, 0, -120])
        drive_arm();
}

module tree() {
    cylinder(r1=frame_ir + 100, r2=frame_ir - 100, h=10000, center=true);
}

module design() {
    translate([0, 0, 20])
        plate();
    frame();
    % tree();
    drive();
}

design();
