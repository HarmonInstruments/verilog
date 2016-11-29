export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=tb

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
VIVADO = $(HOME)/software/Xilinx/Vivado/2016.2
SOURCES = uart.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v)

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
