/*
 * Copyright (C) 2014-2015 Harmon Instruments, LLC
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

module icap(input c, w, input [31:0] i);
   wire [31:0] swapped;
   reg [31:0]  di;
   reg [2:0]   wd;
   genvar      j;
   generate
      for(j=0; j<32; j=j+1)
	begin : swap
	   assign swapped[j] = i[31-j];
	end
   endgenerate
   always @ (posedge c)
     begin
	wd <= {wd[1:0], w};
	if(w)
	  di <= swapped;
     end
   // Write and CE are active low, I is bit swapped
   ICAPE2 #(.ICAP_WIDTH("X32")) ICAP_i
     (.O(), .CLK(wd[2]), .CSIB(1'b0),.I({di[7:0], di[15:8], di[23:16], di[31:24]}), .RDWRB(1'b0));

endmodule
