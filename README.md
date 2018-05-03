# Palapa

This is a giant monorepo of code that's either under development or 
which I never plan to "release" in the sense of making Hex packages, 
expecting patches, etcetera. Whenever that happens, code will be 
pulled out to make everybody's life easier. Until that time, having
a simple repo is just nicer ;-). 

## Stuff in here

* `palapa/` is the original super umbrella. I moved it down a level
  in order to be able to setup ["poncho-style"](http://embedded-elixir.com/post/2017-05-19-poncho-projects/) things for Nerves.
* `attic/` contains failed experiments, parked stuff, the boulevard of broken dreams. 
* `tim/` is a heating thermostat project
* The root dir has some assorted scripts, CI stuff, and so on.

Packages typically have path-relative dependencies to each other.
