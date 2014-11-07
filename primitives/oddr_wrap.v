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

module oddr_wrap (input c, input [1:0] i, output o);
   ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(1'b1), .SRTYPE("SYNC")) ODDR2_i
     (.Q(o),
      .C0(c), .C1(~c),
      .CE(1'b1),
      .D0(i[0]), .D1(i[1]),
      .R(1'b0), .S(1'b0));
endmodule

