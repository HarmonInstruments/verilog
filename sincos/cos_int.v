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

module cosine_int
  (
   input 		   c,
   input [13:0] 	   a,
   input 		   s,
   input [34:0] 	   rom_d,
   output signed [NBO-1:0] o
   );

   parameter NBO = 23; // bits in dout

   reg [2:0] 		   sign = 0;
   reg [21:0] 		   coarse_2 = 0;
   wire [47:0] 		   dsp_o;

   dsp48_wrap_f
     #(.USE_DPORT("TRUE"), // just for the extra pipe stage
       .AREG(2),
       .BREG(1))
   dsp_i
     (.clock(c),
      .ce1(1'b1), .ce2(1'b1), .cem(1'b1), .cep(1'b1),
      .a({1'b0, a, 10'b0}), // 5 regs to out
      .b({5'b0, rom_d[12:0]}), // 3 regs to out
      .c({2'b0, coarse_2, 24'hFFFFFFF}), // 2 regs to out
      .d(25'h0),
      .mode({1'b0,2'd3,sign[2],1'b1}), // A+D 2 regs to out
      .pcin(48'h0),
      .pcout(),
      .p(dsp_o));

   always @ (posedge c) begin
      sign <= {sign[1:0], ~s};
      coarse_2 <= rom_d[34:13];
   end

   assign o = dsp_o[46:47-NBO];

endmodule
