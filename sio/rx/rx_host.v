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

// a transfer is initiated every 512 cycles
// 20 bits out
// 192 + 20 bits in

module rx_host
  (
   input            clock, // 125 MHz
   inout 	    sdio, // 62.5 Mb/s bidir
   output reg       clock_target = 0,
   input 	    wvalid,
   input [31:0]     wdata, // MSB is read, next 4 are addr, ls 16 are data
   input [1:0]      addr,
   output reg [31:0] rdata = 0,
   output reg        rvalid=0
   );

   reg 		    tq = 0;
   reg 		    sdo = 1;
   reg [21:0] 	    tsr = ~22'h0;
   reg [8:0] 	    state = 0;
   reg [8:0] 	    state_prev = 0;
   reg [20:0] 	    tbuf = 0;
   reg [15:0] 	    rsr = 0;
   reg 		    tbuf_valid = 0;
   reg 		    read_active = 0;
   wire 	    id0; // input data from IOBUF to IDDR
   wire [1:0] 	    id1; // input data from IDDR
   reg [7:0] 	    id2 = 8'hFF; // input sample delay line
   reg 		    id3 = 1; // input sample selected by sample_delay
   reg [2:0] 	    sample_delay = 3;
   reg [23:0] 	    isample [0:7];
   reg [23:0] 	    isample_oreg;
   reg [23:0] 	    out_count = 0;
   reg [7:0] 	    out_mask = 0;
   reg [7:0] 	    out_en = 0;
   reg 		    rvalid_next = 0;

   wire [7:0] 	    bitn = state[8:1] - 8'd39;

   always @ (posedge clock)
     begin
	state <= state + 1'b1;
	state_prev <= state;

	if(wvalid && (addr == 1))
	  sample_delay = wdata[2:0];

	if(wvalid && (addr == 0))
	  begin
	     tbuf <= wdata;
	     tbuf_valid <= 1'b1;
	  end
	else if(state == 16)
	  begin
	     tbuf_valid <= 1'b0;
	  end

	if(wvalid && (addr == 2))
	  {out_mask,out_count} <= wdata;
	else if((state == 384) && (out_count != 0))
	  out_count <= out_count - 1'b1;

	if(state == 384)
	  out_en <= (out_count == 0) ? 1'b0 : out_mask;

	if(state == 16) // transmission starts here
	  begin
	     tsr <= tbuf_valid ? {2'b00,tbuf[19:0]} : 22'hFFFFF;
	     read_active <= tbuf_valid && tbuf[20];
	  end
	else if((state > 16) && ~state[0])
	  begin
	     tsr <= {tsr[20:0], 1'b1};
	  end

	if((bitn < 192) && (~state[0]))
	   isample[7-bitn[2:0]][23-bitn[7:3]] <= id3;

	if((state_prev == (78+384+32-1)) && read_active)
	  begin
	     rdata <= rsr[15:0];
	     rvalid <= 1'b1;
	     rvalid_next <= 1'b1;
	  end
	else if((state_prev[8:3] == 48) && out_en[state_prev[2:0]])
	  begin
	     rdata <= {isample_oreg,8'h0};
	     rvalid <= 1'b1;
	     rvalid_next <= 1'b0;
	  end
	else
	  begin
	     rdata <= 1'b0;
	     rvalid <= rvalid_next; // flushes single read through merge_32_64
	     rvalid_next <= 1'b0;
	  end

	if(~state[0])
	  rsr <= {rsr[14:0], id3};

	id2 <= {id2[5:0], id1};
	id3 <= id2[sample_delay];

	tq <= (state > 60);
	sdo <= tsr[21];
	clock_target <= state[1];
	if(state > 383)
	  isample_oreg <= isample[state[2:0]];

     end

   IOBUF iobuf_i (.O(id0), .IO(sdio), .I(sdo), .T(tq));

   IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
	  .INIT_Q1(1'b1), .INIT_Q2(1'b1),
	  .SRTYPE("SYNC")) IDDR_i
     (
      .Q1(id1[1]),
      .Q2(id1[0]),
      .C(clock),
      .CE(1'b1),
      .D(id0),
      .R(1'b0),
      .S(1'b0)
      );

endmodule
