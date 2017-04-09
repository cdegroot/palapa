# Erix

Erix is one of the pirates in Asterix, the son of the captain. As such, he
has intimate knowledge of rafts.

![Erix](http://www.asterix.com/asterix-de-a-a-z/les-personnages/perso/a38b.gif)

This is a fully TDD implementation of Raft, using RocksDB for
persistence. The tests in the main `test/` directory follow the
condensed summary of the protocol in Figure 2 of [the Raft
paper](https://raft.github.io/raft.pdf).

For TDD purposes, the concept of time is externalized - servers receive
`:tick` messages and make decisions on counts of these messages. This makes
testing simple without the need for timeouts in tests. Clicks are sent every
hearbeat interval and other timeouts are specified as integer multiples (for
now, it's all hardcoded values in ``constants.ex``).

TODO: Write it.
TODO: Implement section 6, Cluster Membership Changes
TODO: Implement section 7, Log Compaction

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `erix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:erix, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/erix](https://hexdocs.pm/erix).
