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
import matplotlib.pyplot as plt

def plot_psd(td):
    window = np.kaiser(len(td), 20)
    window /= np.sum(window)
    df = np.fft.fft(td*window)/len(td)
    f = np.fft.fftfreq(len(td), 1.0e-3)
    df = df[:len(df)/2]
    f = f[:len(f)/2]
    offset = 0
    plt.plot(f,20.0*np.log10(np.abs(df)))
    plt.xlabel('Frequency (MHz)')
    plt.ylabel('dBFS')

@cocotb.test()
def run_test(dut):
    """Test hp triangular PDF dither gen"""
    cocotb.fork(Clock(dut.c, 4000).start())
    dut.prn = 0
    for i in range(2000):
        yield RisingEdge(dut.c)
    dither = np.zeros(16384*4*4)
    lfsr = np.zeros(len(dither), dtype=int)
    for i in range(len(dither)/4):
        dither[i*4+0] = int(dut.o0)
        dither[i*4+1] = int(dut.o1)
        dither[i*4+2] = int(dut.o2)
        dither[i*4+3] = int(dut.o3)
        lfsr[i*4+0] = int(dut.lfsr)&0xFF
        lfsr[i*4+1] = (int(dut.lfsr)>>8)&0xFF
        lfsr[i*4+2] = (int(dut.lfsr)>>16)&0xFF
        lfsr[i*4+3] = (int(dut.lfsr)>>24)&0xFF
        yield RisingEdge(dut.c)

    psd = np.zeros(512, dtype=int)
    for i in range(len(dither)):
        psd[int(dither[i])] += 1

    plt.plot(psd)
    plt.show()

    psd = np.zeros(256, dtype=int)
    for i in range(len(lfsr)):
        psd[lfsr[i]] += 1

    plt.plot(psd)
    plt.show()

    plot_psd(lfsr-128)
    plt.show()

    print 'min:', np.min(dither), 'max:', np.max(dither), 'mean:', np.mean(dither)
    plot_psd(dither)
    plt.show()

    n = np.arange(len(dither))
    t = n*1e-9
    d0 = 0.9*np.sin(t*2*np.pi*153.001e6)
    d1 = np.floor(d0+dither/256.0)

    #dut.log.error("FAIL")

    dither = np.random.random(len(d0)+1)
    dither = (dither[:-1] - dither[1:])
    print "hp tri:", min(dither), max(dither), np.mean(dither)
    print 'min:', np.min(dither), 'max:', np.max(dither), 'mean:', np.mean(dither)
    d2 = np.round(d0+dither)

    plot_psd(d0)
    plot_psd(d1)
    plot_psd(d2)
    plt.legend(['original', 'hw', 'sw'])
    plt.show()
