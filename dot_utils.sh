#
# Various utility functions you can source in
#

plt_extra() {
  # Dunno why but Dialyzer doesn't pick up everything. Run this when a new PLT
  # has to be built.
  for i in brod kafka_protocol supervisor3; do
    dialyzer --plt _build/dev/dialyxir_erlang-19.2_elixir-1.4.2_deps-dev.plt --add_to_plt -r deps/$i/ebin/
  done
  dialyzer --plt _build/dev/dialyxir_erlang-19.2_elixir-1.4.2_deps-dev.plt --add_to_plt -r $(asdf where $(grep erlang .tool-versions))/lib/erlang/lib/wx-1.8/ebin
}
