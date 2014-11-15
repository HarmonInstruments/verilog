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
 *
 * LVDS remote IO
 *
 */

`timescale 1ns / 1ps

module lvds_tx(input c, output op, on, input v, input [31:0] d);
   parameter INV = 0;
   reg [1:0] 	od = 0;
   reg [32:0] 	sr = ~33'h0;

   oddr_lvds oddr_lvds_i(.c(c), .i(INV ? ~od : od), .op(op), .on(on));

   always @ (posedge c)
     begin
	sr <= v ? {1'b0, d} : {sr[30:0], 2'b11};
	od[0] <= sr[32];
	od[1] <= sr[31];
     end
endmodule

module lvds_rx(input c, ip, in, output reg [55:0] d=0, output reg v=0);
   parameter INV = 0;
   wire [1:0] 	 id;
   reg [1:0] 	 id_buf;
   reg [4:0] 	 state = 0;
   reg [57:0] 	 sr = ~58'h0;
   reg 		 vp = 0;

   iddr_lvds iddr_lvds_i(.c(c), .o(id), .ip(ip), .in(in));

   always @ (posedge c)
     begin
	id_buf <= INV ? ~id : id;
	sr <= {sr[55:0], id_buf};
	state <= state == 0 ? (id_buf != 3) : state + 1'b1;
	vp <= (state == 28);
	if(vp)
	  d <= sr[57] ? sr[55:0] : sr[56:1];
	v <= vp;
     end
endmodule

module lvds_io
  (
   input 	     clock, clock_2x,
   input 	     sdip, sdin,
   output 	     sdop, sdon,
   output reg 	     wvalid = 0,
   output reg [55:0] wdata,
   input [31:0]      rdata
   );
   parameter TINV = 1'b0;
   parameter RINV = 1'b0;

   wire 	    rv;
   reg 		    tv = 0;
   wire [55:0] 	    rd;
   reg [31:0] 	    td;
   wire 	    rv_100;
   reg 		    rv_100_d = 0;
   reg [7:0] 	    tcount = 0;
   reg 		    tmatch = 0;

   lvds_rx #(.INV(RINV)) r(.c(clock_2x), .ip(sdip), .in(sdin), .d(rd), .v(rv));
   lvds_tx #(.INV(TINV)) t(.c(clock_2x), .op(sdop), .on(sdon), .d(td), .v(tv));

   always @ (posedge clock_2x)
     begin
	if(tmatch)
	  begin
	     if(rd[55:48] == 0) // calibration
	       td <= rd[40] ? rd[31:0] : 32'h080FF010;
	     else
	       td <= rdata;
	  end
	if(rv)
	  tcount <= 8'd1;
	else if(tcount != 0)
	  tcount <= tcount + 1'b1;
	tmatch <= tcount == 255;
	tv <= tmatch;
     end

   always @ (posedge clock)
     begin
	wdata <= rd;
	rv_100_d <= rv_100;
	wvalid <= rv_100_d;
     end

   sync_pulse sync_rv(.ci(clock_2x), .i(rv), .co(clock), .o(rv_100));

endmodule
