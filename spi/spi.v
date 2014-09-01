`timescale 1ns / 1ps
/* SPI Interface CPOL=0, CPHA=0 or CPOL=1, CPHA=1 
 * Copyright 2005 Darrell Harmon
 * 
 */
module spi(miso, mosi, sck, cs, dout, din, drdy, firstword);
   output        miso;
   input         mosi;
   input         sck;
   input         cs;
   output [15:0] dout;
   reg [15:0]    dout;
   input [15:0]  din;
   output        drdy;
   reg           drdy;
   output        firstword;
   reg           firstword;
   reg [3:0]     bits;
   reg [15:0]    shiftin;
   reg [15:0]    shiftout;
   reg           firstbit;
   assign        miso = (cs == 1'b0) ? shiftout[15] : 1'bZ;
   always @(posedge sck)
     if(cs == 1'b0)
       begin
          shiftin[15:1] <= shiftin[14:0];
          shiftin[0] <= mosi;
          firstbit <= 1'b0;
          if(firstbit == 1'b1)
            begin
               bits <= 0;
               firstword <= 1'b1;
            end 
          else
            begin // not firstbit
               bits <= bits + 1;
               if(bits == 15)
                 begin
                    dout <= shiftin;
                    shiftout <= din;
                    drdy <= 1'b1;
                 end
               else
                 drdy <= 1'b0;
            end // not firstbit
          if(firstbit == 1'b0 && drdy == 1'b1)
            firstword <= 1'b0;
       end   
   always @(negedge sck)
     begin
        if(bits == 15)
          begin
             shiftout <= din;
          end
        else
          begin
             shiftout[15:1] <= shiftout[14:0];
             shiftout[0] <= 1'b0;
          end
     end
   always @(negedge cs)
     firstbit <= 1'b1;
endmodule // spi

/* spi_addr_16
 * 
 * SPI bus:
 * miso = serial data output from fpga
 * mosi = serial data input to fpga
 * sck = SPI clock
 * cs = SPI chip select
 * 
 * dout = data output from module: 16 bit bus, data is read MSB first from SPI
 * din = data input to module: 16 bit bus, data written MSB first to SPI
 * addr = 13 bit address of reg to read or write
 * 
 * r = read strobe, data to be read from addr should be placed
 * on din at the rising edge of this signal, and remain until
 * r rises again
 * 
 * w = write strobe, data to be stored at address addr
 * is availble on dout at the rising edge of this signal  
 */

module spi_addr_16(miso, mosi, sck, cs, dout, din, addr, r, w);
   wire           miso, mosi, sck, cs, dout, din, drdy_in, firstword, drdy;
   reg            prevdrdy, r, w, r_en, w_en, autoinc;
   reg [12:0]     addr;
   always @(posedge sck)
     begin
        prevdrdy <= drdy_in;
        if(drdy_in == 1'b1 && prevdrdy == 1'b0)
          begin // posedge drdy_in
             if(firstword == 1'b1)
               begin
                  addr[12:0] <= dout[12:0];
                  r_en <= dout[15];
                  w_en <= dout[14];
                  r <= dout[15];
                  w <= dout[14];
                  autoinc <= dout[13];
               end
             else 
               begin
                  if(autoinc == 1'b1)
                    addr = addr + 1;
                  r <= r_en;
                  w <= w_en;
               end
          end // if (drdy_in == 1'b1 && prevdrdy == 1'b0)
        else 
          begin
             r <= 1'b0;
             w <= 1'b0;
          end
     end
   spi spi1(miso, mosi, sck, cs, dout, din, drdy, firstword);
endmodule // spi_addr_16

