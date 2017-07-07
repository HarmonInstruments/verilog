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

module rio_target(input clock, // clock provided by host
		  inout sdio, // IO pin to host
		  // local bus
		  output reg wvalid = 0,
		  output reg rvalid = 0,
		  output reg [3:0] addr,
		  output reg [31:0] wdata,
		  input [7:0] rdata,
		  input odata // data muxed to output pin
		  );

   reg [5:0]        rsr;
   reg [7:0] 	    tsr;
   wire [1:0] 	    di;
   reg [4:0] 	    state = 0;
   reg 		    oe = 0;
   reg 		    is_read;

   always @ (posedge clock)
     begin
	rsr <= {rsr[5:0], di};
	tsr <= (state == 7) ? rdata : {tsr[6:0], 1'b1};
	oe <= is_read && (state > 7);

	if(state == 0) // wait for the start bit
	  state <= di[1] ? 1'b0 : 1'b1;
	else if(state[4] && state[1])
	  state <= 1'b0;
	else
	  state <= state + 1'b1;

	if(state[1:0] == 2)
	  begin
	     case(state[4:2])
	       0: {is_read,addr} <= {rsr[2:0],di};
	       1: wdata[7:0] <= {rsr,di};
	       2: wdata[15:8] <= {rsr,di};
	       3: wdata[23:16] <= {rsr,di};
	       4: wdata[31:24] <= {rsr,di};
	     endcase
	  end
	wvalid <= (state == 18) && !is_read;
	rvalid <= (state == 4) && is_read;
     end

   SB_IO #(.PIN_TYPE(6'b100100), .PULLUP(1'b1)) iopin // DDR input, SDR output
     (.PACKAGE_PIN(sdio),
      .CLOCK_ENABLE(1'b1),
      .INPUT_CLK(clock),
      .OUTPUT_CLK(clock),
      .OUTPUT_ENABLE(oe),
      .D_OUT_0(tsr[7]), // data out to pin
      .D_IN_0(di[1]), // data in from pin
      .D_IN_1(di[0]));

endmodule
