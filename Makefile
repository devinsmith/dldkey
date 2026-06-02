# Makefile for dldkey

.PHONY: all clean brute decrypt-tools

SRCS = main.c lookup.c
OBJS = $(SRCS:.c=.o)
DEPS = $(SRCS:.c=.d)

CC? = gcc
CXX? = g++

CFLAGS = -Wall -g3

EXE = dldkey
BRUTE = tools/dld_bruteforce
DECRYPT = tools/dld_decrypt

all: $(EXE)

$(EXE): $(OBJS)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJS)

brute: $(BRUTE)

$(BRUTE): tools/dld_bruteforce.c
	$(CC) $(CFLAGS) -O3 -o $(BRUTE) tools/dld_bruteforce.c -lcrypto

decrypt-tools: $(BRUTE) $(DECRYPT)

$(DECRYPT): tools/dld_decrypt.c
	$(CC) $(CFLAGS) -O3 -o $(DECRYPT) tools/dld_decrypt.c -lcrypto

.c.o:
	$(CC) $(CFLAGS) -MMD -MP -MT $@ -o $@ -c $<

clean:
	rm -f $(OBJS) $(EXE) $(BRUTE) $(DECRYPT) $(DEPS)

-include $(DEPS)
