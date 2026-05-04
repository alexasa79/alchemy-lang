+++
date = '2026-02-18T11:23:03-05:00'
draft = true
title = 'Why a New Language'
+++

New programming languages pop up like mushrooms. Nobody wants another
programming language unless it solves a set of profound problems other languages
cannot solve. So why am I confident that this project will not go completely
under the radar?

I think there are two fundamental things that are special about Alchemy that
I have not seen combined anywhere else.

# Macro language

The first thing is the macro language. Now, many programming languages have
their own macro language, but I think what others missed is the fact that having
a macro language requires programmers to learn two programming languages. The
first language is the language itself, and then there is the macro language.
It's just complicated. The macro language itself often turns out to be
underpowered. There are some things that it cannot do.

In Alchemy, I would like the macro language to be the language itself. There are
no two programming languages. The amount of special syntax needed to implement
macros is kept to an absolute minimum: you must tell the compiler where's
your macros, and you need a few bits of syntax that only work in macros, but
this is it.

The macro language generates and/or manipulates the program code before it is
compiled.

## A couple of small and useful examples

### Memory management

Consider the problem of memory management. Let's say we've implemented a TCP
server that does something useful. Whenever we receive a request, we have to
allocate a few objects to handle it, and then, when the request is done, we want
to free that memory. Let's say we identify that allocating these memory objects
and freeing them negatively impacts the system's performance. What can we do
about it?

We could switch to managing memory by using an arena. That is, we allocate one
large buffer for the entire request, and for every object we allocate, we will
advance a pointer in the arena. This seems like a good idea, but what if we want
to avoid changing the entire project? Instead, we want to change the memory
management only for the code that handles requests. How can we do that?

In a contemporary programming language, we would go and change every memory
allocation site to do something else, e.g., to use arenas. But this is wasteful.
What if the arena approach does not work at all? Can we make a single line
change that will fix this problem for us?

With Alchemy, we can. In Alchemy's standard library, there is a function that
traverses all children AST nodes of the current node. There is another function
that allows us to filter AST nodes based on some criteria. Lastly, the standard
library has multiple memory allocators, including arenas. For every memory
allocation AST node, instead of implementing it using the standard memory
manager, we can change the node to use a different memory manager. Thus, with a
single line of code, we can change how we allocate and free memory for an entire
branch of code.

### Debugging

Imagine we have a program that manipulates some variable.

Imagine that in one of the unit tests suddenly find out that the value of this
variable is wrong. And let's say the variable goes through a long series of
manipulations. So it's not trivial to find out what happened to this variable
just by looking at the code. Normally, using a debugger wouldn't help us either
because a debugger allows us to look at the state of the variable in a certain
moment. But it doesn't let us track the value of the variable over a long period
of time.

The way to solve this problem is to trace this variable and the variables that
contributed to it, then print those values to a log file, standard output, or,
for a web program, the browser console.

Usually, you would have to go and pepper the code with print statements and that
will take you half an hour to do that until you find the problem. Well, what if
your macro language had access to the AST node? Specifically, it could track all
the modifications to that variable. It could also track all other variables that
contribute to the value of that variable. And then what if we had a way to
inject code after every modification of the variable or its contributors?

This is exactly the kind of thing that Alchemy's macro language would allow you
to do. It will have an API to track all accesses to a variable. It will have an
API to track all expressions that change the value of the variable and all other
variables that contribute to the expression's value. We should then be able to,
recursively, apply the same logic to all variables, etc. For all these variables
of interest, we could then inject code that prints the value of the variable.
This way, with a single line change you could get the information about the
origin of the variable and all its contributors. Pretty neat!

### Generic data structures

Implementing generic data structures usually implies having a special language
construct that supports them. In Alchemy, generics are plain macros.

```
    l := std.adt.dlist(int)
```

Creates `l`, a doubly linked list of variables of type `int`. Internally,
`std.adt.dlist` is a macro that accepts an AST node as an argument.

