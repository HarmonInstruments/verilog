/*
 * Copyright (C) 2015-2016 Harmon Instruments, LLC
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

//
module halfband_decim
  (
   input 	    c,
   input [17:0]     tap,
   input [NDSP-1:0] load_tap,
   input [23:0]     id0, // input data n
   input [23:0]     id1, // input data n+1
   output [23:0]    od
   );

   parameter integer NCH = 4; // number of channels to process, clock is NCH*OSR
   parameter integer NDSP = 3; // number of DSP blocks to use, = ((NTAPS-1 / 2) + 1)/2

   wire signed [47:0] pcout [0:NDSP-1];
   wire signed [47:0] p [0:NDSP-1];
   wire signed [23:0] a [0:NDSP-1];
   wire signed [23:0] d [0:NDSP-1];
   assign a[0] = id0;
   reg [23:0] 	      odr = 0;
   assign od = odr;

   wire [23:0] 	      center_data;
   delay #(.NB(24), .DEL(1+2+NDSP * (NCH))) cdelay(.c(c), .i(id1), .o(center_data));

   genvar 	      i;
   generate
      for(i=0; i<NDSP; i=i+1) begin: dsp
	 DSP48E1 #(.USE_DPORT("TRUE"), .ADREG(1), .AREG(2), .BREG(1), .CREG(1), .DREG(1), .OPMODEREG(1))
	 dsp48_i
	    (
	     // status
	     .OVERFLOW(), .PATTERNDETECT(), .PATTERNBDETECT(), .UNDERFLOW(),
	     // outs
	     .CARRYOUT(),
	     .P(p[i]),
	     // control
	     .ALUMODE(4'd0),
	     .CARRYINSEL(3'd0),
	     .CLK(c),
	     .INMODE(5'b00100),
	     .OPMODE(i==0 ? 7'b0110101 : 7'b0010101), // if i==0: P + C+(A+D)*B else PCIN instead of C
	     // signal inputs
	     .A({5'd0, a[i][23], a[i]}), // 30
	     .B(tap), // 18
	     .C(i==0 ? {4'h0, center_data, 20'h80000} : 48'h0), // 48
	     .D({d[i][23], d[i]}), // 25
	     .CARRYIN(1'b0),
	     // cascade ports
	     .ACOUT(), .BCOUT(), .CARRYCASCOUT(), .MULTSIGNOUT(), .PCOUT(pcout[i]),
	     .ACIN(30'h0), .BCIN(18'h0), .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0),
	     .PCIN(i==0 ? 48'h0 : pcout[i-1]),
	     // clock enables
	     .CEA1(1'b1), .CEA2(1'b1), .CEAD(1'b1), .CEALUMODE(1'b1),
	     .CEB1(load_tap[i]), .CEB2(load_tap[i]), .CEC(1'b1),
	     .CECARRYIN(1'b1), .CECTRL(1'b1), // opmode
	     .CED(1'b1), .CEINMODE(1'b1), .CEM(1'b1), .CEP(1'b1),
	     .RSTA(1'b0), .RSTALLCARRYIN(1'b0), .RSTALUMODE(1'b0),
	     .RSTB(1'b0), .RSTC(1'b0), .RSTCTRL(1'b0), .RSTD(1'b0), .RSTINMODE(1'b0), .RSTM(1'b0), .RSTP(1'b0)
	     );
	 if(i!=0)
	   delay #(.NB(24), .DEL(1+NCH)) del_a(.c(c), .i(a[i-1]), .o(a[i]));
	 if(i==(NDSP-1))
	   delay #(.NB(24), .DEL(1+NCH)) del_d(.c(c), .i(a[NDSP-1]), .o(d[i]));
	 else
	   delay #(.NB(24), .DEL(NCH-1)) del_d(.c(c), .i(d[i+1]), .o(d[i]));
      end
   endgenerate

   always @ (posedge c) begin
      odr <= p[NDSP-1][43:20];
   end

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule

// i0 and i1 are each two TDM channels
// o0 is even samples
module halfband_reorder(input c, s, input [23:0] i0, i1, output reg [23:0] o0, o1);
   parameter N = 2; // number of input TDM channels
   wire [23:0] i0d2, i1d2, i1d4;
   delay #(.NB(24), .DEL(N)) delay_1(.c(c), .i(i0), .o(i0d2));
   delay #(.NB(24), .DEL(N)) delay_2(.c(c), .i(i1), .o(i1d2));
   delay #(.NB(24), .DEL(N*2)) delay_3(.c(c), .i(i1), .o(i1d4));
   o0 <= s ? i1d4 : i0d2;
   o1 <= s ? i1d2 : i0;
endmodule

module halfband_8ch_decim4(input c, input[1:0] sync, input [23:0] i0, i1, i2, i3, output [23:0] o);
   wire [23:0] i0r, i1r, i2r, i3r, fo0, fo1, fo0r, fo1r;
   reg 	       sr1, sr2;
   reg [2:0]   count;
   always @ (posedge c)
     begin
	count <= sync ? 1'b0 : count + 1'b1;
	case(count)
	  0: {sr1, sr2} <= 2'b00;
	  1: {sr1, sr2} <= 2'b00;
	  2: {sr1, sr2} <= 2'b10;
	  3: {sr1, sr2} <= 2'b10;
	  4: {sr1, sr2} <= 2'b01;
	  5: {sr1, sr2} <= 2'b01;
	  6: {sr1, sr2} <= 2'b11;
	  7: {sr1, sr2} <= 2'b11;
	endcase
     end
   halfband_reorder #(.N(2)) reorder0(.c(c), .s(sr1), .i0(i0), .i1(i1), .o0(i0r), .o1(i1r));
   halfband_reorder #(.N(2)) reorder1(.c(c), .s(sr1), .i0(i2), .i1(i3), .o0(i2r), .o1(i3r));
   halfband_decim #(.NDSP(3)) decim0(.c(c), .tap(tap), .load_tap(lt[2:0]), .id0(i0r), .id1(i1r), .od(fo0));
   halfband_decim #(.NDSP(3)) decim1(.c(c), .tap(tap), .load_tap(lt[2:0]), .id0(i2r), .id1(i2r), .od(fo1));
   halfband_reorder #(.N(4)) reorder1(.c(c), .s(sr2), .i0(fo0), .i1(fo1), .o0(fo0r), .o1(fo1r));
   halfband_decim #(.NDSP(3)) decim1(.c(c), .tap(tap), .load_tap(lt[5:3]), .id0(fo0r), .id1(fo1r), .od(o));
endmodule

module delay (input c, input [NB-1:0] i, output [NB-1:0] o);
   parameter integer NB = 1;
   parameter integer DEL = 2;
   genvar 	     j;
   generate
      if(DEL > 1) begin
	for(j=0; j<NB; j=j+1) begin: dbit
	   reg [DEL-1:0] dreg = 0;
	   always @ (posedge c)
	     dreg <= {dreg[DEL-2:0], i[j]};
	   assign o[j] = dreg[DEL-1];
	end
      end
      else if(DEL == 1) begin
	 reg [NB-1:0] oq;
	 always @ (posedge c)
	   oq <= i;
	 assign o = oq;
      end
      else begin
	 assign o = i;
      end
   endgenerate
endmodule