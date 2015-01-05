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

import sys
import numpy as np

abits = 10
shift = 2

dbits = int(sys.argv[1])
derivbits = dbits-9
rbits = dbits + derivbits
name = "cosrom_"+sys.argv[1]
npoints = 2**abits

n = np.arange(npoints + 1)
d = np.cos(2.0*np.pi*n/(2**(abits+shift))) * ((2**(dbits)) - 1.0)
d = np.round(d)

print "module {} (".format(name)
print "\tinput c, // clock"
print "\tinput [{}:0] a0, a1, // angle".format(abits-1)
print "\toutput reg [{}:0] d0, d1);".format(rbits-1)
print ""
print "\treg [{}:0] oreg0, oreg1;".format(rbits-1)
print '\t(* ram_style = "block" *) reg [{}:0] bram[0:{}];'.format(
    rbits-1, npoints - 1)
print ""
print "always @ (posedge c) begin"
print "\toreg0 <= bram[a0];"
print "\toreg1 <= bram[a1];"
print "\td0 <= oreg0;"
print "\td1 <= oreg1;"
print "end"
print ""
print "initial begin"
for i in n[:-1]:
    val = int(d[i])
    deriv = int(d[i] - d[i+1])
    print "\tbram[{}] <= {{{}'d{},{}'d{}}};".format(
        i, dbits, val, derivbits, deriv)

print "end"
print "endmodule"



