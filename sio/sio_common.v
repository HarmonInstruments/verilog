/*
 * Copyright (C) 2014-2017 Harmon Instruments, LLC
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
 * remote IO
 *
 * from host, LSB first:
/
  * 4 low bits
 * 16 bit address
 * 64 data bits
 * 16 stream bits (most significant 4 are not in CRC)
 * 16 bit CRC16
 *
 * from target:
 * 32 data bits
 * 16 stream bits (ms4 are not in CRC)
 * 16 bit CRC16
 */

`timescale 1ns / 1ps

module sio_common(input c, c2x, wv, tq, // 125 MHz, 250 MHz, write tap, tristate
                  input [4:0] d, // idelay tap
                  inout sdio, // io pin
                  input [3:0] td, // transmit data
                  output reg [3:0] rd = 0); // receive data
   reg [3:0]  tsr = 4'hF; // transmit shift register
   reg        t = 0, tp = 0, ce = 0; // 125 MHz clock enable gen in 2x domain
   reg        tq1 = 0; // buffered tristate at 1x clock
   reg [3:0]  rd2 = 4'hF; // rx data at 2x clock
   reg [1:0]  rdp = 2'h3; // rx data previous
   wire [1:0] id2; // rx data from IDDR at 2x clock

   always @ (posedge c)
     begin
        t <= ~t;
        tq1 <= tq;
        rd <= rd2;
     end

   always @ (posedge c2x)
     begin
        tp <= t;
        ce <= t ^ tp;
        rdp <= id2;
        if(ce)
          rd2 <= {id2,rdp};

        if(ce)
          tsr <= td;
        else
          tsr[1:0] <= tsr[3:2];
     end

   wire tq2, sdo, id0, id1;

   reg  sdod;
   reg  tq2d;

   always @ *
     {sdod,tq2d} <= #0 {sdo,tq2}; // variable delay for sim purposes

   IOBUF iobuf_i (.O(id0), .IO(sdio), .I(sdod), .T(tq2d));
   IDELAYE2 #(.IDELAY_TYPE("VAR_LOAD"), .DELAY_SRC("IDATAIN"), .REFCLK_FREQUENCY(200.0)) deli
     (.DATAOUT(id1), .C(c), .CNTVALUEIN(d[4:0]), .IDATAIN(id0),
      .LD(wv),
      // tied off or ignored signals
      .CNTVALUEOUT(),.INC(1'b0), .CE(1'b0), .CINVCTRL(1'b0),
      .DATAIN(1'b0), .LDPIPEEN(1'b0), .REGRST(1'b0));

   IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .INIT_Q1(1'b1), .INIT_Q2(1'b1), .SRTYPE("SYNC")) IDDR_i
     (.Q1(id2[0]), .Q2(id2[1]), .C(c2x), .CE(1'b1), .D(id1), .R(1'b0), .S(1'b0));
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b1)) ODDR_d
     (.Q(sdo), .C(c2x), .CE(1'b1), .D1(tsr[0]), .D2(tsr[1]), .R(1'b0), .S(1'b0));
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b0)) ODDR_t
     (.Q(tq2), .C(c2x), .CE(1'b1), .D1(tq1), .D2(tq1), .R(1'b0), .S(1'b0));

endmodule

// poly: x^16 + x^15 + x^2 + 1 (11000000000000101)
module crc_16_4_usb (input c, r, ce, input [3:0] di, output reg [15:0] crc);
   always @ (posedge c)
     begin
        if(r)
          begin
             crc <= 16'hFFFF;
          end
        else if(ce)
          begin
             crc[0] <= ^{crc[15:12], di};
             crc[1] <= ^{crc[15:13], di[3:1]};
             crc[2] <= ^{crc[13:12], di[1:0]};
             crc[3] <= ^{crc[14:13], di[2:1]};
             crc[4] <= ^{crc[0], di[3:2], crc[15:14]};
             crc[5] <= crc[1] ^ di[3] ^ crc[15];
             crc[14:6] <= crc[10:2];
             crc[15] <= ^{crc[15:11], di};
          end
     end
endmodule
