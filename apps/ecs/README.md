# Ecs

Entity-Component-System library. E-C-S is a system often applied in games
and other simulations to circumvent the often fluid and complex behaviour
of objects in these systems that is hard to capture in standard OO.

This is very much work in progress. A rough overview:

- Entities are GenServers. In this way, entity updates can be done in parallel;
- Components are modelled by structs in modules.
- Systems are pretty ad-hoc, but usually GenServers.

A System will usually loop. Entities keep pointers to their components in a
central Registry which Systems can use to fetch entities that have components
that they are interested in. An example is the SimplePhysicsSystem that does
velocity updates and collissions every tick. Velocity updates look like:

```elixir
def do_velocity_updates(state) do
  state.registry
    |> Registry.get_all_for_component(:velocity)
    |> Enum.map(&(VelocityComponent.tick(&1)))
end
```

Which asks the registry for all entities components that have a
`:velocity` tag (by convention, these are all components that are
defined in a module named `VelocityComponent`), and then calls
`VelocityComponent.tick` on them. The tick method will then update
the entity's `:position` component to the new position per the
velocity. Although currently the ticks are called synchronously it is
not hard to see how this can be ran in parallel; similarly, the `Registry`
module, which currently is a simple GenServer managing a Map, can easily
be rewritten to use an ETS table for more performance.

Overall, I think that the high level design leverages Erlang processes
quite well. Currently, I'm finalizing a Pong implementation to see how this
all works in practice, which may further inform the system's design. Until
then, documentation is relatively scant although there is good test coverage
and not too much complex code.
