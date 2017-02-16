export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM_DRU -I../
export TOPLEVEL=dru_1_4x

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = dru_1_4x.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v)

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
