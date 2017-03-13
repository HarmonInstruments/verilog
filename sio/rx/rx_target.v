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

// clock is 31.25 MHz
// host will initiate a transfer every 128 clocks

module rx_target(input clock, inout sdio,
		 // uC
		 input cs, sck, mosi,
		 output miso,
		 //
		 input drdy,
		 output [1:0] adclk,
		 output reg [1:0] reset = 0,
		 output [1:0] sync,
		 output [1:0] amosi,
		 output [1:0] asck,
		 input [1:0] amiso,
		 output [1:0] acs,
		 input [7:0] add,
		 output led);

   wire 	 clockbuf;
   SB_GB_IO cbuf (.PACKAGE_PIN(clock), .GLOBAL_BUFFER_OUTPUT(clockbuf));

   reg [7:0] 	    tsr = 0;
   reg [19:0] 	    rsr = 0;
   reg 		    sdo = 1;
   wire [1:0] 	    di;
   reg [6:0] 	    state = 0;
   reg 		    oe = 0;
   reg [7:0] 	    adcbuf = 0;

   reg [3:0] 	    addr;
   reg [15:0] 	    wdata;
   reg 		    wvalid;
   reg [15:0] 	    rdata;
   wire [7:0] 	    spi0_rdata, spi1_rdata;
   reg [23:0] 	    count = 0;

   always @ (posedge clockbuf)
     begin
	rsr <= {rsr[17:0], di};
	if(state[1:0] == 0)
	  begin
	     oe <= (state[6:2] > 2) && (state[6:2] < 29);
	     case(state[6:2])
	       27: tsr <= rdata[15:8];
	       28: tsr <= rdata[7:0];
	       default: tsr <= adcbuf; // 3 - 26
	     endcase
	  end
	else
	  begin
	     tsr <= {tsr[5:0], 2'b11};
	  end

	if((state == 0) || (state > 120))
	  state <= di[1] ? 1'b0 : 1'b1;
	else
	  state <= state + (state != 0);
	if(state == 11)
	  {addr,wdata} <= rsr;
	wvalid <= (state == 11);
	adcbuf <= add;
	if(wvalid && (addr == 0))
	  reset <= {2{wdata[0]}};

	//
	case(addr)
	  0: rdata <= 16'hFFFF;
	  2: rdata <= spi0_rdata;
	  3: rdata <= spi1_rdata;
	  4: rdata <= 16'hCAFE;
	  default: rdata <= 16'hAAA0 | addr;
	endcase
	count <= count + 1'b1;

     end

   sync_out synco(.clock(clockbuf), .wvalid(wvalid && (addr == 1)), .wdata(wdata), .sync(sync));

   spi_ad7768 spi0(.clock(clockbuf), .wvalid(wvalid && (addr == 2)), .wdata(wdata), .rdata(spi0_rdata),
		   .sck(asck[0]), .mosi(amosi[0]), .cs(acs[0]), .miso(amiso[0]));
   spi_ad7768 spi1(.clock(clockbuf), .wvalid(wvalid && (addr == 3)), .wdata(wdata), .rdata(spi1_rdata),
		   .sck(asck[1]), .mosi(amosi[1]), .cs(acs[1]), .miso(amiso[1]));

   assign led = count[23];
   // DDR IO
   SB_IO #(.PIN_TYPE(6'b110000), .PULLUP(1'b1), .IO_STANDARD("SB_LVCMOS")) iopin
     (.PACKAGE_PIN(sdio),
      .LATCH_INPUT_VALUE(1'b0),
      .CLOCK_ENABLE(1'b1),
      .INPUT_CLK(clockbuf),
      .OUTPUT_CLK(clockbuf),
      .OUTPUT_ENABLE(oe),
      .D_OUT_0(tsr[6]), // data out to pin
      .D_OUT_1(tsr[7]),
      .D_IN_0(di[1]), // data in from pin
      .D_IN_1(di[0]));
/*
   reg [1:0] ledi;
   always @ (posedge clockbuf)
     begin
	case(count[5:0])
	  0: ledi <= 2'b00;
	  1: ledi <= 2'b11;
	  2: ledi <= 2'b01;
	  3: ledi <= 2'b10;
	  4: ledi <= 2'b00;
	  5: ledi <= 2'b11;
	  6: ledi <= 2'b00;

	  default: ledi <= 2'b11;
	endcase
     end

   SB_IO #(.PIN_TYPE(6'b110000), .IO_STANDARD("SB_LVCMOS")) led_ddr
     (.PACKAGE_PIN(led),
      .CLOCK_ENABLE(1'b1),
      .OUTPUT_CLK(clockbuf),
      .OUTPUT_ENABLE(1'b1),
      .D_OUT_0(ledi[0]), // data out to pin
      .D_OUT_1(ledi[1]));
*/
   oddr cf0(.pin(adclk[0]), .c(clockbuf), .d(2'b10));
   oddr cf1(.pin(adclk[1]), .c(clockbuf), .d(2'b10));
endmodule

module oddr(inout pin, input c, input [1:0] d);
   wire [1:0] d_in;
   SB_IO #(.PIN_TYPE(6'b010000), .PULLUP(1'b0), .IO_STANDARD("SB_LVCMOS")) SB_IOI
     (.PACKAGE_PIN(pin),
      .LATCH_INPUT_VALUE(1'b0),
      .CLOCK_ENABLE(1'b1),
      .INPUT_CLK(1'b0),
      .OUTPUT_CLK(c),
      .OUTPUT_ENABLE(1'b1),
      .D_OUT_0(d[0]),
      .D_OUT_1(d[1]),
      .D_IN_0(d_in[0]),
      .D_IN_1(d_in[1]));
endmodule

module sync_out(input clock, input wvalid, input [15:0] wdata, output [1:0] sync);
   reg [1:0] dsync = 0;
   reg [7:0] count = 0;
   always @ (posedge clock)
     begin
	if(wvalid)
	  count <= wdata[7:0];
else if(count != 0)
	  count <= count - 1'b1;
	case(count)
	  2: dsync <= 2'b01;
	  3: dsync <= 2'b10;
	  default: dsync <= 2'b11;
	endcase
     end
   oddr osync0(.pin(sync[0]), .c(clock), .d(dsync));
   oddr osync1(.pin(sync[1]), .c(clock), .d(dsync));
endmodule

module spi_ad7768(input clock, input wvalid, input [15:0] wdata, output reg [7:0] rdata,
		  output reg sck, output reg cs, output reg mosi, input miso);

   reg [5:0] 		     state = 0;
   reg [15:0] 		     sro;

   always @ (posedge clock)
     begin
	if(wvalid)
	  state <= 1'b1;
	else if(state != 0)
	  state <= state + 1'b1;

	if(wvalid)
	  cs <= 1'b0;
	else if(state == 0)
	  cs <= 1'b1;

	sck <= (state[1:0] ==1) || (state [1:0] == 2);

	if(wvalid)
	  sro <= wdata;
	else if(state[1:0] == 2)
	  sro <= {sro[14:0], 1'b0};

	mosi <= sro[15];
	if(state[1:0] == 3)
	  rdata <= {rdata[6:0], miso};
     end
endmodule