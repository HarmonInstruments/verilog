/*
 * Copyright (C) 2015 Harmon Instruments, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/
 *
 */

`timescale 1ns / 1ps

// 4 channel filter, decimate by 4, 0 to 0.05 input FS
// clock is 4 * FS
module fir_decim_4
  (
   input 	 c,
   input [6:0] 	 state,
   input [17:0]  id, // input data time multiplexed
   output [17:0] od, // output data, not time multiplexed
   output 	 ov
   );

   wire [17:0] 	 coef;
   wire [4:0] 	 ra0, ra1;
   wire 	 r;
   wire [4:0] 	 s;

   fir_decim_4_common common (.c(c),
			      .state(state[7:0]),
			      .ov(ov),
			      .coef(coef),
			      .ra0(ra0),
			      .ra1(ra1),
			      .r(r),
			      .s(s));

   fir_decim_4_channel channel(.c(c),
			       .state(state[7:0]),
			       .id(id),
			       .od(od),
			       .coef(coef),
			       .ra0(ra0),
			       .ra1(ra1),
			       .r(r),
			       .s(s));

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule

// commmon elements to be shared among channels
module fir_decim_4_common
  (
   input 	     c,
   input [6:0] 	     state,
   output reg 	     ov = 0,
   output reg [17:0] coef = 0,
   output reg [4:0]  ra0 = 0,
   output reg [4:0]  ra1 = 0,
   output reg 	     r = 0,
   output reg [4:0]  s = 0
   );

   reg signed [17:0]  coefrom[15:0];
   reg [3:0] 	      coefa = 0;

   always @ (posedge c) begin
      s <= {s[3:0], (state[3:0] == 15)};
      ov <= r;
      r <= s[4];
      coef <= coefrom[coefa];
      coefa <= state[3:0] - 1'b1;
      ra0 <= s[0] ? state[6:2] - 6'd1: ra0 - 1'b1;
      ra1 <= s[0] ? state[6:2] - 6'd16 : ra1 + 1'b1;
   end

   initial begin
      // 5 MHz
      coefrom[0] = -134;
      coefrom[1] = -436;
      coefrom[2] = -701;
      coefrom[3] = -367;
      coefrom[4] = 1100;
      coefrom[5] = 3375;
      coefrom[6] = 4693;
      coefrom[7] = 2457;
      coefrom[8] = -4629;
      coefrom[9] = -14048;
      coefrom[10] = -18805;
      coefrom[11] = -10233;
      coefrom[12] = 16479;
      coefrom[13] = 57414;
      coefrom[14] = 99576;
      coefrom[15] = 126402;
   end
endmodule

// filter, decimate by 4, 0 to 0.05 input FS
// clock is 4 * FS
module fir_decim_4_channel
  (
   input 	 c,
   input [6:0] 	 state,
   input [17:0]  id, // input data
   output [17:0] od, // output data
   input [17:0]  coef,
   input [4:0] 	 ra0, ra1,
   input 	 r,
   input [4:0] 	 s
   );

   reg [17:0] 	 rd0, rd1; // read data from RAM
   reg [17:0] 	 dram[0:31];
   wire [22:0] 	 dsp_o;

   assign od = dsp_o[17:0];

   dsp48_wrap_f #(.S(25),
		  .AREG(1),
		  .BREG(2),
		  .USE_DPORT("TRUE")) macn
     (
      .clock(c),
      .ce1(1'b1),
      .ce2(1'b1),
      .cem(1'b1),
      .cep(1'b1),
      .a({rd0[17], rd0, 6'd0}),
      .b(coef),
      .c(48'd262144), // convergent rounding
      .d({rd1[17], rd1, 6'd0}),
      .mode(r ? 5'b01100 : 5'b01000),
      .pcin(48'h0),
      .pcout(),
      .p(dsp_o));

   always @ (posedge c) begin
      rd0 <= dram[ra0];
      rd1 <= dram[ra1];
      if(state[1:0]==0)
	dram[state[6:2]] <= id;
   end

endmodule
