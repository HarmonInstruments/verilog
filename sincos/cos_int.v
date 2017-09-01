/*
 * Copyright (C) 2015 - 2017 Harmon Instruments, LLC
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

module cosine_int
  (
   input 		   c,
   input [13:0] 	   a,
   input 		   s,
   input [34:0] 	   rom_d,
   output signed [NBO-1:0] o
   );

   parameter NBO = 23; // bits in dout

   reg [2:0] 		   sign = 0;
   reg [21:0] 		   coarse_2 = 0;
   wire [47:0] 		   dsp_o;
   reg [13:0] 		   a_del = 0;

   always @ (posedge c) begin
      a_del <= a;
      sign <= {sign[1:0], ~s};
      coarse_2 <= rom_d[34:13];
   end

   DSP48E1 #(.AREG(2), .BREG(1)) dsp48_i
     (.OVERFLOW(), .PATTERNDETECT(), .PATTERNBDETECT(), .UNDERFLOW(),
      .CARRYOUT(), .P(dsp_o),
      // control
      .ALUMODE({2'd0, sign[2], 1'b1}), .CARRYINSEL(3'd0),
      .CLK(c), .INMODE(5'b00100), .OPMODE(7'b0110101),
      // signal inputs
      .A({6'b0, a_del, 10'b0}), // 4 regs to outa
      .B({5'b0, rom_d[12:0]}), // 3 regs to out
      .C({2'b0, coarse_2, 24'hFFFFFF}), // 2 regs to out
      .CARRYIN(1'b0), .D(25'b0),
      // cascade ports
      .ACOUT(), .BCOUT(), .CARRYCASCOUT(), .MULTSIGNOUT(), .PCOUT(),
      .ACIN(30'h0), .BCIN(18'h0), .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0), .PCIN(48'h0),
      // clock enables
      .CEA1(1'b1), .CEA2(1'b1), .CEAD(1'b0), .CEALUMODE(1'b1), .CEB1(1'b1), .CEB2(1'b1),
      .CEC(1'b1), .CECARRYIN(1'b1), .CECTRL(1'b1), .CED(1'b0), .CEINMODE(1'b1), .CEM(1'b1), .CEP(1'b1),
      .RSTA(1'b0), .RSTALLCARRYIN(1'b0), .RSTALUMODE(1'b0), .RSTB(1'b0), .RSTC(1'b0), .RSTCTRL(1'b0), .RSTD(1'b0),
      .RSTINMODE(1'b0), .RSTM(1'b0), .RSTP(1'b0)
      );

   assign o = dsp_o[46:47-NBO];

endmodule
