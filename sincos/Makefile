export TOPLEVEL_LANG = verilog
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=sincos

SOURCES_COMMON = cos_int.v sincos.v
SOURCES_7SERIES = cosrom_RAMB36E1.v ../primitives/dsp_DSP48E1.v
SOURCES_GENERIC = cosrom_generic.v
SOURCES = $(SOURCES_COMMON) $(SOURCES_7SERIES)

export VERILOG_SOURCES=$(SOURCES) $(XPRIMS)/RAMB36E1.v $(XPRIMS)/DSP48E1.v

all: sim

cosrom_generic.v: genroms.py
	./genroms.py generic > cosrom_generic.v

cosrom_RAMB36E1.v: genroms.py x_ramb36e1.py
	./genroms.py RAMB36E1 > cosrom_RAMB36E1.v

clean::
	rm -rf *.pyc *~ sim_build *.vcd results.xml

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
