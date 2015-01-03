#!/usr/bin/env python

"""HIFIFO: Harmon Instruments PCI Express to FIFO
Copyright (C) 2014 Harmon Instruments, LLC

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

import sys, os, random
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Event
from cocotb.result import TestFailure, ReturnValue

amult = 2**20/(2.0*np.pi)
dmult = 16384
stages = 24
gain = 1.6467

@cocotb.coroutine
def do_rotate(dut, din, angle):
#This coroutine performs a write of the RAM
    yield RisingEdge(dut.clock)
    angle_scaled = int(round(amult * angle))
    dut.ain = angle_scaled
    in_scaled = np.round(din*dmult)
    dut.in_re = int(np.real(in_scaled))
    dut.in_im = int(np.imag(in_scaled))
    for i in range(stages):
        yield RisingEdge(dut.clock)
    yield ReadOnly() # Wait until all events have executed for this timestep
    result = int(dut.out_re.value.signed_integer) + 1j* int(dut.out_im.value.signed_integer)
    expected = gain * in_scaled * np.exp(1j*angle_scaled/amult)
    error = np.abs(result - expected) / np.abs(expected)
    if error > 5e-4:
        dut.log.error("FAIL: din = {}, angle = {}, result = {}, expected = {}, error = {}".format(din, angle, result, expected, error))
        raise TestFailure("incorrect result")
    raise ReturnValue(result)

@cocotb.test()
def run_test(dut):
    """Test CORDIC rotate"""
    clock = dut.clock
    a = cocotb.fork(Clock(clock, 2500).start())
    angles = np.random.random(20) * 2.0 * np.pi
    for angle in angles:
        a = yield do_rotate(dut, 1.0 + 0.0j, angle)
    for angle in angles:
        a = yield do_rotate(dut, -1.0 + 0.0j, angle)
    
