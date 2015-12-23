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
 * remote IO
 *
 */

`timescale 1ns / 1ps

`ifndef SIM
module sio_host(input c, c2x, c2x_90, r, inout dp, dn, input wvalid, input [NBT-1:0] wdata, output [NBR-1:0] rdata);
   parameter NBR = 32;
   parameter NBT = 40;
   wire 	 sdo, tq;
   wire [1:0] 	 id0;
   reg [4:0] 	 state = 0;
   reg 		 rr;

   IOBUFDS_DIFF_OUT_INTERMDISABLE iobuf_i
     (.O(id0[0]), .OB(id0[1]), .IO(dp), .IOB(dn), .I(sdo), .INTERMDISABLE(1'b0), .IBUFDISABLE(1'b0), .TM(tq), .TS(tq));

   always @ (posedge c) begin
      if(wvalid)
	state <= 1'b1;
      else if(state != 0)
	state <= state + 1'b1;
      rr <= state < 12;
   end
   sio_rx #(.NB(NBR)) rx(.c(c), .c2x(c2x), .c2x_90(c2x_90), .por(r), .r(rr), .i(id0), .d(rdata), .v());
   // the 90 degree clock is used due to a routing constraint into the IO tile
   sio_tx #(.NB(NBT)) tx(.c(c), .c2x(c2x_90), .r(r), .t(state > 11), .d(wdata), .v(wvalid), .o(sdo), .tq(tq));
endmodule

module sio_target(input c, c2x, c2x_90, r, inout dp, dn, input [NBT-1:0] rdata, output [NBR-1:0] wdata, output wvalid);
   parameter NBR = 40;
   parameter NBT = 32;
   wire 	 sdo, tq;
   wire [1:0] 	 id0;
   reg [3:0] 	 state = 0;

   IOBUFDS_DIFF_OUT_INTERMDISABLE iobuf_i
     (.O(id0[0]), .OB(id0[1]), .IO(dp), .IOB(dn), .I(sdo), .INTERMDISABLE(1'b0), .IBUFDISABLE(1'b0), .TM(tq), .TS(tq));

   always @ (posedge c) begin
      if(wvalid)
	state <= 1'b1;
      else if(state != 0)
	state <= state + 1'b1;
   end
   sio_rx #(.NB(NBR)) rx(.c(c), .c2x(c2x), .c2x_90(c2x_90), .por(r), .r(state < 12), .i(id0), .d(wdata), .v(wvalid));
   // the 90 degree clock is used due to a routing constraint into the IO tile
   sio_tx #(.NB(NBT)) tx(.c(c), .c2x(c2x_90), .r(r), .t(state == 0), .d(rdata), .v(state == 4), .o(sdo), .tq(tq));
endmodule

module sio_rx (input c, c2x, c2x_90, // 200 MHz, 400 MHz, 400 MHz 90 deg
	       input [1:0] 	   i,
	       input 		   por, r, // reset
	       output reg [NB-1:0] d,
	       output reg 	   v = 0);

   parameter NB = 32;
   wire [7:0]	   d0;
   reg [7:0] 	   d2;
   wire [3:0] 	   d3;
   wire 	   v3;
   reg [3:0] 	   d4;
   reg 		   v4;
   wire 	   v4d;
   reg [NB-5:0]    d5;

   oversample_8x oversample (.c(c2x), .c90(c2x_90), .r(por), .i(i), .o(d0));
   dru dru(.c(c2x), .r(r), .i(d0 ^ 8'hAA), .d(d3), .v(v3));
   sio_delay_n #(.N((NB/4) - 1)) dlyv (.c(c), .i(v4), .o(v4d));
   always @ (posedge c) begin
      d4 <= d3;
      v4 <= v3;
      d5 <= {d5[NB-9:0],d4};
      if(v4d)
	d <= {d5,d4};
      v <= v4d;
   end
endmodule

module sio_tx(input c, c2x, r, t, v, input [NB-1:0] d, output o, tq);
   parameter NB = 40;
   reg [NB:0] sr;
   wire [3:0] od = {sr[NB-3], sr[NB-2], sr[NB-1], sr[NB]};
   oserdes_4x oserdes_tx(.c(c2x), .cdiv(c), .r(r), .t(t), .din(od), .o(o), .tq(tq));
   always @ (posedge c)
     sr <= v ? {1'b0, d} : {sr[NB-4:0], 4'hF};
endmodule
`endif //  `ifndef SIM

module sio_delay_n(input c, i, output o);
   parameter N=2;
   reg [N-1:0] sr;
   always @ (posedge c)
     sr <= {sr[N-2:0],i};
   assign o = sr[N-1];
endmodule

module dru
  (
   input 	    c, // 400 MHz (half bit rate)
   input 	    r, // reset, must assert prior to start of packet
   input [7:0] 	    i, // bit 7 is the oldest, 312.5 ps sample spacing
   output reg [3:0] d, // output data nibble
   output reg 	    v = 0 // asserted with first valid nibble
   );

   reg [8:0] 	    d0 = 9'h1FF;
   reg [7:0] 	    d1 = 8'hFF;
   reg [1:0] 	    s1 = 0;
   reg 		    idle = 1;
   reg 		    shift1 = 0;
   reg 		    shift2 = 0;
   reg [2:0] 	    d2 = 0;
   reg [1:0] 	    d3 = 0;
   reg [1:0] 	    sr = 0;
   reg [4:0] 	    state = 0;
   reg 		    t = 0;

   wire nzero = d1[0] && d0[7] && d0[5] && d0[3] && d0[2];

   always @ (posedge c) begin
      d0 <= {d0[0], i};
      d1 <= d0[8:1];
      if(~idle) begin
	 idle <= r;
      end
      else begin
	 casex({d1[0],d0[8:3]})
	   7'b0xxxxxx: s1 <= 2'd3;
	   7'b10xxxxx: s1 <= 2'd2;
	   7'b110xxxx: s1 <= 2'd1;
	   7'b1110xxx: s1 <= 2'd0;
	   7'b11110xx: s1 <= 2'd3;
	   7'b111110x: s1 <= 2'd2;
	   7'b1111110: s1 <= 2'd1;
	   7'b1111111: s1 <= 2'd0;
	 endcase
	 idle <= nzero;
	 shift1 <= d1[0] && d0[7] && d0[6];
      end

      state <= {state[3:0], (~nzero && idle)};

      case(s1)
	0: d2 <= {d2[0], d1[4], d1[0]};
	1: d2 <= {d2[0], d1[5], d1[1]};
	2: d2 <= {d2[0], d1[6], d1[2]};
	3: d2 <= {d2[0], d1[7], d1[3]};
      endcase

      shift2 <= shift1;

      d3 <= ~shift2 ? d2[2:1] : d2[1:0];

      sr <= d3;

      t <= state[2] ? 1'b1 : ~t;

      if(~t)
	d <= {sr, d3};
      if(~t)
	v <= state[3] | state[4];
   end

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end
endmodule
