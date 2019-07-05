#!/usr/bin/env python3

"""
Copyright (C) 2014-2019 Harmon Instruments, LLC

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
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly, Event
from cocotb.result import TestFailure, ReturnValue

def safehex(x):
    if not (('x' in x) or ('z' in x)):
        return hex(int(x,2))
    return x

@cocotb.coroutine
def rw(dut, addr, data):
    c = dut.clock
    dut.wvalid = 1
    dut.wdata = data | (addr << 32)
    yield RisingEdge(c)
    dut.wvalid = 0
    yield RisingEdge(c)
    while int(dut.busy) != 0:
        yield RisingEdge(c)
    rv = str(dut.rdata)
    raise ReturnValue(rv)

tdata = 0xF000000F

def parity(x):
    x ^= x >> 16
    x ^= x >> 8
    x ^= x >> 4
    x &= 0xf
    return (0x6996 >> x) & 1 != 0

@cocotb.coroutine
def swd_device(dut):
    c = dut.swclk
    state = 0
    read = 0
    bits = 0
    ones = 0
    header = '00000000'
    while True:
        yield RisingEdge(c)
        d = str(dut.swdio)
        if d == '1':
            ones += 1
        else:
            if ones >= 50:
                state = 0
                print("reset")
            ones = 0

        if state == 0:
            if d == '1':
                state = 1
            header = ''
        else:
            state += 1
        header = d + header
        if state == 46:
            state = 0
            rv = header[1:33]
            print(d, ones, state, header, safehex(rv))
            if not read:
                if parity(int(rv,2)) != int(header[0]):
                    print("parity fail")
            # parity is 0

        if state == 9:
            dut.swdio = 1 if header[::-1][3] != '1' else 0
        if state == 10:
            dut.swdio = 0
        if state == 11:
            dut.swdio = 0
            read = header[::-1][2] == '1'
        if read:
            if (state >= 12) and (state < 44):
                dut.swdio = 1 if (tdata >> (state-12)) & 0x01 else 0
        elif state == 12:
            dut.swdio = cocotb.binary.BinaryValue('z')
        if state == 12 and header[::-1][3] == '1':
            dut.swdio = cocotb.binary.BinaryValue('z')
            state = 0

        if read and (state == 44):
            dut.swdio = parity(tdata)
        if read and (state == 45):
            dut.swdio = cocotb.binary.BinaryValue('z')

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    dut.wvalid = 0
    cocotb.fork(Clock(dut.clock, 8000).start())
    cocotb.fork(swd_device(dut))
    for i in range(100):
        yield RisingEdge(dut.clock)
    yield rw(dut, 0x10, 0)
#    yield rw(dut, 0x10, 0xFFFFFFFF) # min 50 clocks with SWDIO = 1
#    yield rw(dut, 0x10, 0xFFFFFFFF)
#    yield rw(dut, 0x10, 0xFFFFE73C) # JTAG to SWD, 16 clocks high
#    yield rw(dut, 0x10, 0xFFFFFFFF)
#    yield rw(dut, 0x10, 0x0000FFFF) # after min 50 clks SWDIO high, idle 16 clocks
    yield rw(dut, 0, 0xF000000F)
    yield rw(dut, 1, 0xBEEFDEAD)
    yield rw(dut, 6, 0)
    yield rw(dut, 2, 0)
    yield rw(dut, 0x12, 2)
    yield rw(dut, 2, 0)
    yield rw(dut, 0, 0xDEADDEAD)
    for i in range(16):
        v = yield rw(dut, 2, 0)
        print safehex(v)
    yield rw(dut, 3, 0xDEADBEEF)
    for i in range(1000):
        yield RisingEdge(dut.clock)
