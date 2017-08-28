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

module sio_target(input c, c2x,
                  inout sdio,
                  input [31:0] rdata,
                  input [15:0] stream_in,
                  output [31:0] status,
                  output reg [79:0] wdata,
                  output reg [15:0] stream_out,
                  output reg wvalid);

   reg [31:0]   tsr = ~0;
   reg [15:0]   rsr;
   wire [3:0]   id;
   reg [5:0]    state = 53;
   reg [3:0]    id_prev;
   wire [15:0]  crc_val;
   reg [3:0]    crc_failcount = 0;
   wire         crc_pass = crc_val == rsr;
   reg          searching = 1;
   reg          searching_prev = 1;
   wire         crc_pass_30 = crc_pass && (state == 30);
   reg [4:0]    run_length = 0;
   reg          cycle_skip = 0;
   reg          cycle_add = 0;
   reg [3:0]    take_back = 0;
   reg [6:0]    delay = 0;
   reg [7:0]    searches = 0;

   assign status = {searches,3'b0,run_length,1'b0,delay};

   always @ (posedge c)
     begin
        wvalid <= (state == 30) && crc_pass;
        if(state == 30)
          tsr <= {~16'h0, stream_in};
        else if(state == 34)
          tsr <= rdata;
        else if(state == 42)
          tsr <= {~16'h0, crc_val};
        else
          tsr <= {4'hF, tsr[31:4]};

        state <= state + cycle_skip + (cycle_add ? 1'b0 : 1'b1);

        if((state < 30) && (state > 1)) begin
           case(delay[6:5])
             3: rsr <= {id_prev, rsr[15:4]};
             2: rsr <= {id[0], id_prev[3:1], rsr[15:4]};
             1: rsr <= {id[1:0], id_prev[3:2], rsr[15:4]};
             0: rsr <= {id[2:0], id_prev[3], rsr[15:4]};
           endcase
        end
        if(state == 6)
          wdata[15:0] <= rsr;
        if(state == 10)
          wdata[31:16] <= rsr;
        if(state == 14)
          wdata[47:32] <= rsr;
        if(state == 18)
          wdata[63:48] <= rsr;
        if(state == 22)
          wdata[79:64] <= rsr;
        if(state == 26)
          stream_out <= rsr;
        id_prev <= id;
        cycle_skip <= searching && (delay == 121) && (state == 30);
        cycle_add <= (state != 30) && !searching && (take_back != 0) && (delay == 0);
        if(state == 30)
          begin
             if(searching && crc_pass)
               run_length <= run_length + 1'b1;
             else if(!searching && !crc_pass)
               run_length <= 1'b0;

             if(!searching && !crc_pass)
               searching <= 1'b1;
             else if(!crc_pass && (run_length > 7))
               searching <= 1'b0;

             if(searching)
               delay <= (delay[4:0] == 25) ? {delay[6:5],5'd0} + 7'h20 : delay + 1'b1;

             if(searching && !crc_pass)
               take_back <= run_length[4:1];
          end
        else if(!searching && (take_back != 0))
          begin
             take_back <= take_back - 1'b1;
             delay <= (delay[4:0] == 0) ? {delay[6:5], 5'd25} - 7'h20 : delay - 1'b1;
          end
        searching_prev <= searching;
        if(!searching && searching_prev)
          searches <= searches + 1'b1;
     end

   sio_common io(.c(c), .c2x(c2x),
                 .wv(state == 60),
                 .d(delay[4:0]),
                 .sdio(sdio),
                 .tq((state < 26)||(state > 47)),
                 .td(tsr[3:0]),
                 .rd(id));

   crc_16_4_usb crc(.c(c),
                    .ce(((state < 26) && (state > 1)) || ((state > 30) && (state < 48))) ,
                    .r((state == 2) || (state == 30)),
                    .di(state > 30 ? tsr[3:0] : rsr[15:12]),
                    .crc(crc_val));

endmodule
