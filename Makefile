
lisp: main.c
	gcc -o $@ main.c -g -O2 -lm -ldl

.PHONY: clean
clean:
	rm -rf lisp
