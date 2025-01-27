HOST=$(shell uname)

ifeq ($(HOST), Darwin)
  CXX=c++-14
  WARNFLAGS=-Wall
  IFLAGS=-I/opt/homebrew/include
  LIBS=
else
  CXX=gcc
  WARNFLAGS=-Wall
  LIBS=-lstdc++
  IFLAGS=
endif

OPTFLAGS=-O3
DEBUGFLAGS=-g
CXXFLAGS= $(WARNFLAGS) $(OPTFLAGS) $(DEBUGFLAGS) $(IFLAGS)

all: life life2

life: life.cpp Makefile
	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBS)

life2: life2.cpp array_hash.h Makefile
	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f life life2
