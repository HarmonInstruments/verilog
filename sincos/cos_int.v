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
   input 		   c,
   input [NBA-1:0] 	   a,
   input [NBO+NBM-2:0] 	   rom_d,
   output [9:0] 	   rom_a,
   output signed [NBO-1:0] o
   );

   parameter NBA = 22; // bits in angle in - all but 12 are interpolated
   parameter NBO = 18; // bits in dout
   localparam NBP = NBA-12; // bits to interpolator
   localparam NBM = NBO-10; // bits in interpolation multiply value

   reg [1:0] 		   sign; // these two pipe stages are the ROM lookup
   reg [NBP-1:0] 	   alow_0;
   reg signed [NBP:0] 	   alow_1;
   reg signed [NBO-1:0]    coarse_2;

   wire [NBA-3:0] 	a_adj = a[NBA-2] ? ~ a[NBA-3:0] : a[NBA-3:0];

   assign rom_a = a_adj >> NBP;

   wire [NBO-1:0]     coarse_1 = (rom_d >> NBM);

   dsp_wrap_cos_int
     #(.NBA(NBP+1), .NBB(NBM+1), .NBD(NBP+NBO), .NBP(NBO), .S(NBP))
   dsp_i
     (.c(c),
      .a(alow_1),
      .b({1'b0, rom_d[NBM-1:0]}),
      .d({coarse_2, 1'b1, {(NBP-1){1'b0}}}),
      .p(o));

   always @ (posedge c) begin
      sign <= {sign[0], a[NBA-1] ^ a[NBA-2]};
      alow_0 <= a_adj[NBP-1:0];
      alow_1 <= sign[0] ? alow_0 : 2'sd0 - $signed({1'b0, alow_0});
      coarse_2 <= sign[1] ? 2'sd0 - $signed(coarse_1) : coarse_1;
   end

endmodule

//p = d + a * c
module dsp_wrap_cos_int
  (
   input 		   c,
   input signed [NBA-1:0]  a,
   input signed [NBB-1:0]  b,
   input signed [NBD-1:0]  d,
   output signed [NBP-1:0] p);

   parameter NBA = 18;
   parameter NBB = 18;
   parameter NBD = 48;
   parameter NBP = 48;
   parameter S = 0; // Shift

   reg signed [NBA-1:0]     a_1;
   reg signed [NBB-1:0]     b_1;
   reg signed [NBD-1:0]     d_2;
   reg signed [NBA+NBB-1:0] m_2;
   reg signed [NBP+S-1:0]   p_3;
   always @ (posedge c) begin
      a_1 <= a;
      b_1 <= b;
      d_2 <= d;
      m_2 <= a_1 * b_1;
      p_3 <= d_2 + m_2;
   end
   assign p = p_3[NBP+S-1:S];
endmodule