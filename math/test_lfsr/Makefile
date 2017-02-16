export VERILOG_SOURCES = $(PWD)/../lfsr.v
export TOPLEVEL = lfsr_32
export COCOTB=/home/dlharmon/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../../

test:
	make -C coco

clean:
	rm -rf *.pyc *~
	rm -rf coco/*~
	rm -rf coco/*.vcd
	rm -rf coco/*.xml
	make -C coco clean
