# Java is not slow.
--

The version of the Game of Life I've chosen to benchmark is a tiny
little problem.

The initial pattern explodes into many living cells, but the number of
cells can be stored into a very small amount of memory. So little, in
fact, that much of it can fit in the cache of the processor. When
written to account for contiguous memory access, the runtime can be 2x
faster (or more).

Java isn't great for crushing little data structures into small bits
of memory. A C/C++/Zig/Rust structure can be laid out in contiguous
memory, but Java doesn't directly support this sort of representation.
But, if you can make some compromises to readablity and find a
representation that does support continuous storage, the rewards can
be high.

In this case, I've re-writen the C implementation in Java using a very
similar memory layout.

The result is a version that runs *faster* than the C version.

Java isn't my favorite language. Cramming data structures into caches
isn't my idea of a good time in any language, regardless of how easy
it is. But it is remarkable how difficult it is to implement what is
natural in a language like C/Zig/Rust. C++ had it's own struggles
between a "natural" implementation and speed.

