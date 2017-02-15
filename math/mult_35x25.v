/*
 * Copyright (C) 2015-2017 Harmon Instruments, LLC
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

// wide multiply using 2x DSP48E1
// p = ((a * b) + c) >> 17, 4 clock pipe delay
module mult_35x25
  (
   input 	        clock,
   input signed [24:0]  a,
   input signed [34:0]  b,
   input signed [47:0]  c,
   output signed [47:0] p);

   wire signed [29:0] low_acout;
   wire signed [47:0] low_pcout;

   DSP48E1 #(.A_INPUT("CASCADE"), .AREG(1), .BREG(2)) dsp48_high
     (
      // status
      .OVERFLOW(), .PATTERNDETECT(), .PATTERNBDETECT(), .UNDERFLOW(),
      // outs
      .P(p), .CARRYOUT(),
      // control
      .ALUMODE(4'b0), .CARRYINSEL(3'd0),
      .CLK(clock),
      .INMODE(5'b00000),
      .OPMODE(7'b1010101), // a*b + pcin >> 17
      // signal inputs
      .A(30'b0), .B(b[34:17]), .C(48'b0), .CARRYIN(1'b0), .D(25'b0),
      // cascade ports
      .ACOUT(), .BCOUT(), .CARRYCASCOUT(), .MULTSIGNOUT(), .PCOUT(),
      .ACIN(low_acout), .BCIN(18'h0), .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0),
      .PCIN(low_pcout),
      // clock enables, resets
      .CEA1(1'b1), .CEA2(1'b1), .CEAD(1'b1), .CEALUMODE(1'b1),
      .CEB1(1'b1), .CEB2(1'b1), .CEC(1'b1), .CECARRYIN(1'b1),
      .CECTRL(1'b1), .CED(1'b1), .CEINMODE(1'b1), .CEM(1'b1), .CEP(1'b1),
      .RSTA(1'b0), .RSTALLCARRYIN(1'b0), .RSTALUMODE(1'b0),
      .RSTB(1'b0), .RSTC(1'b0), .RSTCTRL(1'b0), .RSTD(1'b0),
      .RSTINMODE(1'b0), .RSTM(1'b0), .RSTP(1'b0)
      );

   DSP48E1 #(.ACASCREG(1), .AREG(1), .BREG(1)) dsp48_low
     (
      // status
      .OVERFLOW(), .PATTERNDETECT(), .PATTERNBDETECT(), .UNDERFLOW(),
      // outs
      .P(), .CARRYOUT(),
      // control
      .ALUMODE(4'b0), .CARRYINSEL(3'd0),
      .CLK(clock),
      .INMODE(5'b00000), .OPMODE(7'b0110101),
      // signal inputs
      .A({{5{a[24]}},a}), .B({1'b0,b[16:0]}),
      .C(c),
      .CARRYIN(1'b0),
      .D(25'b0),
      // cascade ports
      .ACOUT(low_acout), .BCOUT(), .CARRYCASCOUT(), .MULTSIGNOUT(), .PCOUT(low_pcout),
      .ACIN(30'h0), .BCIN(18'h0), .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0), .PCIN(48'h0),
      // clock enables, resets
      .CEA1(1'b1), .CEA2(1'b1), .CEAD(1'b1), .CEALUMODE(1'b1),
      .CEB1(1'b1), .CEB2(1'b1), .CEC(1'b1), .CECARRYIN(1'b1),
      .CECTRL(1'b1), .CED(1'b1), .CEINMODE(1'b1), .CEM(1'b1), .CEP(1'b1),
      .RSTA(1'b0), .RSTALLCARRYIN(1'b0), .RSTALUMODE(1'b0),
      .RSTB(1'b0), .RSTC(1'b0), .RSTCTRL(1'b0), .RSTD(1'b0),
      .RSTINMODE(1'b0), .RSTM(1'b0), .RSTP(1'b0)
      );

   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end


endmodule
