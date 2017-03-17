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

module sio_host_iddr
  (
   input 	    c, c2x,
   inout 	    sdio,
   input 	    wvalid,
   input [NBT-1:0]  wdata,
   output [NBR-1:0] rdata
   );

   parameter NBR = 32;
   parameter NBT = 40;

   // TX
   reg 		    tq = 0;
   reg 		    sdo = 1;
   reg [NBT:0] 	    tsr = ~0;
   reg [6:0] 	    state = 0;
   wire 	    wv_400;

   always @ (posedge c)
     begin
	tsr <= wvalid ? {1'b0, wdata} : {tsr[NBT-1:0], 1'b1};
	tq <= (state > (NBT+6));
	if(state == 0)
	  state <= wvalid && wdata[NBT-1];
	else
	  state <= rvalid ? 1'b0 : state + 1'b1;
	sdo <= tsr[NBT];
     end

   // RX
   wire  	 id0;
   wire [3:0] 	 id1;
   wire [3:0] 	 id2;
   wire 	 iv2;
   IOBUF iobuf_i (.O(id0), .IO(sdio), .I(sdo), .T(tq));

   wire 	 rvalid;

   rx_iddr #(.N(NBR)) rx(.c(c), .c2x(c2x), .r(state < NBT+9), .i(id0), .d(rdata), .v(rvalid));

endmodule
