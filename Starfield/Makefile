# Build & Run simulation -- make verilator && ./obj_dir/VStarfield
# Build & Program FPGA   -- make prog
SHELL := /bin/bash # Use bash syntax
SEED = 10
PROJECT = Starfield

DEVICE = up5k
PIN_DEF = icebreaker.pcf
PACKAGE = sg48

# target freq for vga panel
FREQ = 31.5

all: $(PROJECT).bin

BUILD_DIR = ./
SOURCES = VgaSyncGen.v Starfield.v top.v

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

CFLAGS = -O3 -Iobj_dir -I/usr/share/verilator/include

LDFLAGS = -lSDL2 -lSDL2_image

# rules for building the json
%.json: $(SOURCES)
	yosys -l yosys.log -DSYNTH -p 'synth_ice40 -top top -json $(PROJECT).json' $(SOURCES)

%.asc: %.json $(ICEBREAKER_PIN_DEF) 
	nextpnr-ice40 -l nextpnr.log --seed $(SEED) --freq $(FREQ) --package $(PACKAGE) --$(DEVICE) --asc $@ --pcf $(PIN_DEF) --json $<

gui: $(PROJECT).json $(ICEBREAKER_PIN_DEF) 
	nextpnr-ice40 --gui -l nextpnr.log --seed $(SEED) --freq $(FREQ) --package $(PACKAGE) --$(DEVICE) --asc $(PROJECT).asc --pcf $(PIN_DEF) --json $(PROJECT).json

# bin, for programming
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.asc
	icepack $< $@

prog: $(PROJECT).bin
	iceprog $<

obj_dir/VStarfield.h : $(SOURCES) app_verilator.cpp
	verilator --cc Starfield.v --exe app_verilator.cpp -CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)"

verilator: obj_dir/VStarfield.h
	cd obj_dir && make -f VStarfield.mk

clean:
	rm -f ${PROJECT}.json ${PROJECT}.asc ${PROJECT}.bin *log
	rm -rf obj_dir

#secondary needed or make will remove useful intermediate files
.SECONDARY:
.PHONY: all clean
