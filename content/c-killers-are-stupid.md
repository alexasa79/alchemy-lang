+++
date = '2026-01-04T21:02:34-05:00'
draft = false
title = 'C Killers Are Stupid'
+++

This is just to say that any new programming language trying to replace C is
doomed before it even starts. The primary reason for that is the fact that C is
(at the time of writing this) a 52 years old language. People that choose C for
their project, are looking for one of two things:

1. They are either looking for a niche language for an environment where
   nothing else is available. IOT devices, various embedded systems, kernels are
   such environments.
2. Or they are looking for uncompromised performance stability and maturity.
   With a special emphasis on maturity.

New programming languages are not a good match for IoT and embedded systems
because of a large variety of hardware platforms that would have to be
supported. A small programming language project that just started would not have
the resource to cast their support net so wide. In some cases, the hardware
vendor can only afford supporting one programming language. The hardware
vendors, after all, are thinking about hardware and for them software is usually
an afterthought.

Kernels are somewhat similar in this sense. There is only one Linux kernel. How
many kernels do we need?

Projects that are looking for a mature programming language are looking for a
mature language and a new programming language is just not it.

Nothing in life is absolute. Obviously there are some exceptions. However
starting a programming language project with the intent of replacing C seems
like a dubious proposition. Such a project needs a better goal.
