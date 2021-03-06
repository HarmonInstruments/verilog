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

import sys, os
import numpy as np
from config import *

def gen_angle_rom(name, bits, angles):
    max_angle = np.sum(angles)
    bits = min(bits, int(np.ceil(np.log2(max_angle))) + 1)
    print "\treg signed [{}:0] {}[0:63];".format(bits-1, name)
    print "initial begin"
    for i in range(64):
        j = np.arange(6)
        m = (((i & (1<<j)) == 0) * 2) - 1 # -1 if i[j] is set or else 1
        val = np.sum(m * angles[j])
        val = np.clip(val, -1.0 * 2**(bits-1), (2**bits-1)-1)
        print "\t{}[{}] = {};".format(name, i, int(np.round(val)))
    print "end"

def gen_angle_roms(stages, bits):
    angles = np.arctan(2.0 ** (-1.0 * np.arange(36)))
    angles = np.concatenate([[np.pi*0.5], angles])
    angles = angles * (2**(nbits_aout-1))/np.pi
    for i in range(stages, len(angles)):
        angles[i] = 0
    nroms = int(np.ceil(stages/6.0))
    for i in range(nroms):
        gen_angle_rom('arom_{}'.format(i), bits, angles[6*i:6*i+6])

def gen_translate():
    nroms = int(np.ceil(stages/6.0))
    gain = np.prod(np.sqrt(1.0 + 2.0 ** (-2.0*np.arange(stages))))
    # header
    print "/* generated by " + gplheader
    print "gain =", gain
    print "*/"
    print "module {} (".format(name)
    print "\tinput clock,"
    print "\tinput signed [{}:0] in_re, in_im,".format(nbits_din-1)
    print "\toutput signed [{}:0] out_angle,".format(nbits_aout-1)
    print "\toutput [{}:0] out_mag);".format(nbits_din-1)
    gen_angle_roms(stages, nbits_aout)
    # declarations
    for i in range(stages):
        print "\treg [{0}:0] angle_{0} = 0;".format(i)
    for i in range(stages):
        print "\treg [{0}:0] re_{1} = 0;".format(nbits_din-1, i)
    im_msb = nbits_din * np.ones(stages, dtype=int)
    im_msb[1:stages] -= np.arange(stages-1, dtype=int)
    for i in range(stages-1):
        print "\treg signed [{0}:0] im_{1} = 0;".format(im_msb[i], i)
    # assigns
    print "\tassign out_mag = re_{};".format(stages-1)
    print "\twire [31:0] langle = angle_{};".format(stages-1)
    print "\tassign out_angle =",
    for i in range(nroms):
        print "arom_{}[langle[{}:{}]]".format(i, 6*i+5, 6*i),
        if (i+1) != nroms:
            print "+",
        else:
            print ";"
    print "always @ (posedge clock) begin"
    # prerotate - if im < 0, rotate 90 degrees ccw else rotate 90 ccw
    print "\tangle_0 <= (in_im < 0);"
    print "\tre_0 <= in_im < 0 ? 2'sd0 - in_im : in_im;"
    print "\tim_0 <= in_im < 0 ? in_re : 2'sd0 - in_re;"
    # rotate stages
    for n in range(1, stages):
        sub = "im_{} < 0".format(n-1)
        print "\tangle_{0} <= {{{1}, angle_{2}}};".format(n, sub, n-1)
        if n < im_msb[n]:
            im_shifted = '(im_{0} >>> {0})'.format(n-1)
            abs_im = "(im_{0} < 0 ? 2'sd0 - {1} : {1})".format(n-1, im_shifted)
            print "\tre_{0} <= $signed(re_{1}) + {2};".format(n, n-1, abs_im)
        else:
            print "\tre_{} <= re_{};".format(n, n-1)
        if n != stages - 1:
            re_shifted = '(re_{0} >> {0})'.format(n-1)
            print "\tim_{0} <= im_{1} >= 0 ? im_{1} - {2} : im_{1} + {2};"\
                .format(n, n-1, re_shifted)
    print "end"

    print """initial
     begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
     end"""

    print "endmodule"

if __name__=="__main__":
    gen_translate()

