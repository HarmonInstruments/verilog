export TOPLEVEL_LANG = verilog
export COCOTB=/home/dlharmon/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../

CLEANTB = cd testbench; rm -rf *~ *.vcd *.xml sim_build

RAMPRIM = RAMB36E1
SIMPRIM = ../RAMB36E1.v ../DSP48E1.v

SOURCES_23 = $(SIMPRIM) ../cos_int.v ../sincos_23.v ../cosrom_22.v
SOURCES_18 = $(SIMPRIM) ../cos_int.v ../sincos_18.v ../cosrom_17.v

cosrom_22.v: genroms.py x_ramb36e1.py
	./genroms.py 22 $(RAMPRIM) > cosrom_22.v

cosrom_17.v: genroms.py x_ramb36e1.py
	./genroms.py 17 $(RAMPRIM) > cosrom_17.v

test_18: cosrom_17.v
	$(CLEANTB)
	rm -rf testbench/sim_build testbench/*.vcd testbench/*.xml
	export VERILOG_SOURCES="$(SOURCES_18)";\
	export TOPLEVEL="sincos_18";\
	make -C testbench

test_23: cosrom_22.v
	$(CLEANTB)
	export VERILOG_SOURCES="$(SOURCES_23)";\
	export TOPLEVEL="sincos_23";\
	make -C testbench

test: test_18 test_23

clean:
	rm -rf *.pyc *~
	$(CLEANTB)
