$fs=0.35; $fa=1;
tol = 0.01;

ox = 45/2;
oy = 21/2;

sloty = 3.5;
slotx = 27;

yoff = (oy-sloty*2)/3;

thick = 3;

difference() {
  scale([ox/oy,1,1]) cylinder(r=oy, h=thick);
  translate([ -(ox-slotx/2)*1.5,-yoff*1.5-sloty,-tol]){
    cube([slotx,sloty,thick+tol*2]);
    translate([0,sloty+yoff*3.2])
      cube([slotx,sloty,thick+tol*2]);
  }
}
