// Copyright (C) 2017 Harmon Instruments, LLC
// MIT License

`timescale 1ns / 1ps

// Synchronous clock domain crossing from 100 to 125 MHz via 50 MHz
// up to 100% enable on input
module cdc_100_125
  (
   input             c100, c125, c50,
   input [NB-1:0]    i, // c100
   input             iv, // c100
   output reg [NB-1:0] o,
   output reg  ov = 0);

   parameter integer NB=8;

   reg [NB-1:0] iprev;
   reg 		ivprev = 0;

   always @ (posedge c100)
     begin
	iprev <= i;
	ivprev <= iv;
     end

   reg [NB*2-1:0] i_50;
   reg [1:0] 	  iv_50 = 0;
   reg 		  t_50 = 0;

   always @ (posedge c50)
     begin
	t_50 <= ~t_50;
	i_50 <= {iprev, i};
	iv_50 <= {ivprev, iv};
     end

   reg tprev_125 = 0;
   wire v_125 = t_50 ^ tprev_125;
   reg vprev_125 = 0;

   always @ (posedge c125)
     begin
	tprev_125 <= t_50;
	vprev_125 <= v_125;
	ov <= (v_125 && iv_50[1]) || (vprev_125 && iv_50[0]);
	o <= (v_125) ? i_50[2*NB-1:NB] : i_50[NB-1:0];
     end

   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end


endmodule
