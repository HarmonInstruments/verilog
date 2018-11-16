# Copyright (C) 2014-2018 Harmon Instruments, LLC
# SPDX-License-Identifier: GPL-3.0-or-later
# display serializer/deserializer

import sys, random
import numpy as np
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Event
from cocotb.result import TestFailure, ReturnValue

@cocotb.coroutine
def read(dut, addr, data):
    c = dut.c125
    dut.display_host.wvalid = 1
    dut.display_host.waddr = addr
    dut.display_host.wdata = data
    yield RisingEdge(c)
    dut.display_host.wvalid = 0
    for i in range(300):
        yield RisingEdge(c)
    rv = int(dut.display_host.rdata)
    yield RisingEdge(c)
    raise ReturnValue(rv)

@cocotb.coroutine
def tx_pixels(dut):
    c = dut.c125
    i = 0
    while True:
        dut.display_host.pixel_valid = 1
        dut.display_host.pixel_first = int((i%32) == 0)
        dut.display_host.pixel_data = i
        yield RisingEdge(c)
        if(int(dut.display_host.pixel_ready) == 1):
            i += 1

@cocotb.coroutine
def i2c_ts_1(dut, sda, scl):
    dut.display_host.sda_t = sda
    dut.display_host.scl_t = scl
    for i in range(150):
        yield RisingEdge(dut.c125)
        if (int(dut.display_target.scl_t) == scl) and (int(dut.display_target.sda_t) == sda):
            print("completed in {}".format(i))
            break
    print("i2c_ts: scl: {},{} sda: {},{}".format(scl, dut.display_target.scl_t,
                                                 sda, dut.display_target.sda_t))

@cocotb.coroutine
def i2c_ts(dut):
    yield i2c_ts_1(dut, 0, 0)
    yield i2c_ts_1(dut, 0, 1)
    yield i2c_ts_1(dut, 1, 0)
    yield i2c_ts_1(dut, 1, 1)
    yield i2c_ts_1(dut, 0, 0)

@cocotb.test()
def run_test(dut):
    """Test DRU"""
    dut.reset = 0
    dut.display_host.pixel_valid = 0
    dut.display_host.sda_t = 0
    dut.display_host.scl_t = 0
    dut.display_host.wvalid = 0
    dut.display_target.sda_d = 0
    dut.display_target.scl_d = 1
    dut.display_target.fifostat = 1
    dut.display_target.rdata = 0xDEAD
    cocotb.fork(Clock(dut.c250, 4000).start())
    cocotb.fork(Clock(dut.c125, 8000).start())
    yield RisingEdge(dut.c125)
    yield RisingEdge(dut.c125)
    cocotb.fork(tx_pixels(dut))
    cocotb.fork(i2c_ts(dut))
    for i in range(100):
        yield RisingEdge(dut.c125)
    yield read(dut, 0, 0xCA)
    yield read(dut, 1, 0xFE)
    yield read(dut, 2, 0xBE)
    yield read(dut, 3, 0xEF)

    for i in range(16):
        dut.display_target.rdata = 0xBE00 + i
        v = yield read(dut, 4, 0x55)
        print hex(v)
    yield read(dut, 5, 0x00)
    for i in range(1000):
        yield RisingEdge(dut.c125)
