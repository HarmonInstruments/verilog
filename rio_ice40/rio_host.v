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

module rio_host
  (
   input            clock, // 125 MHz
   inout 	    sdio, // DDR out, SDR in
   output reg       clock_target = 0, // 31.25 MHz
   input 	    wvalid,
   input [38:0]     wdata,
   output reg [7:0] rdata = 0
   );

   reg [39:0] 	    d;
   reg 		    dv = 0;

   reg [2:0] 	    count = 0;
   reg 		    tq = 0;
   reg 		    sdo = 1;
   reg [31:0] 	    csr;
   reg [37:0] 	    tsr = ~38'h0; // start, r/w, addr(4), data(32)
   reg [5:0] 	    state = 0;
   reg [7:0] 	    rsr = 0;
   wire 	    id0; // input data from iobuf_sdio
   reg 		    id1;
   wire 	    is_read = d[36];
   wire 	    is_config = d[37];
   wire 	    cont_clock = d[38];
   reg 		    cont_clock_s = 0;

   always @ (posedge clock)
     begin
	count <= count + 1'b1;

	if(wvalid) begin
	   d <= wdata;
	   dv <= 1'b1;
	end
	else if(state[0]) begin
	   dv <= 1'b0;
	end

	if(dv && (count == 0))
	  cont_clock_s <= cont_clock;

	if(dv && (count == 0))
	  state <= is_config ? 1'b1 : 1'b1;
	else if(!is_config && (state == 11) && (count == 5))
	  state <= 1'b0;
	else
	  state <= state + ((count == 0) && (state != 0));

	if(dv && (count == 0))
	  tsr <= {1'b0,d[36:32], d[7:0], d[15:8], d[23:16], d[31:24]};
	else if(is_config ? (count[2:0] == 0) : (count[0] == 0))
	  tsr <= {tsr[36:0], 1'b1};

	if((state == 9) && (count == 7))
	  rdata <= rsr;

	id1 <= id0;
	if(count[1:0] == 2)
	  rsr <= {rsr[6:0], id1};

	tq <= is_read && (state > 3);
	sdo <= is_config ? tsr[31] : tsr[37];
	clock_target <= is_config ?
			(count[2] && (state != 0) && (state < 33)) :
			(count[1] && ((state != 0) || cont_clock_s));
     end

   IOBUF iobuf_sdio (.O(id0), .IO(sdio), .I(sdo), .T(tq));

endmodule
