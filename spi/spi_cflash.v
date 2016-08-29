/*
 * PCI Express to FIFO - Configuration flash SPI
 * Copyright (C) 2014 Harmon Instruments, LLC
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
 */

`timescale 1ns / 1ps

module spi_cflash
  (
   input 	    c,
   input 	    w,
   input [8:0] 	    din,
   output reg [7:0] dout = 16'h0,
   output reg 	    cs = 1'b1,
   output reg 	    mosi,
   input 	    miso
   );

   reg 		    sck = 1'b0;
   reg [6:0] 	    state = 7'h0;
   reg 		    cs_hold = 0;
   reg 		    misoq;

   always @ (posedge c)
     begin
	misoq <= miso;
	mosi <= dout[7];
	if(w)
	  begin
	     cs_hold <= din[8];
	     dout <= din[7:0];
	     state <= 1'd1;
	  end
	else if(state != 0)
	  begin
	     if(state[3:0] == 15)
	       dout <= {dout[6:0], misoq};
	     state <= state + 1'b1;
	  end
	sck <= state[3];
	cs <= (state == 0) && ~cs_hold;
     end

   (*keep="TRUE"*) STARTUPE2 STARTUPE2
     (
      // outputs
      .CFGCLK(), .CFGMCLK(), .EOS(), .PREQ(),
      // inputs
      .CLK(1'b0), .GSR(1'b0), .GTS(1'b0), .KEYCLEARB(1'b0), .PACK(1'b0),
      .USRCCLKO(sck),
      .USRCCLKTS(1'b0), .USRDONEO(1'b0), .USRDONETS(1'b0)
      );

endmodule
