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

// 8 channel halfband filter, 0 to 0.2 input FS usable
module halfband_59
  (
   input 	  c,
   input 	  reset,
   input [191:0]  id, // input data
   input 	  iv, // input valid
   output [191:0] od,
   output reg 	  ov = 0
   );

   reg signed [17:0] 	   coefrom[15:0];
   reg signed [17:0] 	   coef = 0;
   reg [5:0] 		   wa = 0;
   reg [5:0] 		   ra = 0;
   reg 			   ignore_next = 0;
   reg [4:0] 		   state = 0;
   reg [3:0] 		   coefa = 0;
   reg [3:0] 		   ovpipe = 0;
   wire [191:0] 	   rd; // read data from RAM
   reg 			   r = 0;

   initial begin
      coefrom[0] = 19;
      coefrom[1] = -51;
      coefrom[2] = 116;
      coefrom[3] = -234;
      coefrom[4] = 431;
      coefrom[5] = -745;
      coefrom[6] = 1220;
      coefrom[7] = -1917;
      coefrom[8] = 2916;
      coefrom[9] = -4340;
      coefrom[10] = 6402;
      coefrom[11] = -9543;
      coefrom[12] = 14907;
      coefrom[13] = -26709;
      coefrom[14] = 83065;
      coefrom[15] = 131069;
   end

   bram_192x512 bram_i(.c(c),
		       .w(iv), .wa({5'd0,wa}), .wd(id),
		       .r(~reset), .ra({5'd0,ra}), .rd(rd));

   mac_24x18 mac_0(.c(c), .r(r), .a(rd[ 23:  0]), .b(coef), .p(od[ 23:  0]));
   mac_24x18 mac_1(.c(c), .r(r), .a(rd[ 47: 24]), .b(coef), .p(od[ 47: 24]));
   mac_24x18 mac_2(.c(c), .r(r), .a(rd[ 71: 48]), .b(coef), .p(od[ 71: 48]));
   mac_24x18 mac_3(.c(c), .r(r), .a(rd[ 95: 72]), .b(coef), .p(od[ 95: 72]));
   mac_24x18 mac_4(.c(c), .r(r), .a(rd[119: 96]), .b(coef), .p(od[119: 96]));
   mac_24x18 mac_5(.c(c), .r(r), .a(rd[143:120]), .b(coef), .p(od[143:120]));
   mac_24x18 mac_6(.c(c), .r(r), .a(rd[167:144]), .b(coef), .p(od[167:144]));
   mac_24x18 mac_7(.c(c), .r(r), .a(rd[191:168]), .b(coef), .p(od[191:168]));

   always @ (posedge c) begin
      {ov,ovpipe} <= {ovpipe, (state == 31)};
      r <= state == 3;
      wa <= wa + iv;
      ignore_next <= reset ? 1'b0 : ignore_next ^ iv;
      coef <= coefrom[coefa];
      if(reset)
	state <= 1'b0;
      else
	state <= (state == 0) ? iv & ~ignore_next : state + 1'b1;
      if(state == 0)
	coefa <= 4'd0;
      else if(state < 16)
	coefa <= state - 1'b1;
      else
	coefa <= 5'd31 - state;
      if(state == 0)
	ra <= wa + 4'd2;
      else if((state == 15) || (state == 16))
	ra <= ra + 2'd1;
      else if(state == 31)
	ra <= ra;
      else
	ra <= ra + 2'd2;
   end

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
