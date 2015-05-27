export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=fir_decim_4

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES_COMMON = fir_decim_4.v
VIVADO = $(HOME)/software/Xilinx/Vivado/2015.1
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/xeclib/unisims
SOURCES_7SERIES = ../../primitives/dsp_DSP48E1.v ../../primitives/bram_72x512.v
SOURCES = $(SOURCES_COMMON) $(SOURCES_7SERIES)

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/DSP48E1.v $(XPRIMS)/RAMB36E1.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
