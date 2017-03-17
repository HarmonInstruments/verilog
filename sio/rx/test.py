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
    dut.rx_host.wvalid = 1
    dut.rx_host.addr = 0
    dut.rx_host.wdata = data | (1<<20) | (addr << 16)
    yield RisingEdge(c)
    dut.rx_host.wvalid = 0
    while(int(dut.rx_host.rvalid) == 0):
        yield RisingEdge(c)
    rv = 0xFF & int(dut.rx_host.rdata)
    yield RisingEdge(c)
    raise ReturnValue(rv)

@cocotb.coroutine
def stream(dut, mask, count):
    c = dut.clock
    dut.rx_host.wvalid = 1
    dut.rx_host.addr = 2
    dut.rx_host.wdata = (mask << 24) | count
    yield RisingEdge(c)
    dut.rx_host.wvalid = 0
    channels = bin(mask).count("1")
    d = np.zeros(count*channels, dtype=int)
    for i in range(channels*count):
        while(int(dut.rx_host.rvalid) == 0):
            yield RisingEdge(c)
        d[i] = int(dut.rx_host.rdata)
        yield RisingEdge(c)
    raise ReturnValue(d)

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    dut.rx_host.wvalid = 0
    cocotb.fork(Clock(dut.clock, 8000).start())
    for i in range(1000):
        yield RisingEdge(dut.clock)
    for i in range(16):
        d = i
        if i==0:
            d=1
        if i==1:
            d = 92
        v = yield read(dut, i, d)
        print hex(v)

    print 'capture timing'
    for i in range(89, 97):
        yield read(dut, 1, i)
        yield read(dut, 0, 0)
        v = yield read(dut, 6, 0)
        print i, v
    yield read(dut, 1, 92)
    yield read(dut, 0, 0)
    d = yield stream(dut, 0x83, 4)

    print d
    for i in range(len(d)):
        print hex(d[i])

    for i in range(2000):
        yield RisingEdge(dut.clock)
