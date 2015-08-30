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

module lvds_target(input c, c2x, c2x_90, r, dip, din, rinv, tinv,
		   output 	     dop, don,
		   output reg 	     wvalid = 0,
		   output reg [39:0] wdata,
		   input [31:0]      rdata
		   );

   wire [41:0] 	 rd;
   wire 	 rv;
   reg [31:0] 	 td;
   reg 		 tv = 0;

   reg [255:0] 	 sr;

   always @ (posedge c) begin
      tv <= sr[255];
      if(sr[255])
	td <= rdata;
      sr <= {sr[254:0], wvalid};
      if(rv && (rd[41] == 0))
	wdata <= rd[39:0];
      wvalid <= rv && (rd[41:40] == 0);
   end
   lvds_rx #(.NB(42)) rx(.c(c), .c2x(c2x), .c2x_90(c2x_90), .r(r), .inv(rinv), .ip(dip), .in(din), .d(rd), .v(rv));
   lvds_tx #(.NB(34)) tx(.c(c), .c2x(c2x), .inv(tinv), .r(r), .d({1'b0, ^td, td}), .v(tv), .op(dop), .on(don));
endmodule
