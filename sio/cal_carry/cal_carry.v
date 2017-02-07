/*
 * Copyright (C) 2017 Harmon Instruments, LLC
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

module cal_carry(input c, i, r, output reg [5:0] d, output reg [98:0] eye = 0);

   parameter real CDEL=0.119;

   // delay line and first DFF
   wire [399:0] co;
   (* ASYNC_REG="TRUE" *) reg [99:0] rising0;
   (* ASYNC_REG="TRUE" *) reg [99:0] rising1;

   genvar j;
   generate
      for(j=0; j<100; j=j+1)
	begin : carry
	   wire ci = j==0 ? 1'b0 : co[4*j-1];
	   reg 	cidel;
	   always @ (ci)
	     cidel <= #CDEL ci;
	   CARRY4 C4i (.CO(co[4*j+3:4*j]), // carry out
		       .O(),
		       .CI(cidel),
		       .CYINIT(1'b0),
		       .DI(j==0 ? {3'b000, i} : 4'h0),
		       .S(j==0 ? 4'hE : 4'hF));
	end
      for(j=0; j<100; j=j+1)
	begin : outflop
	   always @ (posedge c)
	     rising0[99 - j] <= co[4*j+0];
	end
   endgenerate

   reg [6:0] state = 0;
   reg [1:0] edges = 0;
   reg [2:0] taps_past_edge = 7;
   reg [5:0] edge1 = 0;

   reg [99:0] sr;

   always @ (posedge c)
     begin
	rising1 <= rising0;
	state <= state + 1'b1;
	sr <= (state == 0) ? rising1 : {sr[99], sr[99:1]};
	if(state == 0)
	  begin
	     edges <= 1'b0;
	     taps_past_edge <= 3'd7;
	  end
	else
	  begin
	     if((sr[0] ^ sr[1]) && (taps_past_edge == 7))
	       begin
		  taps_past_edge <= 1'b0;
		  edges <= (edges == 3) ? 2'd3 : edges + 1'b1;
		  if(edges == 0)
		    edge1 <= state[5:0];
		  if(edges == 2)
		    d <= state[5:0] - edge1;
	       end
	     else
	       begin
		  taps_past_edge <= (taps_past_edge == 7) ? 3'd7 : taps_past_edge + 1'b1;
	       end
	  end
	eye <= r ? 1'b0 : eye | (rising1[99:1] ^ rising1[98:0]);
     end

`ifdef SIM_CAL
   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end
`endif

endmodule
