/*
 * Copyright (C) 2015 Harmon Instruments, LLC
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
 */

`timescale 1ns / 1ps

module bram_72x512
  (
   input 	 c, // clock
   input [8:0] 	 wa,ra,
   input [71:0]  wd,
   input 	 w,
   input 	 r,
   output [71:0] rd);

   RAMB36E1 #(
	      .DOA_REG(1),.DOB_REG(1),
	      .RAM_MODE("SDP"),
	      .READ_WIDTH_A(72), .READ_WIDTH_B(0),
	      .WRITE_WIDTH_A(0), .WRITE_WIDTH_B(72),
	      .SIM_DEVICE("7SERIES"))
   RAMB36E1_inst
     (
      .CASCADEOUTA(), .CASCADEOUTB(),
      .DBITERR(), .ECCPARITY(), .RDADDRECC(), .SBITERR(),
      .DOADO(rd[31:0]),
      .DOPADOP(rd[67:64]),
      .DOBDO(rd[63:32]),
      .DOPBDOP(rd[71:68]),
      .CASCADEINA(1'b0), .CASCADEINB(1'b0),
      .INJECTDBITERR(1'b0), .INJECTSBITERR(1'b0),
      .ADDRARDADDR({1'b0, ra,6'd0}),
      .CLKARDCLK(c),
      .ENARDEN(r),
      .REGCEAREGCE(1'b1),
      .RSTRAMARSTRAM(1'b0),
      .RSTREGARSTREG(1'b0),
      .WEA(4'b0),
      .DIADI(wd[31:0]),
      .DIPADIP(wd[67:64]),
      .ADDRBWRADDR({1'b0,wa,6'd0}),
      .CLKBWRCLK(c),
      .ENBWREN(w),
      .REGCEB(1'b1),
      .RSTRAMB(1'b0),
      .RSTREGB(1'b0),
      .WEBWE(8'hFF),
      .DIBDI(wd[63:32]),
      .DIPBDIP(wd[71:68]));
endmodule
