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

// pulse high 1 clock on rising edge
module sync_oneshot (input c, input i, output reg o);
   wire i_c;
   sync sync_i (.c(c), .i(i), .o(i_c));
   reg 	i_c_prev = 0;
   always @(posedge c) begin
      i_c_prev <= i_c;
      o <= i_c & ~i_c_prev;
   end
endmodule
