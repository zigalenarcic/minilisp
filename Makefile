
lisp: main.c
	gcc -o $@ main.c -g -O2 -ldl

.PHONY: clean
clean:
	rm -rf lisp
