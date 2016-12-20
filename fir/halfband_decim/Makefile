export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=halfband_decim

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
VIVADO = $(HOME)/software/Xilinx/Vivado/2016.3
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/xeclib/unisims
SOURCES = halfband_decim.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/DSP48E1.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
