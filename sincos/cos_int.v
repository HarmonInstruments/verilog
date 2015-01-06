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
   input [NBA-3:0] 	   a,
   input 		   s,
   input [34:0] 	   rom_d,
   output signed [NBO-1:0] o
   );

   parameter NBA = 22; // bits in angle in - all but 12 are interpolated
   parameter NBO = 18; // bits in dout
   localparam OSHIFT = NBA + 11 - NBO; // extra bits

   reg [2:0] 		   sign = 0;
   reg [NBO-2:0] 	   coarse_2 = 0;

   dsp48_wrap
     #(.NBA(NBA-11),
       .NBB(17),
       .NBC(NBO+OSHIFT),
       .NBP(NBO),
       .S(OSHIFT),
       .USE_DPORT("TRUE"), // just for the extra pipe stage
       .AREG(2),
       .BREG(1)
       )
   dsp_i
     (.clock(c),
      .a({1'b0, a[NBA-13:0]}), // 5 regs to out
      .b({4'b0, rom_d[12:0]}), // 3 regs to out
      .c({1'b0, coarse_2, {(OSHIFT){1'b0}}}), // 2 regs to out
      .d({(NBA-11){1'b0}}),
      .mode({1'b0,2'd3,sign[2],1'b1}), // A+D 2 regs to out
      .acin(30'h0),
      .bcin(18'h0),
      .pcin(48'h0),
      .acout(), .bcout(), .pcout(),
      .p(o));

   always @ (posedge c) begin
      sign <= {sign[1:0], ~s};
      coarse_2 <= rom_d[34:36-NBO];
   end

endmodule
