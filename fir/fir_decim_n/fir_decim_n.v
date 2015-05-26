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
   input 		c,
   input [N_CH*18-1:0] 	id, // input data
   input [31:0] 	cd, // coef data [17:0] is data, [31:24] is index, set l2n: 0x40000 | l2n
   input 		cw, // coef write
   output [N_CH*24-1:0] od,
   output 		ov
   );

   parameter N_CH = 4;

   reg [17:0] 		coef = 0;
   reg [8:0] 		wa = 0;
   reg [8:0] 		ra0 = 0;
   reg [8:0] 		ra1 = 0;
   reg [7:0] 		state = 0;
   reg 			w = 0;
   reg [6:0] 		s = 0; // state is 0 when bit 0, ...
   reg [1:0] 		l2n = 0; // log2 (rate)

   wire [71:0] 		coef_p;
   wire [7:0] 		mask;
   wire [N_CH*18-1:0] 	rd0, rd1; // read data from RAM

   assign mask[7] = (l2n > 2);
   assign mask[6] = (l2n > 1);
   assign mask[5] = (l2n > 0);
   assign mask[4:0] = 5'h1F;
   assign ov = s[6];

   always @ (posedge c) begin
      coef <= coef_p[17:0];
      state <= (state + 1'b1) & mask;
      w <= state[3:0] == 1;
      wa <= wa + w;
      s <= {s[5:0],(state == mask)};
      ra0 <= s[0] ? wa - ({mask,1'b1} + 1'b1) : ra0 + 1'b1;
      ra1 <= s[0] ? wa - 1'b1 : ra1 - 1'b1;
      if(cw && cd[18])
	l2n <= cd[1:0];
   end

   // FIXME this fits a RAMB18
   bram_72x512 bram_c(.c(c),
		      .w(cw & ~cd[18]), .wa({1'b0,cd[31:24]}), .wd({54'h0,cd[17:0]}),
		      .r(1'b1), .ra({1'b0,state}), .rd(coef_p));

   genvar j;
   generate
      for (j = 0; j < N_CH/4; j = j+1) begin: ch
	 wire [71:0] c_id = id[71+j*72:j*72];
	 bram_72x512 bram_0(.c(c), .w(w), .wa(wa), .wd(c_id), .r(1'b1), .ra(ra0), .rd(rd0[71+j*72:j*72]));
	 bram_72x512 bram_1(.c(c), .w(w), .wa(wa), .wd(c_id), .r(1'b1), .ra(ra1), .rd(rd1[71+j*72:j*72]));
      end
   endgenerate

   genvar i;
   generate
      for (i = 0; i < N_CH; i = i+1) begin: mac
	 wire [29:0] dsp_o;
	 assign od[23+24*i:24*i] = dsp_o[23:0];
	 dsp48_wrap_f #(.S(18), .AREG(1), .BREG(2), .USE_DPORT("TRUE")) mac
	   (
	    .clock(c), .ce1(1'b1), .ce2(1'b1), .cem(1'b1), .cep(1'b1),
	    .a({rd0[17+18*i], rd0[17+18*i:18*i], 6'd0}),
	    .b(coef),
	    .c(48'd131072), // convergent rounding
	    .d({rd1[17+18*i], rd1[17+18*i:18*i], 6'd0}),
	    .mode(s[5] ? 5'b01100 : 5'b01000),
	    .pcin(48'h0),
	    .pcout(),
	    .p(dsp_o));
      end
   endgenerate

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
     end

endmodule
