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

from config import *

amult = 2**nbits_aout/(2.0*np.pi)
dmult = 2**(nbits_din-1)-1.0
gain = 1.64676025811
count = 5000

@cocotb.coroutine
def do_translate(dut, din):
    yield RisingEdge(dut.clock)
    in_scaled = np.round(din*dmult)
    dut.in_re = int(np.real(in_scaled))
    dut.in_im = int(np.imag(in_scaled))
    yield ReadOnly() # Wait until all events have executed for this timestep
    result_mag = int(dut.out_mag.value.integer)*1.0/dmult
    result_angle = int(dut.out_angle.value.signed_integer)*1.0/amult
    raise ReturnValue((result_mag, result_angle))

@cocotb.test()
def run_test(dut):
    """Test CORDIC rotate"""
    clock = dut.clock
    a = cocotb.fork(Clock(clock, 2500).start())
    angles = np.random.random(count) * 2.0 * np.pi
    din = np.exp(1j*angles)
    expected = gain * din
    expected_mag = np.abs(expected)
    expected_angle = np.angle(expected)
    result_mag = np.zeros(count)
    result_angle = np.zeros(count)
    for i in range(count+pipestages):
        if i < count:
            (m, a) = yield do_translate(dut, din[i])
        else:
            (m, a) = yield do_translate(dut, 0.0)
        if i >= pipestages:
            result_angle[i-pipestages] = a
            result_mag[i-pipestages] = m

    error_angle = result_angle - expected_angle
    error_mag = result_mag - expected_mag
    msum = np.sum(error_mag)/count
    asum = np.sum(error_angle)/count
    mrms = np.sqrt(np.sum(np.square(error_mag))/count)
    arms = np.sqrt(np.sum(np.square(error_angle))/count)

    print "maximum magnitude error =", np.max(error_mag)
    print "maximum magnitude error (LSB) =", np.max(error_mag) * dmult
    print "maximum angle error (radian) =", np.max(error_angle)
    print "maximum angle error (LSB) =", np.max(error_angle) * amult
    print "mean magnitude error =", msum
    print "mean magnitude error (LSB) =", msum * dmult
    print "mean angle error (radian) =", asum
    print "mean angle error (LSB) =", asum * amult
    print "RMS magnitude error =", mrms
    print "RMS magnitude error (LSB) =", mrms * dmult
    print "RMS angle error (radian) =", arms
    print "RMS angle error (LSB) =", arms * amult

    if np.max(error_angle) > 1e-4:
        dut.log.error("FAIL")
