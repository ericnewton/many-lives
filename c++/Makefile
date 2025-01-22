# using auto, so turn off warnings about using c++11 keyword
# CLANG=true
ifdef CLANG
  CXX=c++
  WARNFLAGS=-Wall -Wno-c++11-extensions
  LIBS=
else
  CXX=gcc
  WARNFLAGS=-Wall
  LIBS=-lstdc++
endif

OPTFLAGS=-O2
DEBUGFLAGS=-g
CXXFLAGS= $(WARNFLAGS) $(OPTFLAGS) $(DEBUGFLAGS)

all: life life2

life: life.cpp Makefile
	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBS)

life2: life2.cpp Makefile
	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f life
