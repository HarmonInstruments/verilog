`timescale 1ns / 1ps

module lvds_tx(input c, output dp, dn, input v, input [31:0] d);
   parameter INV = 0;
   reg [1:0] 	od = 0;
   reg [32:0] 	sr = ~33'h0;

   oddr_lvds oddr_lvds_i(.c(c), .i(INV ? ~od : od), .dp(dp), .dn(dn));

   always @ (posedge c)
     begin
	sr <= v ? {1'b0, d} : {sr[30:0], 2'b11};
	od[0] <= sr[32];
	od[1] <= sr[31];
     end
endmodule

module lvds_rx(input c, dp, dn, output reg [55:0] d=0, output reg v=0);
   parameter INV = 0;
   wire [1:0] 	 id;
   reg [1:0] 	 id_buf;
   reg [4:0] 	 state = 0;
   reg [57:0] 	 sr = ~58'h0;
   reg 		 vp = 0;

   iddr_lvds iddr_lvds_i(.c(c), .o(id), .dp(dp), .dn(dn));

   always @ (posedge c)
     begin
	id_buf <= INV ? ~id : id;
	sr <= {sr[55:0], id_buf};
	state <= state == 0 ? (id_buf != 3) : state + 1'b1;
	vp <= (state == 28);
	if(vp)
	  d <= sr[57] ? sr[55:0] : sr[56:1];
	v <= vp;
     end
endmodule

module lvds_io
  (
   input 	     clock, clock_2x,
   input 	     sdip, sdin,
   output 	     sdop, sdon,
   output reg 	     wvalid = 0,
   output reg [55:0] wdata,
   input [31:0]      rdata
   );
   parameter TINV = 1'b0;
   parameter RINV = 1'b0;

   wire 	    rv;
   reg 		    tv = 0;
   wire [55:0] 	    rd;
   reg [31:0] 	    td;
   wire 	    rv_100;
   reg 		    rv_100_d = 0;

   lvds_rx #(.INV(RINV)) r(.c(clock_2x), .dp(sdip), .dn(sdin), .d(rd), .v(rv));
   lvds_tx #(.INV(TINV)) t(.c(clock_2x), .dp(sdop), .dn(sdon), .d(td), .v(tv));

   always @ (posedge clock_2x)
     begin
	if(rv)
	  begin
	     if(rd[55:48] == 0) // calibration
	       td <= rd[40] ? rd[31:0] : 32'h080FF010;
	     else
	       td <= rdata;
	  end
	tv <= rv;
     end

   always @ (posedge clock)
     begin
	wdata <= rd;
	rv_100_d <= rv_100;
	wvalid <= rv_100_d;
     end

   sync_pulse sync_rv(.ci(clock_2x), .i(tv), .co(clock), .o(rv_100));

endmodule
