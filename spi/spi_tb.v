`timescale 10ns / 1ns
/* SPI Interface CPOL=0, CPHA=0 or CPOL=1, CPHA=1 
 * Copyright 2005 Darrell Harmon
 * 
 */
module main;

   reg [15:0]   clkcycle;
   reg          clk;
   reg          mosi;
   reg          cs;
   wire [31:0]  dout;
   reg [31:0]   data;
   wire [15:0]  addr;
   initial 
     begin
        $dumpfile("spi.vcd");
        $dumpvars(0, main);
        clk = 0;
        cs = 1;
        clkcycle = 0;
        data = 32'hDEADBEEF;
        #5000 $finish;
     end
   always
     begin
     #5 clk = ~clk;
     end
   always @(negedge clk)
     begin
        clkcycle = clkcycle + 1;
        if(clkcycle > 7)
          begin
             #0.25 cs <= 1'b0;
             mosi <= data[31];
             data[31:1] <= data[30:0];
             data[0] <= data[31];
          end        
     end 
   spi32 spi32_0(mosi, clk, cs, dout, addr, w);
endmodule // main
