+++
date = '2026-01-11T12:04:39-05:00'
draft = true
title = 'Copy Elision'
+++

As I am designing the language, I ran into an interesting problem. Let's say we
introduced a data type called `linked_list_of_int`. It's a structure that
references itself. It implements a doubly linked, circular list. When the list
is empty, its next and prev pointers will point at the node itself. Thus
self-referencing.

One straightforward way of initializing an instance of this structure is this:
```
l linked_list_of_int
l.init()
```

What if we wanted to use something like a designated initializer? Something like:
```
l := linked_list_of_int{node={next=&l, prev=&l}}
```

When we write the code like this, `l` is declared first and then we assign its
value. While `l` itself does not have valid values, it has an address. We can
then refer to that address when we initialize `next` and `prev`.


