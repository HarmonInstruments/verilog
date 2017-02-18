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

pipestages = 4
count = 20

@cocotb.coroutine
def do_mult(dut, a, b):
    yield RisingEdge(dut.clock)
    dut.a = a
    dut.b = b
    yield ReadOnly() # Wait until all events have executed for this timestep
    try:
        result = int(dut.p.value.signed_integer)
    except:
        result = -1
    raise ReturnValue(result)

@cocotb.test()
def run_test(dut):
    """Test complex multiplier"""
    nbits_a = 25
    nbits_b = 32 # there's a cocotb bug limiting it to 32 bits
    amult = 2**(nbits_a-1)-1
    bmult = 2**(nbits_b-1)-1
    cocotb.fork(Clock(dut.clock, 4000).start())

    a = np.random.randint(-1*amult, amult, count, dtype=np.int64)
    b = np.random.randint(-1*bmult, bmult, count, dtype=np.int64)
    c = (1<<17)

    b[0] = 1
    a[0] = (1<<17)

    b[1] = (1<<17)
    a[1] = -1

    b[3] = 0
    b[4] = 0

    a[13] = 0
    a[14] = 0

    p_expected = (a * b + c) >> 17

    p_result = np.zeros(count, dtype=np.int64)

    dut.c = (1<<17)

    for i in range(count+pipestages):
        if i < count:
            v = yield do_mult(dut, a[i], b[i])
        else:
            v = yield do_mult(dut, 0, 0)
        if i >= pipestages:
            p_result[i-pipestages] = v

    error = p_result - p_expected

    print "maximum error =", np.max(np.abs(error))

    if np.max(np.abs(error)) != 0:
        print 'index, a, b,        expected,    result, error'
        for i in range(count):
            print i, format(2**25-1 & a[i], '07x'), format(2**35-1 & b[i], '09x'), format(2**48-1 & p_expected[i], '012x'), format(2**48-1 & p_result[i], '012x'), format(2**48-1  & (p_result[i] - p_expected[i]), '012x')
        dut.log.error("FAIL")
