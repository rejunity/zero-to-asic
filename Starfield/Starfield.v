`default_nettype none
//`define FIELD_256x256
//`define FIELD_512x256
//`define FIELD_1024x512
//`define FIELD_320x200
//`define FIELD_320x240
`define FIELD_640x480
`define COUNTDOWN (640*480-1) // Displays LSFR value once COUNTDOWN reaches 0

/*
Scrolling starfield generator using LFSR (Linear-feedback shift register).

LFSR taps for different register length can be found here: https://en.wikipedia.org/w/index.php?title=Linear-feedback_shift_register#Example_polynomials_for_maximal_LFSRs

*/
module starfield(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [2:0] rgb;
  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;

`ifdef FIELD_256x256
  localparam TAPS = 16'b1101000000001000;
  localparam SEED = {16{1'b1}};
  localparam ZERO = 16'b0;
  localparam HIGHEST_BIT = 15;

  // LFSR period is 2^16-1
  wire restart_lfsr = reset;
  // enable LFSR only in 256x256 area
  wire star_enable = !hpos[8] & !vpos[8] & !hpos[9] & !vpos[9];

`elsif FIELD_320x200
  localparam TAPS = 16'b1101000000001000;
  localparam SEED = {16{1'b1}};
  localparam ZERO = 16'b0;
  localparam HIGHEST_BIT = 15;
  localparam RESET_CONDITION = 16'b100111011001001; // the value at the 63999th (=320*200-1) iteration

  // LFSR period is shorter than 2^16-1
  // LSFR restarts once its value reaches the Nth iteration
  wire restart_lfsr = lfsr == RESET_CONDITION;
  // enable LFSR only in 320x200 area
  wire star_enable = hpos < 320 & vpos < 200;

`elsif FIELD_512x256
  localparam TAPS = 17'b10010000000000000;
  localparam SEED = {17{1'b1}};
  localparam ZERO = 17'b0;
  localparam HIGHEST_BIT = 16;

  // LFSR period is 2^17-1
  wire restart_lfsr = reset;
  // enable LFSR only in 512x256 area
  wire star_enable = !hpos[9] & !vpos[9] & !vpos[8];

`elsif FIELD_320x240
  localparam TAPS = 17'b10010000000000000;
  localparam SEED = {17{1'b1}};
  localparam ZERO = 17'b0;
  localparam HIGHEST_BIT = 16;
  localparam RESET_CONDITION = 17'b11011110000101111; // the value at the 76799th (=320*240-1) iteration

  // LFSR period is shorter than 2^17-1
  // LSFR restarts once its value reaches the Nth iteration
  wire restart_lfsr = lfsr == RESET_CONDITION;
  // enable LFSR only in 320x240 area
  wire star_enable = hpos < 320 & vpos < 240;

`elsif FIELD_1024x512
  localparam TAPS = 19'b1110010000000000000;
  localparam SEED = {19{1'b1}};
  localparam ZERO = 19'b0;
  localparam HIGHEST_BIT = 18;

  // LFSR period is 2^19-1
  wire restart_lfsr = reset;
  // enable LFSR only in 1024x512 area
  wire star_enable = 1;

`elsif FIELD_640x480
  localparam TAPS = 19'b1110010000000000000;
  localparam SEED = {19{1'b1}};
  localparam ZERO = 19'b0;
  localparam HIGHEST_BIT = 18;
  localparam RESET_CONDITION = 
     19'b1010100000000110111; // value at 307199th (=640*480-1) iteration, scroll left
    // 19'b1111100110110010111; // value at 306560th (=640*479) iteration, scroll up
    // 19'b1110001111001111111; // value at 307840th (=640*481) iteration, scroll down
    // 19'b1011110000000001101; // value at 307201th (=640*480+1) iteration, scroll right

  // LFSR period is shorter than 2^19-1
  // LSFR restarts once its value reaches the Nth iteration
  wire restart_lfsr = lfsr == RESET_CONDITION;
  // enable LFSR only in 640x480 area
  wire star_enable = hpos < 640 & vpos < 480;
`endif

  reg [HIGHEST_BIT:0] lfsr;

  VgaSyncGen vga_0(
    .px_clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .x_px(hpos),
    .y_px(vpos),
    .activevideo(display_on)
  );
  
  always_ff @(posedge clk)
    begin
      if (star_enable & !restart_lfsr) lfsr <= {1'b0, lfsr[HIGHEST_BIT:1]} ^ (lfsr[0] ? TAPS : ZERO);
      if (restart_lfsr) lfsr <= SEED;
      if (reset) lfsr <= SEED;
    end
  
  assign rgb = 
    display_on & star_enable & (&lfsr[HIGHEST_BIT:HIGHEST_BIT-8]) ? lfsr[2:0] : 0;

`ifdef COUNTDOWN
  reg[31:0] counter = `COUNTDOWN;
  always_ff @(posedge clk)
    begin
      if (star_enable & counter > 0)
        begin
          if (counter == 1) $display ("LFSR=%0d'b%0b after %0d iterations with TAPS=%0d'b%0b and SEED=0x%0h", HIGHEST_BIT+1, lfsr, `COUNTDOWN, HIGHEST_BIT+1, TAPS, SEED);
          counter = counter - 1;
        end
      if (reset)
        counter = `COUNTDOWN;
    end
`endif
// LFSR=16'b100111011001001     after 63999  iterations with TAPS=16'b1101000000001000    and SEED=0xffff
// LFSR=17'b11011110000101111   after 76799  iterations with TAPS=17'b10010000000000000   and SEED=0x1ffff
// LFSR=19'b1010100000000110111 after 307199 iterations with TAPS=19'b1110010000000000000 and SEED=0x7ffff
// LFSR=19'b1111100110110010111 after 306560 iterations with TAPS=19'b1110010000000000000 and SEED=0x7ffff
// LFSR=19'b1110001111001111111 after 307840 iterations with TAPS=19'b1110010000000000000 and SEED=0x7ffff
// LFSR=19'b1011110000000001101 after 307201 iterations with TAPS=19'b1110010000000000000 and SEED=0x7ffff
endmodule
`default_nettype wire
