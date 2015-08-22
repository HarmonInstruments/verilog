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

`timescale 1 ps / 1 ps

module oserdes_4x (input c, cdiv, t, input [3:0] din, output op, on);

   wire serdes_o;
   wire tq;

   OBUFTDS OBUFTDS_i(.O(op), .OB(on), .I(serdes_o), .T(tq));

   OSERDESE2 #(.DATA_RATE_OQ("DDR"),
	       .DATA_RATE_TQ("DDR"),
	       .DATA_WIDTH(4),
	       .INIT_OQ(1'b1),
	       .INIT_TQ(1'b0),
	       .SERDES_MODE("MASTER"),
	       .SRVAL_OQ(1'b1),
	       .SRVAL_TQ(1'b1),
	       .TBYTE_CTL("FALSE"),
	       .TBYTE_SRC("FALSE"),
	       .TRISTATE_WIDTH(4)
	       )
   OSERDESE2_i
     (
      .OFB(),
      .OQ(serdes_o),
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
      .D5(1'b0),
      .D6(1'b0),
      .D7(1'b0),
      .D8(1'b0),
      .OCE(1'b1),
      .RST(t),
      .SHIFTIN1(1'b0),
      .SHIFTIN2(1'b0),
      .T1(1'b0),
      .T2(1'b0),
      .T3(1'b0),
      .T4(1'b0),
      .TBYTEIN(1'b0),
      .TCE(1'b1)
      );
endmodule
