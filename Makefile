# Makefile for dldkey

.PHONY: all clean

SRCS = main.c
OBJS = $(SRCS:.c=.o)
DEPS = $(SRCS:.c=.d)

CC? = gcc
CXX? = g++

CFLAGS = -Wall -g3

EXE = dldkey

all: $(EXE)

$(EXE): $(OBJS)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJS)

.c.o:
	$(CC) $(CFLAGS) -MMD -MP -MT $@ -o $@ -c $<

clean:
	rm -f $(OBJS) $(EXE) $(DEPS)

-include $(DEPS)
