/*
 * Copyright (C) 2017 Harmon Instruments, LLC
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

// high pass triangular dither at 4x clock rate
module dither_hp_tri_4(input c, prn, output reg [8:0] o0, o1, o2, o3);

   parameter integer startstate = 32'hDEADBEEF;
   reg [62:0] 	     lfsr = 62'h0CAFEDEADBEEFC0DE ^ startstate;
   // lfsr <= lfsr[0], lfsr[0] ^ lfsr[62], lfsr[61:1]
   always @ (posedge c)
     begin
	lfsr <= {lfsr[31], lfsr[31:1]^lfsr[30:0], lfsr[62] ^ lfsr[0], lfsr[61] ^ prn, lfsr[60:32]};
     end

   always @ (posedge c)
     begin
	o0 <= 9'h100 + lfsr[15: 8] - lfsr[ 7: 0];
	o1 <= 9'h100 + lfsr[23:16] - lfsr[15: 8];
	o2 <= 9'h100 + lfsr[31:23] - lfsr[23:16];
	o3 <= 9'h100 + lfsr[39:32] - lfsr[31:24];
     end

endmodule
