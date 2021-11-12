# Life in many languages

I've become interested in functional programming. Growing numbers of
processors and use of multithreaded designs makes sticking with
functional mechanisms more appealing. In particular, I find the
arguments made by Rich Hickey (author of the language *Clojure*)
compelling.

I found myself on vacation with some travel time, and thought I would
explore functional programming techniques, and Clojure in
particular. I picked a small programming problem, Conway's Game of
Life, as mechanism to explore the language.

[Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) can be
written to use some non-trivial data structures, but it is a smallish
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


The implementation of Life uses a Set to represent the sparse array of cells
that are alive in any one generation. The set of changes for the next
generation are computed from the changes used in the last
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

Here are some numbers from my laptop, a 2020 M1 Macbook. The number
provided here is generations per second for a particular pattern to
run for 1000 generations.

Language  | Generations/sec
--------- | -------------
C++       |  9615
Clojure   |  1438
Go        |  1562
Haskell   |  1139
Java      | 10000
Javascript|   359
Python    |  3279
Racket    |  1439
Ruby      |   376
Scala     |  9345

The reported value is the second fastest of 5 runs . In most cases this
was also the fastest value as well.

*OMG, haskell is a pain to benchmark. The reported value is an
average of 5 runs.*


## The Experience

Again, with the caveat that this was a small programming exercise and
that I'm only really comfortable programming in 2 of the 8 languages,
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
all of the other implementations.

Not that it was intentional, but the Scala version is nearly as short
as the Python version.

I used a new editor, IntelliJ, which I was unfamiliar with, to write
Scala code. It was easy to get a plugin to support Scala. `sbt`, like
`lein`, was a pleasure to use: simple to get started, manage
dependencies, build and execute.

Even with copious references to online documentation, I had the Scala
version running in a couple hours, starting with downloading Scala3,
IntelliJ, etc.

### Java

This is the language I use every day for work. There were no suprises
here: I could write Java quickly. I used IntelliJ even though I was
unfamiliar with it, because I couldn't be bothered to fetch eclipse
for so little code.

But I probably spent half my time wrestling with maven.  I just wanted
to use the Immutable data structures from guava to write my
functional-style code. Somehow, the default Java version used by maven
is 1.5, and that was confusing IntelliJ. I spent more time cribbing
together a standard bit of boilerplate `pom.xml` than I did writing
the Java code.

And I have 10 years of using maven!

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

### C++

I've not programmed professionally in C++ for years. It was a struggle
to re-learn all the little idiosyncracies of the language as I cobbled
together a reasonable implementation. 

This version was easily the longest and most difficult to write. I had
to implement functions just to print anything but primitive types. If
I wanted to see the LiveSet, I needed to write a loop to print the
set. In all the other languages I could just print a set and I'd get
something useful to use while debugging.

Error messages for template errors have improved in the last 20 years,
but I was still rewarded with a page of errors from a template
expansion. I had simply failed to provide a hash function for an
`unordered_set`.  None of the errors said anything about a hash. That
said, the C++ error messages were consistently easier to understand
than the Clojure messages.

Some things were just very hard to do in C++ that were laughably
trivial in other languages.  For example, representing the hard-coded
start set of live cells. I could get something to work, of course, but
getting something pretty and easy to read was much harder. In all the
other languages, it was trivial.

I wrote a Makefile to make sure I recorded the optimization, debugging
and warning options I wanted. It's a simple file, though, and one I
typed in without a 2nd thought even after long years between C++
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
parallel version, though I did spend time doing so for Clojure, Scala
, Java and Haskell.  The limits of the CPython implementation are
unlikely to provide performance improvements with multithreading, and
the nature of the problem does not lend itself to other ways of making
Python programs execute in parallel.

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
snippits into the interactive prompt to get results.

There was a moment when I was unable to reproduce the working code
from the interactive environment in the compiled environment. It
appears to be well-known difference since I was able to find a
[StackOverflow article](https://stackoverflow.com/questions/3327532/haskell-pattern-matching-on-the-empty-set/3327561) about it right away.

I attempted to compile and run the Haskell version using multiple
CPUs, but the performance decreased, so I have that disabled in the
reported numbers.

### Javascript

Javascript seems to go out of its way to be non-functional.  The Life
algorithm I chose is heavily dependent on Sets, to eliminate duplicate
work and to track the set of living cells. Sets in javascript don't
support storing a mutable data structure and the only aggregate value
I see in javascript that is immutable is a string. Rather than convert
cells to strings to store into sets, I chose to rely on the
`immutable-js` package, which provides immutable Set and Map datatypes
which can be used to model the data like the other languages.

Interestingly, Javascript is the only runtime that didn't support
sleep to wait between generations when trying to view the
output. Instead, async calls to a callback are made on a timer.

### Go

Go seems to be actively hostile to a functional style, and the
implementation of Life reflects this.

There's no built-in `Set` and the advice online seems to encourage you
to use a Map to implement your `Set`.  I grabbed one from a library.

There's no map() implementation, so there are a lot of for loops in
the code.  There's no templates or generic/parametric typing so
anything that comes out of the Set has to be type asserted back to the
underlying value type.

I think there might be some fun in trying to parallelize the code
using language-specific features. May need to revisit this.

Performance was disappointing, but perhaps I'm doing something naive
and wasteful.

### Racket

I thought that writing Life in another lisp derivative would be simple
after writing it in Clojure. It was still surprisingly different.

I was very much confused over how to express lists and avoid function
evaluation. I was able to avoid this confusionin Clojure by using
vectors for data structures.

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
lists-as-datastructures need quotes: `'('die '(0 0))` (Racket) rather than
`[die: [0 0]` (Clojure).

The `for` methods and sequences of Racket are nice, but having map
work on sets, lists and vectors in Clojure means there are fewer
iteration mechanisms to learn.

I did not try to run anything in parallel.

It was easy enough to understand the error messages. Short messages
such as `value #f found expecting a procedure` along with line numbers
got me pretty close to problem. Sometimes the line number would be
incorrect, but the scope of the function was always right.

I used lisp-mode in emacs to edit, and command-line racket to run the
code between changes. I would not recommend this extremely simple
environment for any real work, since indentation in lisp-mode was
pretty awful. But it gave me paren matching and emacs could parse the
output of racket errors, so it was horrible.

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

Not crazy about the lambda syntax `{|x| x * 2}`, but it works and is
concise. I was surprised that a return in a lambda expression
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

