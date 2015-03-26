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

`timescale 1ns / 1ps

// 8 channel filter, decimate by 2 to 16
// number of taps is 32*decim rate
// clock is 16 * FS in
module fir_decim_n
  (
   input 	  c,
   input 	  reset,
   input [1:0] 	  l2n, // log2 (rate)
   input [191:0]  id, // input data
   input [17:0]   cd, // coef data
   input [7:0] 	  ca, // coef address
   input 	  cw, // coef write
   input 	  cc, // coef clock
   output [191:0] od,
   output reg 	  ov = 0
   );

   wire [71:0] 	  coef;
   reg [8:0] 	  wa = 0;
   reg [8:0] 	  ra0 = 0;
   reg [8:0] 	  ra1 = 0;
   reg [7:0] 	  state = 0;
   reg [7:0] 	  coefa = 0;
   wire [191:0]   rd0, rd1; // read data from RAM
   reg 		  r = 0;
   reg 		  w = 0;
   wire [7:0] 	  mask;
   assign mask[7] = (l2n > 2);
   assign mask[6] = (l2n > 1);
   assign mask[5] = (l2n > 0);
   assign mask[4:0] = 5'h1F;

   bram_192x512 bram_0(.c(c),
		       .w(w), .wa(wa), .wd(id),
		       .r(~reset), .ra(ra0), .rd(rd0));
   bram_192x512 bram_1(.c(c),
		       .w(w), .wa(wa), .wd(id),
		       .r(~reset), .ra(ra1), .rd(rd1));

   genvar 		   i;
   generate
      for (i = 0; i < 8; i = i+1) begin: maci
	 dsp48_wrap #(.NBA(24),
		      .NBB(18),
		      .NBP(24),
		      .S(18),
		      .AREG(1),
		      .BREG(2),
		      .USE_DPORT("TRUE")) macn
	       (
	        .clock(c),
	        .ce1(1'b1),
	        .ce2(1'b1),
	        .cem(1'b1),
	        .cep(1'b1),
	        .a(rd0[23+24*i:24*i]),
	        .b(coef[17:0]),
	        .c(24'd131072), // convergent rounding
	        .d(rd1[23+24*i:24*i]),
	        .mode(r ? 5'b01100 : 5'b01000),
	        .acin(30'h0),
	        .bcin(18'h0),
	        .pcin(48'h0),
	        .acout(),
	        .bcout(),
	        .pcout(),
	        .p(od[23+24*i:24*i]));
      end
   endgenerate

   always @ (posedge c) begin
      ov <= state == 5;
      r <= state == 4;
      w <= state[3:0] == 1;
      wa <= wa + w;
      state <= reset ? 1'b0 : (state + 1'b1) & mask;
      coefa <= state;
      ra0 <= (state == 0) ? wa - ({mask,1'b1} + 1'b1) : ra0 + 1'b1;
      ra1 <= (state == 0) ? wa - 1'b1 : ra1 - 1'b1;
   end

   RAMB36E1 #(
	      .DOA_REG(1), .DOB_REG(1),
	      .RAM_MODE("SDP"),
	      .READ_WIDTH_A(72), .READ_WIDTH_B(0),
	      .WRITE_WIDTH_A(0), .WRITE_WIDTH_B(72),
	      .SIM_DEVICE("7SERIES"))
   bram_coefs
     (
      .CASCADEOUTA(), .CASCADEOUTB(),
      .DBITERR(), .ECCPARITY(), .RDADDRECC(), .SBITERR(),
      .DOADO(coef[31:0]),
      .DOPADOP(coef[67:64]),
      .DOBDO(coef[63:32]),
      .DOPBDOP(coef[71:68]),
      .CASCADEINA(1'b0), .CASCADEINB(1'b0),
      .INJECTDBITERR(1'b0), .INJECTSBITERR(1'b0),
      .ADDRARDADDR({2'b0, coefa, 6'd0}),
      .CLKARDCLK(c),
      .ENARDEN(~reset),
      .REGCEAREGCE(1'b1),
      .RSTRAMARSTRAM(1'b0),
      .RSTREGARSTREG(1'b0),
      .WEA(4'b0),
      .DIADI({14'h0,cd[17:0]}),
      .DIPADIP(4'h0),
      .ADDRBWRADDR({2'b0,ca,6'd0}),
      .CLKBWRCLK(cc),
      .ENBWREN(cw),
      .REGCEB(1'b1),
      .RSTRAMB(1'b0),
      .RSTREGB(1'b0),
      .WEBWE(8'hFF),
      .DIBDI(32'h0),
      .DIPBDIP(4'h0));

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
