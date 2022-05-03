
lisp: main.c
	$(CC) -Wall -o $@ main.c -g -O2 -lm -ldl

.PHONY: clean
clean:
	rm -rf lisp
