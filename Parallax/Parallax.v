`default_nettype none

/*
Scrolling procedural background using several LFSRs.
*/
module parallax(
    input clk,
    input reset,
    output hsync,
    output vsync,
    output [2:0] rgb
);

  localparam TAPS_19 = 19'b1110010000000000000;
  localparam TAPS_18 = 18'b100000010000000000;
  localparam TAPS_17 = 17'b10010000000000000;
  localparam TAPS_16 = 16'b1101000000001000;
  localparam TAPS_15 = 15'b110000000000000;
  localparam TAPS_14 = 14'b11100000000010;
  localparam TAPS_8  =  8'b10111000;
  localparam TAPS_7  =  7'b1100000;

// 16'b0100111011001001 after (320*200-1)=63999 clocks with TAPS=16'b1101000000001000 and SEED=0xffff
// 17'b11011110000101111 after (320*240-1)=76799 clocks with TAPS=17'b10010000000000000 and SEED=0x1ffff
// 18'b110100101100010001 after (480*320-1)=153599 clocks with TAPS=18'b100000010000000000 and SEED=0x3ffff
// 19'b1010100000000110111 after (640*480-1)=307199 clocks with TAPS=19'b1110010000000000000 and SEED=0x7ffff


  localparam RESET_640x480_MINUS1 = 19'b1010100000000110111; // value at 307199th (=640*480-1) iteration, scroll left
  localparam RESET_320x480_MINUS1 = 18'b110100101100010001;  // value at 153599th (=320*480-1=480*320-1) iteration
  localparam RESET_160x480_MINUS1 = 17'b11011110000101111;   // value at  76799th (=160*480-1=320*240-1) iteration

  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;
  reg [18:0] lfsr;
  reg [17:0] lfsr2;
  reg [16:0] lfsr3;
  reg [7:0] lfsr_, lfsr__;
  reg [6:0] lfsr_2, lfsr__2;
  reg [9:0] mount, mount_;
  reg [9:0] mount2, mount2_;
  reg [4:0] frame;

  VgaSyncGen vga(
    .px_clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .x_px(hpos),
    .y_px(vpos),
    .activevideo(display_on)
  );


  //wire star_enable =  !hpos[8] & !vpos[8] & !hpos[9] & !vpos[9]; // enable parallax only in 256x256 area
  wire star_enable =  hpos < 640 & vpos < 480; // enable parallax in 640x480 area
  wire star2_enable = star_enable & !hpos[0];
  wire star3_enable = star_enable & !hpos[0] & !hpos[1];

  wire restart_lfsr = lfsr == RESET_640x480_MINUS1;
  wire restart_lfsr2 = lfsr2 == RESET_320x480_MINUS1;
  wire restart_lfsr3 = lfsr3 == RESET_160x480_MINUS1;

  always @(posedge clk)
    begin
      if (hpos == 0 && vpos == 0) begin
        frame <= frame + 1;
      end

        //lfsr <= {1'b0, lfsr[15:1]} ^ (lfsr[0] ? TAPS_16 : 16'b0);
        //lfsr2 <= {1'b0, lfsr2[14:1]} ^ (lfsr2[0] ? TAPS_15 : 15'b0);

      if (star_enable & !restart_lfsr)
        lfsr <= {1'b0, lfsr[18:1]} ^ (lfsr[0] ? TAPS_19 : 19'b0);
      if (star2_enable & !restart_lfsr2)
        lfsr2 <= {1'b0, lfsr2[17:1]} ^ (lfsr2[0] ? TAPS_18 : 18'b0);
      if (star3_enable & !restart_lfsr3)
        lfsr3 <= {1'b0, lfsr3[16:1]} ^ (lfsr3[0] ? TAPS_17 : 17'b0);

      if (hpos < 6 && vpos == 1) begin
        lfsr__ <= {1'b0, lfsr__[7:1]} ^ (lfsr__[0] ? TAPS_8 : 8'b0);
        mount_ <= lfsr__[0] ? mount_ + 1: mount_ - 1;
      end
      else if (hpos == 0) begin
        lfsr_ <= lfsr__;
        mount <= mount_;
      end
      else if (star_enable) begin
        lfsr_ <= {1'b0, lfsr_[7:1]} ^ (lfsr_[0] ? TAPS_8 : 8'b0);
        mount <= lfsr_[0] ? mount + 1: mount - 1;
      end

      if (hpos < 3 && vpos == 1) begin
        if (hpos[0] == frame[0])
          lfsr__2 <= {1'b0, lfsr__2[6:1]} ^ (lfsr__2[0] ? TAPS_7 : 7'b0);
        mount2_ <= lfsr__2[0] ? mount2_ + 1: mount2_ - 1;
      end
      else if (hpos == 0) begin
        lfsr_2 <= lfsr__2;
        mount2 <= mount2_;
      end
      else if (star_enable) begin
        if (hpos[0] == frame[0])
          lfsr_2 <= {1'b0, lfsr_2[6:1]} ^ (lfsr_2[0] ? TAPS_7 : 7'b0);
        mount2 <= lfsr_2[0] ? mount2 + 1: mount2 - 1;
      end



      if (reset) frame <= 0;
      if (reset | restart_lfsr ) lfsr  <= {19{1'b1}}; //16'b1100010001010111;
      if (reset | restart_lfsr2) lfsr2 <= {18{1'b1}}; //15'b110001000110111;
      if (reset | restart_lfsr3) lfsr3 <= {17{1'b1}}; //14'b11000100110111;
      if (reset) lfsr__ <= 8'b1100000;
      if (reset) lfsr_ <= 8'b1100000;
      if (reset) lfsr__2 <= 7'b110000;
      if (reset) lfsr_2 <= 7'b110000;
      if (reset) mount_ <= 400;//6'b110000;
      if (reset) mount <=  400;//6'b110000;
      if (reset) mount2_ <= 380;//6'b110000;
      if (reset) mount2 <=  380;//6'b110000;
    end


  assign rgb =
     (star_enable && (&lfsr[18:9]) ? lfsr[2:0] : 0)
    +(star2_enable && (&lfsr2[17:9]) ? lfsr2[2:0] : 0)
    +(star3_enable && (&lfsr3[16:9]) ? lfsr3[2:0] : 0)
    +((star_enable && mount < vpos) ? 2 : 0) +
    +((star_enable && mount2 < vpos) ? 4 : 0);
    ;
endmodule
`default_nettype wire
