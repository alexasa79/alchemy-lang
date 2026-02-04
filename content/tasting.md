+++
date = '2026-01-06T20:44:41-05:00'
draft = true
title = 'Tasting'
+++

## Hello world

```
fn main {
    std.print("hello world\n")
}
```

Already you can see a couple of interesting things. First of all, a function
starts with `fn` keyword. If a function does not accept parameters, you don't
have to type parenthesis. Same with the return type. This function returns
nothing.

The string "hello world\n", is printed using `std.print`. `std` is the name of
the standard namespace. `print` is the name of the function. The standard library
has internal hierarchy, but some of the most common functions available right
there at the top of the library.

No semicolons.

## Variables

There are a couple of ways to declare a variable:
1. We can declare an uninitialized variable by specifying its name and its type.
2. We declare a variable of arbitrary type by assigning it a value of that type.

Here are few examples:
```
fn main {
    uninitialized int
    initialized := true // initialized of type bool
}
```

Note that variable declaration starts with the name followed by the type. This
is different than C, where the type comes first. The `:=` operator creates a
local variable and initializes it with a value. The type will be that of the
value.

### Redeclaring variables

What happens if we already have a variable named `a` and we redeclare another
variable with the same name? Alchemy allows doing that and it is in fact a
convenient construct to use:
```
fn main {
    a := read_something()
    a := process_previous(a)
    a := process_further(a)
    produce_result(a)
}
```

We allow this in the language to allow initializing multiple variables with ":="
operator without worrying about mixing existing and new variables.

## Functions

We've seen a couple of functions. Here's one that accepts arguments:
```
fn func(arg1 int, arg2 int) {
    std.print("{arg1} @ {arg2}\n")
}
```

Alchemy supports overloading functions, so we can have multiple functions named
`func` accepting different set of arguments:
```
fn func(arg1 int) {
    ...
}

fn func(arg1 int, arg2 int) {
    ...
}
```

The two variants are distinguished by the type and the number of the arguments.
Still no return value though. Let's add it:

```
fn div(divident int, divisor int) {
    return divident / divisor, divident % divisor
}
```

Note a couple of things:
1. The return type of the function is still not declared. In Alchemy,
   declaring the return type of the function is optional. If not specified, the
   return type is implied from the return statements. If a function has multiple
   return statements and they contradict, compiler will return an error.
2. A function can return multiple results.

### Error handling in functions

Here's even more interesting example:
```
fn div(divident int, divisor int) {
    if divisor == 0 {
        return error("Division by zero")
    }
    return divident / divisor, divident % divisor
}
```

This gives us an introduction into error handling in Alchemy. Note that in this
case, the function returns either an error, or two integers. A function in
Alchemy can return either a single error or an arbitrary number of results. You
can think of the `error` keyword as a type casting that turns any variable or
object into an error variable or object. In this case, the function returns
an error with a string value "Division by zero".

Handling errors works as follows:
```
fn arithmetic(expr str) {
    arg1, arg2, op or err := parse_expression(expr)
    if err != nil {
        std.print("Error {err} parsing the expression")
        return err
    }

    if op == "/" {
        res := try div(arg1, arg2)
    } else {
        return error("Unsupported operation {op}")
    }
}
```

There are two kinds of error handling here. The first one using `or` operator,
creates a new variable of type pointer to an error. We then check if the error
is `nil` and if it's not, then it will point at the actual error value.

The second kind of error handling is using the `try` operator. This operator
will simply check if the function returned an error, and if it did, it will
propagate that error higher up the stack. If `div` did not return an error,
`res` will be initialized as expected.

Note that `div` and `arithmetic` both return an error. In both cases, the error
is a string. If we, for example, change `div` to return an integer error, then
this code will not compile because in one code path we will be returning a
string error and in another code path we will be returning an integer error. If
a function has multiple code paths that return an error, the type of the error
in all cases must match. This applies to both explicit `return` statements as
well as `try` statements.

What if we try to look at the `arg1`, `arg2`, or `op`, before we check for an
error? The values of these variables is conditioned on error being nil. If we
did not check if `err` is nil, then the values of these variables can be
potentially undefined and this will lead to a compilation error. In other words,
this example will not compile:
```
fn arithmetic(expr str) {
    arg1, arg2, op or err := parse_expression(expr)
    std.print("arg1 is {arg1}\n")
}
```

You can still ignore the error by using `_` as the name of the error variable.
This is a special syntax telling Alchemy's compiler to ignore the error. In this
case, variables `arg1`, `arg2` and `op` will be initialized with the default
initializer for their type.
```
fn arithmetic(expr str) {
    arg1, arg2, op or _ := parse_expression(expr)
    std.print("arg1 is {arg1}\n") // will print 0 if there was an error
}
```

This example, is the first time we saw an `if` statement. The syntax is rather
straightforward. `if` followed by a boolean expression.

## A glimpse into data structures

Let's say we want to create a vector of integers:
```
v := std.adt.vector(int)
v.push(10)
v.push(20)
```

`std.adt` namespace contains different data structures. In this case we need
`vector`. This is the first time we see a macro. `std.adt.vector` is a macro
function. It generates the code for a vector of integers, creates an object of
that type and returns it.

Vector can also accept some options and we can initialize its value:
```
v := std.adt.vector(int, {capacity=16}, {10, 20, 30})
```

Here we initialized it with options. In this case, there is only one option -
capacity. And we initialized it with initial values. We can omit initialization
values or the options structure (it is a structure).

Aside from vector, there are other data structures. For instance
`std.adt.linked_list` is a doubly linked circular list. `std.adt.bst` is a
binary search tree. `std.adt.hashmap` is a hash table.

## Data types, arrays and structures

