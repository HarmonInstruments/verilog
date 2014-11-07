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

// out[0] is the last bit received
module iddr_sync (input c, input i, output [1:0] o);
   wire [1:0] 	iddr_out;
   iddr_wrap iddr_i(.c(c), .i(i), .o(iddr_out));
   sync sync_q0(.c(c), .i(iddr_out[0]), .o(o[0]));
   sync sync_q1(.c(c), .i(iddr_out[1]), .o(o[1]));
endmodule
