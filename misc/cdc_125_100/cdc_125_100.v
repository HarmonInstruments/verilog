// Copyright (C) 2017 Harmon Instruments, LLC
// MIT License

`timescale 1ns / 1ps

// Synchronous clock domain crossing from 125 to 100 MHz via 50 MHz
// 1 enable at a time with 2 not enabled input cycles between
module cdc_125_100
  (
   input             c100, c125, c50,
   input [NB-1:0]    i, // c100
   input             iv, // c100
   output reg [NB-1:0] o,
   output reg  ov = 0);

   parameter integer NB=8;

   reg [NB-1:0] i_125;
   reg 		ivtog_125 = 0; // toggles to indicate a new sample in i_125

   always @ (posedge c125)
     begin
	if(iv)
	  begin
	     ivtog_125 <= ~ivtog_125;
	     i_125 <= i;
	  end
     end

   reg [NB-1:0] i_50;
   reg 		t_50 = 0;

   always @ (posedge c50)
     begin
	t_50 <= ivtog_125;
	i_50 <= i_125;
     end

   reg tprev_100 = 0;
   wire v_100 = t_50 ^ tprev_100;

   always @ (posedge c100)
     begin
	tprev_100 <= t_50;
	ov <= v_100;
	if(v_100)
	  o <= i_50;
     end

   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end


endmodule
