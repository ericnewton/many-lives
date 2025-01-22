default: life life2

life: life.zig
	zig build-exe -O ReleaseFast $< -lc

life2: life2.zig
	zig build-exe -O ReleaseFast $< -lc

clean:
	-rm -f life
