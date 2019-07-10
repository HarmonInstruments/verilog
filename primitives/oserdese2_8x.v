/*
 * Copyright (C) 2015-2019 Harmon Instruments, LLC
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

`timescale 1 ps / 1 ps

module oserdes_8x (input c, cdiv, r, t, tce, input [7:0] din, output o, tq);
   wire serdes_o;
   OSERDESE2 #(.DATA_RATE_OQ("DDR"),
	       .DATA_RATE_TQ("SDR"),
	       .DATA_WIDTH(8),
	       .INIT_OQ(1'b1),
	       .INIT_TQ(1'b0),
	       .SRVAL_OQ(1'b1),
	       .SRVAL_TQ(1'b1),
	       .TBYTE_CTL("FALSE"),
	       .TBYTE_SRC("FALSE"),
	       .TRISTATE_WIDTH(1)
	       )
   OSERDESE2_i
     (
      .OFB(),
      .OQ(o),
      .SHIFTOUT1(),
      .SHIFTOUT2(),
      .TBYTEOUT(),
      .TFB(),
      .TQ(tq),
      .CLK(c),
      .CLKDIV(cdiv),
      .D1(din[0]),
      .D2(din[1]),
      .D3(din[2]),
      .D4(din[3]),
      .D5(din[4]),
      .D6(din[5]),
      .D7(din[6]),
      .D8(din[7]),
      .OCE(1'b1),
      .RST(r),
      .SHIFTIN1(1'b0),
      .SHIFTIN2(1'b0),
      .T1(t),
      .T2(t),
      .T3(t),
      .T4(t),
      .TBYTEIN(1'b0),
      .TCE(tce)
      );
endmodule
