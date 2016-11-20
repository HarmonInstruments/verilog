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
   input 		clock,
   input 		ce,
   input signed [24:0] 	a_re, a_im,
   input signed [17:0] 	b_re, b_im,
   output signed [47:0] p_re, p_im
   );

   dual_mult_add m_re
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

   dual_mult_add m_im
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
