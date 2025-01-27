# Life in many languages

I've become interested in functional programming. Growing numbers of
processors and use of multi-threaded designs makes sticking with
functional mechanisms more appealing. In particular, I find the
arguments made by Rich Hickey (author of the language *Clojure*)
compelling.

I found myself on vacation with some travel time, and thought I would
explore functional programming techniques, and Clojure in
particular. I picked a small programming problem, Conway's Game of
Life, as mechanism to explore the language.

[Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) can be
written to use some non-trivial data structures, and it is a smallish
task that can be completed on a long plane ride. I thought I would
play with it to see how easy Clojure was to use different algorithms.

Once I had written 4 different versions of the game in Clojure, I
thought it had reasonable performance, but wanted to compare the
solution to implementations in other languages. I picked the most
performant algorithm and re-wrote it in several other languages,
trying to stick with a functional style.

I have some thoughts. These my be construed as opinion, and your
experience may vary. In most of these languages, I'm a novice, or I
haven't used the language in years. 

## The Algorithm

The implementation of Life uses a Set to represent the sparse array of
cells that are alive in any one generation. The set of changes for the
next generation are computed from the changes used in the last
generation. The changes themselves are sparse with respect to the set
of alive cells, so tracking the changes between generations saves some
work.

The algorithm itself is parallizable while computing the change
list.

## Performance

See the measurements below, but keep in mind that performance could
likely be improved in each language. If there's something really
stupid that I've done, or a trivial change that should be made to make
the programs fit the natural expression or tools available within a
language, I think those changes should be made. But, the code should
stay as functional as possible: immutable data structures, stateless
functions.

The goal was not to see which language is fastest, but to get a rough
idea of what kind of performance you might get on a CPU-intensive
task. There's not been a lot of effort expended to make the
implementations faster.

I also wanted to see how one might run computations in parallel, and
what effect that would have the code and the performance.

