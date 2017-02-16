export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=sio_test

VIVADO = $(HOME)/software/Xilinx/Vivado/2016.4
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/src/unisims/

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = sio_test.v sio_host.v sio_target.v rx_iddr.v ../primitives/sync.v ../primitives/sync_pulse.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/IOBUF.v $(XPRIMS)/IDDR.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
