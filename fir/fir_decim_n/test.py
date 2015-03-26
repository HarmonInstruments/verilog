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
def impulse(dut):
    vals = 100 * np.arange(1024, dtype=int)
    vals[0:512] = np.zeros(512, dtype=int)
    vals[1] = 131071
    vals[130] = 65536
    #vals[259] = 2**18
    #vals[388] = 2**18
    vals[255:511] = 131071 * np.ones(256, dtype=int)
    for val in vals:
        dut.id = val
        for i in range(16):
            yield RisingEdge(dut.c)

@cocotb.coroutine
def load_coefs(dut, vals):
    dut.cw = 1
    for i in range(len(vals)):
        dut.ca = i
        dut.cd = vals[i]
        yield RisingEdge(dut.c)
    dut.cw = 0

@cocotb.test()
def run_test(dut):
    """Test complex multiplier"""
    dut.id = 0
    dut.cw = 0
    dut.l2n = 0
    dut.state_ext = 0
    a = cocotb.fork(Clock(dut.c, 2500).start())
    yield RisingEdge(dut.c)
    f2 = np.array([-2, -5, 10, 16, -29, -42, 68, 93, -141, -185,
                   266, 338, -466, -580, 772, 946,-1224,  -1480,   1874,   2246,
                   -2800,  -3342,   4131,   4947,  -6121,  -7448,   9391,  11918, -15993, -22898,
                   38984, 117827])
    #f2 = 1 + np.arange(32)
    print np.sum(f2)
    #f2 = np.ones(32, dtype=int) * 2**12
    yield load_coefs(dut, f2)
    cocotb.fork(impulse(dut))

    for i in range(8192):
        dut.state_ext = i & 0x1FF
        yield RisingEdge(dut.c)
        if dut.ov.value.integer == 1:
            v = dut.od.value.integer & 0xFFFFFF
            if v > (2**23-1):
                v = -1* (2**24 - v)
            print 'hit', v
