SHELL=/bin/bash
.PHONY: all
SCAD ?= /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

SCAD_FILE = chain_drive.scad
DEFAULT_DEFS_DIR = /Macintosh HD⁩/⁨Users⁩/apaul⁩/Library⁩/Application Support⁩/cura⁩/3.6
# DEFS_FILE ?= cura-settings-abs-mechpart.json
SETTINGS_FILE = cura-settings-abs-mechpart.txt
# CURA_ENGINE_SEARCH_PATH = $(PWD):$(DEFAULT_DEFS_DIR)

# SETTINGS = $(shell cat $(SETTINGS_FILE))
# START_GCODE = G21 ;metric values\nG90 ;absolute positioning\nM82 ;set extruder to absolute mode\nM107 ;start with the fan off\nG28 X0 Y0 ;move X/Y to min endstops\nG28 Z0 ;move Z to min endstops\nG29 P2\nG1 Z15.0 F9000 ;move the platform down 15mm\nG92 E0 ;zero the extruded length\nG1 F200 E3 ;extrude 3mm of feed stock\nG92 E0 ;zero the extruded length again\nG1 F9000\nM117 Printing...
# END_CODE = M104 S0 ;extruder heater off \nM140 S0 ;heated bed heater off (if you have it) \nG91 ;relative positioning \nG1 E-1 F300  ;retract the filament a bit before lifting the nozzle, to release some of the pressure \nG1 Z+0.5 E-5 X-20 Y-20 F9000 ;move Z up a bit and retract filament even more \nG28 X0 Y0 ;move X/Y to min endstops, so the head is out of the way \nM84 ;steppers off \nG90 ;absolute positioning

# CURA ?= /Applications/Ultimaker\ Cura.app/Contents/MacOS/CuraEngine slice -vvv -p -s $$'machine_start_gcode=$(START_GCODE)' -s $$'machine_end_gcode=$(END_CODE)' $(SETTINGS)
#"$(END_CODE)"

.PHONY: chain_drive
# .PRECIOUS: wall-%.stl wall-%.gcode

all: chain_drive

chain_drive: 40_idler_sprocket.stl 40_drive_sprocket.stl 40_idle_drive_sprocket.stl 40_double_link_clip.stl 

40_idler_sprocket.stl: chain_drive.scad
	$(SCAD) \
		-D plate_obj_id=0 \
		-o 40_idler_sprocket.stl \
		--render \
		$(SCAD_FILE)

40_drive_sprocket.stl: chain_drive.scad
	$(SCAD) \
		-D plate_obj_id=1 \
		-o 40_drive_sprocket.stl \
		--render \
		$(SCAD_FILE)

40_idle_drive_sprocket.stl: chain_drive.scad
	$(SCAD) \
		-D plate_obj_id=2 \
		-o 40_idle_drive_sprocket.stl \
		--render \
		$(SCAD_FILE)

40_double_link_clip.stl: chain_drive.scad
	$(SCAD) \
		-D plate_obj_id=3 \
		-o 40_double_link_clip.stl \
		--render \
		$(SCAD_FILE)


# mowerbot: gcode

# stl: $(ALL_WALLS:%=stl-%)

# stl-%: wall-%.stl
# 	echo "Rendered  wall-$(*).stl"

# wall-%.stl: $(SCAD_FILE)
# 	echo "Rendering wall-$(*).stl"
# 	$(SCAD) \
# 		-D render_wall=$(*) \
# 		-o wall-$(*).stl \
# 		--render \
# 		$(SCAD_FILE)

clean: clean-gcode clean-stl

clean-stl:
	rm -f *.stl

clean-gcode:
	rm -f *.gcode

# gcode: $(ALL_WALLS:%=gcode-%)		
	
# gcode-%: wall-%.gcode
# 	echo "Rendered  wall-$(*).gcode"

# wall-%.gcode: wall-%.stl
# 	echo "Rendering wall-$(*).gcode"
# 	$(CURA) -l wall-$(*).stl -o wall-$(*).gcode