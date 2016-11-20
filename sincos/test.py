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

pipestages = 6
count = 10000

@cocotb.coroutine
def do_angle(dut, angle, dmult, amult):
    yield RisingEdge(dut.c)
    in_scaled = np.round(angle*amult)
    dut.a = int(in_scaled)
    yield ReadOnly() # Wait until all events have executed for this timestep
    result_re = int(dut.o_cos.value.signed_integer)*1.0/dmult
    result_im = int(dut.o_sin.value.signed_integer)*1.0/dmult
    result = result_re + 1j* result_im
    raise ReturnValue(result)

@cocotb.test()
def run_test(dut):
    """Test complex exponential generator"""
    nbits_a = dut.NBA.value.integer
    nbits_d = dut.NBD.value.integer
    amult = 2**nbits_a/(2.0*np.pi)
    dmult = 2**(nbits_d-1)-1.0
    print "using {} bits for angle, {} bits for output".format(nbits_a,
                                                               nbits_d)
    dut.a = 0
    a = cocotb.fork(Clock(dut.c, 2500).start())
    angles = np.random.random(count) * 2.0 * np.pi
    #angles = np.linspace(0,1,count) * 2.0 * np.pi
    expected = np.exp(1j*angles)
    expected_mag = np.abs(expected)
    expected_angle = np.angle(expected)
    result = np.zeros(count, dtype=complex)
    for i in range(10):
        yield RisingEdge(dut.c)
    for i in range(count+pipestages):
        if i < count:
            v = yield do_angle(dut, angles[i], dmult, amult)
        else:
            v = yield do_angle(dut, 0.0, dmult, amult)
        if i >= pipestages:
            result[i-pipestages] = v

    result_angle = np.angle(result)
    result_mag = np.abs(result)

    error_angle = result_angle - expected_angle
    error_mag = result_mag - expected_mag

    msum = np.sum(error_mag)/count
    asum = np.sum(error_angle)/count
    mrms = np.sqrt(np.sum(np.square(error_mag))/count)
    arms = np.sqrt(np.sum(np.square(error_angle))/count)

    print "maximum magnitude error =", np.max(np.abs(error_mag))
    print "maximum magnitude error (LSB) =", np.max(np.abs(error_mag)) * dmult
    print "maximum angle error (radian) =", np.max(np.abs(error_angle))
    print "maximum angle error (LSB) =", np.max(np.abs(error_angle)) * amult
    print "mean magnitude error =", msum
    print "mean magnitude error (LSB) =", msum * dmult
    print "mean angle error (radian) =", asum
    print "mean angle error (LSB) =", asum * amult
    print "RMS magnitude error =", mrms
    print "RMS magnitude error (LSB) =", mrms * dmult
    print "RMS angle error (radian) =", arms
    print "RMS angle error (LSB) =", arms * amult

    for i in range(count):
        if np.abs(error_angle[i]) > 0.1 or np.abs(error_mag[i]) > 0.1:
            print angles[i], expected[i], result[i]

    if np.max(np.abs(error_angle)) > 1e-4:
        dut.log.error("FAIL")
