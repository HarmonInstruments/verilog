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

module sio_test
  (
   input            clock_host, clock_host_2x, clock_target, clock_target_2x,
   input 	    r,
   output [NBR-1:0] rdata,
   input [NBT-1:0]  wdata,
   input 	    wvalid);

   parameter NBT = 16;
   parameter NBR = 16;

   wire 		sdio;

   wire [NBT-1:0] 	t_wdata;
   wire 		t_wvalid;
   reg [NBR-1:0] 	t_rdata = 0;

   sio_target #(.NBT(NBR), .NBR(NBT)) sio_target
     (.c(clock_target),
      .c2x(clock_target_2x),
      .sdio(sdio),
      .rdata(t_rdata),
      .wdata(t_wdata),
      .wvalid(t_wvalid)
      );
   sio_host_iddr #(.NBT(NBT), .NBR(NBR)) sio_host
     (.c(clock_host),
      .c2x(clock_host_2x),
      .sdio(sdio),
      .rdata(rdata),
      .wdata(wdata),
      .wvalid(wvalid));

   always @ (posedge clock_target)
     begin
	if(t_wvalid)
	  t_rdata <= t_wdata[NBR-1:0];
     end

   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end

   glbl glbl();


endmodule

module glbl();
   reg GSR = 1'b1;
   wire GTS = 1'b0;
   initial
     GSR <= #0.01 1'b0;
endmodule
