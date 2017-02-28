#!/usr/bin/env python

"""
Copyright (C) 2017 Harmon Instruments, LLC

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
import struct

count = 20

@cocotb.coroutine
def do_div(dut, a):
    yield RisingEdge(dut.c)
    (a_i, ) = struct.unpack('Q', struct.pack('d', a))
    print hex(a_i)
    dut.i = a_i
    dut.iv = 1
    yield RisingEdge(dut.c)
    dut.iv = 0
    while int(dut.ov) == 0:
        yield RisingEdge(dut.c)
    result_man = int(dut.o)
    result_exp = int(dut.oe.value.signed_integer)
    while result_man & (2**62) == 0:
        result_man <<= 1
        result_exp -= 1
        print "denormal"
    result = 2.0**result_exp * result_man / (2.0**62)
    print a, a/3e9, result, a/3e9 - result
    raise ReturnValue(result)

@cocotb.test()
def run_test(dut):
    """Test divider"""
    cocotb.fork(Clock(dut.c, 8000).start())
    dut.iv = 0

    a = np.random.random(count)*10e9
    a[0] = 5e9
    a[1] = 4e9
    a[2] = 3e9

    for i in range(count):
        v = yield do_div(dut, a[i])


    #dut.log.error("FAIL")
