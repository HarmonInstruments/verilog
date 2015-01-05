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

// 7 clocks
module cosine_dual_23 (input c,
		       input [NBA-1:0] 	    a0, a1,
		       output signed [22:0] d0, d1);

   parameter NBA = 22;
   wire [34:0] rd0, rd1;
   wire [9:0]  ra0, ra1;
   cosrom_22 cosrom (.c(c), .a0(ra0), .a1(ra1), .d0(rd0), .d1(rd1));
   cosine_int #(.NBA(NBA), .NBO(23)) cos_0
     (.c(c), .a(a0), .rom_d(rd0), .rom_a(ra0), .o(d0));
   cosine_int #(.NBA(NBA), .NBO(23)) cos_1
     (.c(c), .a(a1), .rom_d(rd1), .rom_a(ra1), .o(d1));
endmodule

// 8 clocks
module sincos_23 (input c,
		  input [NBA-1:0] 	  a,
		  output signed [NBD-1:0] o_cos, o_sin);

   parameter NBA = 26;
   parameter NBD = 23;
   reg [NBA-1:0] a0, a1;
   always @ (posedge c) begin
      a0 <= a;
      a1 <= (1'b1 << (NBA - 2)) + ~a; // 90 degrees - a, off by one
   end
   cosine_dual_23 #(.NBA(NBA)) cos_dual
     (.c(c), .a0(a0), .a1(a1), .d0(o_cos), .d1(o_sin));
   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
