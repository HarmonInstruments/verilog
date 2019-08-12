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
   input         clock, clock_2x,
   input         r,
   output [31:0] rdata,
   input [79:0]  wdata,
   input         wvalid);

   wire          hdd, dhd;

   wire [79:0]   t_wdata;
   wire          t_wvalid;
   reg [31:0]    t_rdata = 0;
   reg [15:0]    stream_target = 16'hDE00;
   reg [15:0]    stream_host = 16'hBE00;

   sio_target sio_target
     (.c(clock),
      .c2x(clock_2x),
      .sdo(dhd),
      .sdi(hdd),
      .rdata(t_rdata),
      .wdata(t_wdata),
      .wvalid(t_wvalid),
      .stream_in(stream_target),
      .stream_out()
      );
   sio_host sio_host
     (.c(clock),
      .c2x(clock_2x),
      .sync(1'b0),
      .sdi(dhd),
      .sdo(hdd),
      .stream_in(),
      .stream_out(stream_host),
      .rdata(rdata),
      .wdata(wdata),
      .wvalid(wvalid));

   always @ (posedge clock)
     begin
        if(t_wvalid)
          t_rdata <= t_wdata[31:0];
        if(sio_host.state == 0)
          stream_host <= stream_host + 1'b1;
        if(sio_target.state == 1)
          stream_target <= stream_target + 1'b1;

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
