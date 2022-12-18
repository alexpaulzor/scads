CHAIN_SIZE = 520;
TEETH = 42;
NUM_PINS = 114;
// BEND_DEG = 360 / (NUM_PINS / 2);
// BEND_DEG = 360 / TEETH;
BEND_DEG = 5;
LAYERS = NUM_PINS / TEETH;
include <lib/roller_chain.scad>;


pitch_radius = inches2mm(get_pitch(CHAIN_SIZE)/sin(180/TEETH)) / 2;
echo("Pitch Diameter mm=", pitch_radius * 2);

translate([0, 0, -inches2mm(get_thickness(CHAIN_SIZE)/2)])
rotate([0, 0, 360 / TEETH / 2])
    sprocket(CHAIN_SIZE, teeth=TEETH);

translate([pitch_radius, 0, 0])
    chain(num_links=NUM_PINS, 
        bend_deg=BEND_DEG, 
        twist=2);
