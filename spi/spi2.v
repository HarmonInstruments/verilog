/*
SPI Interface for FPGA.

CPHA = 0 mode
CPOL = 0 
MSB first


*/

module spi(miso, mosi, dout, si, so, sck, cs);
	/* The SPI signals */
	input si, sck, cs;
	output reg so;
	/* Interface */
	output [15:0] miso;
	input [15:0] mosi;
	output reg begin_trans;
	/* Interal regs */
	reg [15:0] shiftin, shiftout;
	reg [3:0] bits;
	reg inst;
	/* Reset when selected */
	always @ (negedge cs)
	begin
		bitcount = 0;
	end
	/* Read data on rising edge of CLK */
	always @ (posedge sck)
	begin
		mosi[0] <=  si;
		mosi[15:1] <= mosi[14:0];		
	end
	/* Write data on falling edge of CLK */
	always @ (negedge sck)
	begin
		so <= miso[15];
		miso[15:1] <= miso[14:0];
		miso[0] <= 1'b1; 
	end
endmodule //spi