To make a linked list of integers we need an object that has pointers to the
next and previous members of the list and the integer itself. Internally, such
an object is called `___dlist_node_int`. The macro will check if
`___dlist_node_int` is already in the namespace. If it is not, it will inject it
into the codebase. Then it will initialize `l` as a head node for the doubly
linked list.

# Correctness checker

In recent years, there has been a development that went more or less under the
radar for mainstream software developers. I am talking about SMT solvers. SMT is
an extension of the SAT problem, a problem where we're given a boolean formula
with some variables and we're asked to find the set of values for these
variables that satisfies the formula – makes it true. SMT extends the SAT
solver by adding support for various theories, including manipulations with
integers. What it boils down to is the ability to find a solution to a system
of equations using your computer.

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

    // Add next element to each value
    // Bug: loop attempts to access one past the end (should be i < n-1)
    for i := 0, i < n, i += 1 {
        a[i] += a[i+1]
    }
    for i := 0, i < n, i += 1 {
        std.print("a[{i}] = {a[i]}\n")
    }
}
```

There is a bug in the second loop, where we "by accident" go over the end of the
array. A bug like this would be difficult to catch because most of the time we
will allocate a little more than the exact number of bytes we ask for. This is
just an artifact of how a typical memory allocation works. Accessing one entry
past whatever we allocated will not lead to any problems most of the time.
However, in a typical memory allocator, if the size of `int` is 4 bytes and we
allocate 8 entries, we will likely end up allocating exactly 32 bytes.

If we overflow that, we will likely corrupt memory that does not belong to us.
For instance, if we allocate 7 entries, the memory allocator will likely round
it up to 32 bytes. Then, overflowing one entry will do nothing harmful.

The interesting problem is that none of the contemporary programming languages
will catch this at compile time. Some languages will panic at runtime. This
comes at an expense, where the program must remember, at runtime, the size of
the array. The typical approach in Rust would be to use Vec. Go would use
slices. Both are fat pointers that remember both the pointer to the array and
the size.

This problem can be caught at compile time with relative ease. We can ask to
find a solution to a system of equations where `i+1` in the loop can be bigger
than `n`, the last index in the array. There are obviously plenty of solutions
and an SMT solver will find one for us. Finding a solution to this system of
equations will translate to a compilation error.

Another, a little more subtle problem would be to notice that we're allocating
an arbitrary amount of memory. The amount of memory depends on the input we
receive, and that obviously can be anything. None of the contemporary
programming languages' compilers will even blink at this code. This code is
fundamentally correct. However, Alchemy's correctness checker will notice an
unbounded memory allocation.

To make the correctness checker happy with this code, we would have to add an
invariant. For example:

```
    ...
    n := try std.scan(uint)
    inv n <= 32
    ...
```

This brings us to invariants.

## Compile time and runtime invariants

Alchemy can check for a variety of problems, but these are various mechanical
correctness checks. The compiler does not really know what do you mean in one or
another piece of code. We need a mechanism to tell it.

Integrating SMT solvers into a programming language is not that new. The most
prominent example at this stage is [Dafny](https://dafny.org). Dafny implements
an approach where a programmer must write a program and also write a
specification for the program. Such a specification is written in an extension
of the language.

Alchemy tries to be a minimalist language. In the spirit of minimalism, we do
not want to introduce an extension to the language just for specifications.
Instead, we claim that a program's specification can be described using just two
keywords: `inv` and `assert`. `inv` is for compile-time checks. `assert` is for
run time checks.

`inv` introduces an invariant. Introducing an invariant means that we require
that the compiler verify its correctness. The compilation will fail if we cannot
prove that the invariant holds in all cases.

### Run-time, compile-time division of labor

We discussed how an SMT solver can help us identify a variety of problems at
compile-time. However, there is a wide range of problems that cannot be solved
like this. The most obvious example is when we call an external function and use
its result to access a member of an array:

```
    ar := new int[10]
    ...
    n := try external_function(capacity(ar))
    std.print("{ar[n]}")
    ...
