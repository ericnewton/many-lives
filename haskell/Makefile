run: life
	./life

life: life.hs Makefile
	ghc -o life -threaded -O $<

clean:
	rm -f life
