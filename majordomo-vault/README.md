# MajordomoVault

Secrets management for Majordomo.

This is a very simple approach: stuff lives encrypted in a data file,
$HOME/.majordomo.vault. It is encrypted with ~/.majordomo.passphrase
which is only needed on boot up, so it is for example simple to make
that file a symlink to /home/media/<user>/... and have the actual
data sit on an USB stick. Have the USB stick plugged in during startup
and then remove it to make sure that the vault on disk is secure.

This is nothing high security, just a simple and sufficient way to
keep things like API keys to thermostats out of the hands of the
baddies. Don't use it to secure ICBM launch codes, please.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `majordomo_vault` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:majordomo_vault, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/majordomo_vault](https://hexdocs.pm/majordomo_vault).
