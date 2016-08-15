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
module cosgen (input c, input [NBA-1:0] a, output signed [NBD-1:0] o);

   parameter NBA = 26;
   parameter NBD = 23;

   reg [NBA-3:0]  a0 = 0;
   reg 		  s0 = 0;

   always @ (posedge c) begin
      a0 <= a[NBA-2] ? ~ a[NBA-3:0] : a[NBA-3:0];
      s0 <= a[NBA-1] ^ a[NBA-2];
   end

   wire [34:0] rd0;
   cosrom cosrom
     (.c(c), .a0(a0[NBA-3:NBA-12]), .a1(10'd0), .d0(rd0), .d1());
   cosine_int #(.NBA(NBA), .NBO(NBD)) cos_0
     (.c(c), .a(a0[NBA-13:0]), .rom_d(rd0), .s(s0), .o(o));

endmodule
