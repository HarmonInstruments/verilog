// Copyright (C) 2014-2018 Harmon Instruments, LLC
// SPDX-License-Identifier: GPL-3.0-or-later
// display serializer/deserializer

`timescale 1ns / 1ps

module display_host
  (
   input         c125,
   input         c250,
   input         sdi, // SDR
   output        sdo, // DDR
   output        clock_target, // 12.5 MHz
   // optional inversion of diff pairs
   input         invert_clock, invert_sdo, invert_sdi,
   // pixel data to display
   input         pixel_valid,
   output reg    pixel_ready = 0,
   input [15:0]  pixel_data,
   input         pixel_first, // indicates first pixel in frame
   // I2C
   input         sda_t, scl_t, // tristate
   output        sda_d, scl_d,
   // link status
   output        link_active,
   // pio data to / from display
   input         wvalid,
   input [3:0]   waddr,
   input [7:0]   wdata,
   output        fifostat,
   output [15:0] rdata
   );

   reg [11:0] 	    d = 0;
   reg 		    dv = 0;
   reg              dv_at_start = 0;
   reg [15:0]       tsr = 0;
   reg [6:0] 	    state = 0; // 0 - 99
   reg              ce_2x = 1'b0;
   reg [11:0]       csr = 0;

   wire             pixel_accept = (state[1:0] == 0) && (state[6:4] < 5) && pixel_valid;
   wire [31:0]      data_out = {17'h0000, sda_t, scl_t, dv_at_start, d};

   always @ (posedge c250)
     ce_2x <= ~ce_2x;

   always @ (posedge c125)
     begin
	if(wvalid) begin
	   d <= {waddr, wdata};
	   dv <= 1'b1;
	end
	else if(state == 0) begin
	   dv <= 1'b0;
	end

	state <= state == 99 ? 1'b0 : state + 1'b1;

	if(pixel_accept)
          tsr <= pixel_data;
	else
	  tsr[11:0] <= tsr[15:4];
        pixel_ready <= pixel_accept;

        if(state == 0)
          dv_at_start <= dv;

        if(state[1:0] == 0)
          begin
             if(state[6:2] == 24)
               begin
                  csr <= 12'hFFF; // frame sync
               end
             else
               begin
                  casex({data_out[state[6:2]],pixel_accept,pixel_first})
                    3'b00x: csr <= 12'h00F; // 0
                    3'b010: csr <= 12'h01F; // 1
                    3'b011: csr <= 12'h03F; // 2
                    3'b10x: csr <= 12'h07F; // 3
                    3'b110: csr <= 12'h0FF; // 4
                    3'b111: csr <= 12'h1FF; // 5
                  endcase
               end
          end
        else
          begin
             csr[11:0] <= {4'h0,csr[11:4]};
          end
     end

   out_4x out_d(.c(c125), .c2x(c250), .ce_2x(ce_2x), .i({4{invert_sdo}}^tsr[3:0]), .o(sdo));
   out_4x out_c(.c(c125), .c2x(c250), .ce_2x(ce_2x), .i({4{invert_clock}}^csr[3:0]), .o(clock_target));

   wire [2:0] srdata;

   display_rx rx(.c(c125), .c2x(c250), .r(state == 96), .i(sdi^invert_sdi),
                 .o({srdata, fifostat, sda_d, scl_d}));
   display_rx_rdata rx_rdata(.c(c125), .ce(state == 4), .i(srdata),
                             .active(link_active), .o(rdata));

endmodule

// input is 125 Mb/s async serial

module display_rx(input c, c2x, r, i, output reg [5:0] o = 0);

   wire [1:0] id0;
   IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), .SRTYPE("SYNC")) IDDR_i
     (.Q1(id0[0]), .Q2(id0[1]), .C(c2x), .CE(1'b1), .D(i), .R(1'b0), .S(1'b0));
   reg [3:0]  id1;
   always @ (posedge c2x)
     id1 <= {id0, id1[3:2]};
   reg [28:0] id2;
   reg        waiting = 0;
   always @ (posedge c)
     begin
        id2 <= {id1, id2[28:4]};
        if(r)
          waiting <= 1'b1;
        else if(id2[3:0] != 0)
          waiting <= 1'b0;
        if(waiting && (id2[3:0] != 0))
          begin
             case(id2[3:0])
               4'b1111: o <= {id2[25],id2[21],id2[17],id2[13],id2[9],id2[5]};
               4'b1110: o <= {id2[26],id2[22],id2[18],id2[14],id2[10],id2[6]};
               4'b1100: o <= {id2[27],id2[23],id2[19],id2[15],id2[11],id2[7]};
               4'b1000: o <= {id2[28],id2[24],id2[20],id2[16],id2[12],id2[8]};
             endcase
          end
     end
endmodule

module display_rx_rdata(input c, ce, input [2:0] i, output reg active = 0, output reg [15:0] o = 0);
   reg [15:0] sr;
   reg [6:0]  count_ce = 0;
   reg [3:0]  count_frame = 0;
   reg [1:0]  state_active = 0;

   always @ (posedge c)
     begin
        // verify i[2] is happening every 400 clocks and [11:8] == 0x5
        // count of clocks since valid ce and frame
        if(ce)
          begin
             count_ce <= 1'b0;
             count_frame <= i[2] ? 1'b0 : count_frame + 1'b1;
             if((count_ce != 99) || (i[2] && (count_frame != 7)))
               state_active <= 1'b0;
             else if(state_active != 3)
               state_active <= state_active + i[2];
          end
        else
          begin
             count_ce <= count_ce + 1'b1;
             if(count_ce > 99)
               state_active <= 1'b0;
          end
        active <= state_active == 3;

        if (ce)
          begin
             if(i[2])
               o <= sr;
             sr <= {i[1:0], sr[15:2]};
          end
     end
endmodule

// output 4 bits per c clock, LSB first
module out_4x(input c, c2x, ce_2x, input [3:0] i, output o);

   reg [3:0] i_1x;
   always @ (posedge c)
     begin
        i_1x <= i;
     end

   reg [3:0] i_2x = 0;
   reg [1:0] i_2x_2 = 0;
   always @ (posedge c2x)
     begin
        if(ce_2x)
          i_2x <= i_1x;
        i_2x_2 <= ce_2x ? i_2x[3:2] : i_2x[1:0];
     end

   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b1), .SRTYPE("ASYNC"))
   ODDR_d
     (
      .Q(o),
      .C(c2x),
      .CE(1'b1), // 1-bit clock enable input
      .D1(i_2x_2[0]), // positive edge
      .D2(i_2x_2[1]), // negative edge
      .R(1'b0), .S(1'b0));
endmodule

module out_1x(input c, c2x, ce_2x, input i, output o);

   reg  i_1x = 1;
   always @ (posedge c)
     begin
        i_1x <= i;
     end

   reg i_2x = 1;
   reg i_2x_2 = 1;
   always @ (posedge c2x)
     begin
        if(ce_2x)
          i_2x <= i_1x;
        i_2x_2 <= i_2x;
     end

   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"), .INIT(1'b1), .SRTYPE("ASYNC"))
   ODDR_d
     (
      .Q(o),
      .C(c2x),
      .CE(1'b1), // 1-bit clock enable input
      .D1(i_2x_2), // positive edge
      .D2(i_2x_2), // negative edge
      .R(1'b0), .S(1'b0));
endmodule
