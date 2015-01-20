export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=complex_mult

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES_COMMON = complex_mult.v dual_mult_add.v
VIVADO = $(HOME)/software/Xilinx/Vivado/2014.4
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/xeclib/unisims
SOURCES_7SERIES = ../primitives/dsp_DSP48E1.v
SOURCES = $(SOURCES_COMMON) $(SOURCES_7SERIES)

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/DSP48E1.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
