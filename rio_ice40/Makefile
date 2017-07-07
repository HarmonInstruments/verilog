export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=rio_test

VIVADO = $(HOME)/software/Xilinx/Vivado/2017.2
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/src/unisims/

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = rio_test.v rio_host.v rio_target.v cells_sim.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/IOBUF.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
