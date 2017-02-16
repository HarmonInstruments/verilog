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

module sio_target
  (
   input            c, c2x,
   inout 	    sdio,
   input [NBT-1:0]  rdata,
   output [NBR-1:0] wdata,
   output           wvalid);

   parameter NBR = 40;
   parameter NBT = 32;
   reg [NBT:0] 	    tsr = ~0;

   reg 		    sdo = 1;
   wire 	    id0;
   reg [5:0] 	    state = 0;
   reg 		    tq=1;

   IOBUF iobuf_i (.O(id0), .IO(sdio), .I(sdo), .T(tq));

   rx_iddr #(.N(NBR)) rx(.c(c), .c2x(c2x), .r(state != 0 | wvalid), .i(id0), .d(wdata), .v(wvalid));

   always @ (posedge c)
     begin
	sdo <= tsr[NBT];
	tsr <= (state == 4) ? {1'b0, rdata} : {tsr[NBT-1:0], 1'b1};
	if(wvalid && wdata[NBR-1])
	  begin
	     tq <= 1'b0;
	     state <= 1'b1;
	  end
	else if(state != 0)
	  begin
	     state <= (state == NBT+15) ? 1'b0 : state + 1'b1;
	     if(state == NBT+6)
	       tq <= 1'b1;
	  end
     end

endmodule
