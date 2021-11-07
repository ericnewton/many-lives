# using auto, so turn off warnings about using c++11 keyword
WARNFLAGS=-Wall -Wno-c++11-extensions
OPTFLAGS=-O3
DEBUGFLAGS=-g
CXXFLAGS= $(WARNFLAGS) $(OPTFLAGS) $(DEBUGFLAGS)
CXX=c++

life: life.cpp Makefile
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	rm -f life
