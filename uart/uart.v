/*
 * Copyright (C) 2016 Harmon Instruments, LLC
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
 * One wire UART least significant bit and byte first
 *
 * Set baud rate: write with a=0, wd = cpb | 0x80000000
 * where cpb = (16 * clock) / baud
 *
 * Send 4 bytes: wd = data, a = 3
 * Send 3 bytes: wd[23:0] = data, a = 2
 * Send 2 bytes: wd[16:0] = data, a = 1
 * Send 1 byte : wd[ 7:0] = data, a = 0, wd[31:30] must be 0
 * Send break  : wd = 0x40000000, a = 0
 *
 */

`timescale 1ns / 1ps

module uart_1wire
  (
   input 	     c, // clock
   input 	     w, // write enable
   input [1:0] 	     a, // address
   input [31:0]      wd, // write data
   output reg [31:0] rd = 0, // read data
   inout 	     uart // IO pin
   );

   reg [3:0] 	 rx_state = 0;
   reg [6:0] 	 rx_cur_time = 0;
   reg [6:0] 	 rx_next_event = 0;
   reg [6:0] 	 cpb = 100; // clocks per bit
   reg 		 ireg = 1;
   reg 		 oe = 0;
   reg 		 od = 0;
   reg [5:0] 	 tx_bits = 0; // tx bits remaining
   reg [6:0] 	 tx_cur_time = 0;
   reg [6:0] 	 tx_next_event = 0;
   reg [38:0] 	 tx_sr = 39'h7FFFFFFFF;

   assign uart = oe ? od : 1'bz;

   always @ (posedge c)
     begin
	// receive
	ireg <= uart;
	if(rx_state == 0)
	  begin
	     rx_cur_time <= 1'b0;
	     if (!ireg)
	       begin
		  rx_state <= 1'b1;
		  rx_next_event <= cpb[6:1];
	       end
	  end
	else
	  begin
	     rx_cur_time <= rx_cur_time + 1'b1;
	     if(rx_next_event == rx_cur_time)
	       begin
		  rx_next_event <= rx_next_event + cpb;
		  rx_state <= rx_state == 10 ? 1'b0 : rx_state + 1'b1;
		  if((rx_state > 1) && (rx_state < 10))
		    rd <= {ireg, rd[31:1]};
	       end
	  end
	// transmit
	od <= tx_sr[0];
	oe <= tx_bits != 0;
	if(w)
	  begin
	     if((a == 0) && wd[31])
	       cpb <= wd[6:0];
	     oe <= 1'b1;
	     tx_bits <= 6'd40;
	     tx_cur_time <= 1'b0;
	     tx_next_event <= cpb;
	     tx_sr[38:30] <= a > 2 ? {wd[31:24], 1'b0} : 9'h1FF;
	     tx_sr[29:20] <= a > 1 ? {1'b1, wd[23:16], 1'b0} : 10'h3FF;
	     tx_sr[19:10] <= a > 0 ? {1'b1, wd[15: 8], 1'b0} : 10'h3FF;
	     tx_sr[ 9: 0] <= (a > 0) || (wd[31:30] == 0) ? {1'b1, wd[ 7: 0], 1'b0} :
			     wd[30] == 1 ? 10'h000 : 10'h3FF;
	  end
	else
	  begin
	     tx_cur_time <= tx_cur_time + 1'b1;
	     if(tx_next_event == tx_cur_time)
	       begin
		  tx_next_event <= tx_next_event + cpb;
		  tx_sr <= {1'b1, tx_sr[38:1]};
		  tx_bits <= tx_bits == 0 ? 1'b0 : tx_bits - 1'b1;
	       end
	  end
     end
endmodule

`ifdef SIM
module tb (input c);
   reg w = 0;
   reg [2:0] a = 0;
   reg [31:0] wd = 0;
   wand       uart = 1;
   wire [31:0] rd0, rd1;

   uart_1wire uart0 (.c(c), .w(w & ~a[2]), .a(a[1:0]), .wd(wd), .rd(rd0), .uart(uart));
   uart_1wire uart1 (.c(c), .w(w &  a[2]), .a(a[1:0]), .wd(wd), .rd(rd1), .uart(uart));

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end
endmodule
`endif
