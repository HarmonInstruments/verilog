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

// p = p + (a*b / 2^17)
// if r p = (a*b / 2^17)
module mac_24x18
  (
   input 		c,
   input 		r, // 2 cycles after a, b
   input signed [23:0] 	a,
   input signed [17:0] 	b,
   output signed [23:0] p);

   dsp48_wrap #(.NBA(24), .NBB(18), .NBP(24), .S(18), .AREG(1), .BREG(1)) mac_i
     (
     .clock(c),
     .ce1(1'b1),
     .ce2(1'b1),
     .cem(1'b1),
     .cep(1'b1),
     .a(a),
     .b(b),
     .c(24'd131072), // convergent rounding
     .d(24'h0),
     .mode(r ? 5'b01100 : 5'b01000),
     .acin(30'h0),
     .bcin(18'h0),
     .pcin(48'h0),
     .acout(),
     .bcout(),
     .pcout(),
     .p(p)
     );

endmodule
