`timescale 1ns / 10ps
module addsub14s(in1, in2, out, sub, clk, cken);
   input[13:0] in1, in2;
   output      reg[13:0] out;
   input       sub, clk;
   always @ (posedge clk)
     if(cken == 1'b1)
       begin
          if(sub)
            out <= in1 - in2;
          else
            out <= in1 + in2;
       end
endmodule //addsub14s

module cordic_14(iin, qin, iout, qout, ain, clk, cken);
   input [13:0]    ain;
   input [13:0]    iin, qin;
   output [13:0]   iout, qout;
   input           clk, cken;
   wire [13:0]     i0, i1, i2, i3, i4, i5, i6, i7, i8;
   wire [13:0]     i9, i10, i11, i12, i13;
   wire [13:0]     q0, q1, q2, q3, q4, q5, q6, q7, q8;
   wire [13:0]     q9, q10, q11, q12, q13;
   wire [13:0]     a0, a1, a2, a3, a4, a5, a6, a7, a8;
   wire [13:0]     a9, a10, a11, a12;
   /* Stage 0 90 Degrees */
   addsub14s addsuba0(ain, 14'd4096, a0, ~ain[13], clk, cken);
   addsub14s addsubi0(0, qin, i0, ~ain[13], clk, cken);
   addsub14s addsubq0(0, iin, q0, ain[13], clk, cken);
   /* Stage 1 45 Degrees */
   addsub14s addsuba1(a0, 14'd2048, a1, ~a0[13], clk, cken);
   addsub14s addsubi1(i0, q0, i1, ~a0[13], clk, cken);
   addsub14s addsubq1(q0, i0, q1, a0[13], clk, cken);
   /* Stage 2 26.56 Degrees */
   addsub14s addsuba2(a1, 14'd1209, a2, ~a1[13], clk, cken);
   addsub14s addsubi2(i1, {q1[13], q1[13:1]}, i2, ~a1[13], clk, cken);
   addsub14s addsubq2(q1, {i1[13], i1[13:1]}, q2, a1[13], clk, cken);
   /* Stage 3 14.03 Degrees */
   addsub14s addsuba3(a2, 14'd637, a3, ~a2[13], clk, cken);
   addsub14s addsubi3(i2, {{2{q2[13]}}, q2[13:2]}, i3, ~a2[13], clk, cken);
   addsub14s addsubq3(q2, {{2{i2[13]}}, i2[13:2]}, q3, a2[13], clk, cken);
   /* Stage 4 7.125 Degrees */
   addsub14s addsuba4(a3, 14'd324, a4, ~a3[13], clk, cken);
   addsub14s addsubi4(i3, {{3{q3[13]}}, q3[13:3]}, i4, ~a3[13], clk, cken);
   addsub14s addsubq4(q3, {{3{i3[13]}}, i3[13:3]}, q4, a3[13], clk, cken);
   /* Stage 5 3.57 Degrees */
   addsub14s addsuba5(a4, 14'd163, a5, ~a4[13], clk, cken);
   addsub14s addsubi5(i4, {{4{q4[13]}}, q4[13:4]}, i5, ~a4[13], clk, cken);
   addsub14s addsubq5(q4, {{4{i4[13]}}, i4[13:4]}, q5, a4[13], clk, cken);
   /* Stage 6 1.79 Degrees */
   addsub14s addsuba6(a5, 14'd81, a6, ~a5[13], clk, cken);
   addsub14s addsubi6(i5, {{5{q5[13]}}, q5[13:5]}, i6, ~a5[13], clk, cken);
   addsub14s addsubq6(q5, {{5{i5[13]}}, i5[13:5]}, q6, a5[13], clk, cken);
   /* Stage 7 0.895 Degrees */
   addsub14s addsuba7(a6, 14'd41, a7, ~a6[13], clk, cken);
   addsub14s addsubi7(i6, {{6{q6[13]}}, q6[13:6]}, i7, ~a6[13], clk, cken);
   addsub14s addsubq7(q6, {{6{i6[13]}}, i6[13:6]}, q7, a6[13], clk, cken);
   /* Stage 8 0.448 Degrees */
   addsub14s addsuba8(a7, 14'd20, a8, ~a7[13], clk, cken);
   addsub14s addsubi8(i7, {{7{q7[13]}}, q7[13:7]}, i8, ~a7[13], clk, cken);
   addsub14s addsubq8(q7, {{7{i7[13]}}, i7[13:7]}, q8, a7[13], clk, cken);
   /* Stage 9 0.224 Degrees */
   addsub14s addsuba9(a8, 14'd10, a9, ~a8[13], clk, cken);
   addsub14s addsubi9(i8, {{8{q8[13]}}, q8[13:8]}, i9, ~a8[13], clk, cken);
   addsub14s addsubq9(q8, {{8{i8[13]}}, i8[13:8]}, q9, a8[13], clk, cken);
   /* Stage 10 0.112 Degrees */
   addsub14s addsuba10(a9, 14'd5, a10, ~a9[13], clk, cken);
   addsub14s addsubi10(i9, {{9{q9[13]}}, q9[13:9]}, i10, ~a9[13], clk, cken);
   addsub14s addsubq10(q9, {{9{i9[13]}}, i9[13:9]}, q10, a9[13], clk, cken);
   /* Stage 11 0.056 Degrees */
   addsub14s addsuba11(a10, 14'd3, a11, ~a10[13], clk, cken);
   addsub14s addsubi11(i10, {{10{q10[13]}}, q10[13:10]}, i11, ~a10[13], clk, cken);
   addsub14s addsubq11(q10, {{10{i10[13]}}, i10[13:10]}, q11, a10[13], clk, cken);
   /* Stage 12 0.028 Degrees */
   addsub14s addsuba12(a11, 14'd1, a12, ~a11[13], clk, cken);
   addsub14s addsubi12(i11, {{11{q11[13]}}, q11[13:11]}, i12, ~a11[13], clk, cken);
   addsub14s addsubq12(q11, {{11{i11[13]}}, i11[13:11]}, q12, a11[13], clk, cken);
   /* Stage 13 0.014 Degrees */
   addsub14s addsubi13(i12, {{12{q12[13]}}, q12[13:12]}, i13, ~a12[13], clk, cken);
   addsub14s addsubq13(q12, {{12{i12[13]}}, i12[13:12]}, q13, a12[13], clk, cken);
   assign          iout = i13;
   assign          qout = q13;
endmodule //cordic
