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
 *
 * Data recovery unit
 * takes in raw bit stream sampled at 3.2 GHz
 * outputs bytes
 *
 */

`timescale 1ns / 1ps

module dru
  (
   input 	    c, // 400 MHz
   input [7:0] 	    i, // bit 7 is the oldest, 312.5 ps sample spacing
   output reg [3:0] d, // data nibble
   output reg 	    v = 0 // last
   );

   reg [9:0] 	    d0 = 10'h3FF;

   reg [7:0] 	    d1 = 8'hFF;
   reg [1:0] 	    s1 = 0;
   reg 		    idle = 1;
   reg 		    shift = 0;

   reg [2:0] 	    d2 = 0;

   reg [1:0] 	    d3 = 0;

   reg [3:0] 	    sr = ~4'b0;

   reg [28:0] 	    state = 0;
   reg 		    t = 0;

   always @ (posedge c) begin
      d0 <= {d0[1:0], i};

      d1 <= d0[7:0];
      if(~idle) begin
	 idle <= state[25];
      end
      else begin
	 casex(d0[9:3])
	   7'b0xxxxxx: s1 <= 2'd3;
	   7'b10xxxxx: s1 <= 2'd2;
	   7'b110xxxx: s1 <= 2'd1;
	   7'b1110xxx: s1 <= 2'd0;
	   7'b11110xx: s1 <= 2'd3;
	   7'b111110x: s1 <= 2'd2;
	   7'b1111110: s1 <= 2'd1;
	   7'b1111111: s1 <= 2'd0;
	 endcase
	 idle <= (d0[9:2] == 8'hFF);
	 shift <= (d0[9:6] == 4'hF);
      end

      state <= {state[27:0], ((d0[9:2] != 8'hFF) && idle)};

      case(s1)
	0: d2 <= {d2[0], d1[4], d1[0]};
	1: d2 <= {d2[0], d1[5], d1[1]};
	2: d2 <= {d2[0], d1[6], d1[2]};
	3: d2 <= {d2[0], d1[7], d1[3]};
      endcase

      d3 <= ~shift ? d2[2:1] : d2[1:0];

      sr <= {sr[1:0], d3};

      t <= state[1] ? 1'b1 : ~t;

      if(t)
	d <= sr;
      if(t)
	v <= state[27] | state[28];
   end

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
