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
module dual_cos (input c,
		 input [25:0] 		 a0, a1,
		 output signed [NBD-1:0] o0, o1);

   parameter NBD = 23;

   reg [23:0]     a0_1 = 0;
   reg [23:0]     a1_1 = 0;
   reg 		  s0 = 0;
   reg 		  s1 = 0;

   always @ (posedge c) begin
      a0_1 <= a0[24] ? ~ a0[23:0] : a0[23:0];
      a1_1 <= a1[24] ? ~ a1[23:0] : a1[23:0];
      s0 <= a0[25] ^ a0[24];
      s1 <= a1[25] ^ a1[24];
   end

   wire [34:0] rd0, rd1;
   cosrom cosrom
     (.c(c),
      .a0(a0_1[23:14]),
      .a1(a1_1[23:14]),
      .d0(rd0),
      .d1(rd1));
   cosine_int #(.NBO(NBD)) cos_0
     (.c(c), .a(a0_1[13:0]), .rom_d(rd0), .s(s0), .o(o0));
   cosine_int #(.NBO(NBD)) cos_1
     (.c(c), .a(a1_1[13:0]), .rom_d(rd1), .s(s1), .o(o1));

endmodule
