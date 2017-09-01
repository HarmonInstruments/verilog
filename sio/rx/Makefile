export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=rx_test

VIVADO = $(HOME)/software/Xilinx/Vivado/2016.4
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/src/unisims/

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = rx_test.v rx_host.v rx_target.v cells_sim.v lfsr_22_8.v lfsr_22_1.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/IOBUF.v $(XPRIMS)/IDDR.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
