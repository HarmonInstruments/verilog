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
`include "config.vh"

module target_tx(input c, c2x, inv, r, v, input [41:0] d, output op, on);
   reg [42:0] sr = ~43'h0;
   wire [3:0] od = (inv ? 4'hF : 4'h0) ^ {sr[39], sr[40], sr[41], sr[42]};
   oserdes_4x oserdes_tx(.c(c2x), .cdiv(c), .t(r), .din(od), .op(op), .on(on));
   always @ (posedge c)
     sr <= v ? {1'b0, d} : {sr[38:0], 4'hF};
endmodule

module target_rx
  (
   input 	     c, // 200 MHz
   input 	     c2x, c2x_90, // 400 MHz, 400 MHz 90 deg
   input 	     ip, in, // diff pair in
   input 	     inv,
   input 	     r, // reset
   output reg [41:0] d,
   output reg 	     v = 0);

   wire [7:0] 	     d2;
   wire [3:0] 	     d3;
   wire 	     v3;
   reg [3:0] 	     d4;
   reg 		     v4;
   reg [37:0] 	     d5;

   oversample_8x oversample (.c(c2x), .c90(c2x_90), .r(r), .ip(ip), .in(in), .o(d2));

   dru dru(.c(c2x), .i(d2 ^ (inv ? 8'h55 : 8'hAA)), .d(d3), .v(v3));

   always @ (posedge c) begin
      d4 <= d3;
      v4 <= v3;
      d5 <= {d5[33:0],d4};
      if(v4)
	d <= {d5,d4};
      v <= v4;
   end
endmodule

`ifndef HOST
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
   target_rx rx(.c(c), .c2x(c2x), .c2x_90(c2x_90), .r(r), .inv(rinv), .ip(dip), .in(din), .d(rd), .v(rv));
   target_tx tx(.c(c), .c2x(c2x), .inv(tinv), .r(r), .d({10'h0,td}), .v(tv), .op(dop), .on(don));
endmodule
`else
module lvds_host(input c, c2x, c2x_90, r, dip, din,
		 output        dop, don,
		 input 	       rinv, tinv,
		 input 	       wvalid,
		 input [39:0]  wdata,
		 output [31:0] rdata
		 );

   wire [41:0] 	 odataq;
   assign rdata = odataq[31:0];

   target_rx rx(.c(c), .c2x(c2x), .c2x_90(c2x_90), .r(r), .inv(rinv), .ip(dip), .in(din), .d(odataq), .v());
   target_tx tx(.c(c), .c2x(c2x), .inv(tinv), .r(r), .d({2'd0, wdata}), .v(wvalid), .op(dop), .on(don));
endmodule
`endif
