export TOPLEVEL_LANG = verilog
export MODULE=test
export COMPILE_ARGS=-D SIM -I../
export TOPLEVEL=sio_test

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build
SOURCES = sio_test.v sio_host.v sio_target.v sio_common.v

export VERILOG_SOURCES=$(SOURCES:%.v=../%.v) $(XPRIMS)/IOBUF.v $(XPRIMS)/IDDR.v $(XPRIMS)/IDELAYE2.v $(XPRIMS)/ODDR.v

all: test

test: $(SOURCES)
	$(CLEANTB)
	make -C testbench

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
