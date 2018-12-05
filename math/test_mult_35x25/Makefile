export TOPLEVEL_LANG = verilog
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=mult_35x25

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES_COMMON = ../mult_35x25.v
SOURCES = $(SOURCES_COMMON)

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/DSP48E1.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
