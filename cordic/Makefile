cordic.v: cordic.py
	./cordic.py > cordic.v
translate.v: cordic.py
	./cordic.py translate > translate.v

clean:
	rm -rf *~
	make -C testbenches clean