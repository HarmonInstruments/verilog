export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM
export TOPLEVEL=cdc_100_125

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = cdc_100_125.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v)

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
