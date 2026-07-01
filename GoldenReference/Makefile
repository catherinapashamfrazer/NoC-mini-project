CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -O2

all: noc_golden

noc_golden: main.o noc_golden.o
	$(CC) $(CFLAGS) -o $@ $^

main.o: main.c noc_golden.h
	$(CC) $(CFLAGS) -c $< -o $@

noc_golden.o: noc_golden.c noc_golden.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f noc_golden *.o

.PHONY: all clean