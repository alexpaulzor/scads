SHELL=/bin/bash
.PHONY: all
SCAD ?= /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

ALL_WALLS := 0 1 2 3 4 5
SCAD_FILE = mower_electrics_compact.scad
DEFAULT_DEFS_DIR = /Macintosh HD⁩/⁨Users⁩/apaul⁩/Library⁩/Application Support⁩/cura⁩/3.6
# DEFS_FILE ?= cura-settings-abs-mechpart.json
SETTINGS_FILE = cura-settings-abs-mechpart.txt
# CURA_ENGINE_SEARCH_PATH = $(PWD):$(DEFAULT_DEFS_DIR)

SETTINGS = $(shell cat $(SETTINGS_FILE))
START_GCODE = G21 ;metric values\nG90 ;absolute positioning\nM82 ;set extruder to absolute mode\nM107 ;start with the fan off\nG28 X0 Y0 ;move X/Y to min endstops\nG28 Z0 ;move Z to min endstops\nG29 P2\nG1 Z15.0 F9000 ;move the platform down 15mm\nG92 E0 ;zero the extruded length\nG1 F200 E3 ;extrude 3mm of feed stock\nG92 E0 ;zero the extruded length again\nG1 F9000\nM117 Printing...
END_CODE = M104 S0 ;extruder heater off \nM140 S0 ;heated bed heater off (if you have it) \nG91 ;relative positioning \nG1 E-1 F300  ;retract the filament a bit before lifting the nozzle, to release some of the pressure \nG1 Z+0.5 E-5 X-20 Y-20 F9000 ;move Z up a bit and retract filament even more \nG28 X0 Y0 ;move X/Y to min endstops, so the head is out of the way \nM84 ;steppers off \nG90 ;absolute positioning

CURA ?= /Applications/Ultimaker\ Cura.app/Contents/MacOS/CuraEngine slice -vvv -p -s $$'machine_start_gcode=$(START_GCODE)' -s $$'machine_end_gcode=$(END_CODE)' $(SETTINGS)
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
