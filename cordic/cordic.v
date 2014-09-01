`timescale 1ns / 10ps
module addsub16s(in1, in2, out, sub, clk);
	input[15:0] in1, in2;
	output reg[15:0] out;
	input sub, clk;
	always @ (posedge clk)
	begin
		if(sub)
			out <= in1 - in2;
		else
			out <= in1 + in2;
	end
endmodule //addsub16s

module addsub18s(in1, in2, out, sub, clk);
	input[17:0] in1, in2;
	output reg[17:0] out;
	input sub, clk;
	always @ (posedge clk)
	begin
		if(sub)
			out <= in1 - in2;
		else
			out <= in1 + in2;
	end
endmodule //addsub18s

module cordic(iin, qin, iout, qout, ain, clk);
	input [17:0] ain;
	input [15:0] iin, qin;
	output [15:0] iout, qout;
	input clk;
	wire [15:0] i0, i1, i2, i3, i4, i5, i6, i7, i8;
	wire [15:0] i9, i10, i11, i12;
	wire [15:0] q0, q1, q2, q3, q4, q5, q6, q7, q8;
	wire [15:0] q9, q10, q11, q12;
	wire [17:0] a0, a1, a2, a3, a4, a5, a6, a7, a8;
	wire [17:0] a9, a10, a11;
	/* Stage 0 90 Degrees */
	addsub18s addsub18s1(ain, 65536, a0, ~ain[17] ,clk);
	addsub16s addsub16s1(0, qin, i0, ~ain[17] ,clk);
	addsub16s addsub16s2(0, iin, q0, ain[17] ,clk);
	/* Stage 1 45 Degrees */
	addsub18s addsub18s2(a0, 32768, a1, ~a0[17] ,clk);
	addsub16s addsub16s3(i0, q0, i1, ~a0[17] ,clk);
	addsub16s addsub16s4(q0, i0, q1, a0[17] ,clk);
	/* Stage 2 26.56 Degrees */
	addsub18s addsub18s3(a1, 19344, a2, ~a1[17] ,clk);
	addsub16s addsub16s5(i1, q1>>>1, i2, ~a1[17] ,clk);
	addsub16s addsub16s6(q1, i1>>>1, q2, a1[17] ,clk);
	/* Stage 3 14.03 Degrees */
	addsub18s addsub18s4(a2, 10221, a3, ~a2[17] ,clk);
	addsub16s addsub16s7(i2, q2>>>2, i3, ~a2[17] ,clk);
	addsub16s addsub16s8(q2, i2>>>2, q3, a2[17] ,clk);
	/* Stage 4 7.125 Degrees */
	addsub18s addsub18s5(a3, 5188, a4, ~a3[17] ,clk);
	addsub16s addsub16s9(i3, q3>>>3, i4, ~a3[17] ,clk);
	addsub16s addsub16s10(q3, i3>>>3, q4, a3[17] ,clk);
	/* Stage 5 3.57 Degrees */
	addsub18s addsub18s6(a4, 2604, a5, ~a4[17] ,clk);
	addsub16s addsub16s11(i4, q4>>>4, i5, ~a4[17] ,clk);
	addsub16s addsub16s12(q4, i4>>>4, q5, a4[17] ,clk);
	/* Stage 6 1.79 Degrees */
	addsub18s addsub18s7(a5, 1303, a6, ~a5[17] ,clk);
	addsub16s addsub16s13(i5, q5>>>5, i6, ~a5[17] ,clk);
	addsub16s addsub16s14(q5, i5>>>5, q6, a5[17] ,clk);
	/* Stage 7 0.895 Degrees */
	addsub18s addsub18s8(a6, 652, a7, ~a6[17] ,clk);
	addsub16s addsub16s15(i6, q6>>>6, i7, ~a6[17] ,clk);
	addsub16s addsub16s16(q6, i6>>>6, q7, a6[17] ,clk);
	/* Stage 8 0.448 Degrees */
	addsub18s addsub18s9(a7, 325, a8, ~a7[17] ,clk);
	addsub16s addsub16s17(i7, q7>>>7, i8, ~a7[17] ,clk);
	addsub16s addsub16s18(q7, i7>>>7, q8, a7[17] ,clk);
	/* Stage 9 0.224 Degrees */
	addsub18s addsub18s10(a8, 163, a9, ~a8[17] ,clk);
	addsub16s addsub16s19(i8, q8>>>8, i9, ~a8[17] ,clk);
	addsub16s addsub16s20(q8, i8>>>8, q9, a8[17] ,clk);
	/* Stage 10 0.112 Degrees */
	addsub18s addsub18s11(a9, 81, a10, ~a9[17] ,clk);
	addsub16s addsub16s21(i9, q9>>>9, i10, ~a9[17] ,clk);
	addsub16s addsub16s22(q9, i9>>>9, q10, a9[17] ,clk);
	/* Stage 11 0.056 Degrees */
	addsub18s addsub18s12(a10, 41, a11, ~a10[17] ,clk);
	addsub16s addsub16s23(i10, q10>>>10, i11, ~a10[17] ,clk);
	addsub16s addsub16s24(q10, i10>>>10, q11, a10[17] ,clk);
	/* Stage 12 0.028 Degrees */
	addsub16s addsub16s25(i11, q11>>>11, i12, ~a11[17] ,clk);
	addsub16s addsub16s26(q11, i11>>>11, q12, a11[17] ,clk);
	assign iout = i12;
	assign qout = q12;
endmodule //cordic

module main();
	reg clk = 0;
	reg [15:0] q = 0, i = 10000;
	reg [17:0] a = 0;
	wire [36:0] millidegreesk = (a - 13312)*360000;
	wire [18:0] millidegrees = millidegreesk>>>18;
	wire [15:0] qout, iout;
	always
		#6.25 clk = ~clk;
	initial
	begin
		$dumpvars;
		$dumpfile("tb.vcd");
		$dumpon;
		#10000 $dumpoff;
		#10000 $finish;
		$dumpall;
	end
	always @ (posedge clk)
		a <= a + 1024;
	cordic c0 (i, q, iout, qout, a, clk);	
endmodule
