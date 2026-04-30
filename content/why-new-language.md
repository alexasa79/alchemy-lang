+++
date = '2026-02-18T11:23:03-05:00'
draft = true
title = 'Why New Language'
+++

New programming languages pop up like mushrooms. Nobody wants a new programming
language and certainly not I am. Then why bother with the new programming
language at all? What makes me somewhat confident that this project will not go
completely under the radar?

I think there are two fundamental things that are special about alchemy that are
not available elsewhere and I want to call them out.

# Macro language

The first thing is the macro language. Now, many programming languages have
their own macro language, but I think what others missed is the fact that having
a macro language requires us to learn two programming languages. First language
is the language itself and then there is also the macro language. It's just
complicated. The macro language itself turns out to be underpowered. There are
some things that it cannot do.

In Alchemy, I would like the macro language to be the language itself. There are
no two programming languages. There is no special syntax. Well, there is a
special syntax, but only to the degree where you have to tell the compiler where
is a macro and where is not a macro.

The macro language generates and/or manipulates program's code before it is
compiled. I've never seen a programming language where a macro language has a
library of useful functions and code snippets that can be used everywhere.

## A couple of small and useful examples

### Memory management

Consider a problem of memory management. Let's say we've implemented a TCP
server that does something useful. Whenever we receive a request, we have to
allocate a few objects to handle it, and then, when the request is done, we want
to free that memory. Let's say we identify that allocating these memory objects
and freeing them negatively impacts the system's performance. What can we do
about it?

We could switch to managing memory by using an arena. That is, we allocate one
large buffer for the entire request, and for every object we allocate, we will
advance a pointer in the arena. This seems like a good idea, but what if we want
to avoid changing the entire project. Instead, we want to change the memory
management only for the code that handles requests. How can we do that?

In a contemporary programming language, we would go and change every time we
allocate memory to do something else, to use arenas. But this is wasteful. What
if the arenas approach does not work at all? Can we make a single line change
that will fix this problem for us?

With Alchemy, we can. In Alchemy's standard library, there is a function that
traverses all children AST nodes of the current node. There is another function
that allows us to filter AST nodes based on some criteria. Lastly, the standard
library has multiple memory allocators, including arena. For every memory
allocation AST node, instead of implementing it using the standard memory
manager, we can change the node to use a different memory manager. Thus, with a
single line of code, we can change how we allocate and free memory for an entire
branch of code.

### Debugging 

Imagine we have a program that manipulates some variable.

Imagine that in one of the unit tests we all of a sudden find out that the value
of this variable is wrong. And let's say the variable goes through a long series
of manipulations. So it's not trivial to find out what happened to this variable
just by looking at the code. Normally, using a debugger wouldn't help us either
because debugger allows us to look at the state of the variable in a certain
moment. But it doesn't let us track the value of the variable over a long period
of time.

The way to solve this problem is by tracing the value of this variable and other
variables that contributed to it throughout the code and printing them to a log
file or maybe just standard output. Or if you are a web programmer, to the
browser's console.

Usually, you would have to go and pepper the code with printouts and that will
take you half an hour to do that until you find the problem. Well, what if your
macro language had access to AST node? Specifically, it could track all the
modifications to that variable. It could also track all other variables that
contribute to the value of that variable. And then what if we had a way to
inject code after every modification of the variable or its contributors?

This is exactly the kind of thing that Alchemy's macro language would allow you
to do. It will have an API to track all accesses to a variable. It will have an
API to track all expressions that change the value of the variable and all other
variables that contribute to the expression's value. We then should be able to,
recursively, apply the same logic to all variables, etc. For all these variables
of interest, we could then inject a code that prints the value of the variable.
This way with a single line change you could get the information about the
origin of the variable and all its contributors. Pretty neat!

### Generators



# Correctness checker

In recent years, there has been a development that went more or less under the
radar for mainstream software developers. I am talking about SMT solvers. SMT is
an extension of the SAT problem, a problem where we're given a boolean formula
with some unknowns and we're asked to find the set of values for these unknowns
that satisfies the formula – makes it true. SMT extends the SAT solver by
adding support for various theories, including manipulations with integers. What
it boils down to, is the ability to find a solution to a system of equations
using your computer.

Donald Knuth wrote that SAT solvers (and SMT solvers by extension) "can now
routinely find solutions to practical problems that involve millions of
variables and were thought until very recently to be hopelessly difficult."

Consider the simple program below:

```
fn main {
    n := try std.scan(uint)
    a := new int[n]
    for i := 0, i < n, i += 1 {
        a[i] = i * i
    }

    // Add previous element to each value
    // Bug: loop goes one past the end (should be i < n)
    for i := 0, i < n, i += 1 {
        a[i+1] = a[i+1] + a[i]
    }
    for i := 0, i < n, i += 1 {
        std.print("a[{i}] = {a[i]}\n")
    }
}
```

There is a bug in the loop, where we "by accident" go over the end of the array.
A bug like this would be difficult to catch because most of the time we will
allocate a little more than the exact number of bytes we ask for. This is just
an artifact of how a typical memory allocation works. Accessing one entry past
whatever we allocated will not lead to any problems most of the time. However,
in a typical memory allocator, if the size of `int` is 4 bytes and we allocate 8
entries, we will likely end up allocating exactly 32 bytes.

If we overflow that, we will likely corrupt memory that does not belong to us.
For instance, if we allocate 7 entries, the memory allocator will likely round
it up to 32 bytes. Then, overflowing one entry will do nothing harmful.

The interesting problem is that none of the contemporary programming languages
will catch this at compile time. Some languages will panic at runtime. This
comes at an expense, where the program must remember, at runtime, the size of
the array. The typical approach in Rust would be to use Vec. Go would use
slices. Both are fat pointers that remember both the pointer to the array and
the size.

This problem can be caught at compile time with relative ease. We can ask an SMT
solver to find a solution to a system of equations where `i` in the loop can be
bigger than `n-1`, the last index in the array. There is obviously plenty of
solutions and SMT solver will find one for us. Finding a solution to this
problem would lead to a compilation error.

Another, a little more subtle problem would be to notice that we're allocating
an arbitrary amount of memory. The amount of memory depends on the input we
receive, and that obviously can be anything. None of the contemporary
programming languages' compilers will even blink at this code. This code is
fundamentally correct. However, Alchemy's sanity tester will notice an unbounded
memory allocation.

To make the sanity checker happy with this code, we would have to add an
invariant. For example

```
    ...
    n := try std.scan(uint)
    inv n <= 32
    ...
```

Which brings us to invariants.

## Compile time and runtime invariants

Alchemy can check for a variety of problems, but these are various mechanical
correctness checks. Compiler does not really know what do you mean in one or
another piece of code. We need a mechanism to tell it.

Integrating SMT solvers into a programming language is not that new. The most
prominent example at this stage is [Dafny](dafny.org). Dafny implements an
approach where a programmer must write a program and also write a specification
for the program. Such specification is written in yet another language.

Alchemy tries to be a minimalist language. In the spirit of minimalism, we do
not want to introduce an extension to the language just for specifications.
Instead, we claim that program's specification can be described using just two
key words: `inv` and `assert`. `inv` is for compile time checks. `assert` is for
run time checks.

`inv` introduces an invariant. Introducing an invariant means that we require
that the compiler verify its correctness. The compilation will fail if we cannot
prove that the invariant holds in all cases.

## More broad conversation

I hope this is obvious that SMT solver can help us identify varety of bugs at
compilation stage.




