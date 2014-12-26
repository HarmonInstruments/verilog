export VERILOG_SOURCES = ../../translate.v

export TOPLEVEL = translate
export TOPLEVEL_LANG = verilog
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