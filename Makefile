#
#
PACKAGES := amnesix ecs erix pong simpler tim tim_nerves

all: setup deps test

deps:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; mix deps.get) done

test:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; mix test) done

#
# We install the global .tool-versions specifications and then
# anything extra in subdirectories. The interesting invocation of
# `test` here is to make sure we always exit 0 whether */.tool-versions
# exists or not.
setup:
	asdf install
	mix local.hex --force --if-missing
	mix local.rebar --force
	echo yes | mix archive.install https://github.com/nerves-project/archives/raw/master/nerves_bootstrap.ez
	for i in */.tool-versions; do test ! -f $$i || (cd $$(dirname $$i); asdf install) done
	for i in */.tool-versions; do test ! -f $$i || (cd $$(dirname $$i); mix local.hex --force --if-missing) done
	for i in */.tool-versions; do test ! -f $$i || (cd $$(dirname $$i); mix local.rebar --force) done
