# 
#
PACKAGES := amnesix ecs erix palapa pong simpler tim tim_nerves

all: setup deps test

deps:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; mix deps) done

test:
	set -e; for pkg in $(PACKAGES); do (cd $$pkg; mix test) done

setup:
	asdf install
	for i in */.tool-versions; do (cd $$(dirname $$i); asdf install) done
