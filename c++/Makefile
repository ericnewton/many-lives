# using auto, so turn off warnings about using c++11 keyword
# CLANG=true
ifdef CLANG
  CXX=c++
  WARNFLAGS=-Wall -Wno-c++11-extensions
  LIBS=
else
  CXX=gcc-12
  WARNFLAGS=-Wall
  LIBS=-lstdc++
endif

OPTFLAGS=-O3
DEBUGFLAGS=-g
CXXFLAGS= $(WARNFLAGS) $(OPTFLAGS) $(DEBUGFLAGS)

life: life.cpp Makefile
	$(CXX) $(CXXFLAGS) -o $@ $< $(LIBS)


clean:
	rm -f life
