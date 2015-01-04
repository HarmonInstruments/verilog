translate.v: cordic.py
	./cordic.py translate > translate.v
test:
	make -C test_translate

clean:
	rm -rf *~
	rm *.v
	make -C test_rotate clean
	make -C test_translate clean
