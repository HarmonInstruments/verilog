/*
 * Copyright (C) 2014-2017 Harmon Instruments, LLC
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
 * remote IO
 *
 */

`timescale 1ns / 1ps

module rio_test
  (input            clock);

   wire 	    sdio;
   wire 	    clock_target;

   rio_target rio_target
     (.clock(clock_target),
      .sdio(sdio),
      .wvalid(),
      .addr(),
      .wdata(),
      .rdata(8'h81),
      .odata(clock_target)
      );

   rio_host rio_host
     (.clock(clock),
      .clock_target(clock_target),
      .sdio(sdio));

   pullup(sdio);

   initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end

   glbl glbl();

endmodule

module glbl();
   reg GSR = 1'b1;
   wire GTS = 1'b0;
   initial
     GSR <= #0.01 1'b0;
endmodule
