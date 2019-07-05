export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=swd_host

SOURCES = swd_host.v

export VERILOG_SOURCES=$(SOURCES) #$(XPRIMS)/IOBUF.v

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean::
	rm -rf *.pyc *~ *.vcd *.xml
