// Copyright (C) 2014-2018 Harmon Instruments, LLC
// SPDX-License-Identifier: GPL-3.0-or-later
// display serializer/deserializer

`timescale 1ns / 1ps

module display_test
  (input            c125, c250, reset);
   wire 	    sdi, sdo;
   wire 	    clock_target;
   reg              c250_target = 0;
   reg              c125_target = 0;

   display_target display_target
     (.c125(c125_target),
      .c250(c250_target), // in application, these two are PLL derived from clock_target
      .reset(reset),
      .clock(clock_target),
      .sdi(sdi),
      .sdo(sdo),
      .wvalid(),
      .addr(),
      .wdata(),
      .rdata()
      );

   display_host display_host
     (.c125(c125),
      .c250(c250),
      .invert_clock(1'b0),
      .invert_sdo(1'b0),
      .invert_sdi(1'b0),
      .clock_target(clock_target),
      .sdi(sdo),
      .sdo(sdi)
      );

   always @ *
     c250_target <= #1 c250;

   always @ (posedge c250_target)
     c125_target <= ~c125_target;


   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end

   glbl glbl();
   GSR_Lattice GSR_INST();
   PUR_Lattice PUR_INST();

endmodule

// for Xilinx
module glbl();
   reg GSR = 1'b1;
   wire GTS = 1'b0;
   initial
     GSR <= #0.01 1'b0;
endmodule

module GSR_Lattice();
   reg GSRNET = 1'b0;
   initial
     GSRNET <= #0.01 1'b1;
endmodule

module PUR_Lattice();
   reg PURNET = 1'b0;
   initial
     PURNET <= #0.01 1'b1;
endmodule
