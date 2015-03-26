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

# extract 4 signed 18 bit values from 72 bits
def extract18s(v):
    d = np.zeros(4, dtype = int)
    for i in range(4):
        d[i] = 0x3FFFF & (v >> (18*i))
        if d[i] > (2**17-1):
            d[i] = -1* (2**18 - d[i])
    return d

@cocotb.coroutine
def impulse(dut):
    vals = np.arange(1024, dtype=int)
    vals[512:768] = np.zeros(256, dtype=int)
    vals[512+64] = 32767
    vals[512+64+65] = 32767
    vals[512+128+66] = 32767
    vals[256:512] = 32767 * np.ones(256, dtype=int)
    for val in vals:
        for i in range(4):
            dut.id = val*(i+1)
            yield RisingEdge(dut.c)

@cocotb.test()
def run_test(dut):
    """Test complex multiplier"""
    dut.id = 0
    dut.sel = 0
    dut.state = 0
    a = cocotb.fork(Clock(dut.c, 2500).start())
    yield RisingEdge(dut.c)
    yield RisingEdge(dut.c)
    cocotb.fork(impulse(dut))
    for i in range(4096):
        dut.state = i & 0xFF
        yield RisingEdge(dut.c)
        if dut.ov.value.integer == 1:
            v = dut.od.value.integer
            print 'hit', extract18s(v)
