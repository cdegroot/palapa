#
#

# Everything with a mix.exs is a package.
PACKAGES := $(shell ls */mix.exs | xargs dirname)

all: setup deps test

deps:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; echo "Resolving deps in $$pkg"; mix deps.get) done

test:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; echo "Testing in $$pkg"; mix test) done

#
# We install the global .tool-versions specifications and then
# anything extra in subdirectories. The interesting invocation of
# `test` here is to make sure we always exit 0 whether */.tool-versions
# exists or not.
setup:
	docker-compose up -d
	asdf install
	mix local.hex --force --if-missing
	mix local.rebar --force
	mix archive.install --force hex nerves_bootstrap
	for i in */.tool-versions; do test ! -f $$i || (cd $$(dirname $$i); asdf install) done
	for i in */.tool-versions; do test ! -f $$i || (cd $$(dirname $$i); mix local.hex --force --if-missing) done
	for i in */.tool-versions; do test ! -f $$i || (cd $$(dirname $$i); mix local.rebar --force) done
