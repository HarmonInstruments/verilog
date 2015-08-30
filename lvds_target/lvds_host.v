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
 * LVDS remote IO
 *
 */

`timescale 1ns / 1ps

module lvds_host(input c, c2x, c2x_90, r, dip, din,
		 output 	  dop, don,
		 input 		  rinv, tinv,
		 input 		  wvalid,
		 input [39:0] 	  wdata,
		 output reg [31:0] rdata
		 );

   wire [33:0] 	 rd;
   wire 	 rv;
   always @ (posedge c) begin
      if(rv && ~rd[33])
	rdata <= rd[31:0];
   end
   lvds_rx #(.NB(34)) rx(.c(c), .c2x(c2x), .c2x_90(c2x_90), .r(r), .inv(rinv), .ip(dip), .in(din), .d(rd), .v(rv));
   lvds_tx #(.NB(42)) tx(.c(c), .c2x(c2x), .inv(tinv), .r(r), .d({2'd0, wdata}), .v(wvalid), .op(dop), .on(don));
endmodule
