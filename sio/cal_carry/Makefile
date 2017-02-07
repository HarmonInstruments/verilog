export TOPLEVEL_LANG = verilog
export COCOTB=$(HOME)/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=cal_carry

VIVADO = $(HOME)/software/Xilinx/Vivado/2016.4
XPRIMS = $(VIVADO)/ids_lite/ISE/verilog/src/unisims/

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = cal_carry.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/CARRY4.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
