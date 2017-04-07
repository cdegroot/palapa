# Simpler

This library contains some tools and utilities to make writing good quality
Elixir code simpler.

I know it's risky to plaster layers over the language using macros and stuff.
Regardless, I'm giving it a spin here.

## Status

I'm using it in my own code. YMMV. Feel free to give feedback.

It's not on hex yet until I have done a couple of projects with it but of
course you can point `:git` dependencies at it.

## Stuff in here

`Simpler.Interface` helps in setting up objects that can easily be mocked. See
[this blog post](http://evrl.com/elixir/tdd/mocking/2017/03/05/elixir-mocking.html)
for some background info.

`Simpler` is some example code. It probably should move to a different place. That
and the test show how to use `Simpler.Interface`.

## TODO

Basic mocking works, so you can write code using interface definitions which will
generate forwarding calls, and then you can mock the implementation modules. Mocking
is based on a very dirty "generate a module per mock" hack which seems to work well. Needs
cleanup, more validation in some of my actual code, and then extension (expectations with
pattern matching most notably isn't there yet).

All the other TODOs are in the code. `ag` be your friend :-)
