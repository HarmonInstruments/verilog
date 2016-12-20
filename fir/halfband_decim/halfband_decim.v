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
   assign od = p[NDSP-1][40:17];

   wire [23:0] 	      center_data;
   delay #(.NB(24), .DEL(1+2+NDSP * (NCH))) cdelay(.c(c), .i(id1), .o(center_data));

   genvar 	      i;
   generate
      for(i=0; i<NDSP; i=i+1) begin: dsp
	 DSP48E1 #(
		   .A_INPUT("DIRECT"), .B_INPUT("DIRECT"), // "DIRECT" "CASCADE"
		   .USE_DPORT("TRUE"),
		   // register enables
		   .ADREG(1),      // pipeline stages for pre-adder (0 or 1)
		   .ALUMODEREG(1), // pipeline stages for ALUMODE (0 or 1)
		   .AREG(2),       // pipeline stages for A (0, 1 or 2)
		   .BCASCREG(1),   // pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
		   .BREG(1),       // pipeline stages for B (0, 1 or 2)
		   .CARRYINREG(1), // this and below are 0 or 1
		   .CARRYINSELREG(1),
		   .CREG(1), .DREG(1), .INMODEREG(1), .MREG(1), .OPMODEREG(1), .PREG(1))
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
	     .C(i==0 ? {center_data, 17'h10000} : 48'h0), // 48
	     .D({d[i][23], d[i]}), // 25
	     .CARRYIN(1'b0),
	     // cascade ports
	     .ACOUT(), .BCOUT(), .CARRYCASCOUT(), .MULTSIGNOUT(),
	     .PCOUT(pcout[i]),
	     .ACIN(30'h0),
	     .BCIN(18'h0),
	     .CARRYCASCIN(1'b0),
	     .MULTSIGNIN(1'b0),
	     .PCIN(i==0 ? 48'h0 : pcout[i-1]),
	     // clock enables
	     .CEA1(1'b1), .CEA2(1'b1), .CEAD(1'b1), .CEALUMODE(1'b1),
	     .CEB1(load_tap[i]), .CEB2(load_tap[i]), .CEC(1'b1),
	     .CECARRYIN(1'b1),
	     .CECTRL(1'b1), // opmode
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

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

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