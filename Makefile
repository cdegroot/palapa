#
#
PACKAGES := amnesix ecs erix pong simpler tim tim_nerves

all: setup deps test

deps:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; mix deps.get) done

test:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; mix test) done

setup:
	asdf install
	mix local.hex --force --if-missing
	mix local.rebar --force
	for i in */.tool-versions; do (cd $$(dirname $$i); asdf install) done
	for i in */.tool-versions; do (cd $$(dirname $$i); mix local.hex --force --if-missing) done
	for i in */.tool-versions; do (cd $$(dirname $$i); mix local.rebar --force) done
