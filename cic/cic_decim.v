module integrate_8_18(in, out, clk);
endmodule //integrate_8_18

module cic_decim_18(in, out, rate, clken, clk);
	input clk
	input [7:0] rate;
	input [17:0] in;
	output [17:0] out;
	output reg clken;
	reg clken_next;
	reg [17:0] acc [0:7];
	reg [17:0] comb [0:7];	
	reg [7:0] count = 0;
	always @ (posedge clk)
	begin
		count <= count + 1;
		/* The integrator */
		acc[0] <= acc[0] + in;
		acc[1] <= acc[1] + acc[0];
		acc[2] <= acc[2] + acc[1];
		acc[3] <= acc[3] + acc[2];
		acc[4] <= acc[4] + acc[3];
		acc[5] <= acc[5] + acc[4];
		acc[6] <= acc[6] + acc[5];
		acc[7] <= acc[7] + acc[6];	
		if()
		begin
			clken <= 1`b1;
			count <= 0;
			/* The comb */
			comb[0] <= acc[7];
			comb[1] <= comb[0] - acc[7];
		end
		else
		begin
			clken <= 1`b0;
		end
	end
endmodule //cic_decim