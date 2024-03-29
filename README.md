# Workspace for Zero To ASIC course
This repository is my personal workspace for [Zero to ASIC course](https://www.zerotoasiccourse.com) by Matt Venn.

## Prerequisites
### Simulation
You will need to have libsdl2 and [verilator](https://www.veripool.org/verilator/) installed.

On Linux:

    sudo apt-get install libsdl2-dev libsdl2-image-dev verilator

On OSX using [Brew](https://brew.sh/):

    brew install sdl2 sdl2_image verilator

*NOTE: Theoretically installing verilator through [MacPorts](https://www.macports.org/) should work too, however I ran into the verilator compilation problems this way.*

### Hardware
Use [1 Bit Squared icebreaker FPGA board](https://1bitsquared.com/products/icebreaker) with [Digilent VGA pmod](https://digilent.com/shop/pmod-vga-video-graphics-array/) plugged into pmod1a and pmod1b.

To build binaries and deploy them onto FPGA you will need to have [yosys](https://yosyshq.net/yosys/), [nextpnr](https://github.com/YosysHQ/nextpnr) and [icestorm](http://www.clifford.at/icestorm/) installed.

On Linux:

    TODO

On OSX (for more details visit [Tobias Müller's blog](https://www.twam.info/software/using-the-icebreaker-with-an-open-source-fpga-toolchain-on-os-x)):

    brew tap twam/openfgpa
    brew install yosys icestorm
    brew install nextpnr --without-arch-ecp5


## Projects
Projects below are based upon:
* [Matt's VGA Clock repo](https://github.com/mattvenn/vga-clock)
* [Will Green's Project F](https://projectf.io/sitemap/#fpga-graphics)
* [Steven Hugg's FPGA examples for 8bitworkshop.com](https://github.com/sehugg/fpga-examples)

### Starfield
Run simulation:

    make verilator && ./obj_dir/VStarfield
    
Run on FPGA:

    make prog

### FlappySpace
Run simulation:

    make verilator && ./obj_dir/VFlappySpace
    
Run on FPGA:

    make prog

## ASIC
TODO
