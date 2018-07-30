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
def impulse(dut, s=[0,1]):
    r = np.zeros(32)
    print "s = ", s
    ampl = 131072
    dut.id1 = s[1]*ampl
    dut.id0 = s[0]*ampl
    yield RisingEdge(dut.c)
    dut.id1 = -1*s[1]*ampl
    dut.id0 = -1*s[0]*ampl
    for i in range(31):
        yield RisingEdge(dut.c)
        dut.id1 = 0
        dut.id0 = 0
        v = dut.od.value.integer
        if v > (2**23-1):
            v = -1* (2**24 - v)
        print v
        r[i] = v
    print r
    raise ReturnValue(r)

@cocotb.coroutine
def load_taps(dut, taps):
    for i in range(len(taps)):
        dut.tap = taps[i]
        dut.load_tap = 1<<i
        yield RisingEdge(dut.c)
    dut.load_tap = 0
    dut.tap = 0

@cocotb.test()
def run_test(dut):
    """Test halfband FIR"""
    dut.id0 = 0
    dut.id1 = 0
    a = cocotb.fork(Clock(dut.c, 2500).start())
    yield RisingEdge(dut.c)
    yield load_taps(dut, [1604*8, -12992*8, 8*(76924-65536)])
    for i in range(16):
        yield RisingEdge(dut.c)
    a = yield impulse(dut, s=[0,1])#cocotb.fork(impulse(dut))
    b = yield impulse(dut, s=[1,0])#cocotb.fork(impulse(dut))
    print a, b
    print zip(a,b)[7:][::4]
    print zip(a,b)[8:][::4]
