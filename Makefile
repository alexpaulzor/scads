SHELL=/bin/bash
.PHONY: all
SCAD ?= /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

.PRECIOUS: *.stl *.gcode

MODULE_CMD := cut -d'.' -f2- | cut -d'(' -f1
# Have to invoke with `make 'stl-openbeam.beam(length~500)'`
# for named params, because make will not recognize wildcards contaning `=`
ARGS_CMD := cut -d'.' -f2- | grep -F '(' | cut -d'(' -f2- | sed -e 's/[)]$$//' | tr '~' '='

all: prep

prep:
	mkdir -p stl

stl-%: prep
	export     fname="$(shell echo '$(*)' | cut -d'.' -f1)" \
	&& export module="$(shell echo '$(*)' | $(MODULE_CMD))" \
	&& export   args="$(shell echo '$(*)' | $(ARGS_CMD))" \
	&& export tmpfile="$(shell mktemp)" \
	&& echo -e "use <$$PWD/$$fname.scad>\n$$module($$args);" > $$tmpfile \
	&& cat $$tmpfile \
	&& time $(SCAD) \
		-o stl/$$module.$$fname.stl \
		$$tmpfile \
	&& echo "Rendered stl/$$module.$$fname.stl" \
	&& echo "Rendered $$module" | say
	rm -f $$tmpfile

clean: clean-gcode clean-stl

clean-stl:
	rm -f *.stl stl/*.stl

clean-gcode:
	rm -f *.gcode


lsmod-%:
	grep 'module ' $(*).scad \
		| sed -e 's/module //g'

lsmod:
	egrep '^module .*\(' *.scad lib/*.scad \
		| sed -e 's/\.scad:module /./' -e 's/[(].*//'

autostl-%:
	egrep '^module .*\(' a $(*).scad 2>/dev/null \
		| grep use_stl= \
		| sed -e 's/\.scad:module /./' -e 's/[(].*//' \
		| xargs -I{} make stl-{}

view:
	open stl

dot-%: 
	# fdp also works ok
	dot -Tsvg -O $(*).dot \
		&& open $(*).dot.svg