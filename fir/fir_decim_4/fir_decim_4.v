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

// 4 channel filter, decimate by 4, 0 to 0.05 input FS
// clock is 4 * FS
module fir_decim_4
  (
   input 	 c,
   input 	 sel,
   input [7:0] 	 state,
   input [17:0]  id, // input data time multiplexed
   output [71:0] od, // output data, not time multiplexed
   output 	 ov
   );

   wire signed [17:0] coef;
   wire [5:0] 	      ra0, ra1;
   wire [3:0] 	      coefa;
   wire 	      r;
   wire [4:0] 	      s;

   fir_decim_4_common common (.c(c),
			      .sel(sel),
			      .state(state[7:0]),
			      .ov(ov),
			      .coef(coef),
			      .ra0(ra0),
			      .ra1(ra1),
			      .r(r),
			      .s(s));

   fir_decim_4_channel channel(.c(c),
			       .state(state[7:0]),
			       .id(id),
			       .od(od),
			       .coef(coef),
			       .ra0(ra0),
			       .ra1(ra1),
			       .r(r),
			       .s(s));

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule

// commmon elements to be shared among channels
module fir_decim_4_common
  (
   input 	     c,
   input 	     sel,
   input [7:0] 	     state,
   output reg 	     ov = 0,
   output reg [17:0] coef = 0,
   output reg [5:0]  ra0 = 0,
   output reg [5:0]  ra1 = 0,
   output reg 	     r = 0,
   output reg [4:0]  s = 0
   );

   reg signed [17:0]  coefrom[31:0];
   reg [3:0] 	      coefa = 0;

   always @ (posedge c) begin
      s <= {s[3:0], (state[3:0] == 15)};
      ov <= r;
      r <= s[4];
      coef <= coefrom[{sel,coefa}];
      coefa <= state[3:0] - 1'b1;
      ra0 <= s[0] ? state[7:2] - 1'b1: ra0 - 1'b1;
      ra1 <= s[0] ? state[7:2] - 6'd32 : ra1 + 1'b1;
   end

   initial begin
      // 5 MHz
      coefrom[0] = -134;
      coefrom[1] = -436;
      coefrom[2] = -701;
      coefrom[3] = -367;
      coefrom[4] = 1100;
      coefrom[5] = 3375;
      coefrom[6] = 4693;
      coefrom[7] = 2457;
      coefrom[8] = -4629;
      coefrom[9] = -14048;
      coefrom[10] = -18805;
      coefrom[11] = -10233;
      coefrom[12] = 16479;
      coefrom[13] = 57414;
      coefrom[14] = 99576;
      coefrom[15] = 126402;
      // 4 MHz
      coefrom[16] = -39;
      coefrom[17] = -167;
      coefrom[18] = -333;
      coefrom[19] = -236;
      coefrom[20] = 577;
      coefrom[21] = 2146;
      coefrom[22] = 3375;
      coefrom[23] = 2064;
      coefrom[24] = -3498;
      coefrom[25] = -11889;
      coefrom[26] = -16993;
      coefrom[27] = -9948;
      coefrom[28] = 15273;
      coefrom[29] = 55919;
      coefrom[30] = 99015;
      coefrom[31] = 126877;
   end

endmodule

// 4 channel filter, decimate by 4, 0 to 0.05 input FS
// clock is 4 * FS
module fir_decim_4_channel
  (
   input 	       c,
   input [7:0] 	       state,
   input [17:0]        id, // input data time multiplexed
   output [71:0]       od, // output data, not time multiplexed
   input signed [17:0] coef,
   input signed [5:0]  ra0, ra1,
   input 	       r,
   input [4:0] 	       s
   );

   wire [143:0]       rd; // read data from RAM

   genvar 	      i;
   generate
      for (i = 0; i < 4; i = i+1) begin: maci
	 wire [36:0] dsp_o;
	 assign od[17+18*i:18*i] = dsp_o[36:19];
	 wire [17:0] po = dsp_o[36:19];
	 dsp48_wrap #(.NBA(18),
		      .NBB(18),
		      .NBP(37),
		      .S(0),
		      .AREG(1),
		      .BREG(2),
		      .USE_DPORT("TRUE")) macn
	       (
	        .clock(c),
	        .ce1(1'b1),
	        .ce2(1'b1),
	        .cem(1'b1),
	        .cep(1'b1),
	        .a(rd[17+18*i:18*i]),
	        .b(coef),
	        .c(19'd262144), // convergent rounding
	        .d(rd[72+17+18*i:72+18*i]),
	        .mode(r ? 5'b01100 : 5'b01000),
	        .acin(30'h0),
	        .bcin(18'h0),
	        .pcin(48'h0),
	        .acout(),
	        .bcout(),
	        .pcout(),
	        .p(dsp_o));
      end
   endgenerate

   generate
      for (i = 0; i < 2; i = i+1) begin: rami
	 wire [71:0] rdi;
	 assign rd[71+72*i:72*i] = rdi;
	 RAMB36E1 #(
	            .DOA_REG(1),.DOB_REG(1),
	            .RAM_MODE("SDP"),
	            .READ_WIDTH_A(72), .READ_WIDTH_B(0),
	            .WRITE_WIDTH_A(0), .WRITE_WIDTH_B(18),
	            .SIM_DEVICE("7SERIES"))
	 RAMB36E1_inst
	       (
	        .CASCADEOUTA(), .CASCADEOUTB(),
	        .DBITERR(), .ECCPARITY(), .RDADDRECC(), .SBITERR(),
	        .DOADO({rdi[33:18], rdi[15:0]}),
	        .DOPADOP({rdi[35:34], rdi[17:16]}),
	        .DOBDO({rdi[69:54], rdi[51:36]}),
	        .DOPBDOP({rdi[71:70], rdi[53:52]}),
	        .CASCADEINA(1'b0), .CASCADEINB(1'b0),
	        .INJECTDBITERR(1'b0), .INJECTSBITERR(1'b0),
	        .ADDRARDADDR({4'b0, (i==0 ? ra0 : ra1), 6'd0}),
	        .CLKARDCLK(c),
	        .ENARDEN(1'b1),
	        .REGCEAREGCE(1'b1),
	        .RSTRAMARSTRAM(1'b0),
	        .RSTREGARSTREG(1'b0),
	        .WEA(4'b0),
	        .DIADI(32'h0),
	        .DIPADIP(4'h0),
	        .ADDRBWRADDR({4'b0,state,4'd0}),
	        .CLKBWRCLK(c),
	        .ENBWREN(1'b1),
	        .REGCEB(1'b1),
	        .RSTRAMB(1'b0),
	        .RSTREGB(1'b0),
	        .WEBWE(8'hFF),
	        .DIBDI({16'h0,id[15:0]}),
		.DIPBDIP({2'h0,id[17:16]}));
      end
   endgenerate

endmodule
