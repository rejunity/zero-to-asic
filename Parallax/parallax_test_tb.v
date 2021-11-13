// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

//`define SHORT_TEST // check just a portion of the frame, instead of 2 full frames

module parallax_test_tb;
	reg clock;
	reg reset;
	reg power1, power2, power3, power4;
	wire [37:0] io_out;

	wire hsync;
	wire vsync;
	wire [2:0] rgb;

	assign hsync = io_out[8];
	assign vsync = io_out[9];
	assign rgb = io_out[12:10];

	initial begin
		$dumpfile("parallax_test.vcd");
		$dumpvars(0, parallax_test_tb);

		// PIXEL_CLK = 31500 (31.74us) @70?
		// 832 x 520 = 432640 dots
		// HSYNC: ^^^^ [24] ____ [64] ^^^^ ... 832
		// VSYNC: ^^^^ [ 9] ____ [12] ^^^^ ... 520

		// .hsync(io_out[8]),  // skip 0..7 pins
		// .vsync(io_out[9]),
		// .rgb(io_out[12:10]),

		// Repeat enough cycles for more than 2 frames of VGA signal to complete testbench
		repeat (3) begin
			repeat (52) begin
				repeat (832*10) @(posedge clock);
				$display("8320 cycles passed (10 lines x 832 pixel clocks)");
			end
			$display("frame passed");
		end

		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, VGA signal (GL) Failed");
		`else
			$display ("Monitor: Timeout, VGA signal (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	always @(io_out) begin
		//#1 $display("RGB=%b   HSYNC=%b VSYNC=%b", rgb, hsync, vsync);
		if (rgb != 0 && vsync != 1)
			$display("005 failed, RGB signal inside VSYNC");
		if (rgb != 0 && hsync != 1)
			$display("005 failed, RGB signal inside HSYNC");
	end

	initial begin
		wait(hsync == 1);
		#1;
		`ifdef SHORT_TEST
		repeat (1) begin // check just a portion of the frame
		`else
		repeat (1) begin // check 2 frames
		`endif
			if (hsync != 1 ||
				vsync != 1 ||
				rgb != 0) $display("000 failed! io_out=%b", io_out);
			$display("Vertical retrace started");

			// VBLANK FRONT porch
			repeat (9) begin
				wait(hsync == 0);
				wait(hsync == 1);
				if (vsync != 1 ||
					rgb != 0) $display("001 failed! io_out=%b", io_out);
				$display("VBLANK FRONT porch line started");
			end

			// VSYNC
			#1 wait(vsync == 0);
			$display("Vertical sync period started");
			repeat (3) begin
				wait(hsync == 0);
				wait(hsync == 1);
				if (vsync != 0 ||
					rgb != 0) $display("002 failed! io_out=%b", io_out);
				$display("VSYNC line started");
			end
			#1 wait(vsync == 1);

			// VBLANK BACK porch
			repeat (28) begin
				wait(hsync == 0);
				wait(hsync == 1);
				if (vsync != 1 ||
					rgb != 0) $display("003 failed! io_out=%b", io_out);
				$display("VBLANK BACK porch line started");
			end

			// ACTIVE
			$display("Visible portion of the frame started");
			`ifdef SHORT_TEST
			repeat (10) begin
			`else
			repeat (480) begin
			`endif
				wait(hsync == 0);
				wait(hsync == 1);
				if (vsync != 1) $display("004 failed! io_out=%b", io_out);
				$display("ACTIVE line started");
			end

			`ifdef SHORT_TEST
			`else
			$display("Frame ended");
			`endif
		end

		`ifdef GL
		$display("Monitor: VGA signal (GL) Passed");
		`else
		$display("Monitor: VGA signal (RTL) Passed");
		`endif
		$finish;
	end

	initial begin
		clock = 0;
	end

	always begin
 		#1  clock = !clock;
 	end

	initial begin
		reset <= 1'b0;
		#100;
		reset <= 1'b1;	    // Release reset
	end

	initial begin			// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;

		#8;
		power1 <= 1'b1;
		#8;
		power2 <= 1'b1;
		#8;
		power3 <= 1'b1;
		#8;
		power4 <= 1'b1;
	end

	wire VDD1V8;
    wire VDD3V3;
	wire VSS;
	wire RESETB;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;
	assign RESETB = !reset;

parallax i_parallax (
    .clk(clock),
    .reset(RESETB),

    .hsync(io_out[8]),  // skip 0..7 pins
    .vsync(io_out[9]),
    .rgb(io_out[12:10])
);

endmodule
`default_nettype wire
