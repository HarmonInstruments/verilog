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

// 4x oversampled 2 bits per clock
module dru_2_4x
  (
   input 	        c, // 400 MHz (half bit rate)
   input 	        r, // reset, must assert prior to start of packet
   input [7:0] 	        i, // bit 7 is the oldest, 312.5 ps sample spacing
   output reg [NBO-1:0] d, // output data
   output reg 	        v = 0 // asserted with first valid bit pair
   );

   parameter NBO = 16;

   reg [13:0] 	    d0 = 14'h3FFF;
   reg [2:0] 	    s1 = 0;
   reg 		    idle = 1;
   reg [1:0] 	    d2 = 0;
   reg [NBO/2+1:0]  vpipe = 0;
   reg [NBO-1:0]    dr = 0;

   wire 	    nzero = d0[10:3] == 8'hFF;

   always @ (posedge c) begin
      d0 <= {d0[5:0], i};
      if(~idle) begin
	 idle <= r;
      end
      else begin
	 casex({d0[10:4]})
	   7'b0xxxxxx: s1 <= 3'd7;
	   7'b10xxxxx: s1 <= 3'd6;
	   7'b110xxxx: s1 <= 3'd5;
	   7'b1110xxx: s1 <= 3'd4;
	   7'b11110xx: s1 <= 3'd3;
	   7'b111110x: s1 <= 3'd2;
	   7'b1111110: s1 <= 3'd1;
	   7'b1111111: s1 <= 3'd0;
	 endcase
	 idle <= nzero;
      end

      case(s1)
	0: d2 <= {d0[6], d0[2]};
	1: d2 <= {d0[7], d0[3]};
	2: d2 <= {d0[8], d0[4]};
	3: d2 <= {d0[9], d0[5]};
	4: d2 <= {d0[10], d0[6]};
	5: d2 <= {d0[11], d0[7]};
	6: d2 <= {d0[12], d0[8]};
	7: d2 <= {d0[13], d0[9]};
      endcase

      dr <= {dr[NBO-3:0], d2};
      vpipe <= {vpipe[NBO/2:0], (~nzero && idle)};

      if(vpipe[NBO/2+1])
	d <= dr;

      v <= vpipe[NBO/2+1];
   end

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end
endmodule
