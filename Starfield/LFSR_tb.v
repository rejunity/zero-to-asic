`default_nettype none

`timescale 1 ns / 1 ps


module LFSR_tb;
	reg [18:0] lfsr_19bit;
	reg [17:0] lfsr_18bit;
	reg [16:0] lfsr_17bit;
	reg [15:0] lfsr_16bit;
	reg [7:0]  lfsr_8bit;
	localparam TEXT = "%0d'b%b after %s=%0d clocks with TAPS=%0d'b%0b and SEED=0x%0h";

	initial #(640*480-1) $display(TEXT, $bits(TAPS_19), lfsr_19bit, "(640*480-1)", $time, $bits(TAPS_19), TAPS_19, SEED_19);
	initial #(480*320-1) $display(TEXT, $bits(TAPS_18), lfsr_18bit, "(480*320-1)", $time, $bits(TAPS_18), TAPS_18, SEED_18);
	initial #(320*240-1) $display(TEXT, $bits(TAPS_17), lfsr_17bit, "(320*240-1)", $time, $bits(TAPS_17), TAPS_17, SEED_17);
	initial #(320*200-1) $display(TEXT, $bits(TAPS_16), lfsr_16bit, "(320*200-1)", $time, $bits(TAPS_16), TAPS_16, SEED_16);


	`define LFSR lfsr_8bit
	//`define BIT 0
	integer bit = 0;
	integer zeros = 0, ones = 0, symmetry_at = -1;
	reg [$bits(`LFSR)-1:0] symmetric_lfsr_value;
	always begin
		#1;
		if (bit < $bits(`LFSR)) begin
			if (`LFSR[bit] == 0)
				zeros = zeros + 1;
			else
				ones = ones + 1;

			if (zeros == ones) begin
				symmetry_at = $time;
				symmetric_lfsr_value = `LFSR;
			end

			if ($time % 2**($bits(`LFSR)) == 0) begin
				if (symmetry_at != -1)
					$display("The longest %0d-bit sequence with 0/1 symmetry at bit [%0d] reached after %0d clocks with the value: %b",
						$bits(symmetric_lfsr_value), bit, symmetry_at, symmetric_lfsr_value);
				zeros = 0;
				ones = 0;
				symmetry_at = -1;
				bit = bit + 1;
			end
		end
	end
	`undef LFSR
	//`undef BIT

	initial begin
		#(1024*1024)
		$display("%c[1;33m",27);
		$display("Finished!!!");
		$display("%c[0m",27);
		$finish;
	end

	initial begin
		lfsr_19bit <= SEED_19;
		lfsr_18bit <= SEED_18;
		lfsr_17bit <= SEED_17;
		lfsr_16bit <= SEED_16;
		lfsr_8bit  <= SEED_8;
	end

	always begin
		#1; // update LFSRs once a clock
		lfsr_19bit <= {1'b0, lfsr_19bit[18:1]} ^ (lfsr_19bit[0] ? TAPS_19 : 19'b0);
		lfsr_18bit <= {1'b0, lfsr_18bit[17:1]} ^ (lfsr_18bit[0] ? TAPS_18 : 18'b0);
		lfsr_17bit <= {1'b0, lfsr_17bit[16:1]} ^ (lfsr_17bit[0] ? TAPS_17 : 17'b0);
		lfsr_16bit <= {1'b0, lfsr_16bit[15:1]} ^ (lfsr_16bit[0] ? TAPS_16 : 16'b0);
		lfsr_8bit  <= {1'b0, lfsr_8bit[7:1]} ^ (lfsr_8bit[0] ? TAPS_8 : 8'b0);
 	end

	localparam TAPS_19 = 19'b1110010000000000000;
	localparam TAPS_18 = 18'b100000010000000000;
	localparam TAPS_17 = 17'b10010000000000000;
	localparam TAPS_16 = 16'b1101000000001000;
	localparam TAPS_15 = 15'b110000000000000;
	localparam TAPS_14 = 14'b11100000000010;
	localparam TAPS_8  =  8'b10111000;
	localparam TAPS_7  =  7'b1100000;

	localparam SEED_19 = {19{1'b1}};
	localparam SEED_18 = {18{1'b1}};
	localparam SEED_17 = {17{1'b1}};
	localparam SEED_16 = {16{1'b1}};
	localparam SEED_15 = {15{1'b1}};
	localparam SEED_14 = {14{1'b1}};
	localparam SEED_8  = { 8{1'b1}};
	localparam SEED_7  = { 7{1'b1}};

endmodule
`default_nettype wire
