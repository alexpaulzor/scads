SHELL=/bin/bash
.PHONY: all
SCAD ?= /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

ALL_WALLS := 0 1 2 3 4 5
SCAD_FILE = mower_electrics_compact.scad
DEFAULT_DEFS_DIR = /Macintosh HD⁩/⁨Users⁩/apaul⁩/Library⁩/Application Support⁩/cura⁩/3.6
DEFS_FILE ?= cura-settings-abs-mechpart.json
# CURA_ENGINE_SEARCH_PATH = $(PWD):$(DEFAULT_DEFS_DIR)

# END_CODE = machine_end_gcode='M104 S0 ;extruder heater off \n M140 S0 ;heated bed heater off (if you have it) \n G91 ;relative positioning \n G1 E-1 F300  ;retract the filament a bit before lifting the nozzle, to release some of the pressure \n G1 Z+0.5 E-5 X-20 Y-20 F9000 ;move Z up a bit and retract filament even more \n G28 X0 Y0 ;move X/Y to min endstops, so the head is out of the way \n M84 ;steppers off \n G90 ;absolute positioning'

CURA ?= /Applications/Ultimaker\ Cura.app/Contents/MacOS/CuraEngine slice -vvv -p -j $(DEFS_FILE)
#"$(END_CODE)"

.PHONY: mowerbot stl gcode
.PRECIOUS: wall-%.stl wall-%.gcode

all: mowerbot

mowerbot: gcode

stl: $(ALL_WALLS:%=stl-%)

stl-%: wall-%.stl
	echo "Rendered  wall-$(*).stl"

wall-%.stl: $(SCAD_FILE)
	echo "Rendering wall-$(*).stl"
	$(SCAD) \
		-D render_wall=$(*) \
		-o wall-$(*).stl \
		--render \
		$(SCAD_FILE)

clean: clean-gcode clean-stl

clean-stl:
	rm -f *.stl

clean-gcode:
	rm -f *.gcode

gcode: $(ALL_WALLS:%=gcode-%)		
	
gcode-%: wall-%.gcode
	echo "Rendered  wall-$(*).gcode"

wall-%.gcode: wall-%.stl
	echo "Rendering wall-$(*).gcode"
	$(CURA) -l wall-$(*).stl -o wall-$(*).gcode

# usage:
# CuraEngine help
# 	Show this help message

# CuraEngine connect <host>[:<port>] [-j <settings.def.json>]
#   --connect <host>[:<port>]
# 	Connect to <host> via a command socket,
# 	instead of passing information via the command line
#   -v
# 	Increase the verbose level (show log messages).

# CuraEngine slice [-v] [-p] [-j <settings.json>] [-s <settingkey>=<value>] [-g] [-e<extruder_nr>] [-o <output.gcode>] [-l <model.stl>] [--next]
#   -v
# 	Increase the verbose level (show log messages).
#   -p
# 	Log progress information.
#   -j
# 	Load settings.def.json file to register all settings and their defaults.
#   -s <setting>=<value>
# 	Set a setting to a value for the last supplied object,
# 	extruder train, or general settings.
#   -l <model_file>
# 	Load an STL model.
#   -g
# 	Switch setting focus to the current mesh group only.
# 	Used for one-at-a-time printing.
#   -e<extruder_nr>
# 	Switch setting focus to the extruder train with the given number.
#   --next
# 	Generate gcode for the previously supplied mesh group and append that to
# 	the gcode of further models for one-at-a-time printing.
#   -o <output_file>
# 	Specify a file to which to write the generated gcode.

# The settings are appended to the last supplied object:
# CuraEngine slice [general settings]
# 	-g [current group settings]
# 	-e0 [extruder train 0 settings]
# 	-l obj_inheriting_from_last_extruder_train.stl [object settings]
# 	--next [next group settings]
# 	... etc.

# In order to load machine definitions from custom locations, you need to create the environment variable CURA_ENGINE_SEARCH_PATH, which should contain all search paths delimited by a (semi-)colon.
