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

pipestages = 4
count = 10

@cocotb.coroutine
def do_mult(dut, a_re, a_im, b_re, b_im):
    yield RisingEdge(dut.clock)
    dut.a_re = a_re
    dut.a_im = a_im
    dut.b_re = b_re
    dut.b_im = b_im
    yield ReadOnly() # Wait until all events have executed for this timestep
    result_re = int(dut.p_re.value.signed_integer)
    result_im = int(dut.p_im.value.signed_integer)
    raise ReturnValue((result_re, result_im))

@cocotb.test()
def run_test(dut):
    """Test complex multiplier"""
    nbits_a = dut.NBA.value.integer
    nbits_b = dut.NBB.value.integer
    amult = 2**(nbits_a-1)-1
    bmult = 2**(nbits_b-1)-1
    print amult, bmult
    dut.ce = 1
    a = cocotb.fork(Clock(dut.clock, 2500).start())

    a_re = np.random.randint(-1*amult, amult, count)
    a_im = np.random.randint(-1*amult, amult, count)

    b_re = np.random.randint(-1*bmult, bmult, count)
    b_im = np.random.randint(-1*bmult, bmult, count)

    p_re_expected = a_re * b_re - a_im * b_im
    p_im_expected = a_re * b_im + a_im * b_re
    p_re_expected /= (2**dut.S.value.integer)
    p_im_expected /= (2**dut.S.value.integer)

    p_re_result = np.zeros(count, dtype=int)
    p_im_result = np.zeros(count, dtype=int)

    for i in range(count+pipestages):
        if i < count:
            v = yield do_mult(dut, a_re[i], a_im[i], b_re[i], b_im[i])
        else:
            v = yield do_mult(dut, 0, 0, 0, 0)
        if i >= pipestages:
            (p_re_result[i-pipestages], p_im_result[i-pipestages]) = v

    error_re = p_re_result - p_re_expected
    error_im = p_im_result - p_im_expected

    print "maximum real error =", np.max(np.abs(error_re))
    print "maximum imag error =", np.max(np.abs(error_im))

    if np.max(np.abs(error_re)) > 1:
        dut.log.error("FAIL")
    if np.max(np.abs(error_im)) > 1:
        dut.log.error("FAIL")
