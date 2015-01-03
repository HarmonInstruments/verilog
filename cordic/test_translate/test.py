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
dmult = 2**18-1.0
stages = 20
gain = 1.6467

@cocotb.coroutine
def do_rotate(dut, din):
#This coroutine performs a write of the RAM
    yield RisingEdge(dut.clock)
    in_scaled = np.round(din*dmult)
    dut.in_re = int(np.real(in_scaled))
    dut.in_im = int(np.imag(in_scaled))
    for i in range(stages):
        yield RisingEdge(dut.clock)
    yield ReadOnly() # Wait until all events have executed for this timestep
    result_mag = int(dut.out_mag.value.integer)*1.0/dmult
    result_angle = int(dut.out_angle.value.signed_integer)*1.0/amult
    expected = gain * din
    expected_mag = np.abs(expected)
    expected_angle = np.angle(expected)
    error_angle = result_angle - expected_angle
    error_mag = result_mag - expected_mag
    #print result_mag, expected_mag, error_mag
    #print result_angle, expected_angle, error_angle, error_angle * amult
    #error = np.abs(result - expected) / np.abs(expected)
    if error_angle > 1e-4:
        dut.log.error("FAIL: din = {}, angle = {}, result = {}, expected = {}, error = {}".format(din, expected_angle, result_angle, expected_mag, error_mag))
    #    raise TestFailure("incorrect result")
    raise ReturnValue((error_mag, error_angle))

@cocotb.test()
def run_test(dut):
    """Test CORDIC rotate"""
    clock = dut.clock
    a = cocotb.fork(Clock(clock, 2500).start())
    count = 1000
    angles = np.random.random(count) * 2.0 * np.pi
    din = np.exp(1j*angles)
    msum = 0.0
    asum = 0.0
    mrms = 0.0
    arms = 0.0
    for dinv in din:
        (m, a) = yield do_rotate(dut, dinv)
        msum += m
        asum += a
        mrms += m*m
        arms += a*a
    msum /= count
    asum /= count
    mrms /= count
    arms /= count
    mrms = np.sqrt(mrms)
    arms = np.sqrt(arms)
    print "mean magnitude error =", msum
    print "mean magnitude error (LSB) =", msum * dmult
    print "mean angle error (radian) =", asum
    print "mean angle error (LSB) =", asum * amult
    print "RMS magnitude error =", mrms
    print "RMS magnitude error (LSB) =", mrms * dmult
    print "RMS angle error (radian) =", arms
    print "RMS angle error (LSB) =", arms * amult
