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

// 5 clocks
module cosine_dual_23 (input c,
		       input [NBA-3:0] 	    a0, a1,
		       input 		    s0, s1,
		       output signed [22:0] d0, d1);

   parameter NBA = 22;
   wire [34:0] rd0, rd1;
   cosrom_22 cosrom
     (.c(c), .a0(a0[NBA-3:NBA-12]), .a1(a1[NBA-3:NBA-12]), .d0(rd0), .d1(rd1));
   cosine_int #(.NBA(NBA), .NBO(23)) cos_0
     (.c(c), .a(a0), .rom_d(rd0), .s(s0), .o(d0));
   cosine_int #(.NBA(NBA), .NBO(23)) cos_1
     (.c(c), .a(a1), .rom_d(rd1), .s(s1), .o(d1));
endmodule

// 6 clocks
module sincos_23 (input c,
		  input [NBA-1:0] 	  a,
		  output signed [NBD-1:0] o_cos, o_sin);

   parameter NBA = 26;
   parameter NBD = 23;
   parameter SIN_EN = 1'b1;

   reg [NBA-3:0]  a0 = 0;
   reg [NBA-3:0]  a1 = 0;
   reg 		  s0 = 0;
   reg 		  s1 = 0;

   // 90 degrees - a, off by one
   wire [NBA-1:0] a_sin = (SIN_EN << (NBA - 2)) + ~a;

   always @ (posedge c) begin
      a0 <= a[NBA-2] ? ~ a[NBA-3:0] : a[NBA-3:0];
      a1 <= a_sin[NBA-2] ? ~ a_sin[NBA-3:0] : a_sin[NBA-3:0];
      s0 <= a[NBA-1] ^ a[NBA-2];
      s1 <= a_sin[NBA-1] ^ a_sin[NBA-2];
   end
   cosine_dual_23 #(.NBA(NBA)) cos_dual
     (.c(c), .a0(a0), .a1(a1), .s0(s0), .s1(s1), .d0(o_cos), .d1(o_sin));
   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
