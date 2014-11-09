/*
 * Copyright (C) 2014 Harmon Instruments, LLC
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
 * Xilinx internal configuration access port
 *
 */

`timescale 1ns / 1ps
`include "config.vh"

module icap(input c, w, input [15:0] i);
   reg [3:0] state = 0;
   wire [15:0] swapped;
   reg [15:0]  di;
   genvar      j;
   generate
      for(j=0; j<16; j=j+1)
	begin : swap
	   assign swapped[j] = i[15-j];
	end
   endgenerate
   always @ (posedge c)
     begin
	if(w)
	  di <= swapped;
	if(w)
	  state <= 1'b1;
	else if(state != 0)
	  state <= state + 1'b1;
     end
   // Write and CE are active low, I is bit swapped
`ifdef SPARTAN3A
   ICAP_SPARTAN3A ICAP_i(.BUSY(), .O(), .CE(1'b0), .CLK(state[2]),
			 .I(state[3] ? di[15:8] : di[7:0]), .WRITE(1'b0));
`endif
`ifdef SPARTAN6
   ICAP_SPARTAN6 ICAP_i(.BUSY(), .O(), .CE(1'b0), .CLK(state[3]),
			.I({di[7:0], di[15:8]}), .WRITE(1'b0));
`endif
`ifdef X7SERIES
   ICAPE2 #(.ICAP_WIDTH("X16")) ICAP_i
     (.O(), .CLK(state[3]), .CSIB(1'b0),.I({di[7:0], di[15:8]}), .RDWRB(1'b0));
`endif
endmodule

