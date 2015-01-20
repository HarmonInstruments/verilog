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

// p = (a*b) +- (c*d)
// 4 cycle pipe, (3 for sub)
module dual_mult_add
  (
   input 		   clock,
   input 		   ce,
   input 		   sub, // 1: (a*b) - (c*d), 0: (a*b) + (c*d)
   input signed [NBA-1:0]  a,
   input signed [NBB-1:0]  b,
   input signed [NBA-1:0]  c,
   input signed [NBB-1:0]  d,
   output signed [NBP-1:0] p
   );

   parameter NBA = 25; // number of bits a, c
   parameter NBB = 18; // number of bits b, d
   parameter NBP = 48; // number of bits out
   parameter S = 0; // shift of out

   wire [47:0] 		   pc;

   dsp48_wrap #(.NBA(NBA), .NBB(NBB), .NBP(NBP), .S(S), .AREG(1), .BREG(1)) m0
     (
     .clock(clock),
     .ce1(ce),
     .ce2(1'b1),
     .cem(1'b1),
     .cep(1'b1),
     .a(a),
     .b(b),
     .c(1'b0),
     .d(1'b0),
     .mode(5'd0),
     .acin(30'h0),
     .bcin(18'h0),
     .pcin(48'h0),
     .acout(),
     .bcout(),
     .pcout(pc),
     .p()
     );

   dsp48_wrap #(.NBA(NBA), .NBB(NBB), .NBP(NBP), .S(S), .AREG(2), .BREG(2)) m1
     (
     .clock(clock),
     .ce1(ce),
     .ce2(1'b1),
     .cem(1'b1),
     .cep(1'b1),
     .a(c),
     .b(d),
     .c(1'b0),
     .d(1'b0),
     .mode({3'b001,sub,sub}),
     .acin(30'h0),
     .bcin(18'h0),
     .pcin(pc),
     .acout(),
     .bcout(),
     .pcout(),
     .p(p)
     );

endmodule