Here are some numbers from several personal computers, a 2020 M1
Macbook, an inexpensive NUC and a RaspberryPi 5. The number provided
here is generations per second for a [particular
pattern](https://conwaylife.com/wiki/R-pentomino) to run for 1000
generations.

Generations/sec 
===

Language          | M1 mac | AMD Ryzen 7 5700U | RaspberryPi 5
------------      | ------------- | ------------ | ------------ 
C                 | 36734  | 56679 | 32412 |
C#                |  1049  |  1590 | |
C++               |  9832  |  9226 |  5329 |
C++ (v2)          | 15761  | 18343 | 11189 |
C++ (v2.5, sparse)|  7902  | 13635 |  8074 |
C++ (v2.5, dense) | 30485  | 44393 | 27901 |
C++ (v2.5, custom)| 40773  | 57640 | 36983 |
Clojure           |  1438  |   582 | |
Common Lisp       |  4089  |  5385 | |
Elixir            |  1400  |  1095 | |
F#                |   806  |   628 | |
Go                |  1923  |  1805 | |
Haskell           |  1653  |  1416 | |
Janet             |   773  |   462 | |
Janet(2)          |  1208  | | |
Janet(3)          |  2316  | | |
Java              |  5128  |  5000 |  2487 |
Java (v2)         | 15873  | 27027 | 10989 |
Javascript        |   359  |   160 | |
Kotlin            |  4975  |  5434 | |
Nim               |  5761  |  6585 | |
OCaml             |  1858  |  1328 | |
Python (c-python 3.12) |  3279 | 1566 | |
Python (jython)   |  1287 |   558 | |
Racket            |  1439 |   922 | |
Ruby              |   411 |   231 | |
Rust              |  6506 |  9886 |  5273 |
Rust (v2)         | 22240 | 36732 | 20132 |
Scala             |  9345 |  7518 | |
Scheme (guile-2.2)|   313 |  1037 | |
Scheme (guile-3.0)|       |   809 | |
Scheme (chicken)  |   598 |   902 | |
Scheme (gerbil)   |   504 |   566 | |
Sql-postgres      |  1265 |   200 | |
Swift             |  1804 |  2480 | |
Typed Racket      |  1289 |   874 | |
Zig               | 11764 | 12196 |  7352 |
Zig (v2)          | 26315 | 40000 | 25000 |

The reported value is the second fastest of 5 or more runs. In most
cases this was also the fastest value as well.

*OMG, Haskell is a pain to benchmark. The reported value is an
average of 5 runs.*

## The Experience

Again, with the caveat that this was a small programming exercise and
that I'm only really comfortable programming in 2 of the languages,
there was a great variation in the time and effort needed to write
each version.

### Clojure

I started with Clojure and wrote at least 4 different versions of
Life. It's hard to say how long this version would have taken if I
started with another implementation and focused on how to replicate
it. In any case, I was running a basic version in a few hours.

I used the opportunity to learn other tools around the Clojure
ecosystem: a new editor, for example as well as some performance
tuning tools

I found myself using the REPL to diagnose error messages. If I did
something basic, like mismatched parens, the errors were fine. But
once a bit of code got expanded by a macro, the errors were very hard
to diagnose. I would resort to typing in small bits of code to slowly
build up to the expression I thought would work. By tweaking small
bits of the expression, I could usually figure out what was going on.

I started using *Parinfer* mode in Atom, and that was a very nice
experience. It simplified the task of typing matching brackets and
parenthesis, so much so that I hardly thought about it at all. I also
used Emacs and Clojure mode, which also worked just fine.

The REPL environment is very nice, too. The language's terseness makes
it easy to write small examples to exercise functions and macros that
were new and unfamiliar.

`lein` was a pleasure to use as well. It was easy to start a small
program, make changes, re-run it, update dependencies, etc.

I *liked* the fact that it was easiest to write in a functional style.
I learned a lot, which was my goal.

### Scala

A friend recommended Scala as an alternative way to get to functional
programming within the JVM ecosystem. It also supports strong typing,
and I thought that would be a chore. I find myself typing a lot of
duplicate declaration information why specifying types in Java, for
example:

```
Person person = new Person();
```

When using Java, I lean heavily on the IDE, often writing incomplete
declarations:

```
person = new Person();
```

and ask the IDE just add the type to make a complete declaration. I
like strong typing, I just don't like redundancy.

However, I found myself really liking Scala's strong typing. I found
the error messages to be clear when I got the typing wrong, or when I
messed up the syntax by typing '->' for "=>" or : instead of = for a
function definition. I just never ran into a "huh... 30 lines of
errors because I missed a semicolon on line 8."

I was pleasantly surprised I could make type aliases, like `typedef`
in C/C++. I could change my types from `Set[Position]` to a mnemonic
like `LiveSet` and it remained compatible with all things needing a
`Set[Position]`. I used this a lot and I think it clarified code over
the other implementations.

Not that it was intentional, but the Scala version is nearly as short
as the Python version.

I used a new editor, IntelliJ, which I was unfamiliar with, to write
Scala code. It was easy to get a plugin to support Scala. `sbt`, like
`lein`, was a pleasure to use: simple to get started, manage
dependencies, build and execute.

Even with copious references to online documentation, I had the Scala
version running in a couple hours, starting with downloading Scala,
IntelliJ, etc.

### Java

This is the language I use every day for work. There were no surprises
here: I could write Java quickly. I used IntelliJ even though I was
unfamiliar with it, because I couldn't be bothered to fetch my usual
editor (eclipse) for so little code.

But I probably spent half my time wrestling with maven.  I just wanted
to use the Immutable data structures from guava to write my
functional-style code. Somehow, the default Java version used by maven
is 1.5, and that was confusing IntelliJ. I spent more time cribbing
together a standard bit of boilerplate `pom.xml` than I did writing
the Java code.

And I have 10 years experience using maven! I just never start from an
empty project.

lein and sbt have learned lessons and built a newbie friendly
build/dependency management infrastructure.

### Python

I've been using Python for a long time, and use it for small tasks at
work.  It was the easiest and shortest implementation. It was very
close to running the first time I ran it.

Fortunately, I didn't need any dependencies, though perhaps I should
have tried to look for immutable versions of the built-in data
structures. Without dependencies, experimenting and writing Python has
few infrastructure requirements, which makes it very easy to write a
small program like Life.

I attempted to switch from using tuples for small data types to
`namedtuples` to improve readability, but performance suffered.

The limits of the CPython implementation are unlikely to provide
performance improvements with multi-threading, and the nature of the
problem does not lend itself to other ways of making Python programs
execute in parallel.

### C++

I've not programmed professionally in C++ for years. It was a struggle
to re-learn all the little idiosyncrasies of the language as I cobbled
together a reasonable implementation. 

This version was easily the longest and most difficult to write (to
this point, looking at you Haskell). I had to implement functions just
to print anything but primitive types. If I wanted to see the LiveSet,
I needed to write a loop to print the set. In all the other languages
I could just print a set and I'd get something useful to use while
debugging.

Error messages for template errors have improved in the last 20 years,
but I was still rewarded with a page of errors from a template
expansion. I had failed to provide a hash function for an
`unordered_set`. None of the errors said anything about a hash. That
said, the C++ error messages were consistently easier to understand
than the Clojure messages.

Some things were just very hard to do in C++ that were trivial in
other languages.  For example, representing the hard-coded start set
of live cells. I could get something to work, of course, but getting
something pretty *and* easy to read was much harder. In all the other
languages, it was trivial.

I wrote a Makefile to make sure I recorded the optimization, debugging
and warning options I wanted. It's a simple file, though, and one I
typed in without a second thought even after long years between C++
projects.

I finished writing most of my C++ version before I got to the final
line of code:

```
  board = nextGeneration(board);
```

And that's when I found out my strategy for using `const` to create
immutable types was insufficient. After some time reviewing
strategies, including an entire re-write to hide non-const values
behind a read-only interface, I decided to use auto_ptr and store the
board on the heap, and avoid the requirement to support `operator=`.

There were many cases where I just wrote bugs because C++ let me. My
initial version of `operator<` was just wrong: I was writing something
like Java's comparable... return 0, -1, or 1 for the return value. The
compiler was fine with that, though -1 is not a useful boolean value
for `operator<`.

I'm sure my code could be more efficient. There seems to be no end of
ways to tweak C++ to make it do something faster. As long as it's not
too involved, I'd be happy to change the code.

I did not have the time or inclination to put effort into writing
parallel version, though I did spend time doing so for Clojure, Scala,
Java, Haskell and Janet.

After writing several other implementations, like the one in C and
Zig, I've found performance to be sensitive to reallocation, so
tweaking `reserve` sizes finally improved performance to the level
you'd expect from C++.

### Haskell

If you're going to try functional programming, why not go all the way
with a pure functional language like Haskell? If I thought I struggled
with a language like Clojure, I nearly failed using Haskell.

I spent about 75% of my time learning how to intersperse IO operations
with computation, since the style of coding changes so much between
computation and IO-related functions. In the end, I isolated the IO
from the computation, which is The Right Way to Do It, I'm sure. It
just wasn't obvious that I should start that way.

The error messages were almost as hard to understand in Haskell as
they were with Clojure, and I used the same strategy of plunking small
snippets into the interactive prompt to get results.

There was a moment when I was unable to reproduce the working code
from the interactive environment in the compiled environment. It
appears to be well-known difference since I was able to find a
[StackOverflow article](https://stackoverflow.com/questions/3327532/haskell-pattern-matching-on-the-empty-set/3327561) about it right away.

I attempted to compile and run the Haskell version using multiple
CPUs, but the performance decreased, so I have that disabled in the
reported numbers.

Thank you to Alex Newton for making my Haskell less embarrassing.

-- A month later --

I implemented a few more suggestions, added a lot more typing. Towards
the end, I started to understand the error messages. Now I just don't
know what to think. This bit of code is very small and took a long
time to wring out, but I do like the result. Mostly.  Field
accessors-as-functions seem so clunky. I liked being able to create
type aliases and overall I think the result is readable.

I once heard someone say, or maybe I just made it up, that "Object
Oriented programming is higher-order functions for the
[unsophisticated]." A different word might have have been used for
unsophisticated. But I'm one of them, I think.

### Javascript

Javascript seems to go out of its way to be non-functional.  The Life
algorithm I chose is heavily dependent on Sets, to eliminate duplicate
work and to track the set of living cells. Sets in javascript don't
support storing a mutable data structure and the only aggregate value
I see in javascript that is immutable is a string. Rather than convert
cells to strings to store into sets, I chose to rely on the
`immutable-js` package, which provides immutable Set and Map data types
which can be used to model the data like the other languages.

Interestingly, Javascript is the only runtime that didn't support
sleep to wait between generations when trying to view the
output. Instead, async calls to a callback are made on a timer.

[Well, I can't really do an animation of Life using Sql, either, but
its not claiming to be a general purpose language.]

### Go

Go seems to be actively hostile to a functional style, and the
implementation of Life reflects this.

There's no built-in `Set` and the advice online seems to encourage you
to use a Map to implement your `Set`.  I grabbed one from a library.

There's no map() implementation, so there are a lot of for loops in
the code. There's no templates or generic/parametric typing so
anything that comes out of the Set has to be type asserted back to the
underlying value type. [This is updated now? I need to go back and
rewrite it using a more recent version of the language.]

I think there might be some fun in trying to parallelize the code
using language-specific features. May need to revisit this.

Performance was disappointing, but perhaps I'm doing something naive
and wasteful.

### Racket

I thought that writing Life in another lisp derivative would be simple
after writing it in Clojure. It was still surprisingly different.

I was very much confused over how to express lists and avoid function
evaluation. That is, properly quoting lists-as-data vs lists-as-code.
I was able to avoid this confusion in Clojure by using vectors for
data structures.

By the time I wrote the Racket implementation I had stopped caring
about structuring components together. In my mind, each generation of
the Game of Life is represented by the set of Live Cells and the list
of updates to apply to get to the next generation. A single instance
of a generation is what I call a Board. In Racket, it's cumbersome to
construct a Board and deconstruct it to get to the elements of the
board, so I just stopped doing that, and pass the set or the list to
functions as needed. In a bigger project, not grouping together parts
that should stay together seems like a bad idea.

I used the same convention for the update list: each change is a How
(live or die symbol) and the cell position. In Clojure this is a
little vector of two elements.  In Racket, I used a list with two
elements. But then I needed to resort to lispy list accessors, like
`cadr` to get to the second element of the list. And
lists-as-data-structures need quotes: `'('die '(0 0))` (Racket) rather than
`[die: [0 0]]` (Clojure).

The `for` methods and sequences of Racket are nice, but having map
work on sets, lists and vectors in Clojure means there are fewer
iteration mechanisms to learn.

I did not try to run anything in parallel.

It was easy enough to understand the error messages. Short messages
such as `value #f found expecting a procedure` along with line numbers
got me pretty close to problem. Sometimes the line number would be
incorrect, but the scope of the function was always right.

I used lisp-mode in emacs to edit, and command-line racket to run the
code between changes. I would not recommend this environment for any
real work, since indentation in lisp-mode was pretty awful. But it
gave me paren matching and emacs could parse the output of racket
errors, so it wasn't horrible.

I should revisit Racket and attempt a strongly typed version. There
are likely some simple changes to avoid list construction that might
help performance. I could at least try to do some work in parallel to
see if it helps or hurts.

### Ruby

I expected ruby to be more like python.  It turns out to be quite a
bit different. I have some experience writing
ruby-as-configuration-language, so some of the syntax wasn't new to
me. However, this was the first time I had written anything close to
algorithmic code.

It was nice that many of the basic functional features on lists
(Arrays) worked on Sets, too.

The syntax for set operations was neat, but I'm not sure I'd remember
that "|" is union and "-" is difference.

I found the lambda syntax `{|x| x * 2}` cumbersome, but it works and
is concise. I was surprised that a return in a lambda expression
terminated the outer function, so I had to hoist code with early
returns out to a function. That was probably for the best, style-wise,
anyhow.

Not having module-level values available in methods forced me to add
constants as arguments to functions. It wasn't hard, but it was
unexpected.

I liked the "\e" symbol representation for the escape character. I
didn't have to figure out how a decimal 27, or octal 33 or a hex 1b
was turned into a string character.

That performance, though: that's not great. I changed the coordinate
of a cell from a Struct to a list-of-2-elements, but that didn't have
any effect. I changed the top call for generations from recursive to
iterative, and that made no change, either.

I was surprised I could not write a for-loop over a range with
decreasing values: `(1..-1)`, but needed to use `1.downto(-1)`. It had
me scratching my head because I seemed to be able to do
`(1..-1).map{|x| x}` just fine.

Lots of quirks to learn, but development went pretty fast and the
error messages easy to diagnose. Online help and examples were
abundant. Emacs, in ruby-mode, was my editor.

### Elixir

I have a learning disability: I continuously misspell "Elixir" as
Elixer. Also, "Clojure" as "Closure" but I think that one is
forgivable.

Writing Life in Elixir was pretty fast and easy. Online documentation
was helpful, the built-in data types helped a lot. It even had the
coveted "min_max" function, which I've only seen in C++. 

Error messages were pretty good, even though things like `if` are
really macros under the covers. I was always forgetting the `end` to
my lambda's, but the error message was clear and told me that exact
problem.  Functions missing `end` keywords would report a problem at
the end of the file, but also did a good job of guessing where I was
missing the closing `end`.

I kept trying to index tuples with integers (`{1, 2}[0]`), which I
eventually figured out wasn't a feature tuples supported, but the
error message wasn't clear. And, of course, decoding tuples doesn't
need integer indexing.

It was strange to use `Enum.map(collection, f)` instead of
`collection.map(f)`, but I got over that.

I used elixir-mode for emacs to do my editing.

I used list comprehensions, but I didn't see a way to filter in the
middle of the comprehension, like I did in Python or Haskell.

It was much easier to do I/O in Elixir than Haskell, and so debugging
was easy. The handy `IO.inspect` function was very helpful.

Again, there was support for the escape character as "\e", which was
nice.

Using Elixir, I created the shortest, clearest method for encoding the
rules for Life:

```
  def rules(liveSet, pos) do
    count = neighborCount(liveSet, pos)
    case count do
      2 -> nil
      3 -> if !alive?(liveSet, pos), do: {:live, pos}
      _ -> if alive?(liveSet, pos), do: {:die, pos}
    end
  end
```

It might be worth going back to see if I can't clarify some of the
other implementations the same way.

I was able to add some parallelism which increased performance by
15-20%. The only other language that I've been able to get an increase
in performance with parallel execution is Java, though I've not tried
on most of the other languages.

### Rust

Writing code in Rust was strangely comfortable. The reference
ownership memory model was new to me so I read a bit about it before
attempting to build anything.  The concepts were fairly
straightforward, though I'll admit to a bunch of guessing when I was
feeding code to the compiler.

The error messages were very helpful and complete. The only gotcha I
hit consistently was adding a semicolon after the return value as the
final result of a function. This was documented in the tutorial I read
about reference ownership, so it wasn't tricky to figure out.

I used type aliases for the different data structures, ranges for
constant loops. The iterator/map/filter functional constructs are
similar enough to those in Java that I was able to adapt easily.

Performance is good, though not quite as fast as the C++ version. And,
as always, I could be doing something wrong, since this is my very
first Rust program.

Tooling was pretty good: installing cargo and building the project was
simple enough, though I did not end up using any packages outside of
`std`. Code was edited in emacs `rust` mode. I didn't even bother
running the compiler under emacs, the error messages and context
provided by the compiler made it easy to trace the error back to the
code.

Online documentation is very good, with simple examples to show off a
library function call, or a language feature. Every time I looked for
a something, I would just search for the name I use for that feature
and the term "rust-lang"... a search engine would provide the answer
in the first page of results.

This was the fastest "new language" implementation to write: just
about two hours from start to finish. That's very fast to go from
"Hello World!" to a program that benchmarks itself and uses advanced
data structures.

Not all the code is written in a functional style. `for` loops are
used in a couple of places, collections are pre-allocated for size for
performance. Attempts were made to use `rayon` to speed up the
algorithm, but it made it (only slightly) slower. I was hoping Rust
performance would get closer to the top performers, but I was unable
to get it there.

### Kotlin

Apparently I'm unable to learn from mistakes, because I used maven
to build my Kotlin project. It went better than my Java experience
but I think that's only because Kotlin doesn't have ancient examples
laying around the Internet.

Kotlin was surprisingly hard for me. I was able to type in the data 
structures easily enough.  In fact, that part went very fast.

I struggled getting IntelliJ to add the right dependency for the
kotlin immutable collections library. It added one, and the program
would run within IntelliJ, but then I could not build from the command
line.

I was irked that I could not define a constant based on a complex
expression. Sure, I could get into trouble executing arbitrary expressions 
to make a constant, and I could define an immutable `val`, but the 
naming convention is all wrong.  I could not easily define a 
constant data structure, such as the initial set of live cells. 
That is, there's no list of tuples as part of the syntax. I made a 
list of a data type, but it's fat and clumsy. 

Performance is less than Java and Scala. I don't know what I'm doing, 
so perhaps it's easy enough to fix with experience.

IntelliJ locked up for me as I was wrapping up. Given that JetBrains builds
both IntelliJ and Kotlin, I was expecting a smoother experience.

The Kotlin compiler was easy to understand.  I enjoyed not having to 
specify redundant type information.  I used immutable data classes 
for all my data structures and they were very nice.  I think Kotlin 
has a very readable result. Type aliases improve readability, though
the need to add '.toPersistentHashSet()' at the end of every transformative
pipeline constantly betrays the implementation details. Comparing the Java
and Kotlin versions for basic structures shows how much extra is required
for a simple data type in Java.

IntelliJ did suggest a simpler stream for counting neighbors, and I'm
going to go back and see if there are other languages that consume
a stream/iterator/etc with a count function that takes a predicate.
That was a good suggestion, and a good mark for IntelliJ.

### Zig

Zig, simple as the programming model is, with user-managed memory
allocation, and limited support for higher-order functions, did
support a usable debug print formatting with no extra work. This was
unbelievably welcome.  As were the defaults for the HashMap I used.

The documentation for the `std` library was, um, sparse.  I finally
resorted to searching the installed .zig files and guessing at
function names. I only needed a mechanism to sleep, and a way to time
the performance with millisecond granularity (or better).

Type aliases were nice. That let me define a new type name based on
existing types. Interesting that the type for something like
`AutoHashMap` looks like a function, with type arguments. See the
error message below for the type errors this created.


```
./life.zig:110:19: error: expected type 'std.hash_map.HashMap(Change,void,std.hash_map.AutoContext(Change),80)', found '@typeInfo(@typeInfo(@TypeOf(computeChanges)).Fn.return_type.?).ErrorUnion.error_set!std.hash_map.HashMap(Change,void,std.hash_map.AutoContext(Change),80)'
        changes = nextGen;
```

Here, the function `nextGen` returns a possible error, and the type
`changes` does not support that. This is reminicent of the very long
error messages one used to get with templates in C++. That's not great.

Once the program was working, I played around a little to tweak
performance. I turned on optimization, changed the allocator, and
tuned the HashMap capacities, and it got pretty fast.  But it's
written in a pretty low-level way, with hand-written loops, and manual
Set (Map) operations.

While I was typing this up, I checked, and it looks like arguments
passed to functions are immutable.  This didn't come up as I was
coding because the original design was written for a functional style,
so it was never an issue.  I altered the code to attempt to mutate a
parameter and received an error message.  That's a nice discovery,
because the other trappings of functional programming, such as
closures, currying, and more complicated higher-order functions are
not supported. Of course, there are ways to do these things manually.

Speaking of doing things manually, as you start to wander off into the
details of more complicated data structures, such as `HashMap`, you
can see things like the Context parameter, which is starting to look
like C++ template traits. Or java interfaces.  It provides functions
that are needed by the data structure data types and those functions
have arguments like `self` or `This`.

I never had a crash with a null pointer, or for that matter, any other
runtime crash, which is that basic premise of Zig. Development went
about as fast as C++, and would have been faster with more online
examples or library documentation.

The compiler could complain more about unused variables, imports and
definitions.

I used zig-mode in emacs. It runs the compiler to check the code and
reformat as you save the file, which I found that I liked.

# OCaml

Took me a while to get into the swing of OCaml.  I got stuck on some
basic syntax-level problems: `[a, b, c]` vs `[a; b; c]`.  I would call
functions with tuples `f(a, b)` vs. `(f a b)`. The compiler complained
about types, and I was completely lost on reading the type information
presented based on what I had provided.

Other than type confusion when using the wrong syntax, it went
alright.  It took me about as long to learn how to create and print
basic data structures as it took me to write the actual logic.  But
this is after writing out many functional versions, especially
grinding out the Haskell version.

I used taureg-mode in emacs, which was fine, but nothing special.
Auto indentation let me know when my syntax was wrong, which was
often.

Performance was disappointing.  I've turned on optimizations by
installing and using the `4.10.2+flambda` compiler as `ocamlopt`. It's
3x faster than the default `ocamlc` runtime, but it's still half as
fast as python.

There were some annoying collection/iterator issues. By specifying the
type of the collection to execute a method, such as `Set.map` you have
to change the function call if you switch from a Set to a List or
Seq. `Set.map` must return a `Set` of the same type, which is really
limiting.  For example, if I wanted to get the Set of first names from
a Set of People, I'd like to write `Set.map (fun p -> p.first) people`
but the result of `Set.map` on people must be the same type as people.
So, then I map over `Set.elements` but that generates an intermediate
list that is really unnecessary, especially if the result is to be
filtered before stuffing into some kind of collected result.

So, the base types (Set, Seq, List) exist, but did not work well
together for me; or I'm misunderstanding how they work together.

### C

[A programming language is low level when its programs require attention to the irrelevant]
(http://www.cs.yale.edu/homes/perlis-alan/quotes.html)

Well, it is fast.

I am comfortable in C, though it's been a while since I wrote anything
in it. I avoided writing life in C because I knew I'd have to build
some of the required data structures from scratch.

"Why didn't you use a library?" That's fair, and maybe I'll do a 2nd
version that leans on a library. But, there is no dependency
management tooling for C that is widely used, nor is there any sort of
standard library like there is for C++ that handles these basic data
structures. It's also an opportunity to point out the costs of error
handling and memory management on the C programmer.

Long as it is, this version only took me about 3 hours, with my creaky
old C skills. Still, considering I've written this code over a dozen
times already, and I already know C, it was not fast to write.

It helped having written the Rust and Zig versions in advance. I knew
there were some properties of the problem that informed my choices of
data structures. For example, it's possible to get a bound on the
number of changes per generation, so that data structure does not have
to be re-allocated while computing the change list. Having written the
problem in-the-most-functional-style-possible before, it was easy to
have `const` correct data structures and operations on them.

This is a tiny problem, and it is well-suited to being written in C:
integers, counting and conditionals. Still, there's a bunch of code
duplication in this short exercise:
 * enumerating the neighbor offsets
 * iterating over the hash map
 * deallocating memory under error conditions

These could be tightened up a bit, but that's not going to improve the
readability much.

### Swift

Very few problems. Online documentation was pretty good. Error
messages were good. Used emacs swift-mode for editing.

There are some interesting language choices. The whole "named
parameter" bit was surprising, and I don't know if I like it or if
it's brittle. Leaning towards liking it for overloading.

As I was coding along, I was guessing syntax. I found declaring a
variable of a type is easy enough:

```
   var i : Int = 0;
```

Same for function arguments:

```
   func f(i : Int) {
```

But the return value?  That uses an arrow (`->`):

```
  func f(i : Int) -> Int {
```

Of course, I guessed it would be:
```
  // not correct
  func f(i : Int) : Int {
```

Why the arrow over a colon here?

It was nice that `map`, `flatMap`, immutable values and the rest of
the functional goodness was available. I guessed at how reduce worked,
and got it correct.

I find myself liking the `{ $0 }` for lambdas. That simplified
reference is usually enough and there's no weird syntax like `{|arg|
code }` or `{ arg -> code }`. The dollar sign makes it clear that
we're getting some value from the context since it's not a legal
variable name elsewhere.

Performance isn't great, but I just found one optimization flag, and
haven't investigated other tweaks.

### F#

Fastest language to write: basically copy-and-modify the OCaml version.
Took me about as long to download the environment as it did to write Life
in F#!

That said, F# was easier to write than OCaml, primarily due to the Set
type inferring the type parameter. It was nice to have portable,
convenient and well-documented methods for sleeping and timing.

Error messages, that I saw, were easy to read. VisualStudio was used to 
edit because it came with the F# environment. 

Performance is not good; I'm not sure what I'm doing wrong, but it's
surprisingly bad for a strongly typed compiled language.  I made some
attempt to compile with optimization (see `run.sh`), which gave it a
30% boost.

### C#

Like F# is with OCaml, I thought that C# would be a review of Java. I
was wrong. Where I'm equally uneasy in OCaml and F#, I'm quite fluent
in Java (and all it's supporting packages), but C# is an ever growing
mystery for me.

I struggled to know the best way to make things immutable, especially
collections. When I switched from using `HashSet` to
`ImmutableHashSet` performance dropped by 30%. This made C# only
slightly faster than Javascript. This can't be the best a functional
C# can do: there's nothing in the way of the `ImmutableHashMap` that
the algorithm does that could not be optimized away.

I have to say I really liked the LINQ stuff.  I don't really
understand it, so I'm treating it like a way to do a list
comprehension. It seems to be Functional, in that it works on
immutable data structures and returns one. It was a reasonable
substitute for a `map` function.

The `var` keyword and type inference is nice. I like that I can leave
the type off a collection:

```
var List<Thing> things = new();
```

or
```
var things = new List<Thing>();
```

Like Java, the lack of a typedef hurts: the method signatures that take
template types get wordy and long:

```
private static IEnumerable<Change> ComputeUpdates(ISet<Coord> liveSet, ISet<Coord> neighbors)
```

It could be worse: it could be `IImmutableSet<Coord>`.

I found it strange that I couldn't put free-floating code and
constants in the namespace, outside of a class. I wish I knew why. My
mental model of what's going on in C# doesn't match reality, yet.

I was hoping I could do things on the stack with value types, so I
wouldn't have to create them constantly on the heap. I don't see how
this is done.

It's nice that the HashMap can figure out `hash` and `equals` without
having to supply them.  The `readonly` keyword is nice, but it's too
bad it's not the default.

The Range function takes start and count values. Every other language
that supports such an iterator takes start and end, which I find more
intuitive. It was so expected that I just assumed that's what it took
without reading very carefully.

I just verified that the MacOS version of dotnet is generating x86
executables, and not Mac ARM ones.  That helps explain the poor
performance of C# and F#.

Like F#, the C# code was written in VisualStudio.

### Typed Racket

The idea of a strongly typed (or, staticly type checked) lisp variant
was interesting. I'm familiar with optional typing in Python, and
wanted to give it a try.

The implementation is a bit different. Instead of relying on lists for
simple data structures, I used the `struct` constructor to define new
types. In many ways, I think this improved the code.  The random
appearance of list decomposition methods like `(car c)` changed into
`(Coord-x c)` which provides a lot more context for the reader.

Converting the code was harder than my experience using type
annotations in Python. I found that one of the library functions I was
using (`in-inclusive-range`) wasn't type annotated, so I needed to
define annotations for it. The type system seemed very confused by the
two-loop `for*/list` comprehension, so I re-wrote it as nested `for`
expressions.

The rest went surprisingly well. The notation is hard to read, but
everything is hard when it's new. At some point the typing helped me
convert the code from lists to structs.

The last problem I had was that structs, by default, do not export
enough features to support set membership tests.  Adding the magic
`#:transparent` to the struct definition fixed it, with the bonus of
giving me useful printable representations. The type system did not
save me from this mistake, and it would have been nice if it could.

Error messages for type errors got a little hairy, but it wasn't
overwhelming. They were easier for me to understand than Haskell/F#
because the typing wasn't interlaced with types created via partial
function application. That is, I never had to see type expressions
that were a result of using too few arguments to a method. The
compiler/interpreter would just complain that I hadn't provided enough
arguments. Haskell, by contrast, would complain of a type mismatch
because I was improperly using a new function that was the result of
too few arguments.

Typed Racket seems to give up at a lambda definition. It might give up
on all functions, but I was careful to provide type annotations to the
functions defined at package scope. The type checker seemed to think
that all my lambda functions took values of type `Any` even if it was
perfectly knowable what it required from the functions used within. I
don't dislike providing expected types to functions as a reasonable
approach to type annotations. At the module level, it makes for
reasonable documentation. It complicates the lambda definition,
though.

The level of typing defined for values is pretty impressive. I'm not
sure it helped to know I had a Zero instead of an Integer, but it
didn't get in the way or cause me any problems, either.

To print the Life board, which I use for testing and validation, each
version scans the set of living cells and determines the bounding
box. I converted this version to use a technique I use in most of the
other implementations: apply a function "expand-box" to the current
bounding box for each cell. In most other languages I start with a
tiny box, which is defined using maximum values for integer.  Since
Racket doesn't have a defined maximum (or minimum) value, I had to
invent one.  Alternatively I could define the box using the first cell
position, but depending on the looping constructs, or pattern
matching, this might be more trouble than I feel like exploring: it's
really only used for debugging.  The plain Racket version used min/max
functions over the set of all positions. This works, but I really like
the functional approach of expanding the box, rather than extracting
the components of each cell location.

I used DrRacket to write this version.

### Nim

Somewhere I read that Nim was similar to python so I gave it a whirl.
The error messages from the compiler were very nice, typically readable
and close to the true error.  In particular, the messages about generic types
were quite readable.  I made many newbie syntax mistakes and the messages
nearly always landed in the right location.

I had one instance where I was unpacking a tuple:

 let (a, b) = functionCall(data)

But the error message was on the function definition.  That was 
the only case where the error messages led me astray.

I'm a little confused by the use of seq, the use of collect, and the use
of the sugar module.  They appear to be options to do similar things, but 
I remain confused on which is the best to use.

I did not see a mechanism to get the compiler to emit file names and
offsets that emacs might parse to support finding those lines in the
compilation buffer.  I didn't look too hard, so maybe it just works
for other people. I edited the code with nim-mode in emacs.  The
collect (macro?) mechanism confused it somewhat.

Performance is good.

### Janet

Someday I hope to be working on tiny little computers for fun. My hope
is that Janet will be a nice extension language for that
environment. Like Clojure, it's lisp-like with a bit of deviation from
traditional syntax to support hash-maps and arrays more directly like
most other modern scripting languages.

The error messages in Janet are very good, though I was confused by
this:

```
repl:1:> (+ 1, 2, 3)
repl:1:5: compile error: cannot use unquote here
```

Once I learned to read "unquote" as "stop adding commas" every other
message was great. Lines attributing the location of the error were
spot-on; the messages were particularly clear.

It's interesting to note that Janet comes with a simple little
game-of-life example that demonstrates what a nice little language it
is. That version is faster than my algorithm.

The example computes the neighbor count for all cells in each
generation. The algorithm used in many-lives only computes the
neighbor count around those cells that have changed. Perhaps that
optimization is not worth the effort and the complexity.

Janet does not support sets as a type, which is a little sad.

Unlike most of the other languages, I was able to get a small
performance improvement (40%) by using multiple threads. However, that
speed is still half that of the simpler (single threaded) algorithm.

Hmm... converting the janet example to python, I get a performance
improvement there, too.

Maybe it's time to re-write everything to use the simpler alogrithm
from the Janet example.

### Common Lisp

The Common Lisp experience was a little jarring. The error messages
being spit back with ALL UPPERCASE added another step between `(this
is my code)` and understaing `BROKEN: (THIS IS MY CODE)`.

I implemented the simpler version of life. I found the hash-table
mechanism to use for sets and maps, but it is not particularly
full-featured or easy to use. I would have liked to translate from
collection (list) to set (hash-table) without having to build a
hash-table and then add each item. I would have liked to use the same
iteration mechanisms on lists as a hash-table. I would have liked to
have iterated through a hashtable to produce a new collection type.

For example, there isn't a function that builds a new collection by
default. The function `map` will do this for lists, but `hashmap` does
not. Or maybe there is a function, but I can't find it.

But, at least there was a hash-table, a mechanism for building new
types, and a means by which a hast-table collection of those types
could be created. Not bad for 1990.

Writing this little program in CL really made me appreciate the
features and function set of Clojure (and Janet).

Performance is surprisingly good.

### SQL

It's weird, but you can use a query to generate successive generations
of a game-of-life board. I was able to visually validate the generated
board at different generations with some tricky queries.

The performance is pretty shocking when you consider it keeps the
entire history of all 1000 generations in a persistent table.

### Scheme

I started off a little enamored with Scheme as a simple, but powerful
language. I'm quite sure it is still both of those things, but I don't
know how much I'd like to work in it.

First, portability: trying to execute the same code under guile and
chicken is not trivial. Let's just take the `1+` function. It was used
in guile examples and did not exist in chicken. For sure this is easy
enough to define, but why doesn't it exist?

I have no idea what's going on with import and/or use-modules. Where
is this described and standardized? I just copied and pasted examples
until I found a combo that updated my local namespace and my code
could find the utilities I needed.

For example, why:

```
; chicken scheme
(import srfi-69)
```
vs
```
; guile
(import (srfi srfi-69))
```

[Here's a web page](https://rain-1.github.io/scheme-srfi-1.html) that
shows the many ways of importing srfi1 for various schemes.

If I had two implementations of python (for example) and I wanted to
write something as simple as the Game of Life in those two different
versions, it would be trivial to make them work against the same
source file. In fact, I modified the python version to run in python2
and it runs under C python3, python2 and jython just fine.

Performance is not great. Maybe I'm doing something horrible in my
implementation. Racket and common lisp are more than 3 and 6 times
faster, respectively. It's slower than SQL running under postgres.

The functions over collections (map, hash-table-fold) were nice.
However, I didn't find anything simple to generate the neighbor
offsets. For example, python's list comprehension:

```
rng = (-1, 0, 1)
offsets = [(x, y) for x in rng for y in rng if x or y]
```

I managed to come up with something using map-append and filter, but
in the end decided that a hard-coded list was easier to understand. It
may be easier to understand than the list comprehension above, too.

Using chicken's `csc` to compile down to a small-ish executable was
pretty sweet.

Update:

I just tried to reuse the same code to run under gerbil scheme. The
website claims that gerbil scheme is modern and supports "the most
common" SRFIs. Yet SRFI-69 (basic hash tables) was finalized in 2005,
which is 19 years ago, and I don't see it listed as supported.
Certainly one *can* adapt the hash functions provided, and I have, but
it looks like even basic data structures have not been uniformly
standardized across implementations. That's going to make it tricky to
build much without committing deeply to a single implementation.

I'm not even sure if SRFI compatibility is worth searching for, or if
I should be looking for R7RS level of standardization.

I'm still lost when it comes to modules. Fortunately the Game of Life
is so small I don't have to know the extent to which the namespace
created is defined, exported and shared.

Why guile, chicken and gerbil? I've always been interested in guile
since it was announced as the "GNU extension language" back in the
90s. After having so many issues with imports I thought I'd try other
implementations and these other two had been mentioned in online
comments I'd read recently.

I heard chez scheme is fast, but I could not work out how to get srfi
functions available for it.

C++, Rust and Java Revisited
===

I was reading the C implementation of hash tables in the Janet
implementation and ran into a bunch of interesting techniques. I'll
list them here without much in the way of explanation:

* no buckets of linked lists
* resizable record to keep metadata and array in the same memory block
* RobinHood hashing

After banging out the highly procedural style C version using a
faster (custom) hash table, the speed difference between C++ and C was
eye-opening.

In fact, the Java version was sometimes faster than the C++ version.
Digging into the implementation of `unordered_map`, I see it's using
the same "bucket and linked-list" hash table I originally used for C.
I had already discovered that approach destroys locality and CPU
caches.

So I went looking for a better C++ hash table. I stumbled onto [this
talk](https://www.youtube.com/watch?v=M2fKMP47slQ), which told me more
about hash tables than I ever wanted to know. As suggested in the
talk, I gave Google's `dense_hash_map` a chance. It was faster, but
not nearly as fast as the C map. So I sat down and wrote my own C++
hashmap container.

My hashmap container is simple, doesn't support `erase` but it is
source-compatible with `unordered_map` for this little use-case.
Trying to read and understand the provided STL `unordered_map` or even
`vector` is very hard. My little container class doesn't follow most
of the conventions used in those header files because I'm just not
smart enough to do it.

Kudos to Rust, Java and Zig for providing pretty nice hashmap
performance out-of-the-box. I created a second version (V2) of the
game of life for each of these languages which uses a blatantly
procedural style more commonly used with those languages. The
performance is very good.
