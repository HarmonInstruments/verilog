export TOPLEVEL_LANG = verilog
export COCOTB=/home/dlharmon/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build

cosrom_22.v: genroms.py
	./genroms.py 22 > cosrom_22.v

cosrom_17.v: genroms.py
	./genroms.py 17 > cosrom_17.v

test_18: cosrom_17.v
	$(CLEANTB)
	rm -rf testbench/sim_build testbench/*.vcd testbench/*.xml
	export VERILOG_SOURCES="../cos_int.v ../sincos_18.v ../cosrom_17.v";\
	export TOPLEVEL="sincos_18";\
	make -C testbench

test_23: cosrom_22.v
	$(CLEANTB)
	export VERILOG_SOURCES="../cos_int.v ../sincos_23.v ../cosrom_22.v";\
	export TOPLEVEL="sincos_23";\
	make -C testbench

test: test_18 test_23

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
