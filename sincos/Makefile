export VERILOG_SOURCES = ../cosine_18.v ../cosrom_17.v
export TOPLEVEL = sincos_18
export TOPLEVEL_LANG = verilog
export COCOTB=/home/dlharmon/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../

cosrom_22.v: genroms.py
	./genroms.py 22 > cosrom_22.v

cosrom_17.v: genroms.py
	./genroms.py 17 > cosrom_17.v

test: cosrom_17.v
	make -C testbench

clean:
	rm -rf *.pyc *~
	rm -rf testbench/*~
	rm -rf testbench/*.vcd
	rm -rf testbench/*.xml
