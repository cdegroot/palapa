# BoidsUi

This is the Uderzo UI for a Boids demo.

## Running

After checkout,

```
   mix deps.get
   make -f deps/uderzo/setup.mk $(uname -s | tr A-Z a-z)
   mix run -e Demo.run
```
