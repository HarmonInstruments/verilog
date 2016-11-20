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

// 6 clocks
module cosgen (input c, input [25:0] a, output signed [NBD-1:0] o);

   parameter NBD = 23;

   reg [23:0]     a0 = 0;
   reg 		  s0 = 0;

   always @ (posedge c) begin
      a0 <= a[24] ? ~ a[23:0] : a[23:0];
      s0 <= a[25] ^ a[24];
   end

   wire [34:0] rd0;
   cosrom cosrom
     (.c(c), .a0(a0[23:14]), .a1(10'd0), .d0(rd0), .d1());
   cosine_int #(.NBO(NBD)) cos_0
     (.c(c), .a(a0[13:0]), .rom_d(rd0), .s(s0), .o(o));

endmodule
