/*
 * Copyright (C) 2017 Harmon Instruments, LLC
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

// divide a double precision float by 3e9 0x41E65A0BC0000000
// 63: sign, 62:52 exponent with bias of 1023, 51:0 mantissa
//
module div_3e9
  (
   input             c,
   input [62:0]      i, // double float without sign bit
   input             iv,
   output reg [62:0] o,
   output reg [10:0] oe,
   output reg        ov = 0);

   reg [53:0] 	     sr;
   reg [6:0] 	     state = 0;

   wire [53:0] 	     sub = sr - 54'h165A0BC0000000;

   always @ (posedge c)
     begin
	if(iv)
	  oe <= i[62:52] - (1023+31);
	else if(state == 64)
	  oe <= o[62] ? oe : oe-1'b1;

	if(iv)
	  state <= 1'b1;
	else if(state == 64)
	  state <= 1'b0;
	else
	  state <= state + (state != 0);

	if(iv)
	  sr <= {2'b01,i[51:0]};
	else
	  sr <= sub[53] ? {sr[52:0],1'b0} : {sub[52:0],1'b0};
	if(state == 64)
	  o <= o[62] ? o : {o[61:0],1'b0};
	else if(state != 0)
	  o <= {o[61:0], ~sub[53]};
	ov <= (state == 64);

     end

   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end


endmodule
