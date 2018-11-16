export TOPLEVEL_LANG = verilog
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=display_test
export PYTHON_BIN=python3

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = display_test.v display_host.v display_target.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/ODDR.v $(XPRIMS)/IDDR.v $(XPRIMS)/IOBUF.v $(LPRIMS)/IDDRX2F.v $(LPRIMS)/BB.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
