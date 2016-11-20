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
    vals = np.arange(2048, dtype=int)
    vals[256:512] = 100000 * np.ones(256, dtype=int)
    vals[512:2048] = np.zeros(1024+512, dtype=int)
    vals[512+128] = 131071
    vals[512+256+1] = 131071
    vals[512+384+2] = 131071
    vals[512+512+3] = 131071
    vals[512+512+128+4] = 131071
    vals[512+512+256+5] = 131071
    vals[512+512+384+6] = 131071
    vals[512+512+512+7] = 131071
    vals[512+512+512+128+8] = 131071
    vals[2048-384:2048+8-384] = 131071 * np.ones(8, dtype=int)
    for val in vals:
        dut.id = val
        for i in range(2):
            yield RisingEdge(dut.c)
    dut.id = 0
@cocotb.test()
def run_test(dut):
    dut.id = 0
    dut.sel = 1
    a = cocotb.fork(Clock(dut.c, 2500).start())
    for i in range(2000):
        yield RisingEdge(dut.c)
    cocotb.fork(impulse(dut))
    for i in range(4096):
        yield RisingEdge(dut.c)
        if dut.ov.value.integer == 1:
            v = dut.od.value.integer
            if v > 131071:
                v = v - 262144
            print 'v', v
