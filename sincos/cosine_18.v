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
module cosine_int
  (
   input 		       c,
   input [NBA-1:0] 	       a,
   input [2*NBO-12:0] 	       rom_d,
   output [9:0] 	       rom_a,
   output reg signed [NBO-1:0] o
   );

   parameter NBA = 22; // bits in angle in - all but 12 are interpolated
   parameter NBO = 18; // bits in dout
   localparam NBP = NBA-12; // bits to interpolator
   localparam NBM = NBO-10; // bits in interpolation multiply value

   reg [5:0]     sign; // these two pipe stages are the ROM lookup
   reg [NBP-1:0] alow_0;
   reg [NBP-1:0] alow_1;
   reg [NBP-1:0] alow_2; // these next 4 pipe stages are the DSP48
   reg [NBO-2:0] coarse_2;
   reg [NBM-1:0]  fine_2;
   reg [NBP-1:0] alow_3;
   reg [NBO-2:0] coarse_3;
   reg [NBM-1:0]  fine_3;
   reg [NBP+NBM-1:0] p_4;
   reg [NBO-2:0] coarse_4;
   reg [NBO+NBP-2:0] p_5;

   wire signed [NBO+NBP-1:0] s_5 = sign[5] ? 2'sd0 - $signed({1'b0,p_5}) : p_5;

   wire [NBA-3:0]     a_adj = a[NBA-2] ? ~ a[NBA-3:0] : a[NBA-3:0];

   assign rom_a = a_adj >> NBP;

   always @ (posedge c) begin
      sign <= {sign[4:0], a[NBA-1] ^ a[NBA-2]};

      alow_0 <= a_adj[NBP-1:0];

      alow_1 <= alow_0;

      alow_2 <= alow_1;
      fine_2 <= rom_d[NBM-1:0];
      coarse_2 <= rom_d >> NBM;

      alow_3 <= alow_2;
      fine_3 <= fine_2;
      coarse_3 <= coarse_2;

      p_4 <= fine_3 * alow_3;
      coarse_4 <= coarse_3;

      p_5 <= ({coarse_4, 1'b1} << (NBP-1)) - p_4;

      o <= s_5 >>> NBP;
   end

endmodule

// 7 clocks
module cosine_dual (input c, input [21:0] a0, a1, output [17:0] d0, d1);
   wire [24:0] rd0, rd1;
   wire [9:0]  ra0, ra1;
   cosrom_17 cosrom (.c(c), .a0(ra0), .a1(ra1), .d0(rd0), .d1(rd1));
   cosine_int cos_0 (.c(c), .a(a0), .rom_d(rd0), .rom_a(ra0), .o(d0));
   cosine_int cos_1 (.c(c), .a(a1), .rom_d(rd1), .rom_a(ra1), .o(d1));
endmodule

// 8 clocks
module sincos_18 (input c, input [21:0] a, output [17:0] o_cos, o_sin);
   parameter NBA = 22;
   reg [NBA-1:0] a0, a1;
   always @ (posedge c) begin
      a0 <= a;
      a1 <= (1'b1 << (NBA - 2)) + ~a; // 90 degrees - a, off by one
   end
   cosine_dual cos_dual (.c(c), .a0(a0), .a1(a1), .d0(o_cos), .d1(o_sin));
   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
