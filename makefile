.PHONY: all clean

all: sum_test

sum_test: sum_example.o sum.o
	gcc -z noexecstack -o $@ $^


sum_example.o: sum_example.c
	gcc -c -Wall -Wextra -std=c17 -O2 -o $@ $<

sum.o: sum.asm
	nasm -f elf64 -w+all -w+error -o $@ $<

tester: tester.o sum.o
	gcc -z noexecstack -o $@ $^

tester.o: tester.c
	gcc -c -std=c17 -O2 -o $@ $<

clean:
	rm -r -f *.o sum_test