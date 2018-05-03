#!/bin/bash

for i in palapa tim
do
  (cd $i; mix deps.get; mix test)
done
