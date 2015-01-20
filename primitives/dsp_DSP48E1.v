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

// m = b * (a + d)
// p = c+m or p+m
module dsp48_wrap
  (
   input 		   clock,
   input 		   ce1,
   input 		   ce2,
   input 		   cem,
   input 		   cep,
   input signed [NBA-1:0]  a,
   input signed [NBB-1:0]  b,
   input signed [NBC-1:0]  c,
   input signed [NBA-1:0]  d, // this has two fewer pipe stages
   // bit 1:0: 0: Z+X+Y 3:Z-(X+Y) 1: -Z + (X+Y) 2: -1*(Z+X+Y+1)
   // bits 3:2, 0: P=M+0, 1: P=M+PCIN, 2: P=M+P, 3: P = M+C
   // bit 4: sub in pre add
   input [4:0] 		   mode,
   input signed [29:0] 	   acin,
   input signed [17:0] 	   bcin,
   input signed [47:0] 	   pcin,
   output signed [29:0]    acout,
   output signed [17:0]    bcout,
   output signed [47:0]    pcout,
   output signed [NBP-1:0] p);

   parameter NBA = 24; // D is same - really 25, but causes a warning
   parameter NBB = 18;
   parameter NBP = 48;
   parameter NBC = NBP;
   parameter S = 0;

   parameter USE_DPORT = "FALSE"; // enabling add 1 reg to A path
   parameter AREG = 1;
   parameter BREG = 1; // 0 - 2

   localparam SA = 24 - NBA; // D is smae
   localparam SB = 18 - NBB;
   localparam SC = SB + SA;


   wire signed [47:0] 	   dsp_p;
   assign p = dsp_p[NBP+SC+S-1:SC+S];

   DSP48E1
     #(
       .A_INPUT("DIRECT"),   // "DIRECT" "CASCADE"
       .B_INPUT("DIRECT"),   // "DIRECT" "CASCADE"
       .USE_DPORT(USE_DPORT),
       .USE_MULT("MULTIPLY"),// "MULTIPLY" "DYNAMIC" "NONE"
       .USE_SIMD("ONE48"),   // "ONE48" "TWO24" "FOUR12"
       // pattern detector - not used
       .AUTORESET_PATDET("NO_RESET"), .MASK(48'h3fffffffffff),
       .PATTERN(48'h000000000000), .SEL_MASK("MASK"),
       .SEL_PATTERN("PATTERN"), .USE_PATTERN_DETECT("NO_PATDET"),
       // register enables
       .ACASCREG(1),   // pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
       .ADREG(1),      // pipeline stages for pre-adder (0 or 1)
       .ALUMODEREG(1), // pipeline stages for ALUMODE (0 or 1)
       .AREG(AREG),       // pipeline stages for A (0, 1 or 2)
       .BCASCREG(1),   // pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
       .BREG(BREG),    // pipeline stages for B (0, 1 or 2)
       .CARRYINREG(1), // this and below are 0 or 1
       .CARRYINSELREG(1),
       .CREG(1),
       .DREG(1),
       .INMODEREG(1),
       .MREG(1),
       .OPMODEREG(1),
       .PREG(1))
   DSP48E1_inst
     (
      // status
      .OVERFLOW(),
      .PATTERNDETECT(), .PATTERNBDETECT(),
      .UNDERFLOW(),
      // outs
      .CARRYOUT(),
      .P(dsp_p),
      // control
      .ALUMODE({2'd0, mode[1:0]}),
      .CARRYINSEL(3'd0),
      .CLK(clock),
      .INMODE({1'b0,mode[4],3'b100}),
      .OPMODE({1'b0,mode[3:2],4'b0101}),
      // signal inputs
      .A({{6{a[NBA-1]}},a,{SA{1'b0}}}), // 30
      .B({b,{SB{1'b0}}}), // 18
      .C({{(48-(SC+NBC)){c[NBC-1]}},c,{SC{1'b0}}}), // 48
      .CARRYIN(1'b0),
      .D({d[NBA-1],d,{SA{1'b0}}}), // 25
      // cascade ports
      .ACOUT(acout),
      .BCOUT(bcout),
      .CARRYCASCOUT(),
      .MULTSIGNOUT(),
      .PCOUT(pcout),
      .ACIN(acin),
      .BCIN(bcin),
      .CARRYCASCIN(1'b0),
      .MULTSIGNIN(1'b0),
      .PCIN(pcin),
      // clock enables
      .CEA1(ce1), .CEA2(ce2),
      .CEAD(1'b1),
      .CEALUMODE(1'b1),
      .CEB1(ce1), .CEB2(ce2),
      .CEC(1'b1),
      .CECARRYIN(1'b1),
      .CECTRL(1'b1), // opmode
      .CED(1'b1),
      .CEINMODE(1'b1),
      .CEM(cem), .CEP(cep),
      .RSTA(1'b0),
      .RSTALLCARRYIN(1'b0),
      .RSTALUMODE(1'b0),
      .RSTB(1'b0),
      .RSTC(1'b0),
      .RSTCTRL(1'b0),
      .RSTD(1'b0),
      .RSTINMODE(1'b0),
      .RSTM(1'b0),
      .RSTP(1'b0)
      );

endmodule
