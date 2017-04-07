[![Build Status](https://travis-ci.org/cdegroot/exgame.svg?branch=master)](https://travis-ci.org/cdegroot/exgame)

# Exgame

Hacking on writing games in Elixir, using ECS and wxWindows. Note
that I never write games, my knowledge is largely theoretical, and
I'm learning by doing.  Especially by implementing the silliest
version of Pong ever. Still, there might be code bits you're
interested in or maybe you just want to have a good laugh at my
incompetence.

## ECS

[ECS](apps/ecs) is an entity-component-system library. ECS is
apparently a well-worn design pattern in games, and I wanted to
experiment with it. It should work as a stand-alone library.

Although strictly not part of ECS, I'm also putting some simple
generic game stuff in here, like a trivial physics system. The only
thing that won't land in the library is any graphics stuff.

## WxEx

[WxEx](apps/wxex) contains some (mostly generated) Elixir constants
and record definitions for wxWidgets. It's quite complete and should
prove useful to anyone interacting with WX from Elixir.

## Pong

[Pong](apps/pong) is the first sample game driving the design. It's
very much a WIP, and probably the most over-engineered Pong game
on the planet as it uses ECS, a simple physics engine, etcetera.
It's the proof-of-concept for the other two libraries and once it's
done, I'll do Space Invaders :)
