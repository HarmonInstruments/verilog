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
    dut.i = 0xFF
    dut.r = 1
    print "in: {:016b}".format(data)
    bstream = "1111000{:016b}1111".format(data)
    expstream = ""
    coff = 0
    for b in bstream:
        coff += (4.0 * 0.999)
        nb = int(round(coff) + (2.0 * (random.random() - 0.5)))
        coff -= nb
        expstream += nb*b
    print expstream
    dut.r = 1
    dut.i = 0xFF
    yield RisingEdge(dut.c)
    dut.r = 0
    yield RisingEdge(dut.c)
    for i in range((len(expstream)/8)):
        v = expstream[8*i:8*i+8]
        dut.i = int(v,2)
        yield RisingEdge(dut.c)
    dut.i = 0xFF
    raise ReturnValue(0)

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    dut.i = 0xFF
    a = cocotb.fork(Clock(dut.c, 2500).start())
    din = np.arange(101, dtype=np.uint64)
    din[0] = 0xFFFE
    din[1] = 0xCAFE
    din[2] = 0xCAFE
    din[3] = 0xF0F0
    din[4] = 0xF0F0
    din[5] = 0xF0F0
    rdata = ""
    rv = np.zeros(len(din), dtype=np.uint64)
    for i in range(len(din)):
        cocotb.fork(do_input(dut, din[i]))
        while int(dut.v) == 0:
            yield RisingEdge(dut.c)
        rdata = ""
        for j in range(4):
            v = int(dut.d)
            yield RisingEdge(dut.c)
            yield RisingEdge(dut.c)
            rdata += "{:04b}".format(v&0xF)
        rv[i] = int(rdata[-16:],2)
        print "d", rv[i]
        if rv[i] != din[i]:
            print "error, ", i, rv[i], din[i]
            dut.log.error("FAIL")
