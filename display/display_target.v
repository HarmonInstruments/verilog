// Copyright (C) 2014-2018 Harmon Instruments, LLC
// SPDX-License-Identifier: GPL-3.0-or-later
// display serializer/deserializer

`timescale 1ns / 1ps

module display_target
  (
   input             c125, c250, // PLL derived from clock
   input             reset,
   input             clock, // clock provided by host, 31.25 MHz
   input             sdi, // data from host
   output reg        sdo, // dat to host
   // display
   output reg        pixel_valid = 0,
   output reg        pixel_start_of_frame = 0,
   output reg [15:0] pixel_data = 0,
   // I2C
   output reg        sda_t = 1,
   output reg        scl_t = 1,
   input             sda_d, scl_d,
   input             fifostat,
   output [3:0]      ic,
   // local bus
   output reg        wvalid = 0,
   output reg [3:0]  addr,
   output reg [7:0]  wdata,
   input [15:0]      rdata // return data,
   );

   reg [15:0]        rsr = 0;
   reg [11:0]        tsr = 0;
   reg [6:0]         state = 0;
   reg               td = 0;

   wire [3:0]        id;
   reg [18:0]        sric = 0;
   reg [17:0]        srid = 0;
   reg               iv1 = 0;
   reg [15:0]        ic1 = 0;
   reg [15:0]        id1 = 0;
   reg               ic2_dbit = 0; // 3, 4 or 5 bits high
   reg               ic2_frame = 0; // 8 bits high

   wire [2:0]        rdata_tx_o;

   always @ (posedge c125)
     begin
	tsr <= (state == 74) ? {rdata_tx_o, fifostat, sda_d, scl_d, 6'b100000} :
               {1'b0, tsr[11:1]};
        sdo <= tsr[0];

        state <= ic2_frame ? 1'b0 : state + 1'b1;

        sric <= {ic, sric[18:4]};
        srid <= {id, srid[17:4]};

        iv1 <= (sric[3:2] == 2'b10) || (sric[1:0] == 2'b10);
        ic2_frame <= iv1 && (ic1 == 16'h0FFF);

        if(sric[3:2] == 2'b10)
          begin
             ic1 <= sric[18:3];
             id1 <= srid[17:2];
          end
        else if(sric[1:0] == 2'b10)
          begin
             ic1 <= sric[16:1];
             id1 <= srid[15:0];
          end
        pixel_data <= id1;
        pixel_start_of_frame <= (ic1[11:4] == 8'b00000011) || (ic1[11:4] == 8'b00011111);
        pixel_valid <= (state[1:0] == 2) &&
                       ((ic1[11:4] == 8'b00000001) || (ic1[11:4] == 8'b00000011) ||
                        (ic1[11:4] == 8'b00001111) || (ic1[11:4] == 8'b00011111));
        ic2_dbit <= (ic1[11:9] == 3'b000) && (ic1 [6:4] == 3'b111);

        if(state[1:0] == 3)
          rsr <= {ic2_dbit,rsr[15:1]};

        wvalid <= (state == 67) && rsr[12];

        if(state == 67)
          {addr,wdata} <= rsr[11:0];
        if(state == 60)
          {sda_t, scl_t} <= rsr[15:14];
     end

   IDDRX2F IDDRd
     (
      .D(sdi), // in from host
      .SCLK(c125), // div 2 of eclk
      .ECLK(c250), // fast clock
      .RST(reset),
      .ALIGNWD(1'b0),
      .Q0(id[0]), .Q1(id[1]), .Q2(id[2]), .Q3(id[3]));

   IDDRX2F IDDRc
     (
      .D(clock), // in from pin
      .SCLK(c125), // div 2 of eclk
      .ECLK(c250), // fast clock
      .RST(reset),
      .ALIGNWD(1'b0),
      .Q0(ic[0]), .Q1(ic[1]), .Q2(ic[2]), .Q3(ic[3]));

   display_rdata_tx rdata_tx(.c(c125), .ce(state == 70), .d(rdata), .o(rdata_tx_o));

endmodule

module display_rdata_tx(input c, ce, input[15:0] d, output [2:0] o);
   reg [15:0] sr = 0;
   reg [2:0]  state = 0;

   always @ (posedge c)
     begin
        if(ce)
          begin
             state <= state + 1'b1;
             sr <= (state == 0) ? d : {2'b00, sr[15:2]};
          end
     end

   assign o[2] = (state == 1);
   assign o[1:0] = sr[1:0];

endmodule