```

Since we do not know the return value of the `external_function`, we cannot make
assumptions about the correctness of accessing an element of array `ar`. Array
boundary checks are implicit in the compiler (i.e., making sure we do not access
past the end of the array is built into the compiler). Since we must consider
the value of `n` to be arbitrary, this code will not compile.

This is where we discover the secret power of `assert`. It's not just a runtime
check of correctness. `assert` serves as an additional piece of information that
is fed into the compiler. The compiler uses asserts as additional equations in
the system of equations that decides if the code is correct or not. The code
below will compile.

```
    arr := new int[10]
    ...
    n := try external_function(capacity(arr))
    assert n < capacity(arr)
    std.print("{arr[n]}")
    ...
```

Arguably, adding an `assert n < capacity(arr)` does not make this code more
correct because, if `n` is wrong, then the program will still crash at runtime.
It will crash with an assertion violation instead of segmentation fault, but a
crash is a crash, right?

There is a deeper way to look at assertions. A function is not just one large
block of code. It is a composition of smaller blocks, and each block has facts
that must be true before it runs, and facts that become true after it runs.

In that sense, an assertion in the middle of a function sits on the boundary
between two blocks. It is a postcondition for the code above it: the previous
code is expected to establish this fact. It is also a precondition for the code
below it: the following code is allowed to rely on this fact.

`assert n < capacity(arr)` is not merely a nicer crash before array access. It
states the condition under which the next block of code is meaningful. If the
assertion succeeds, the compiler and the reader both know that `n` is a valid
index for `arr`. If it fails, the program stops exactly where this local contract
was violated.

This argument is broadly known as Hoare logic. Hoare logic states that a
function is correct if it follows a series of preconditions and postconditions.

## Broader conversation

A correctness checker has a few important consequences for the rest of the
language.

There is a lot of complexity involved in solving multiple systems of equations
for every few lines of code. Some of these systems can be large and may take
seconds and perhaps even minutes to find a solution. It may take a long time
solving some of these systems.

A typical programmer's workflow is to edit the code, compile it, then run some
unit tests and repeat. In programming languages like C and Go, compilation is
relatively fast, so the compile step of the process may not be a burden.
Languages like C++ and Rust are notorious for taking long times to compile.
There have been multiple attempts to improve the compilation time with these
languages, and yet the problem hasn't been solved and likely will never be
solved. With Alchemy, I am afraid, the correctness checker will likely make
things even worse.

This is perhaps one of the major reasons why SMT checkers would be difficult to
integrate into existing programming languages. The language has to be built from
the ground up around the idea of correctness checkers. This is perhaps one of
the reasons why Rust came into being. Rust implemented a borrow checker, and one
cannot simply build something like this into an existing language. It has to be
built from the ground up. This implies a new programming language.

In the case of Alchemy, the compilation times will likely be even worse than
with C++ and Rust. We must think through not just how to compile the code
faster, but rather the entire process of writing the code and building
artifacts. Ideally, most of the code should be compiled before an engineer
explicitly invokes the build command.

Another interesting wrinkle to this problem is static compilation. To make
correctness verification simpler and more accurate, we need access to the entire
codebase. In the example above I described how having an external function whose
code is not visible makes it harder to prove correctness of everything else.
Alchemy language therefore must prefer static linking. While it should support
linking with external libraries, the preferred mode of operation should be
having access to the entire codebase that is being built. This is another reason
the correctness checker cannot simply be bolted onto an existing language.

# Summary

Here, I argue for a new language because its two core ideas need to be designed
into the language from the start: macros that are written in the language
itself, and a correctness checker powered by an SMT solver.

The macro system should make broad code transformations, debugging
instrumentation, and allocation strategies available as normal library-level
tools instead of a separate, underpowered language.

The correctness checker should let programmers express invariants and assertions
directly in code, catching mechanical errors like out-of-bounds access or
unbounded allocation before they become runtime failures. Together, these goals
imply a language built around whole-program visibility, static compilation, and
a workflow that can tolerate deeper compile-time analysis.
