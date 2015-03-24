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

// 8 channel filter, decimate by 4, 0 to 0.05 input FS
// clock is 4 * FS
module fir_decim_4
  (
   input 	  c,
   input 	  reset,
   input [191:0]  id, // input data
   output [191:0] od,
   output reg 	  ov = 0
   );

   reg signed [17:0] 	   coefrom[15:0];
   reg signed [17:0] 	   coef = 0;
   reg [4:0] 		   wa = 0;
   reg [4:0] 		   ra0 = 0;
   reg [4:0] 		   ra1 = 0;
   reg [3:0] 		   state = 0;
   reg [3:0] 		   coefa = 0;
   wire [191:0] 	   rd0, rd1; // read data from RAM
   reg 			   r = 0;
   reg 			   w = 0;

   bram_192x512 bram_0(.c(c),
		       .w(w), .wa({5'd0,wa}), .wd(id),
		       .r(~reset), .ra({5'd0,ra0}), .rd(rd0));
   bram_192x512 bram_1(.c(c),
		       .w(w), .wa({5'd0,wa}), .wd(id),
		       .r(~reset), .ra({5'd0,ra1}), .rd(rd1));

   genvar 		   i;
   generate
      for (i = 0; i < 8; i = i+1) begin: maci
	 dsp48_wrap #(.NBA(24),
		      .NBB(18),
		      .NBP(24),
		      .S(19),
		      .AREG(1),
		      .BREG(2),
		      .USE_DPORT("TRUE")) macn
	       (
	        .clock(c),
	        .ce1(1'b1),
	        .ce2(1'b1),
	        .cem(1'b1),
	        .cep(1'b1),
	        .a(rd0[23+24*i:24*i]),
	        .b(coef),
	        .c(24'd262144), // convergent rounding
	        .d(rd1[23+24*i:24*i]),
	        .mode(r ? 5'b01100 : 5'b01000),
	        .acin(30'h0),
	        .bcin(18'h0),
	        .pcin(48'h0),
	        .acout(),
	        .bcout(),
	        .pcout(),
	        .p(od[23+24*i:24*i]));
      end
   endgenerate

   always @ (posedge c) begin
      ov <= state == 5;
      r <= state == 4;
      w <= state[1:0] == 1;
      wa <= wa + w;
      coef <= coefrom[coefa];
      state <= reset ? 1'b0 : state + 1'b1;
      coefa <= state - 1'b1;
      ra0 <= (state == 0) ? wa : ra0 + 1'b1;
      ra1 <= (state == 0) ? wa + 5'd31 : ra1 - 1'b1;
   end

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

   initial begin
      coefrom[0] = -37;
      coefrom[1] = -613;
      coefrom[2] = -627;
      coefrom[3] = -409;
      coefrom[4] = 688;
      coefrom[5] = 4037;
      coefrom[6] = 4336;
      coefrom[7] = 2679;
      coefrom[8] = -3761;
      coefrom[9] = -15371;
      coefrom[10] = -17888;
      coefrom[11] = -10844;
      coefrom[12] = 15325;
      coefrom[13] = 59127;
      coefrom[14] = 98065;
      coefrom[15] = 127437;
   end

endmodule
