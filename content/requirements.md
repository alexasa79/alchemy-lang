+++
date = '2026-01-03T18:05:00-05:00'
draft = true
title = 'Alchemy Requirements'
+++

# What kind of language?

Generally speaking the goal is to have a language that could be used for any
purpose. At first we can probably skip embedded programming, although
contemporary devices like Raspberry Pi should be able to run programs compiled
with Alchemy.

There are several important requirements for the language:

## The basics

I am looking for a language that could replace C or C++ for typical use cases. I
do want to call out that [C killers are stupid](/c-killers-are-stupid/). Being
an alternative to C means that we do not compromise on features and we do not
compromise on performance. We want to support variety of platforms.

One potential niche that Alchemy could start with is being a language of
programming languages. I.e., a language where it's easy to implement a parser for
another programming language. Similarly, it should be easy to implement RPC
infrastructure. Alchemy's macro support should make it easy (more on this
later).

## Brevity, or less is more.

Contemporary programming languages are full of specialized syntax constructs.
Most languages mentioned in this document are actually a combination of multiple
languages. First language is the main language itself. Then there is at least
one more macro language. Some languages have also a pattern recognition
language. Others have specialized language for contracts. I need a language that
is easy to learn and easy to forget, only to re-learn later.

Another aspect of brevity is how much text one has to write to express some
logic. I want a language that has minimum syntax and semantic constructs. For
every feature we discuss we will ask ourselves is it possible to write it with
less characters. `func` is better than `function` and `fn` is better than
`func`.

## Knowing when to stop.

Knowing when to stop is another kind of brevity. C is known to release 0.75
features per year. C++ releases around 6 features per year and Rust releases 12.
(I heard this somewhere, but could not find an independent source to confirm
this, so take these numbers with a grain of salt; the numbers nevertheless
seem to be in the ballpark). According to [Signer et. al](#singer), Java's
specification has grown by annualized rate of 55.6 pages per year between 1996
and 2006.

The idea of minimalist language is incompatible with this rate of growth. While
we can add stuff to the standard library, the language itself should stay mostly
unchanged. I would like to see a change rate below that of C.

## Readability.

We will prioritize readability over brevity. We write the code once, but then we
read it over and over again, so readability is paramount.

## Macro language as the first class citizen.

Having a macro language is a major advantage. However, for some reason,
inventors of programming languages keep inventing new macro languages. In
Alchemy, Alchemy is its own macro language.

This makes Alchemy an interesting beast. Macro languages are interpreted
languages. Compiled languages are, well, compiled. I would like Alchemy to be
both compiled and interpreted. A macro written in Alchemy will run in the
context of the compiler. This creates a few interesting problems with security,
but aside from that this opens an entire universe of interesting features.

One such feature is allowing the macro full access to the program's AST. A macro
in Alchemy, is a function that can:
1. Inject new code into the program.
2. Change overall behavior of the program.
3. Modify existing code.

We will talk more about macros in Alchemy, but this is probably one of the most
fascinating features a language could have.

*Despite this is not the first "requirement" I call out, this is one of the
strong reasons why a new language is necessary.*

## Correctness checker.

A straightforward approach to the correctness checker is for the compiler to be
able to catch common problems. Given the requirement to have a somewhat low
level language, we want to support a notion of pointers and null pointer, but we
want the compiler to tell us when we're introducing bugs. We want to support
uninitialized variables, but the compiler should tell us when we're using such a
value. We want to support concurrency and multi-threading, but we want the
compiler to tell us when we introduce blatant race conditions.

The world of automated software verification is fascinating and full of
exceptionally interesting and complicated problems. I am and have been for a
long time a proponent of TLA+ ([2](#lamport)), HarmonyLang ([3](#harmony)) and
others. These two languages allow one to formally verify correctness of an
algorithm. However, they come with two major drawbacks:

1. Formal verification methods today imply checking every possible state of the
   system for a set of invariants. The emphasis on every possible state. Adding
   a single bit of state to the system, doubles the number of states we have to
   check. This is commonly referred to as an exponential explosion of state.
2. Formal verification system checks the correctness of a model. The model is
   written in TLA+ or other language. It does not check the correctness of an
   implementation of the model. Seemingly benign mistake, such as forgetting a
   semicolon, can introduce a bug into an implementation of a correct algorithm.

These two problems make formal verification with a model a hard sell, especially
in a context of heterogeneous teams, that mix junior and experienced engineers.
A different approach is to use some form of programming by contracts paradigm.
The idea here is that the engineer will specify the contract that the function
adheres to and the compiler will verify that the code implements the contract.
Having an SMT solver primed to hunt for bugs is a strong requirement.

Most programming languages that support programming-by-contract paradigm offer
this feature via large extension to the programming language. Not only the
entire topic of contracts is incredibly complicated, but now you also have to
learn a new programming language just to use this feature. In the spirit of
Alchemy's minimalism, the language extension to support contracts must be
brought to an absolute minimum.

*Despite this is not the first "requirement" I call out, this is one of the
strong reasons why a new language is necessary.*

## Contemporary experience.

Simply put, Alchemy must support the contemporary set of tools. Aside from
compiler, it must come with a LSP server. It must support REPL workflow as well
as support building complex software projects. A set of plugins for various
editors would be nice.

## AI.

AI is everywhere. Alchemy must be friendly to AI. One interesting aspect is
how to vibe code using Alchemy. This is where minimalism comes in handy. Imagine
having a short Alchemy manual for AI. Add this manual to the AI context and you
could vibe code in Alchemy without waiting for AIs to learn about Alchemy.

## Linker features.

One thing that I do not understand is why linking with a library would
automatically drag the entire library into the binary file. Ideally, the
language's linker should build a call graph and should include only the code
that is actually invoked in the program. This optimization is often referred to
as Dead Code Elimination or DCE.

I really like how Go approaches linking. Binaries compiled with Go are
statically linked by default. This has two major advantages:

1. The binary is universal for a platform. For Linux, it runs on Debians and
   RedHat's disregarding the exact versions of various libraries installed on
   the machine.
2. Static linkage means that correctness checker sees the entire code base and
   can let you know about a bug in a remote library.

Statically linked binaries are bigger, but I hope that DCE will be able to
cancel this out. Unlike in gcc and clang, I want this feature to be enabled by
default.

## Prefer smart compiler over slow code.

This is perhaps another way of looking at the correctness checker. We want
compiler to find the bugs for us instead of forcing us to do something in a
certain way. For example, one potential source of bugs are uninitialized
variables. Various programming languages approach this problem differently. C
mostly ignores it, while other languages force you to initialize the variable,
or sometimes initialize it for you.

The right way to approach this problem is to not force the program to initialize
all variables. This can affect performance. In many cases it is not strictly
necessary. With that said, the compiler will know when a variable being used
without initializing it. It should not force initialization, but it must
guarantee that the program will not use uninitialized value.

# To be continued...

## References
#### 1. Singer et al. {#singer}
John Singer, et. al. Programming Language Feature Agglomeration.
https://www.dcs.gla.ac.uk/~jsinger/pdfs/ple14.pdf

#### 2. Lamport {#lamport}
Leslie Lamport, My TLA+ Home Page
https://lamport.azurewebsites.net/tla/tla.html

#### 3. HarmonyLang {#harmony}
https://harmonylang.dev/

