/* Copyright (C) 2015 Harmon Instruments, LLC
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

`timescale 1ns / 1ps

// FIR filter, decimate by 8, 64 taps, symmetric
module fir_decim_8
  (
   input 		    c, // 2 * input sample rate
   input 		    sel, // 0: 2.5 MHz BW, 1: 1.25 MHz BW
   input [N_CH*18-1:0] 	    id, // input data
   output reg [N_CH*18-1:0] od, // output data
   output reg 		    ov = 0 // new output sample available
   );

   parameter N_CH = 4; // must be a multiple of 4

   reg [17:0] 		    coef0 = 0, coef1 = 0;
   reg [5:0] 		    ra0 = 0, ra1 = 0, ra2 = 0, ra3 = 0;
   reg [22:0] 		    s = 0;
   reg [4:0] 		    state = 0;
   reg signed [17:0] 	    coefrom[63:0];
   reg [4:0] 		    coefa0 = 0, coefa1 = 0;
   reg [5:0] 		    wa = 0;
   reg 			    w = 0;
   wire 		    ce = 1'b1;
   wire [N_CH*18-1:0] 	    rd0, rd1, rd2, rd3; // s3

   always @ (posedge c) begin
      state <= state + 1'b1;
      s <= {s[21:0], (state[4:0] == 31)};
      ov <= s[5] | s[21];
      coef0 <= coefrom[{sel,coefa0}]; // s3
      coef1 <= coefrom[{sel,coefa1}];
      coefa0 <= s[1] ? 1'b0 : coefa0 + 1'b1; // s2
      coefa1 <= s[17] ? 1'b0 : coefa1 + 1'b1;
      ra0 <= s[0] ? wa : ra0 + 1'b1; // s1
      ra1 <= s[0] ? wa - 1'b1: ra1 - 1'b1;
      ra2 <= s[16] ? wa : ra2 + 1'b1;
      ra3 <= s[16] ? wa - 1'b1 : ra3 - 1'b1;
      w <= ~w;
      wa <= wa + w;
   end

   genvar j;
   generate
      for (j = 0; j < N_CH/4; j = j+1) begin: ram
	 wire [71:0] wd = id[71+j*72:j*72];
	 wire [8:0]  a = {3'd0, wa};
	 bram_72x512 br0 (.c(c), .w(w), .wa(a), .wd(wd), .r(ce), .ra({3'd0,ra0}), .rd(rd0[71+72*j:72*j]));
	 bram_72x512 br1 (.c(c), .w(w), .wa(a), .wd(wd), .r(ce), .ra({3'd0,ra1}), .rd(rd1[71+72*j:72*j]));
	 bram_72x512 br2 (.c(c), .w(w), .wa(a), .wd(wd), .r(ce), .ra({3'd0,ra2}), .rd(rd2[71+72*j:72*j]));
	 bram_72x512 br3 (.c(c), .w(w), .wa(a), .wd(wd), .r(ce), .ra({3'd0,ra3}), .rd(rd3[71+72*j:72*j]));
      end
   endgenerate

   generate
      for (j = 0; j < N_CH; j = j+1) begin: ch
	 wire [17:0] 	 d0 = rd0[17+j*18:j*18]; // s3
	 wire [17:0] 	 d1 = rd1[17+j*18:j*18];
	 wire [17:0] 	 d2 = rd2[17+j*18:j*18];
	 wire [17:0] 	 d3 = rd3[17+j*18:j*18];
	 wire [21:0] 	 dsp_o0, dsp_o1; // s7

	 dsp48_wrap_f #(.S(26), .AREG(1), .BREG(2), .USE_DPORT("TRUE")) mac0
	   (
	    .clock(c), .ce1(1'b1), .ce2(1'b1), .cem(1'b1), .cep(1'b1),
	    .a({d0[17], d0, 6'd0}),
	    .b(coef0),
	    .c(48'd262144), // convergent rounding
	    .d({d1[17], d1, 6'd0}),
	    .mode(s[5] ? 5'b01100 : 5'b01000),
	    .pcin(48'h0), .pcout(),
	    .p(dsp_o0));

	 dsp48_wrap_f #(.S(26), .AREG(1), .BREG(2), .USE_DPORT("TRUE")) mac1
	   (
	    .clock(c), .ce1(1'b1), .ce2(1'b1), .cem(1'b1), .cep(1'b1),
	    .a({d2[17], d2, 6'd0}),
	    .b(coef1),
	    .c(48'd262144), // convergent rounding
	    .d({d3[17], d3, 6'd0}),
	    .mode(s[21] ? 5'b01100 : 5'b01000),
	    .pcin(48'h0), .pcout(),
	    .p(dsp_o1));

	 always @ (posedge c) begin
	    if(s[6])
	      od[17+18*j:18*j] <= dsp_o0[17:0];
	    else if(s[22])
	      od[17+18*j:18*j] <= dsp_o1[17:0];
	 end
	 wire [17:0] mon = od[17+18*j:18*j];
      end
   endgenerate

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

   initial begin
      // 2.5 MHz
      coefrom[0] = -86;
      coefrom[1] = -185;
      coefrom[2] = -336;
      coefrom[3] = -509;
      coefrom[4] = -653;
      coefrom[5] = -694;
      coefrom[6] = -546;
      coefrom[7] = -129;
      coefrom[8] = 595;
      coefrom[9] = 1600;
      coefrom[10] = 2762;
      coefrom[11] = 3856;
      coefrom[12] = 4571;
      coefrom[13] = 4555;
      coefrom[14] = 3486;
      coefrom[15] = 1165;
      coefrom[16] = -2394;
      coefrom[17] = -6895;
      coefrom[18] = -11721;
      coefrom[19] = -15965;
      coefrom[20] = -18519;
      coefrom[21] = -18223;
      coefrom[22] = -14060;
      coefrom[23] = -5356;
      coefrom[24] = 8041;
      coefrom[25] = 25657;
      coefrom[26] = 46358;
      coefrom[27] = 68446;
      coefrom[28] = 89847;
      coefrom[29] = 108369;
      coefrom[30] = 122010;
      coefrom[31] = 129243;
      // 1.25 MHz
      coefrom[32] = -10;
      coefrom[33] = -31;
      coefrom[34] = -69;
      coefrom[35] = -122;
      coefrom[36] = -179;
      coefrom[37] = -210;
      coefrom[38] = -174;
      coefrom[39] = -20;
      coefrom[40] = 298;
      coefrom[41] = 797;
      coefrom[42] = 1440;
      coefrom[43] = 2117;
      coefrom[44] = 2634;
      coefrom[45] = 2733;
      coefrom[46] = 2131;
      coefrom[47] = 597;
      coefrom[48] = -1966;
      coefrom[49] = -5428;
      coefrom[50] = -9367;
      coefrom[51] = -13050;
      coefrom[52] = -15482;
      coefrom[53] = -15528;
      coefrom[54] = -12097;
      coefrom[55] = -4359;
      coefrom[56] = 8036;
      coefrom[57] = 24805;
      coefrom[58] = 44952;
      coefrom[59] = 66831;
      coefrom[60] = 88324;
      coefrom[61] = 107122;
      coefrom[62] = 121068;
      coefrom[63] = 128495;
   end

endmodule
