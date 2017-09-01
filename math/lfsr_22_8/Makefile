export VERILOG_SOURCES = $(PWD)/lfsr_22_8.v
export TOPLEVEL = lfsr_22_8
export COCOTB=$(HOME)/software/cocotb
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
