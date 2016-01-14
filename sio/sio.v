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
module sio_host(
		input 		     c, c2x, c2x_90,
		input 		     r, // power on reset
		inout 		     dp, dn,
		input 		     wvalid,
		input [NBT-1:0]      wdata,
		output reg [NBR-1:0] rdata);
   parameter NBR = 32;
   parameter NBT = 40;
   parameter STATE_END = ((NBR+NBT)/4) + 7;
   reg [4:0] 	 state = 0;
   wire [3:0] 	 id3;
   wire		 iv3;
   reg [NBR-5:0] id4;
   wire 	 iv4;
   reg [NBT:0] 	 sr;

   sio_io_common sioc(.c(c), .c2x(c2x), .c2x_90(c2x_90),
		      .r(r),
		      .drureset(state == ((NBT/4)+6)), // seems to be on the edge
		      .dp(dp), .dn(dn),
		      .rd(id3),
		      .rv(iv3),
		      .t(state > ((NBT/4)+1)),
		      .td(sr[NBT:NBT-3]));
   sio_delay_n #(.N((NBR/4) - 1)) dlyv (.c(c), .i(iv3), .o(iv4));
   always @ (posedge c) begin
      id4 <= {id4[NBR-9:0],id3};
      if(iv4)
	rdata <= {id4,id3};
      if(wvalid)
	state <= 1'b1;
      else if(state == STATE_END)
	state <= 1'b0;
      else if(state != 0)
	state <= state + 1'b1;
      sr <= wvalid ? {1'b0, wdata} : {sr[NBT-4:0], 4'hF};
   end
endmodule

module sio_target(
		  input 	       c, c2x, c2x_90,
		  input 	       r, // power on reset
		  inout 	       dp, dn,
		  input [NBT-1:0]      rdata,
		  output reg [NBR-1:0] wdata,
		  output reg 	       wvalid);
   parameter NBR = 40;
   parameter NBT = 32;
   parameter STATE_WV = (NBR/4) - 1;
   parameter STATE_TS = (NBR/4) - 6;
   parameter STATE_END = ((NBR+NBT)/4) + 3;
   reg [4:0]     state = 0;
   wire [3:0] 	 id3;
   wire 	 iv3;
   reg [NBR-5:0] id4;
   reg [NBT:0] 	 sr;

   sio_io_common sioc (.c(c), .c2x(c2x), .c2x_90(c2x_90),
		       .r(r),
		       .drureset(r || state == STATE_END),
		       .dp(dp), .dn(dn),
		       .rd(id3),
		       .rv(iv3),
		       .t(state < STATE_TS),
		       .td(sr[NBT:NBT-3]));

   always @ (posedge c) begin
      id4 <= {id4[NBR-9:0],id3};
      if(state == STATE_WV)
	wdata <= {id4,id3};
      wvalid <= (state == STATE_WV);
      state <= (state == STATE_END) ? 1'b0 : state + (iv3 || (state != 0));
      sr <= (state==((NBR/4)-6)) ? {1'b0, rdata} : {sr[NBT-4:0], 4'hF};
   end
endmodule

// The IOB, serdes and DRU
module sio_io_common(
		     input 	      c, c2x, c2x_90, r,
		     input 	      drureset, // reset the DRU
		     inout 	      dp, dn, // IOB
		     output reg [3:0] rd, // RX data, ~ 5 clocks from in
		     output reg       rv, // RX valid - asserted on first valid nibble
		     input 	      t, // tristate, 2 clocks to out
		     input [3:0]      td // TX data
		     );
   wire 	 sdo;
   wire [1:0] 	 id0;
   wire [7:0] 	 id1;
   wire [3:0] 	 id2;
   wire 	 iv2;
   reg 		 druresetr;
   // the 90 degree clock is used due to a routing constraint into the IO tile
   oserdes_4x os(.c(c2x_90), .cdiv(c), .r(r), .t(t), .din({td[0], td[1], td[2], td[3]}), .o(sdo), .tq(tq));
   IOBUFDS_DIFF_OUT iobuf_i (.O(id0[0]), .OB(id0[1]), .IO(dp), .IOB(dn), .I(sdo), .TM(tq), .TS(tq));
   oversample_8x oversample (.c(c2x), .c90(c2x_90), .r(r), .i(id0), .o(id1));
   dru dru(.c(c2x), .r(druresetr), .i(id1 ^ 8'hAA), .d(id2), .v(iv2));
   always @ (posedge c) begin
      rd <= id2;
      rv <= iv2;
      druresetr <= drureset;
   end
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
