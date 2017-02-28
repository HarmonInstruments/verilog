export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=div_3e9

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES_COMMON = ../div_3e9.v
SOURCES = $(SOURCES_COMMON)

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v)

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
