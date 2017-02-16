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

module rx_iddr(input c, c2x, i, r, output reg [N-1:0] d=0, output reg v=0);
   parameter N = 40;

   wire [1:0] d0;

   IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
	  .INIT_Q1(1'b1), .INIT_Q2(1'b1),
	  .SRTYPE("SYNC")
   ) IDDR_i (
      .Q1(d0[1]),
      .Q2(d0[0]),
      .C(c2x),
      .CE(1'b1),
      .D(i),
      .R(1'b0),
      .S(1'b0)
   );

   reg [1:0]  state = 0;
   reg 	      r2x = 1'b1;
   reg 	      d1 = 1'b1;
   reg 	      offset = 0;
   reg 	      t = 0;
   reg 	      first = 0;

   always @ (posedge c2x)
     begin
	r2x <= r;
	if(r2x)
	  state <= 2'd0;
	else if((state == 0) && (d0 != 2'b11))
	  state <= 2'd1;
	else if((state == 1) && first)
	  state <= 2'd2;
	else
	  state <= state;

	if(t)
	  first <= t & (state == 1);

	if(state == 0)
	  offset <= d0[1];
	t <= (state == 0) ? 1'b0 : ~t;
	if(t)
	  d1 <= d0[~offset];
     end

   reg [N-1:0] 	 vpipe = 0;
   reg [N-1:0] 	 dr = 0;

   always @ (posedge c)
     begin
        dr <= {dr[N-1:0], d1};
	vpipe <= {vpipe[N-2:0], first};
	if(vpipe[N-1])
          d <= dr;
	v <= vpipe[N-1];
     end

endmodule
