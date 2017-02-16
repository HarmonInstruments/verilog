/*
 * Copyright (C) 2014-2017 Harmon Instruments, LLC
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

// 4x oversampled 1 bit per clock
module dru_1_4x
  (
   input 	        c, // 400 MHz (half bit rate)
   input 	        r, // reset, must assert prior to start of packet
   input [3:0] 	        i, // bit 3 is the oldest, 625 ps sample spacing
   output reg [NBO-1:0] d, // output data
   output reg 	        v = 0 // asserted with first valid bit pair
   );

   parameter NBO = 16;

   reg [6:0] 	    d0 = 7'h7F;
   reg [1:0] 	    s1 = 0;
   reg 		    idle = 1;
   reg 		    d2 = 0;
   reg [NBO+2:0]    vpipe = 0;
   reg [NBO-1:0]    dr = 0;

   wire nzero = d0[3:0] == 4'hF;

   always @ (posedge c) begin
      d0 <= {d0[2:0], i};
      if(~idle)
	begin
	   idle <= r;
	end
      else
	begin
	   casex(d0[3:1])
	     3'b0xx: s1 <= 2'd3;
	     3'b10x: s1 <= 2'd2;
	     3'b110: s1 <= 2'd1;
	     3'b111: s1 <= 2'd0;
	   endcase
	   idle <= nzero;
	end

      case(s1)
	0: d2 <= d0[3];
	1: d2 <= d0[4];
	2: d2 <= d0[5];
	3: d2 <= d0[6];
      endcase

      dr <= {dr[NBO-2:0], d2};
      vpipe <= {vpipe[NBO+1:0], (~nzero && idle)};

      if(vpipe[NBO+2])
	d <= dr;

      v <= vpipe[NBO+2];
   end

`ifdef SIM_DRU
   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end
`endif
endmodule
