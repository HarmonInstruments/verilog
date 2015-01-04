export VERILOG_SOURCES = ../translate.v
export TOPLEVEL = translate
export TOPLEVEL_LANG = verilog
export COCOTB=/home/dlharmon/software/cocotb
export MODULE=test
export COMPILE_ARGS=-D SIM -I../

translate.v: cordic.py config.py
	./cordic.py translate > translate.v

test: translate.v
	make -C test_translate

clean:
	rm -rf *~ *.v *.pyc
	rm -rf test_translate/*.vcd
	rm -rf test_translate/*.xml
	rm -rf test_translate/sim_build
