export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=mult_35x25_s17

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES_COMMON = ../mult_35x25_s17.v
VIVADO = $(HOME)/software/Xilinx/Vivado/2016.4
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/xeclib/unisims
SOURCES = $(SOURCES_COMMON)

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/DSP48E1.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
