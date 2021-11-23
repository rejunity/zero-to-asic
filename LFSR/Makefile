# Build & Run simulation -- make run
SHELL := /bin/bash # Use bash syntax
SEED = 10
PROJECT = LFSR

BUILD_DIR = ./
SOURCES = *.v

all: $(PROJECT).bin

run: $(PROJECT).bin
	vvp $(PROJECT).bin -fst

$(BUILD_DIR)/%.bin:
	echo $@
	iverilog -o $@ $(SOURCES)

# $@ The file name of the target of the rule.rule
# $< first pre requisite
# $^ names of all preerquisites

clean:
	rm -f ${PROJECT}.json ${PROJECT}.asc ${PROJECT}.bin *log
	rm -rf obj_dir

#secondary needed or make will remove useful intermediate files
.SECONDARY:
.PHONY: all clean
