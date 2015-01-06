#!/usr/bin/env python

gplheader = """Harmon Instruments CORDIC generator
Copyright (C) 2014 Harmon Instruments, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/
"""

import numpy as np

def gen(name, dbits, abits, d):
    print "module {} (".format(name)
    print "\tinput c, // clock"
    print "\tinput [{}:0] a0, a1, // angle".format(abits-1)
    print "\toutput [{}:0] d0, d1);".format(dbits-1)
    print ""
    print "wire [35:0] o0, o1;"
    print "assign d0 = o0[{}:0];".format(dbits-1)
    print "assign d1 = o1[{}:0];".format(dbits-1)
    print ""
    print "RAMB36E1 #("
    print ".DOA_REG(1),.DOB_REG(1),"
    print ".INIT_A(36'h000000000), .INIT_B(36'h000000000),"
    print '.RAM_MODE("TDP"),'
    print ".READ_WIDTH_A(36), .READ_WIDTH_B(36),"
    print ".WRITE_WIDTH_A(36), .WRITE_WIDTH_B(36),"
    for i in range(128):
        v = 0
        for j in range(8):
            v1 = int(d[8*i+j]) & 0xFFFFFFFF
            v |= v1 << (32*j)
        print ".INIT_{:02X}(256'h{:064X}),".format(i,v)
    for i in range(16):
        v = 0
        for j in range(64):
            v1 = (int(d[64*i+j]) >> 32) & 0x7
            v |= v1 << (4*j)
        print ".INITP_{:02X}(256'h{:064X}),".format(i, v)
    print '.SIM_DEVICE("7SERIES"))'
    print "RAMB36E1_inst ("
    print ".CASCADEOUTA(), .CASCADEOUTB(),"
    print ".DBITERR(), .ECCPARITY(), .RDADDRECC(), .SBITERR(),"
    # out
    print ".DOADO(o0[31:0]),"
    print ".DOPADOP(o0[35:32]),"
    print ".DOBDO(o1[31:0]),"
    print ".DOPBDOP(o1[35:32]),"
    # unused inputs
    print ".CASCADEINA(1'b0), .CASCADEINB(1'b0),"
    print ".INJECTDBITERR(1'b0), .INJECTSBITERR(1'b0),"
    # port A inputs
    print ".ADDRARDADDR({1'b0,a0,5'd0}),"
    print ".CLKARDCLK(c),"
    print ".ENARDEN(1'b1),"
    print ".REGCEAREGCE(1'b1),"
    print ".RSTRAMARSTRAM(1'b0),"
    print ".RSTREGARSTREG(1'b0),"
    print ".WEA(4'b0),"
    print ".DIADI(32'h0),"
    print ".DIPADIP(4'h0),"
    # port B inputs
    print ".ADDRBWRADDR({1'b0,a1,5'd0}),"
    print ".CLKBWRCLK(c),"
    print ".ENBWREN(1'b1),"
    print ".REGCEB(1'b1),"
    print ".RSTRAMB(1'b0),"
    print ".RSTREGB(1'b0),"
    print ".WEBWE(8'b0),"
    print ".DIBDI(32'h0),"
    print ".DIPBDIP(4'h0));"

    print "endmodule"

