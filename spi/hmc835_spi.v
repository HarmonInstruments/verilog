`timescale 1ns / 1ps

module hmc835_spi
  (
   input 	     clock,
   input 	     write,
   input [31:0]      din,
   output reg [31:0] dout = 32'h0,
   output reg 	     busy = 1'b0,
   output reg 	     cs = 1'b1,
   output reg 	     sck = 1'b1,
   output reg 	     mosi = 1'b0,
   input 	     miso
   );
   reg [6:0] 	     state = 7'h0;
   reg [31:0] 	     sreg = 32'h0;
   
   always @ (posedge clock)
     begin
	busy <= write | (state != 0);
	sck <= ~state[0] | state[6];
	cs <= ~(state[5] | state[6]);
	mosi <= sreg[31];
	if(write)
	  sreg <= din[31:0];
	else if(~state[0] & ~state[6])
	  sreg <= {sreg[30:0],miso};
	
	if(write)
	  state <= 1'b1;
	else if(state == 68)
	  state <= 1'b0;
	else if(state != 0)
	  state <= state + 1'b1;
     end
  
endmodule // hmc835_spi
