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
module sincos (input c,
	       input [25:0] 	       a,
	       output signed [NBD-1:0] o_cos, o_sin);

   parameter NBD = 25;
   parameter SIN_EN = 1'b1;

   reg [23:0]     a0 = 0;
   reg [23:0]     a1 = 0;
   reg 		  s0 = 0;
   reg 		  s1 = 0;

   // 90 degrees - a, off by one
   wire [25:0] a_sin = (SIN_EN << (24)) + ~a;

   always @ (posedge c) begin
      a0 <= a[24] ? ~ a[23:0] : a[23:0];
      a1 <= a_sin[24] ? ~ a_sin[23:0] : a_sin[23:0];
      s0 <= a[25] ^ a[24];
      s1 <= a_sin[25] ^ a_sin[24];
   end

   wire [34:0] rd0, rd1;
   cosrom cosrom
     (.c(c), .a0(a0[23:14]), .a1(a1[23:14]), .d0(rd0), .d1(rd1));
   cosine_int #(.NBO(NBD)) cos_0
     (.c(c), .a(a0[13:0]), .rom_d(rd0), .s(s0), .o(o_cos));
   cosine_int #(.NBO(NBD)) cos_1
     (.c(c), .a(a1[13:0]), .rom_d(rd1), .s(s1), .o(o_sin));

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
