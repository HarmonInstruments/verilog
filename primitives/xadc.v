/*
 * Xilinx ADC interface
 * Copyright (C) 2014-2016 Harmon Instruments, LLC
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
 * din[15:0] DRP data
 * din[22:16] DRP address
 * din[23] DRP write enable
 *
 * dout[15:0] DRP data
 * dout[16] busy
 *
 */

module xadc
  (
   input 	     clock,
   input 	     write,
   input [23:0]      din,
   input [15:0]      vauxp, vauxn,
   output reg [16:0] dout = 0
   );

   reg 		     busy = 0;
   wire [15:0] 	     drp_do;
   wire 	     drp_drdy;

   always @ (posedge clock)
     begin
	dout[16] <= busy;
	if(write)
	  busy <= 1'b1;
	else if(drp_drdy)
	  busy <= 1'b0;
	if(drp_drdy)
	  dout[15:0] <= drp_do;
     end

   XADC #(.INIT_42(16'h0400)) xadc_i
     (
      .ALM(),
      .OT(),
      .BUSY(),
      .CHANNEL(),
      .EOC(),
      .EOS(),
      .JTAGBUSY(),
      .JTAGLOCKED(),
      .JTAGMODIFIED(),
      .MUXADDR(),
      .VAUXN(vauxn),
      .VAUXP(vauxp),
      .VN(),
      .VP(), // analog
      .CONVST(1'b0),
      .CONVSTCLK(1'b0),
      .RESET(1'b0),
      // DRP outputs
      .DO(drp_do),
      .DRDY(drp_drdy),
      // DRP inputs
      .DADDR(din[22:16]),
      .DCLK(clock),
      .DEN(write),
      .DI(din[15:0]),
      .DWE(din[23])
      );

endmodule
