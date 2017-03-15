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

module rx_test
  (input            clock,
   input [19:0]     wdata,
   input 	    wvalid);

   wire 	    sdio;
   wire 	    clock_target;

   wire [1:0] 	    amosi;
   wire [1:0] 	    sync;
   wire [7:0] 	    add;

   rx_target rx_target
     (.clock(clock_target),
      .add(add),
      .sync(sync),
      .amosi(amosi),
      .amiso(amosi),
      .sdio(sdio),
      .drdy(drdy)
      );

   rx_host rx_host
     (.clock(clock),
      .clock_target(clock_target),
      .sdio(sdio));

   ad7768_sim a0(.clock(clock_target), .sync(sync[0]), .d(add[0]), .channel(3'd0), .drdy(drdy));
   ad7768_sim a1(.clock(clock_target), .sync(sync[0]), .d(add[1]), .channel(3'd1));
   ad7768_sim a2(.clock(clock_target), .sync(sync[0]), .d(add[2]), .channel(3'd2));
   ad7768_sim a3(.clock(clock_target), .sync(sync[0]), .d(add[3]), .channel(3'd3));
   ad7768_sim a4(.clock(clock_target), .sync(sync[0]), .d(add[4]), .channel(3'd4));
   ad7768_sim a5(.clock(clock_target), .sync(sync[0]), .d(add[5]), .channel(3'd5));
   ad7768_sim a6(.clock(clock_target), .sync(sync[0]), .d(add[6]), .channel(3'd6));
   ad7768_sim a7(.clock(clock_target), .sync(sync[0]), .d(add[7]), .channel(3'd7));

   pullup(sdio);

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

module ad7768_sim(input clock, sync, output reg d, input [2:0] channel, output reg drdy = 0);
   reg [6:0] state = 0;
   reg [15:0] count = 0;
   wire [4:0] bitn = state[6:2];
   wire [31:0] odata = {5'h10, channel, 5'h10, channel, count};

   always @ (posedge clock)
     begin
	state <= ~sync ? 7'd15 : state - 1'b1;
	if(state == 0)
	  count <= count + 1'b1;

	if(state[1:0] == 1)
	  begin
	     drdy <= bitn == 0;
	     d <= odata[bitn];
	  end
     end
endmodule