`timescale 1ns / 1ps

//LFSR-22 22, 21, 8 outputs per clock
module lfsr_22_8(input c, ce, r, output [7:0] o);
   parameter integer startstate = 22'h1;
   reg [21:0]        lfsr = startstate;
   // lfsr <= {lfsr[0], lfsr[0] ^ lfsr[21], lfsr[20:1]}
   always @ (posedge c)
     begin
        if(r)
          lfsr <= startstate;
        else if(ce)
          lfsr <= {lfsr[7], lfsr[7:1]^lfsr[6:0], lfsr[21] ^ lfsr[0], lfsr[20:8]};
     end
   assign o = {lfsr[0], lfsr[1], lfsr[2], lfsr[3], lfsr[4], lfsr[5], lfsr[6], lfsr[7]};
endmodule
