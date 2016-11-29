#!/usr/bin/env python

"""
Copyright (C) 2014-2016 Harmon Instruments, LLC

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
def write(dut, addr, data, clocks):
    dut.a = addr
    dut.wd = data
    dut.w = 1
    yield RisingEdge(dut.c)
    dut.w = 0
    for i in range(clocks):
        yield RisingEdge(dut.c)

@cocotb.test()
def run_test(dut):
    """Test UART"""
    dut.a = 0
    dut.w = 0
    a = cocotb.fork(Clock(dut.c, 10000).start())
    yield RisingEdge(dut.c)
    yield write(dut, 3, 0x80000001, 6000)
    print hex(int(dut.uart0.rd)), hex(int(dut.uart1.rd))
    yield write(dut, 7, 0x12345678, 5000)
    print hex(int(dut.uart0.rd)), hex(int(dut.uart1.rd))
