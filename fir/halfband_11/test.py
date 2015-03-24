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
    vals = 100 * np.arange(256, dtype=int)
    vals[0:64] = np.zeros(64, dtype=int)
    vals[8] = 2**18
    vals[23] = 2**18
    vals[64:128] = 9999 * np.ones(64, dtype=int)
    #vals[1] = 131072
    #vals[12] = 131072
    for val in vals:
        dut.id = val
        dut.iv = 1
        yield RisingEdge(dut.c)
        dut.iv = 0
        for i in range(3):
            yield RisingEdge(dut.c)


"""module halfband_11
  (
   input          c,
   input          reset,
   output [191:0] od,
   output reg     ov = 0
   );
"""

@cocotb.test()
def run_test(dut):
    """Test complex multiplier"""
    dut.id = 0
    dut.iv = 0
    dut.reset = 1
    a = cocotb.fork(Clock(dut.c, 2500).start())
    yield RisingEdge(dut.c)
    yield RisingEdge(dut.c)
    dut.reset = 0
    cocotb.fork(impulse(dut))

    for i in range(4096):
        yield RisingEdge(dut.c)
        #dut.iv = 1 if i%4 == 0 else 0
        if dut.ov.value.integer == 1:
            v = dut.od.value.integer
            if v > (2**23-1):
                v = -1* (2**24 - v)
            print 'hit', v
