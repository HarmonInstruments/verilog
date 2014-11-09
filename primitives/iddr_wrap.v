/*
 * Copyright (C) 2014 Harmon Instruments, LLC
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
`include "config.vh"

module iddr_wrap(input c, input i, output[1:0] o);
`ifdef X7SERIES
   IDDR #(.DDR_CLK_EDGE("SAME_EDGE"), .SRTYPE("ASYNC")) IDDR_i
     (.Q1(o[0]), .Q2(o[1]),
      .C(c),
      .CE(1'b1),
      .D(i),
      .R(1'b0), .S(1'b0));
`else
   IDDR2 #(.DDR_ALIGNMENT("C0"), .SRTYPE("ASYNC")) IDDR2_i
     (.Q0(o[0]), .Q1(o[1]),
      .C0(c), .C1(~c),
      .CE(1'b1),
      .D(i),
      .R(1'b0), .S(1'b0)
      );
`endif
endmodule
