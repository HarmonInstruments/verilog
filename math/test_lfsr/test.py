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

import sys, os, random
import numpy as np
import matplotlib.pyplot as plt
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Event
from cocotb.result import TestFailure, ReturnValue

@cocotb.test()
def run_test(dut):
    """Test sequencer"""
    cocotb.fork(Clock(dut.c, 10000).start())
    for i in range(1024):
        yield RisingEdge(dut.c)
    d = np.zeros(8192)
    for i in range(len(d)):
        yield RisingEdge(dut.c)
        d[i] = dut.o.value.signed_integer
    print d
    plt.plot(d)
    plt.show()
    d *= np.kaiser(len(d), 10)
    fd = np.fft.fft(d)
    f = np.fft.fftfreq(len(d), 10.0e-3)
    plt.plot(f[:len(f)/2],20.0*np.log10(np.abs(fd[:len(f)/2])))
    plt.show()
