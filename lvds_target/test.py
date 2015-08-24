#!/usr/bin/env python

"""
Copyright (C) 2014-2015 Harmon Instruments, LLC

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

import sys, random
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Event
from cocotb.result import TestFailure, ReturnValue

@cocotb.coroutine
def do_input(dut, data):
    bstream = "11"*65
    for v in data:
        print "in: {:018b}".format(v)
        bstream += "11110{:018b}".format(v)
    bstream += "1111111111111"
    print bstream
    expstream = ""
    coff = 0
    for b in bstream:
        coff += (4.0 * 0.999)
        nb = int(round(coff) + (2.0 * (random.random() - 0.5)))
        coff -= nb
        expstream += nb*b
    for i in range((len(expstream)/8)):
        yield RisingEdge(dut.c)
        v = expstream[8*i:8*i+8]
        dut.i = int(v,2)
        yield ReadOnly()
        #result_re = int(dut.o_cos.value.signed_integer)
    dut.i = 0xFF
    raise ReturnValue(0)

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    dut.i = 0xFF
    a = cocotb.fork(Clock(dut.c, 2500).start())
    din = np.arange(401, dtype=np.uint64)
    din[0] = 0x1FFFE
    din[1] = 0x1CAFE
    din[2] = 0x2CAFE
    din[3] = 0x0F0F0
    din[4] = 0x0F0F0
    din[5] = 0x0F0F0
    b = cocotb.fork(do_input(dut, din))
    #angles = np.random.random(count)

    rdata = ""
    rv = np.zeros(len(din), dtype=np.uint64)
    for i in range(len(rv)):
        while True:
            yield RisingEdge(dut.c)
            yield RisingEdge(dut.c)
            f = int(dut.v)
            v = int(dut.d)
            rdata += "{:04b}".format(v&0xF)
            if f:
                print "d", rdata[-18:]
                rv[i] = int(rdata[-18:],2)
                rdata = ""
                break

    print "e", rdata
    rdata = ""

    for i in range(len(rv)):
        if rv[i] != din[i]:
            print "error, ", i, rv[i], din[i]
            dut.log.error("FAIL")
