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

// 4 channel filter, decimate by 2 to 16
// number of taps is 32*decim rate
// clock is 16 * FS in
module fir_decim_n
  (
   input 	 c,
   input [7:0] 	 state_ext,
   input [1:0] 	 l2n, // log2 (rate)
   input [71:0]  id, // input data
   input [17:0]  cd, // coef data
   input [7:0] 	 ca, // coef address
   input 	 cw, // coef write
   output [95:0] od,
   output 	 ov
   );

   wire [71:0] 	  coef;
   wire [8:0] 	  wa, ra0, ra1;
   wire [7:0] 	  state;
   wire 	  r, w;
   wire [6:0] 	  s; // state is 0 when bit 0, ...

   fir_decim_n_common common
     (.c(c),
      .state_ext(state_ext),
      .l2n(l2n),
      .cd(cd),
      .ca(ca),
      .cw(cw),
      .ov(ov),
      .wa(wa),
      .ra0(ra0),
      .ra1(ra1),
      .state(state),
      .w(w),
      .s(s),
      .coef(coef));

   fir_decim_n_channel channel
     (.c(c),
      .id(id),
      .od(od),
      .wa(wa),
      .ra0(ra0),
      .ra1(ra1),
      .state(state),
      .w(w),
      .s(s),
      .coef(coef[17:0]));

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule

// common logic for multi channel
module fir_decim_n_common
  (
   input 	    c,
   input [7:0] 	    state_ext,
   input [1:0] 	    l2n, // log2 (rate)
   input [17:0]     cd, // coef data
   input [7:0] 	    ca, // coef address
   input 	    cw, // coef write
   output 	    ov,
   output reg [8:0] wa = 0,
   output reg [8:0] ra0 = 0,
   output reg [8:0] ra1 = 0,
   output reg [7:0] state = 0,
   output reg 	    w = 0,
   output reg [6:0] s = 0, // state is 0 when bit 0, ...
   output [71:0]    coef
   );

   reg [7:0] 	  coefa = 0;
   wire [7:0] 	  mask;
   assign mask[7] = (l2n > 2);
   assign mask[6] = (l2n > 1);
   assign mask[5] = (l2n > 0);
   assign mask[4:0] = 5'h1F;
   assign ov = s[6];

   always @ (posedge c) begin
      state <= state_ext & mask;
      w <= state[3:0] == 1;
      wa <= wa + w;
      coefa <= state;
      s <= {s[5:0],(state == mask)};
      ra0 <= s[0] ? wa - ({mask,1'b1} + 1'b1) : ra0 + 1'b1;
      ra1 <= s[0] ? wa - 1'b1 : ra1 - 1'b1;
   end

   bram_72x512 bram_c(.c(c),
		      .w(cw), .wa({1'b0,ca}), .wd({cd,cd,cd,cd}),
		      .r(1'b1), .ra({1'b0,coefa}), .rd(coef));

endmodule

// 4 channel filter, decimate by 2 to 16
// number of taps is 32*decim rate
// clock is 16 * FS in
module fir_decim_n_channel
  (
   input 	 c,
   input [71:0]  id, // input data
   output [95:0] od,
   input [8:0] 	 wa, ra0, ra1,
   input [7:0] 	 state,
   input 	 w,
   input [6:0] 	 s,
   input [17:0]  coef
   );

   wire [71:0] 	 rd0, rd1; // read data from RAM
   wire 	 r = s[5];

   bram_72x512 bram_0(.c(c),
		      .w(w), .wa(wa), .wd(id),
		      .r(1'b1), .ra(ra0), .rd(rd0));
   bram_72x512 bram_1(.c(c),
		      .w(w), .wa(wa), .wd(id),
		      .r(1'b1), .ra(ra1), .rd(rd1));

   genvar 	 i;
   generate
      for (i = 0; i < 4; i = i+1) begin: mac
	 wire [29:0] dsp_o;
	 assign od[23+24*i:24*i] = dsp_o[23:0];
	 dsp48_wrap_f #(.S(18), .AREG(1), .BREG(2), .USE_DPORT("TRUE")) maci
	   (
	    .clock(c),
	    .ce1(1'b1),
	    .ce2(1'b1),
	    .cem(1'b1),
	    .cep(1'b1),
	    .a({rd0[17+18*i], rd0[17+18*i:18*i], 6'd0}),
	    .b(coef),
	    .c(48'd131072), // convergent rounding
	    .d({rd1[17+18*i], rd1[17+18*i:18*i], 6'd0}),
	    .mode(r ? 5'b01100 : 5'b01000),
	    .pcin(48'h0),
	    .pcout(),
	    .p(dsp_o));
      end
   endgenerate

endmodule

module bram_72x512
  (
   input 	 c, // clock
   input [8:0] 	 wa,ra,
   input [71:0]  wd,
   input 	 w,
   input 	 r,
   output [71:0] rd);

   RAMB36E1 #(
	      .DOA_REG(1),.DOB_REG(1),
	      .RAM_MODE("SDP"),
	      .READ_WIDTH_A(72), .READ_WIDTH_B(0),
	      .WRITE_WIDTH_A(0), .WRITE_WIDTH_B(72),
	      .SIM_DEVICE("7SERIES"))
   RAMB36E1_inst
     (
      .CASCADEOUTA(), .CASCADEOUTB(),
      .DBITERR(), .ECCPARITY(), .RDADDRECC(), .SBITERR(),
      .DOADO(rd[31:0]),
      .DOPADOP(rd[67:64]),
      .DOBDO(rd[63:32]),
      .DOPBDOP(rd[71:68]),
      .CASCADEINA(1'b0), .CASCADEINB(1'b0),
      .INJECTDBITERR(1'b0), .INJECTSBITERR(1'b0),
      .ADDRARDADDR({1'b0, ra,6'd0}),
      .CLKARDCLK(c),
      .ENARDEN(r),
      .REGCEAREGCE(1'b1),
      .RSTRAMARSTRAM(1'b0),
      .RSTREGARSTREG(1'b0),
      .WEA(4'b0),
      .DIADI(wd[31:0]),
      .DIPADIP(wd[67:64]),
      .ADDRBWRADDR({1'b0,wa,6'd0}),
      .CLKBWRCLK(c),
      .ENBWREN(w),
      .REGCEB(1'b1),
      .RSTRAMB(1'b0),
      .RSTREGB(1'b0),
      .WEBWE(8'hFF),
      .DIBDI(wd[63:32]),
      .DIPBDIP(wd[71:68]));
endmodule
