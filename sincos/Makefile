export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=sincos

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES_COMMON = cos_int.v sincos.v
VIVADO = $(HOME)/software/Xilinx/Vivado/2016.4
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/xeclib/unisims
SOURCES_7SERIES = cosrom_RAMB36E1.v ../primitives/dsp_DSP48E1.v
SOURCES_GENERIC = cosrom_generic.v
SOURCES = $(SOURCES_COMMON) $(SOURCES_7SERIES)

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/RAMB36E1.v $(XPRIMS)/DSP48E1.v

all: cosrom_generic.v cosrom_RAMB36E1.v test

cosrom_generic.v: genroms.py
	./genroms.py generic > cosrom_generic.v

cosrom_RAMB36E1.v: genroms.py x_ramb36e1.py
	./genroms.py RAMB36E1 > cosrom_RAMB36E1.v

test: $(SOURCES)
	$(CLEANTB)

	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
