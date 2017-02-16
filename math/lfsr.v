`timescale 1ns / 1ps

//LFSR-63 63, 62
module lfsr_32(input c, output [31:0] o);
   parameter integer startstate = 32'hDEADBEEF;
   reg [62:0] 	     lfsr = startstate;
   // lfsr <= lfsr[0], lfsr[0] ^ lfsr[62], lfsr[61:1]
   always @ (posedge c)
     begin
	lfsr <= {lfsr[31], lfsr[31:1]^lfsr[30:0], lfsr[62] ^ lfsr[0], lfsr[61:32]};
     end
   assign o = lfsr[31:0];
endmodule
