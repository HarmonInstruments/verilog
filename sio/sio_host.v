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
 */

`timescale 1ns / 1ps

module sio_host (input c, c2x, sync, wvalid,
                 inout sdio,
                 input [79:0] wdata,
                 input [15:0] stream_out,
                 output reg [15:0] stream_in,
                 output reg [15:0] crc_failcount = 0,
                 output reg [31:0] rdata,
                 output reg rvalid = 0);
   reg [83:0]   tsr = ~0;
   reg [15:0]   rsr;
   reg [5:0]    state = 60;
   wire [3:0]   id;
   reg [3:0]    id_prev;
   wire [15:0]  crc_val;
   reg [79:0]   wdata_latch = 0; // holds wdata until tx opportunity
   reg          ce_rcrc;
   reg [16:0]   rx_state = 0;
   wire         crc_match = rsr == crc_val;
   reg          was_read = 0;
   reg [5:0]    delay = {~4'd8,2'd2};

   always @ (posedge c)
     begin
        if(wvalid)
          wdata_latch <= wdata;
        else if(state == 0)
          wdata_latch <= ~80'h0; // keep for retry?
        if((state == 0) && ~wdata_latch[79])
          was_read <= 1'b1;
        else if(rx_state[16])
          was_read <= 1'b0;
        state <= sync ? 1'b0 : state + 1'b1;
        // TX
        if(state == 0)
          tsr <= {wdata_latch,4'h0};
        else if(state == 21)
          tsr <= {~64'h0, stream_out};
        else if(state == 25)
          tsr <= {~64'h0, crc_val};
        else
          tsr <= {4'hF, tsr[83:4]};

        // RX
        id_prev <= id;
        rx_state <= {rx_state[15:0], ((state[5:4] == 2) && (~delay[5:2] == state[3:0]))};

        if(wvalid && wdata[75:64] == 1)
          delay <= wdata[10:5];

        if(rx_state[0])
          ce_rcrc <= 1'b1;
        else if(rx_state[11])
          ce_rcrc <= 1'b0;

        if(state > 32) begin
           case(delay[1:0])
             3: rsr <= {id_prev, rsr[15:4]};
             2: rsr <= {id[0], id_prev[3:1], rsr[15:4]};
             1: rsr <= {id[1:0], id_prev[3:2], rsr[15:4]};
             0: rsr <= {id[2:0], id_prev[3], rsr[15:4]};
           endcase
        end
        if(rx_state[4])
          stream_in <= rsr;
        if(rx_state[8] && was_read)
          rdata[15:0] <= rsr;
        if(rx_state[12] && was_read)
          rdata[31:16] <= rsr;

        rvalid <= rx_state[16] && crc_match;
        if(rx_state[16] & ~crc_match)
          crc_failcount <= crc_failcount + 1'b1;

     end

   sio_common io(.c(c), .c2x(c2x),
                 .wv(wvalid && (wdata[75:64] == 1)),
                 .d(wdata[4:0]),
                 .sdio(sdio),
                 .tq((state > 29) && (state < 55)),
                 .td(tsr[3:0]),
                 .rd(id));

   crc_16_4_usb crc(.c(c),
                    .ce(((state < 25) && (state > 0)) || ce_rcrc),
                    .r((state == 1) || rx_state[0]),
                    .di(state[5] ? rsr[15:12] : tsr[3:0]),
                    .crc(crc_val));

endmodule
