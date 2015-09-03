/*
 * HIFIFO: Harmon Instruments PCI Express to FIFO
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
 */

/*
 * First word fall through FIFO
 * Copyright 2014 Harmon Instruments
 * Author: Darrell Harmon
 */

module fwft_fifo
  (
   input 	      reset, // async
   input 	      i_clock,
   input [NBITS-1:0]  i_data,
   input 	      i_valid,
   output 	      i_ready,
   input 	      o_clock,
   input 	      o_read,
   output [NBITS-1:0] o_data,
   output 	      o_valid,
   output 	      o_almost_empty
   );

   parameter NBITS = 64; // 1 to 72 valid
   parameter FULL_OFFSET = 9'h080;

`ifdef SIM
   // this is for simulation only!!!
   reg [NBITS-1:0]    fifo[0:511];
   reg [NBITS-1:0]    a_d, b_d;
   reg 		      a_v, b_v;
   wire 	      a_cken = (p_out != p_in) && (~a_v | ~b_v | c_cken);
   wire 	      b_cken = a_v && (~b_v | c_cken);
   wire 	      c_cken = o_read;
   reg [8:0] 	      p_in, p_out;
   wire [8:0] 	      count = p_in - p_out;

   assign o_valid = b_v;
   assign o_data = b_d;

   assign i_ready = (count < 384);
   assign o_almost_empty = ((count + a_v + b_v) < 16);

   always @ (posedge i_clock)
     begin
	if(i_valid)
	  fifo[p_in] <= i_data;
	p_in <= reset ? 1'b0 : p_in + i_valid;
     end

   always @ (posedge o_clock)
     begin
	p_out <= reset ? 1'b0 : p_out + a_cken;
	a_v <= reset ? 1'b0 : a_cken | (a_v && ~b_cken);
	if(a_cken)
	  a_d <= fifo[p_out];
	b_v <= reset ? 1'b0 : b_cken | (b_v && ~c_cken);
	if(b_cken)
	  b_d <= a_d;
     end

`else
   wire empty, almostfull;
   assign i_ready = ~almostfull;
   assign o_valid = ~empty;
   generate
      if(NBITS>36) begin : fifo_36
	 FIFO_DUALCLOCK_MACRO
	   #(
	     .ALMOST_EMPTY_OFFSET(9'h00F),
	     .ALMOST_FULL_OFFSET(FULL_OFFSET),
	     .DATA_WIDTH(NBITS),
	     .DEVICE("7SERIES"),
	     .FIFO_SIZE ("36Kb"),
	     .FIRST_WORD_FALL_THROUGH ("TRUE")
	     )
	 FIFO_DUALCLOCK_MACRO_inst
	   (
	    .ALMOSTEMPTY(o_almost_empty),
	    .ALMOSTFULL(almostfull),
	    .DO(o_data),
	    .EMPTY(empty),
	    .FULL(),
	    .RDCOUNT(),
	    .RDERR(),
	    .WRCOUNT(),
	    .WRERR(),
	    .DI(i_data),
	    .RDCLK(o_clock),
	    .RDEN(o_read),
	    .RST(reset),
	    .WRCLK(i_clock),
	    .WREN(i_valid)
	    );
      end
      else begin : fifo_18
	 FIFO_DUALCLOCK_MACRO
	   #(
	     .ALMOST_EMPTY_OFFSET(9'h00F),
	     .ALMOST_FULL_OFFSET(FULL_OFFSET),
	     .DATA_WIDTH(NBITS),
	     .DEVICE("7SERIES"),
	     .FIFO_SIZE ("18Kb"),
	     .FIRST_WORD_FALL_THROUGH ("TRUE")
	     )
	 FIFO_DUALCLOCK_MACRO_inst
	   (
	    .ALMOSTEMPTY(o_almost_empty),
	    .ALMOSTFULL(almostfull),
	    .DO(o_data),
	    .EMPTY(empty),
	    .FULL(),
	    .RDCOUNT(),
	    .RDERR(),
	    .WRCOUNT(),
	    .WRERR(),
	    .DI(i_data),
	    .RDCLK(o_clock),
	    .RDEN(o_read),
	    .RST(reset),
	    .WRCLK(i_clock),
	    .WREN(i_valid)
	    );
      end
   endgenerate
`endif
endmodule