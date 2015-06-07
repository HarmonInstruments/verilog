/*
 * Copyright (C) 2015 Harmon Instruments, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/
 *
 */

`timescale 1ns / 1ps

// FIR filter, decimate by 2 to 16
// number of taps is 32*decim rate
// clock is 8 * FS in
// output is 2 channels at a time
module fir_decim_n
  (
   input 	       c,
   input [N_CH*18-1:0] id, // input data
   input [1:0] 	       sel, // 0: decim 2, 1: decim 4, 2: decim 8, 3: decim 16
   output [47:0]       od, // gain is 8 * (2^sel)
   output reg 	       ov = 0 // first channel output valid, additional channels on successive cycles
   );

   parameter N_CH = 4;
   reg signed [17:0]    coefrom [511:0];
   reg [17:0] 		coef0 = 0, coef1 = 0;
   reg [8:0] 		coefa0 = 0, coefa1 = 0;
   reg [8:0] 		wa = 0;
   reg [8:0] 		ra0 = 0, ra1 = 0, ra2 = 0, ra3 = 0;
   reg [7:0] 		state = 0;
   reg 			w = 0;
   reg [6:0] 		s0 = 0, s1 = 0; // state is 0 when bit 0, ...
   reg [1:0] 		l2n = 0; // log2 (rate)

   wire [N_CH*18-1:0] 	rd0, rd1, rd2, rd3; // read data from RAM
   wire [N_CH*24-1:0] 	dd0, dd1; // dsp data out
   reg [N_CH*24-1:0] 	od1;

   wire 		ce = 1'b1;

   wire [7:0] 		mask = {(sel > 2), (sel > 1), (sel > 0), 5'h1F};

   assign od = od1[47:0];

   always @ (posedge c) begin
      if(s0[6])
	od1 <= dd0;
      else if(s1[6])
	od1 <= dd1;
      else
	od1 <= od1[N_CH*24-1:48];
      ov <= s0[6] | s1[6];

      state <= (state + 1'b1) & mask;
      w <= state[2:0] == 7;
      wa <= wa + w;
      s0 <= {s0[5:0],(state == mask)};
      s1 <= {s1[5:0],(state == mask[7:1])};
      ra0 <= s0[0] ? wa - ({mask,1'b1} + 1'b1) : ra0 + 1'b1;
      ra1 <= s0[0] ? wa - 1'b1 : ra1 - 1'b1;
      ra2 <= s1[0] ? wa - ({mask,1'b1} + 1'b1) : ra2 + 1'b1;
      ra3 <= s1[0] ? wa - 1'b1 : ra3 - 1'b1;
      case(sel)
	0: begin // decim by 2, 64 taps
	   coefa0 <= s0[1] ? 9'h20 : coefa0 + 1'b1;
	   coefa1 <= s1[1] ? 9'h20 : coefa1 + 1'b1;
	end
	1: begin // decim by 4, 128 taps
	   coefa0 <= s0[1] ? 9'h40 : coefa0 + 1'b1;
	   coefa1 <= s1[1] ? 9'h40 : coefa1 + 1'b1;
	end
	2: begin // decim by 8, 256 taps
	   coefa0 <= s0[1] ? 9'h80 : coefa0 + 1'b1;
	   coefa1 <= s1[1] ? 9'h80 : coefa1 + 1'b1;
	end
	3: begin // decim by 16, 512 taps
	   coefa0 <= s0[1] ? 9'h100 : coefa0 + 1'b1;
	   coefa1 <= s1[1] ? 9'h100 : coefa1 + 1'b1;
	end
      endcase
      coef0 <= coefrom[coefa0];
      coef1 <= coefrom[coefa1];
   end

   genvar j;
   generate
      for (j = 0; j < N_CH/4; j = j+1) begin: ch
	 wire [71:0] wd = id[71+j*72:j*72];
	 bram_72x512 br0 (.c(c), .w(w), .wa(wa), .wd(wd), .r(ce), .ra(ra0), .rd(rd0[71+72*j:72*j]));
	 bram_72x512 br1 (.c(c), .w(w), .wa(wa), .wd(wd), .r(ce), .ra(ra1), .rd(rd1[71+72*j:72*j]));
	 bram_72x512 br2 (.c(c), .w(w), .wa(wa), .wd(wd), .r(ce), .ra(ra2), .rd(rd2[71+72*j:72*j]));
	 bram_72x512 br3 (.c(c), .w(w), .wa(wa), .wd(wd), .r(ce), .ra(ra3), .rd(rd3[71+72*j:72*j]));
      end
   endgenerate

   genvar i;
   generate
      for (i = 0; i < N_CH; i = i+1) begin: mac
	 wire [26:0] dsp_o0, dsp_o1;
	 dsp48_wrap_f #(.S(21), .AREG(1), .BREG(2), .USE_DPORT("TRUE")) mac0
	   (
	    .clock(c), .ce1(1'b1), .ce2(1'b1), .cem(1'b1), .cep(1'b1),
	    .a({rd0[17+18*i], rd0[17+18*i:18*i], 6'd0}),
	    .b(coef0),
	    .c(48'd131072), // convergent rounding
	    .d({rd1[17+18*i], rd1[17+18*i:18*i], 6'd0}),
	    .mode(s0[5] ? 5'b01100 : 5'b01000),
	    .pcin(48'h0),
	    .pcout(),
	    .p(dsp_o0));

	 dsp48_wrap_f #(.S(21), .AREG(1), .BREG(2), .USE_DPORT("TRUE")) mac1
	   (
	    .clock(c), .ce1(1'b1), .ce2(1'b1), .cem(1'b1), .cep(1'b1),
	    .a({rd2[17+18*i], rd2[17+18*i:18*i], 6'd0}),
	    .b(coef1),
	    .c(48'd131072), // convergent rounding
	    .d({rd3[17+18*i], rd3[17+18*i:18*i], 6'd0}),
	    .mode(s1[5] ? 5'b01100 : 5'b01000),
	    .pcin(48'h0),
	    .pcout(),
	    .p(dsp_o1));

	 assign dd0[23+24*i:24*i] = dsp_o0[23:0];
	 assign dd1[23+24*i:24*i] = dsp_o1[23:0];
      end
   endgenerate

   initial
     begin
	$dumpfile("dump.vcd");
	$dumpvars(0);
// tap numbers for debug
coefrom[0] = 25600;
coefrom[1] = 25856;
coefrom[2] = 26112;
coefrom[3] = 26368;
coefrom[4] = 26624;
coefrom[5] = 26880;
coefrom[6] = 27136;
coefrom[7] = 27392;
coefrom[8] = 27648;
coefrom[9] = 27904;
coefrom[10] = 28160;
coefrom[11] = 28416;
coefrom[12] = 28672;
coefrom[13] = 28928;
coefrom[14] = 29184;
coefrom[15] = 29440;
coefrom[16] = 29696;
coefrom[17] = 29952;
coefrom[18] = 30208;
coefrom[19] = 30464;
coefrom[20] = 30720;
coefrom[21] = 30976;
coefrom[22] = 31232;
coefrom[23] = 31488;
coefrom[24] = 31744;
coefrom[25] = 32000;
coefrom[26] = 32256;
coefrom[27] = 32512;
coefrom[28] = 32768;
coefrom[29] = 33024;
coefrom[30] = 33280;
coefrom[31] = 33536;
	// decim 2
coefrom[32] = -2;
coefrom[33] = -5;
coefrom[34] = 10;
coefrom[35] = 16;
coefrom[36] = -29;
coefrom[37] = -42;
coefrom[38] = 68;
coefrom[39] = 93;
coefrom[40] = -141;
coefrom[41] = -185;
coefrom[42] = 266;
coefrom[43] = 338;
coefrom[44] = -466;
coefrom[45] = -580;
coefrom[46] = 772;
coefrom[47] = 946;
coefrom[48] = -1224;
coefrom[49] = -1480;
coefrom[50] = 1874;
coefrom[51] = 2246;
coefrom[52] = -2800;
coefrom[53] = -3342;
coefrom[54] = 4131;
coefrom[55] = 4947;
coefrom[56] = -6121;
coefrom[57] = -7448;
coefrom[58] = 9391;
coefrom[59] = 11918;
coefrom[60] = -15993;
coefrom[61] = -22898;
coefrom[62] = 38984;
coefrom[63] = 117827;
	// decim4
coefrom[64] = 0;
coefrom[65] = -4;
coefrom[66] = -5;
coefrom[67] = -3;
coefrom[68] = 5;
coefrom[69] = 15;
coefrom[70] = 20;
coefrom[71] = 10;
coefrom[72] = -14;
coefrom[73] = -42;
coefrom[74] = -52;
coefrom[75] = -26;
coefrom[76] = 34;
coefrom[77] = 97;
coefrom[78] = 116;
coefrom[79] = 56;
coefrom[80] = -71;
coefrom[81] = -198;
coefrom[82] = -231;
coefrom[83] = -110;
coefrom[84] = 134;
coefrom[85] = 370;
coefrom[86] = 424;
coefrom[87] = 199;
coefrom[88] = -237;
coefrom[89] = -644;
coefrom[90] = -729;
coefrom[91] = -338;
coefrom[92] = 395;
coefrom[93] = 1062;
coefrom[94] = 1189;
coefrom[95] = 547;
coefrom[96] = -628;
coefrom[97] = -1677;
coefrom[98] = -1862;
coefrom[99] = -850;
coefrom[100] = 965;
coefrom[101] = 2560;
coefrom[102] = 2825;
coefrom[103] = 1284;
coefrom[104] = -1444;
coefrom[105] = -3819;
coefrom[106] = -4200;
coefrom[107] = -1906;
coefrom[108] = 2131;
coefrom[109] = 5636;
coefrom[110] = 6200;
coefrom[111] = 2820;
coefrom[112] = -3150;
coefrom[113] = -8378;
coefrom[114] = -9278;
coefrom[115] = -4261;
coefrom[116] = 4800;
coefrom[117] = 12970;
coefrom[118] = 14648;
coefrom[119] = 6905;
coefrom[120] = -8012;
coefrom[121] = -22626;
coefrom[122] = -27086;
coefrom[123] = -13851;
coefrom[124] = 18019;
coefrom[125] = 61250;
coefrom[126] = 102520;
coefrom[127] = 127672;
	// decim 8
coefrom[128] = 2;
coefrom[129] = -3;
coefrom[130] = -4;
coefrom[131] = -5;
coefrom[132] = -6;
coefrom[133] = -6;
coefrom[134] = -4;
coefrom[135] = -2;
coefrom[136] = 2;
coefrom[137] = 7;
coefrom[138] = 13;
coefrom[139] = 17;
coefrom[140] = 20;
coefrom[141] = 19;
coefrom[142] = 14;
coefrom[143] = 6;
coefrom[144] = -7;
coefrom[145] = -22;
coefrom[146] = -36;
coefrom[147] = -47;
coefrom[148] = -53;
coefrom[149] = -50;
coefrom[150] = -37;
coefrom[151] = -14;
coefrom[152] = 17;
coefrom[153] = 51;
coefrom[154] = 84;
coefrom[155] = 108;
coefrom[156] = 119;
coefrom[157] = 110;
coefrom[158] = 80;
coefrom[159] = 30;
coefrom[160] = -35;
coefrom[161] = -106;
coefrom[162] = -172;
coefrom[163] = -220;
coefrom[164] = -238;
coefrom[165] = -218;
coefrom[166] = -157;
coefrom[167] = -59;
coefrom[168] = 66;
coefrom[169] = 200;
coefrom[170] = 322;
coefrom[171] = 408;
coefrom[172] = 438;
coefrom[173] = 397;
coefrom[174] = 284;
coefrom[175] = 105;
coefrom[176] = -117;
coefrom[177] = -353;
coefrom[178] = -562;
coefrom[179] = -707;
coefrom[180] = -753;
coefrom[181] = -680;
coefrom[182] = -482;
coefrom[183] = -178;
coefrom[184] = 196;
coefrom[185] = 586;
coefrom[186] = 929;
coefrom[187] = 1162;
coefrom[188] = 1231;
coefrom[189] = 1104;
coefrom[190] = 780;
coefrom[191] = 287;
coefrom[192] = -313;
coefrom[193] = -932;
coefrom[194] = -1470;
coefrom[195] = -1830;
coefrom[196] = -1930;
coefrom[197] = -1724;
coefrom[198] = -1213;
coefrom[199] = -445;
coefrom[200] = 481;
coefrom[201] = 1429;
coefrom[202] = 2248;
coefrom[203] = 2788;
coefrom[204] = 2931;
coefrom[205] = 2611;
coefrom[206] = 1831;
coefrom[207] = 671;
coefrom[208] = -720;
coefrom[209] = -2139;
coefrom[210] = -3356;
coefrom[211] = -4154;
coefrom[212] = -4359;
coefrom[213] = -3877;
coefrom[214] = -2715;
coefrom[215] = -995;
coefrom[216] = 1062;
coefrom[217] = 3157;
coefrom[218] = 4953;
coefrom[219] = 6129;
coefrom[220] = 6431;
coefrom[221] = 5721;
coefrom[222] = 4011;
coefrom[223] = 1473;
coefrom[224] = -1569;
coefrom[225] = -4675;
coefrom[226] = -7352;
coefrom[227] = -9123;
coefrom[228] = -9603;
coefrom[229] = -8576;
coefrom[230] = -6039;
coefrom[231] = -2231;
coefrom[232] = 2381;
coefrom[233] = 7152;
coefrom[234] = 11334;
coefrom[235] = 14184;
coefrom[236] = 15077;
coefrom[237] = 13614;
coefrom[238] = 9710;
coefrom[239] = 3643;
coefrom[240] = -3938;
coefrom[241] = -12064;
coefrom[242] = -19536;
coefrom[243] = -25065;
coefrom[244] = -27424;
coefrom[245] = -25617;
coefrom[246] = -19020;
coefrom[247] = -7494;
coefrom[248] = 8559;
coefrom[249] = 28203;
coefrom[250] = 50039;
coefrom[251] = 72337;
coefrom[252] = 93208;
coefrom[253] = 110807;
coefrom[254] = 123534;
coefrom[255] = 130210;
	// decim 16
coefrom[256] = 5;
coefrom[257] = -2;
coefrom[258] = -2;
coefrom[259] = -3;
coefrom[260] = -3;
coefrom[261] = -4;
coefrom[262] = -4;
coefrom[263] = -5;
coefrom[264] = -5;
coefrom[265] = -6;
coefrom[266] = -6;
coefrom[267] = -5;
coefrom[268] = -5;
coefrom[269] = -4;
coefrom[270] = -3;
coefrom[271] = -1;
coefrom[272] = 1;
coefrom[273] = 3;
coefrom[274] = 6;
coefrom[275] = 9;
coefrom[276] = 11;
coefrom[277] = 14;
coefrom[278] = 16;
coefrom[279] = 18;
coefrom[280] = 20;
coefrom[281] = 20;
coefrom[282] = 20;
coefrom[283] = 19;
coefrom[284] = 16;
coefrom[285] = 13;
coefrom[286] = 8;
coefrom[287] = 3;
coefrom[288] = -3;
coefrom[289] = -10;
coefrom[290] = -18;
coefrom[291] = -25;
coefrom[292] = -33;
coefrom[293] = -39;
coefrom[294] = -45;
coefrom[295] = -50;
coefrom[296] = -53;
coefrom[297] = -53;
coefrom[298] = -52;
coefrom[299] = -48;
coefrom[300] = -41;
coefrom[301] = -32;
coefrom[302] = -21;
coefrom[303] = -7;
coefrom[304] = 8;
coefrom[305] = 25;
coefrom[306] = 42;
coefrom[307] = 60;
coefrom[308] = 76;
coefrom[309] = 91;
coefrom[310] = 104;
coefrom[311] = 113;
coefrom[312] = 118;
coefrom[313] = 119;
coefrom[314] = 115;
coefrom[315] = 105;
coefrom[316] = 90;
coefrom[317] = 70;
coefrom[318] = 45;
coefrom[319] = 15;
coefrom[320] = -17;
coefrom[321] = -52;
coefrom[322] = -88;
coefrom[323] = -123;
coefrom[324] = -157;
coefrom[325] = -186;
coefrom[326] = -211;
coefrom[327] = -228;
coefrom[328] = -237;
coefrom[329] = -238;
coefrom[330] = -228;
coefrom[331] = -208;
coefrom[332] = -177;
coefrom[333] = -136;
coefrom[334] = -87;
coefrom[335] = -30;
coefrom[336] = 33;
coefrom[337] = 99;
coefrom[338] = 167;
coefrom[339] = 233;
coefrom[340] = 294;
coefrom[341] = 348;
coefrom[342] = 391;
coefrom[343] = 422;
coefrom[344] = 437;
coefrom[345] = 435;
coefrom[346] = 416;
coefrom[347] = 377;
coefrom[348] = 320;
coefrom[349] = 246;
coefrom[350] = 156;
coefrom[351] = 54;
coefrom[352] = -58;
coefrom[353] = -176;
coefrom[354] = -294;
coefrom[355] = -409;
coefrom[356] = -515;
coefrom[357] = -607;
coefrom[358] = -680;
coefrom[359] = -730;
coefrom[360] = -754;
coefrom[361] = -748;
coefrom[362] = -711;
coefrom[363] = -643;
coefrom[364] = -544;
coefrom[365] = -417;
coefrom[366] = -264;
coefrom[367] = -91;
coefrom[368] = 98;
coefrom[369] = 294;
coefrom[370] = 490;
coefrom[371] = 679;
coefrom[372] = 852;
coefrom[373] = 1001;
coefrom[374] = 1118;
coefrom[375] = 1197;
coefrom[376] = 1233;
coefrom[377] = 1220;
coefrom[378] = 1157;
coefrom[379] = 1043;
coefrom[380] = 881;
coefrom[381] = 673;
coefrom[382] = 425;
coefrom[383] = 146;
coefrom[384] = -156;
coefrom[385] = -468;
coefrom[386] = -780;
coefrom[387] = -1078;
coefrom[388] = -1349;
coefrom[389] = -1581;
coefrom[390] = -1762;
coefrom[391] = -1883;
coefrom[392] = -1934;
coefrom[393] = -1910;
coefrom[394] = -1807;
coefrom[395] = -1626;
coefrom[396] = -1370;
coefrom[397] = -1044;
coefrom[398] = -659;
coefrom[399] = -226;
coefrom[400] = 239;
coefrom[401] = 720;
coefrom[402] = 1197;
coefrom[403] = 1652;
coefrom[404] = 2064;
coefrom[405] = 2415;
coefrom[406] = 2687;
coefrom[407] = 2866;
coefrom[408] = 2939;
coefrom[409] = 2898;
coefrom[410] = 2738;
coefrom[411] = 2460;
coefrom[412] = 2069;
coefrom[413] = 1575;
coefrom[414] = 993;
coefrom[415] = 340;
coefrom[416] = -359;
coefrom[417] = -1079;
coefrom[418] = -1792;
coefrom[419] = -2470;
coefrom[420] = -3083;
coefrom[421] = -3603;
coefrom[422] = -4006;
coefrom[423] = -4268;
coefrom[424] = -4372;
coefrom[425] = -4307;
coefrom[426] = -4066;
coefrom[427] = -3650;
coefrom[428] = -3068;
coefrom[429] = -2334;
coefrom[430] = -1470;
coefrom[431] = -505;
coefrom[432] = 529;
coefrom[433] = 1593;
coefrom[434] = 2646;
coefrom[435] = 3646;
coefrom[436] = 4549;
coefrom[437] = 5316;
coefrom[438] = 5909;
coefrom[439] = 6295;
coefrom[440] = 6449;
coefrom[441] = 6353;
coefrom[442] = 5999;
coefrom[443] = 5387;
coefrom[444] = 4529;
coefrom[445] = 3448;
coefrom[446] = 2173;
coefrom[447] = 748;
coefrom[448] = -780;
coefrom[449] = -2355;
coefrom[450] = -3917;
coefrom[451] = -5402;
coefrom[452] = -6749;
coefrom[453] = -7897;
coefrom[454] = -8789;
coefrom[455] = -9377;
coefrom[456] = -9621;
coefrom[457] = -9494;
coefrom[458] = -8981;
coefrom[459] = -8082;
coefrom[460] = -6810;
coefrom[461] = -5196;
coefrom[462] = -3285;
coefrom[463] = -1135;
coefrom[464] = 1182;
coefrom[465] = 3584;
coefrom[466] = 5982;
coefrom[467] = 8281;
coefrom[468] = 10384;
coefrom[469] = 12198;
coefrom[470] = 13634;
coefrom[471] = 14612;
coefrom[472] = 15066;
coefrom[473] = 14944;
coefrom[474] = 14214;
coefrom[475] = 12866;
coefrom[476] = 10910;
coefrom[477] = 8381;
coefrom[478] = 5337;
coefrom[479] = 1861;
coefrom[480] = -1945;
coefrom[481] = -5959;
coefrom[482] = -10041;
coefrom[483] = -14041;
coefrom[484] = -17798;
coefrom[485] = -21150;
coefrom[486] = -23934;
coefrom[487] = -25996;
coefrom[488] = -27193;
coefrom[489] = -27397;
coefrom[490] = -26504;
coefrom[491] = -24434;
coefrom[492] = -21138;
coefrom[493] = -16598;
coefrom[494] = -10829;
coefrom[495] = -3882;
coefrom[496] = 4159;
coefrom[497] = 13177;
coefrom[498] = 23021;
coefrom[499] = 33516;
coefrom[500] = 44462;
coefrom[501] = 55641;
coefrom[502] = 66821;
coefrom[503] = 77763;
coefrom[504] = 88228;
coefrom[505] = 97984;
coefrom[506] = 106810;
coefrom[507] = 114503;
coefrom[508] = 120886;
coefrom[509] = 125809;
coefrom[510] = 129157;
coefrom[511] = 130851;
     end
endmodule
