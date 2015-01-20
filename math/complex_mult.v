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

// 4 cycle pipe
module complex_mult
  (
   input 		   clock,
   input 		   ce,
   input signed [NBA-1:0]  a_re, a_im,
   input signed [NBB-1:0]  b_re, b_im,
   output signed [NBP-1:0] p_re, p_im
   );

   parameter NBA = 24; // number of bits a, c (up to 25)
   parameter NBB = 18; // number of bits b, d (up to 18)
   parameter NBP = 32; // number of bits out
   parameter S = 10; // shift of out

   dual_mult_add #(.NBA(NBA), .NBB(NBB), .NBP(NBP), .S(S)) m_re
     (
     .clock(clock),
     .ce(ce),
     .sub(1'b1),
     .a(a_re),
     .b(b_re),
     .c(a_im),
     .d(b_im),
     .p(p_re)
     );

   dual_mult_add #(.NBA(NBA), .NBB(NBB), .NBP(NBP), .S(S)) m_im
     (
     .clock(clock),
     .ce(ce),
     .sub(1'b0),
     .a(a_im),
     .b(b_re),
     .c(a_re),
     .d(b_im),
     .p(p_im)
     );

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
