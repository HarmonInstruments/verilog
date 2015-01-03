cordic.v: cordic.py
	./cordic.py > cordic.v
translate.v: cordic.py
	./cordic.py translate > translate.v

clean:
	rm -rf *~
	rm *.v
	make -C test_rotate clean
	make -C test_translate clean
