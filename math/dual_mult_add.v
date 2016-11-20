/*
 * Copyright (C) 2015-2016 Harmon Instruments, LLC
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
   input signed [25:0] 	   a,
   input signed [17:0] 	   b,
   input signed [25:0] 	   c,
   input signed [17:0] 	   d,
   output signed [47:0]    p
   );

   wire [47:0] 		   pc;

   dsp48_wrap_f #(.AREG(1), .BREG(1)) m0
     (
     .clock(clock),
     .ce1(ce),
     .ce2(1'b1),
     .cem(1'b1),
     .cep(1'b1),
     .a(a),
     .b(b),
     .c(48'h0),
     .d(25'h0),
     .mode(5'd0),
     .pcin(48'h0),
     .pcout(pc),
     .p()
     );

   dsp48_wrap_f #(.AREG(2), .BREG(2)) m1
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
     .pcin(pc),
     .pcout(),
     .p(p)
     );

endmodule
