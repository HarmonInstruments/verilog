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
    c = dut.clock
    dut.wvalid = 1
    dut.wdata = data
    print "in: {:04x}".format(data)
    yield RisingEdge(c)
    dut.wvalid = 0
    for i in range(250):
        yield RisingEdge(c)
    print hex(int(dut.rdata))
    raise ReturnValue(int(dut.rdata))

@cocotb.test()
def run_test(dut):
    """Test SIO"""
    dut.r = 1
    dut.wvalid = 0
    cocotb.fork(Clock(dut.clock, 8000).start())
    cocotb.fork(Clock(dut.clock_2x, 4000).start())
    c = dut.clock
    for i in range(20000):
        yield RisingEdge(c)
    dut.r = 0
    for i in range(10):
        yield RisingEdge(c)
    yield do_input(dut, 0xBEE0)
    yield do_input(dut, 0xFFFFFFFFFF)
    yield do_input(dut, 0xCAFE | (0xFF << 64))
    for i in range(10):
        yield do_input(dut, i)
    yield do_input(dut, 0xFFF0)
