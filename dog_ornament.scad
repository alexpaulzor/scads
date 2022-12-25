

// module paw_side() {
//     # linear_extrude(8.0)
//         import("dog_paw_ornament.dxf", layer=2);
// }

// paw_side();

// import("dog_paw_ornament.dxf", layer="Layer 1");

module ornament_frame() {
    difference() {
        union() {
            circle(r=75/2, $fn=128);
            translate([0, 75/2])
                circle(r=9/2, $fn=128);
        }
        circle(r=65/2, $fn=128);
        translate([0, 75/2])
            circle(r=3/2, $fn=128);
    }
}

// ornament_frame();


th = 3;
or = 75/2;

spine_dz = [
    -or/2, 
    0, 
    or/2
];
layer_dz = [
    -or * 3/5, 
    -or * 1/5, 
    or * 1/5, 
    or * 3/5
];

layer_letter = "A";
spine_letter = "P";
font = "Black Ops One:style=Regular";
// font = "neo latina:style=Regular";

module layer_mask() {
    translate([-or/2 + th*1.5, 0, 0])
        rotate([0, 0, 90])
        linear_extrude(th*2, center=true)
        text(
            layer_letter, 
            size=or*3/4,
            font=font,
            halign="center", 
            valign="center"
        );
}

module spine_mask() {
    translate([or/2 - th, th*0.8, 0])
    rotate([0, 0, 90])
        linear_extrude(th*2, center=true)
        text(
            spine_letter, 
            size=or*3/4,
            font=font,
            halign="center", 
            valign="center"
        );
}

function tropic_or(or=or, h=or/2) = 
    sqrt(or * or - h * h);

module ornament_equator(or=or, th=th) {
    // echo(str("ornament_equator(or=", or, ", th=", th, ");"));
    difference() {
        cylinder(r=or, h=th, center=true, $fn=64);
        for (dy=spine_dz)
            translate([
                or/2 * (dy == 0 ? 1 : -1), 
                dy, 
                0])
            cube([or, th, th*2], center=true);
    }
}

// ! ornament_equator();

module ornament_equator_letter(or=or, th=th) {
    difference() {
        ornament_equator(or=or, th=th);
        layer_mask();
    }
}

// ! ornament_equator_letter();

module ornament_tropic(or=or, th=th, h=or/2, dr=0, use_text=true) {
    echo(str("ornament_tropic(or=", or, ", th=", th, ", h=", h, ", dr=", dr, ");"));
    if (use_text)
        ornament_equator_letter(or=tropic_or(or, h) + dr, th=th);
    else
        ornament_equator(or=tropic_or(or, h) + dr, th=th);
}

module ornament_layers(or=or, th=th, dr=0, use_text=true) {
    for (h=layer_dz) {
        translate([0, 0, h])
            ornament_tropic(
                or=or, th=th, 
                h=abs(h), 
                dr=dr,
                use_text=use_text);
    }
}

// ! ornament_layers();

// layer_ids = [0:len(layer_dz)-1];
layer_ids = [0, 1, 2, 3];

module plate_ornament_layers(or=or, th=th, dr=0, layers=layer_ids) {
    for (i=layers) {
        rotate([
            0, 0, 
            max(0, (i - 1)) / 
            max(1, len(layers) - 1) * 360])
        translate([
                0, 
                len(layers) > 1 ? 
                    (i == 1 ? 0 : 2*or) :
                    0, 
                0])
            rotate([0, 0, 90])
            ornament_tropic(
                or=or, th=th, 
                h=abs(layer_dz[i]), 
                dr=dr);
    }
}

// ! plate_ornament_layers();

module ornament_spine(or=or, th=th, hole=true) {
    difference() {
        cylinder(r=or, h=th, center=true, $fn=64);
        rotate([90, 0, 0])
            ornament_layers(dr=10, use_text=false);
        if (hole) {
            translate([-or + 6, 0, 0])
                cylinder(r=3/2, h=th*2, center=true, $fn=64);
            rotate([0, 0, 0])
                spine_mask();
        } else {
            rotate([0, 0, 180])
                spine_mask();
        }
        
    }
}

// ! ornament_spine();
// ! ornament_spine(hole=false);

// spine_layer_ids = [0:len(spine_dz)-1];
spine_layer_ids = [0, 1, 2];

module ornament_tri_spine(or=or, th=th) {
    for (dz=spine_dz)
        translate([0, 0, dz])
        rotate([0, 0, (dz == 0 ? 0 : 180)])
        ornament_spine(
            or=tropic_or(or=or, h=abs(dz)),
            th=th,
            hole=(dz == 0));
}

// ! ornament_tri_spine();

module plate_ornament_tri_spine(or=or, th=th, layers=spine_layer_ids) {
    // for (dz=spine_dz)
    //     translate([0, 0, dz])
    for (i=layers) {
        dz = spine_dz[i];
        rotate([
            0, 0, 
            (0.5 - i) / 
            (len(layers)) * 360])
        translate([
                0, 
                (len(layers) > 1 ? 2*or : 0), 
                0])
        rotate([0, 0, -90])
            ornament_spine(
                or=tropic_or(or=or, h=abs(dz)),
                th=th,
                hole=(dz == 0));
    }
}

// ! plate_ornament_tri_spine();
// ! plate_ornament_tri_spine(layers=[0]);

module ornament_sphere(or=or, th=th) {
    ornament_layers();
    rotate([90, 0, 0])
        ornament_tri_spine();
        // ornament_spine();
}

// ornament_sphere();

// echo("plate time");
module plate_sphere() {
    // % ornament_sphere();
    plate_ornament_layers();
    plate_ornament_tri_spine();
    
}

// ! plate_sphere();

module plate() {
    projection() 
        plate_sphere();
}

// plate();


module plate_spine_center() {
    projection() 
        plate_ornament_tri_spine(layers=[1]);
}

module plate_spine_wing() {
    projection() 
        plate_ornament_tri_spine(layers=[0]);
}

module plate_layer_center() {
    projection() 
        plate_ornament_layers(layers=[1]);
}

module plate_layer_wing() {
    projection() 
        plate_ornament_layers(layers=[0]);
}

// plate_spine_center();
// plate_spine_wing();
// plate_layer_center();
// plate_layer_wing();
