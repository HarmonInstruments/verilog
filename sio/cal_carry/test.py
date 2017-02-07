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
    c = dut.clock_host
    dut.wvalid = 1
    dut.wdata = data
    print "in: {:04x}".format(data)
    yield RisingEdge(c)
    dut.wvalid = 0
    for i in range(100):
        yield RisingEdge(c)
    raise ReturnValue(int(dut.rdata))

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    cocotb.fork(Clock(dut.c, 4000).start())
    cocotb.fork(Clock(dut.i, 2000).start())
    c = dut.c
    for i in range(300):
        yield RisingEdge(c)
    print int(dut.d)
