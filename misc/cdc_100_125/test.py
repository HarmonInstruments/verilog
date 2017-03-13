#!/usr/bin/env python

"""
Copyright (C) 2017 Harmon Instruments, LLC
MIT License
"""

import sys, random
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Event
from cocotb.result import TestFailure, ReturnValue

count = 256

@cocotb.coroutine
def do_input(dut):
    yield RisingEdge(dut.c100)
    for i in range(count):
        while(random.choice([0,1,1,1]) == 0):
            dut.iv = 0
            yield RisingEdge(dut.c100)
        dut.i = i
        dut.iv = 1
        yield RisingEdge(dut.c100)
    dut.iv = 0

@cocotb.coroutine
def get_output(dut):
    while(int(dut.ov) == 0):
        yield RisingEdge(dut.c125)
    rv = int(dut.o)
    yield RisingEdge(dut.c125)
    raise ReturnValue(rv)

@cocotb.test()
def run_test(dut):
    """Test cdc"""
    cocotb.fork(Clock(dut.c100, 10000).start())
    cocotb.fork(Clock(dut.c125,  8000).start())
    cocotb.fork(Clock(dut.c50, 20000).start())
    dut.iv = 0
    dut.i = 0
    for i in range(3):
        yield RisingEdge(dut.c50)
    cocotb.fork(do_input(dut))

    for i in range(count):
        v = yield get_output(dut)
        if v != i:
            dut.log.error("FAIL")
