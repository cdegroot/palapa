# Erix

Erix is one of the pirates in Asterix, the son of the captain. As such, he
has intimate knowledge of rafts.

![Erix](http://www.asterix.com/asterix-de-a-a-z/les-personnages/perso/a38b.gif)

This is a fully TDD implementation of Raft, using LevelDB for
persistence. The tests in the main `test/` directory follow the
condensed summary of the protocol in Figure 2 of [the Raft
paper](https://raft.github.io/raft.pdf). The reason that I'm writing this
is a) because I can and it's a good exercise, and b) because the other
Raft implementations in Elixir I'm aware of are either unmaintained, untested,
or deemed by the author not to be fit for production use. This one is meant
to be maintained, used in production, etcetera.

For TDD purposes, the concept of time is externalized - servers receive
`:tick` messages and make decisions on counts of these messages. This makes
testing simple without the need for timeouts in tests. Clicks are sent every
hearbeat interval and other timeouts are specified as integer multiples (for
now, it's all hardcoded values in ``constants.ex``).

* [x] TODO: Implement all of the specs as basic tests
* [x] TODO: Add persistence of the required values
* [x] TODO: Implement LevelDB persistence engine
* [x] TODO: Client/state machine interaction
* [ ] TODO: Implement section 6, Cluster Membership Changes
* [ ] TODO: Implement section 7, Log Compaction
* [ ] TODO: Crazy integration testing

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
