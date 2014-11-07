`timescale 1ns / 1ps

module spi_24bit_wo
  (
   input 	clock,
   input 	write,
   input [23:0] din,
   output reg 	cs = 1'b1,
   output reg 	sck = 1'b0,
   output 	mosi
   );
   
   reg [7:0] 	state = 8'h0;
   reg [23:0] 	sreg = 24'h0;
   assign mosi = sreg[23];
   
   always @ (posedge clock)
     begin
	cs <= state == 0;
	sck <= state[2];
	if(write)
	  begin
	     sreg <= din;
	     state <= 1'b1;
	  end
	else if(state != 0) 
	  begin
	     if(state[2:0] == 0)
	       sreg <= {sreg[22:0], 1'b0};
	     if(state == 194)
	       state <= 8'h0;
	     else if(state[1:0] == 2)
	       state <= state + 2'd2;
	     else
	       state <= state + 1'b1;
	  end
     end  
endmodule
