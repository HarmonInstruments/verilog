#!/usr/bin/env python

"""
Copyright (C) 2014-2017 Harmon Instruments, LLC

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
def read(dut, addr, data):
    c = dut.clock
    dut.rio_host.wvalid = 1
    dut.rio_host.wdata = data | (addr << 32)
    yield RisingEdge(c)
    dut.rio_host.wvalid = 0
    for i in range(400):
        yield RisingEdge(c)
    rv = 0xFF & int(dut.rio_host.rdata)
    yield RisingEdge(c)
    raise ReturnValue(rv)

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    dut.rio_host.wvalid = 0
    cocotb.fork(Clock(dut.clock, 8000).start())
    for i in range(100):
        yield RisingEdge(dut.clock)
    yield read(dut, 0, (1<<37) | 0x01000080)
    yield read(dut, 0, (1<<38) | 0xFFFFFFFF) # reset the state machines
    yield read(dut, 3, 0xDEADBEEF)
    yield read(dut, 7, (1<<36) | 0)

    for i in range(16):
        v = yield read(dut, 7, (1<<36))
        print hex(v)
    yield read(dut, 3, 0xDEADBEEF)
    for i in range(1000):
        yield RisingEdge(dut.clock)