Arrays are defined as
```
a := int[10]
```

You can initialize the array with
```
a := int[]{1, 2, 3, 4}
```

Note that you don't have to specify the size if there is an initializer. You can
mix size and initializer as well as tell Alchemy to initialize all members to a
certain type.
```
a := int[10]{1, }
```

This syntax will create an array of 10 elements and will initialize them all
with 1.

### Built-in types

We saw `int`, which is a platform specific integer type. It is usually either 32
or 64 bits. `uint` is the unsigned version and `float` is the platform dependent
floating point type.

Here's a list of other built-in types and their sizes:

- Types named `iN` where `N` is one of 8, 16, 32, 64, 128, represent signed
  integer of different sizes. For instance `i64` is a 64-bit signed integer.
- Types named `uN` where `N` is one of the 8, 16, 32, 64, 128, represent
  unsigned integers of different sizes.
- Types named `fN` are the floating point types.
- `str` is the "fat" string type. It is usually an `int` representing the length
  of the string, followed by the string's characters.
- `char` represents a single character. It is usually 4 bytes to accomodate a
  single unicode character.
- `byte` is a single byte type. It is the equivalent of `u8`.
- `bool` is the boolean type. Variables of this type can be either `true` or
  `false`.

### Structure types

We can create structures, as follows:
```
new_type := struct {
    field1 int
    field2 str
    field3 f64
}
```

Note that this will create a new type. Yes, it uses `:=`, same operator we used
to create a variable. As you might have guessed, this implies that you can use
this operator to create aliases to types.

```
alias := new_type
array := int[20]
```

When using structure type, no need to specify the `struct` keyword (like you
would in C). You can use the type name directly.

### Pointers

Alchemy supports pointers. Pointers to various types are declared as the name of
the type, followed by the `*` character. For example:
```
n := 10
pn := &n
pend := int* // uninitialized pointer
pstruct := new_type* // This is our structure type...
```

### Macro

Macros are one of the most exciting features in Alchemy. Macros in Alchemy are
functions. Instead of declaring the function with `fn` we will use `macro`.

```
macro fibonacci(n int) {
    if n <= 3 {
        return 1
    } else {
        return fibonacci(n-1) + fibonacci(n-2)
    }
}
```

Unlike the typical function, macros are executed in the compiler during
compilation. The consequence of that is that the arguments passed to macros must
be known at compile time. The following use of the `fibonacci` function

```
fn main { std.print("{fibonacci(10)}\n") }
```

will work, and the following:

```
fn main {
    a := 10
    std.print("{fibonacci(n)}\n")
}
```

will not work. That is because the value of the variable `n` is not known at
compile time.

The true power of macros in Alchemy comes from the ability to manipulate the AST
nodes of the program. ADT, or Abstract Data Types in Alchemy are implemented
using macros. Alchemy does not support templates or generics. Instead, macros
fulfil this role.

Macros returns an array of AST nodes. These nodes are then stored in the
variables that receive the return value of the macro.

```
list := std.adt.linked_list(int)
```

Here, `linked_list` is a macro inside of package `std.adt`. It receives a type
as an argument and returns the AST node representing an empty linked list of
that type. In the example above the type is an integer.

To implement something like `linked_list` we need two things. First we have to
introduce the `linked_list` structure into some scope. Since the implementation
depends on the type, the new type we introduce must be named after the type it
contains. For integers, `linked_list_of_int` seems like a good type name. The
scope we will introduce it to is the scope of the `std.ast` package. It is a
scope used by different packages and multiple users of linked lists in the
program will be able to find the `linked_list_of_int` there.

We start by checking if `linked_list_of_int` is already in the scope. One
helpful package that will help us with these and other AST manipulations is
`std.ct`. `ct` stands for Compile Time.

```
macro linked_list(n std.ct.type) {
    if !std.ct.find_in_scope(std.ct.package, "linked_list_of_##n.name") {
        std.ct.inject(std.ct.package, ast {
            linked_list_node_of_##n.name := struct {
                next linked_list_node_of_##n.name*
                prev linked_list_node_of_##n.name*
                data n
            }

            linked_list_of_##n.name := struct {
                head linked_list_node_of_##n.name
            }
        })
    }

    return ast init linked_list_of_##n.name {
        self.head.next = &self.head
        self.head.prev = &self.head
    }
}
```

Let's break down what's happening here:

The `macro` keyword declares a compile-time function. The argument `n` is of
type `std.ct.type`, meaning it receives a type (like `int`) at compile time.

We check if `linked_list_of_##n.name` already exists in the package scope. The
`##` operator concatenates identifiers, so for `n = int`, this becomes
`linked_list_of_int`. If the type doesn't exist, we inject it.

The `ast { }` block creates AST nodes from the code inside. This is how we
generate new code at compile time. We inject two struct definitions:
- `linked_list_node_of_##n.name`: A node with next/prev pointers and data
- `linked_list_of_##n.name`: The list itself, containing a sentinel head node

4. Finally, we return an `init` block. Init blocks are special constructs for
   in-place initialization. The `self` keyword refers to the variable being
   initialized. When someone writes:

```
list := std.adt.linked_list(int)
```

The macro expands to:

```
list := init linked_list_of_int {
    self.head.next = &self.head
    self.head.prev = &self.head
}
```

The init block guarantees that `self` IS `list`—same memory location, no copy.
This is critical for self-referential structures like our circular linked list,
where the sentinel node's pointers must reference itself. Without this
guarantee, we would create a temporary, set its pointers, then copy it to
`list`, leaving the pointers dangling at the old location.

Init blocks are like inline constructors that can see variables from their
surrounding scope, making them more flexible than traditional class
constructors.
















