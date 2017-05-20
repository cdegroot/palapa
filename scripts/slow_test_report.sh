#!/bin/sh
#
#  Generate a list of all tests, sorted by duration
#
mix test --trace |
  grep '([0-9.]*ms)' |
  sed -e 's/.*\* test //' -e 's/ (\(.*\)ms)/	\1/' |
  sort '-t	' -n -k2
