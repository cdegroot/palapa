# Palapa

This is a giant monorepo of code that's either under development or 
which I never plan to "release" in the sense of making Hex packages, 
expecting patches, etcetera. Whenever that happens, code will be 
pulled out to make everybody's life easier. Until that time, having
a simple repo is just nicer ;-). 

The name comes from a previous iteration of this repository, as one
giant umbrella. I've since moved it to a "poncho" style repository
but I like the picture too much so I'm keeping the name. 

![Nice Picture Of A Palapa I Found On The Interwebs](https://nyxonenterprises.files.wordpress.com/2012
/05/jacky_li_beach_palapa_hires.jpg)


## Stuff in here

In alphabetical order:

* [Amnesix, a work scheduler using Kafka for persistence and distribution](amnesix)
* [Entity-Component-System library, for games and maybe other things](ecs)
* [Erix, a Raft implemenation that should be fit for production use](erix)
* [Game related utilities](exgame)
* [A Pong game using ECS](pong)
* [Generic coding and test tools](simpler)
* [A Thermostat system](tim)
* [Nerves packaging of said thermostat system](tim_nerves)
* [Some helpers for using WX from Elixir](wxex)
* The root dir has some assorted scripts, CI stuff, and so on.

Packages typically have path-relative dependencies to each other.
