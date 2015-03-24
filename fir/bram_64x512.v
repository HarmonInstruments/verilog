module bram_64x512 (
		    input 	  c, // clock
		    input [8:0]   wa,ra,
		    input [63:0]  wd,
		    input 	  w,
		    input 	  r,
		    output [63:0] rd);

   RAMB36E1 #(
	      .DOA_REG(1),.DOB_REG(1),
	      .RAM_MODE("SDP"),
	      .READ_WIDTH_A(72), .READ_WIDTH_B(0),
	      .WRITE_WIDTH_A(0), .WRITE_WIDTH_B(72),
	      .SIM_DEVICE("7SERIES"))
   RAMB36E1_inst
     (
      .CASCADEOUTA(), .CASCADEOUTB(),
      .DBITERR(), .ECCPARITY(), .RDADDRECC(), .SBITERR(),
      .DOADO(rd[31:0]),
      .DOPADOP(),
      .DOBDO(rd[63:32]),
      .DOPBDOP(),
      .CASCADEINA(1'b0), .CASCADEINB(1'b0),
      .INJECTDBITERR(1'b0), .INJECTSBITERR(1'b0),
      .ADDRARDADDR({1'b0, ra,6'd0}),
      .CLKARDCLK(c),
      .ENARDEN(r),
      .REGCEAREGCE(1'b1),
      .RSTRAMARSTRAM(1'b0),
      .RSTREGARSTREG(1'b0),
      .WEA(4'b0),
      .DIADI(wd[31:0]),
      .DIPADIP(4'h0),
      .ADDRBWRADDR({1'b0,wa,6'd0}),
      .CLKBWRCLK(c),
      .ENBWREN(w),
      .REGCEB(1'b1),
      .RSTRAMB(1'b0),
      .RSTREGB(1'b0),
      .WEBWE(8'hFF),
      .DIBDI(wd[63:32]),
      .DIPBDIP(4'h0));
endmodule

module bram_192x512 (
		    input 	   c, // clock
		    input [8:0]    wa,ra,
		    input [191:0]  wd,
		    input 	   w,
		    input 	   r,
		    output [191:0] rd);

   bram_64x512 bram_0(.c(c), .w(w), .wa(wa), .wd(wd[63:0]), .r(r), .ra(ra),
		      .rd(rd[63:0]));
   bram_64x512 bram_1(.c(c), .w(w), .wa(wa), .wd(wd[127:64]), .r(r), .ra(ra),
		      .rd(rd[127:64]));
   bram_64x512 bram_2(.c(c), .w(w), .wa(wa), .wd(wd[191:128]), .r(r), .ra(ra),
		      .rd(rd[191:128]));
endmodule
