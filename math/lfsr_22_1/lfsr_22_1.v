`timescale 1ns / 1ps

//LFSR-22 22, 21, 1 output per clock
module lfsr_22_1(input c, ce, r, output o);
   parameter integer startstate = 22'h1;
   reg [21:0]        lfsr = startstate;
   always @ (posedge c)
     begin
        if(r)
          lfsr <= startstate;
        else if(ce)
          lfsr <= {lfsr[0], lfsr[21] ^ lfsr[0], lfsr[20:1]};
     end
   assign o = lfsr[0];
endmodule
