# Amnesix

An Elixir implementation of [scheduler](http://github.com/PagerDuty/scheduler). Named
after the Asterix character because I was fed up with naming every Elixir project
with `ex` somewhere in there and then noticed that `ix` actually occurs in `Elixir` ;-).

Asterix, of course, is one of the best strips ever.

![Amnesix](http://www.asterix.com/asterix-de-a-a-z/les-personnages/perso/g53b.gif)

Amnesix will allow you to enqueue future work to be done with the following
properties:

* It scales out elastically - in case of spikes, adding more nodes will quickly
add more capacity;
* It will survive crashes;
* It can work across multiple datacenters (mostly a property of Kafka ;-))
* It gets fed by Kafka and has no further dependencies.

In short, he makes sure you don't forget stuff in the future.

## Status

Current state:

- [x] Doc-driven design, no code yet. Everything below here is a lie.
- [x] Individual worker schedules and can load/persist stuff
- [x] A process that reads and writes the kafka journal
- [x] Brod subscriber group sets up workers, initializes them
- [x] Subscriber group changes are handled correctly
- [ ] Up the coverage with an integration test


## Kafka queue setup

Amnesix needs two queues, by default `scheduler` and `scheduler_journal`. The
latter is a compacted queue where in-memory state is kept.

    kafka-topics --zookeeper localhost:2181 --create --topic scheduler_journal --partitions 2 --replication-factor 1 --config cleanup.policy=compact --config segment.bytes=100000 --config segment.ms=900000
    kafka-topics --zookeeper localhost:2181 --create --topic scheduler --partitions 2 --replication-factor 1

Is what I'm using for development. The compacted topic has small segments and short TTLs
for a segment so we get reasonably fast compaction making tests a bit quicker.

## Design

Amnesix listens on a queue for work tuples, which are Kafka key/value pairs. The key is
basically describing what the work is for and is the partitioning key. The value is some
json describing the task:

    {
      "id": "unique tracking number for the job",
      "time": "unix timestamp the job should be executed",
      "url": "url that needs to be POSTed to"
    }

So, for example, we have this key/value pair:

    key: "user:1234"
    value: {
      "id": "renew-subscription",
      "time": "(unix timestamp for now plus 30 days)",
      "url": "https://my-renewal-service/renew/user/1234"
    }

That's all. In 30 days, user 1234 will be renewed.

### Meaning of key and id

The `key` partitions work and by virtue of Kafka consumer groups directs all work for
that key to the same node. The `id` identifies a particular job. Say that the user
switches from monthly to yearly payments, then sending:

    key: "user:1234"
    value: {
      "id": "renew-subscription",
      "time": "(unix timestamp for now plus 1 year)",
      "url": "https://my-renewal-service/renew/user/1234"
    }

will be guaranteed to be processed after the first message (as Kafka guarantees
ordering withint the same partition), and therefore we will use the duplicate
id to overwrite the previous message. The old one simply never gets executed.

### Kafka queues

The `scheduler` queue is the API to the system. It's a regular Kafka topic
where you can send jobs to. Set it up with more partitions then you ever
need parallelism (in terms of number of nodes processing messages).

The `scheduler_journal` queue is a compacted queue where state snapshots
are stored for each `key`'s Process. It should have the same number of
partitions for efficiency reasons (TODO check whether this is mandatory).

## Detailed processing steps

### Writing

Brod is used to divide partitions to consumers. So there's always at most
one worker for a partition (a worker can do more than one partition). When
a message comes in, it is sent to a partition-specific dispatcher which
finds the process responsible for the `key` and sends it the work order. The
process adds the work order to its state and sends the full state to the
journal topic.

### Executing

The worker process has a timer that triggers on the next job. If a new work
order comes in, the timer is cancelled and reset with the time left until
the first job has to be executed. When the timer triggers, the first job
is fetched, executed, and on success the state is rewritten. On failure,
the timer will be set to a small delay for a retry. If the job keeps failing,
it is logged as an error and removed. In either case, the new state is sent
to the journal topic.

### Restarts, etcetera.

Brod+Kafka will tell us which nodes will process what partitions. For
each partition, a process will read the journal queue, and send data to the
key-speficif process so it can rebuild its state. When the whole journal
queue has been read, processing will start. Each worker will get a signal
that the system is ready to roll and thus can setup their initial timer.

## Assumptions

Assumptions are that you won't have a ton of jobs scheduled per `key` and
that you have a nice number of partitions. That will make the system scale
nicely - the bottleneck is keeping the jobs for a single `key` in order.

Also, restarting the system, or changing nodes, will probably trigger a
complete reset and reload, as this is the safest option. This may be an
operation that stalls the system for a bit - the system is clearly not
meant to schedule with millisecond precision.

## MFA Hook

Amnesix has a hook that allows you to embed it in your system and instead
of doing URL posts, you can queue stuff like:

    key: "user:1234"
    value: {
      "id": "renew-subscription",
      "time": "(unix timestamp for now plus 1 year)",
      "mfa": "{RenewlSystem, renew-subscription, [user: 123, period: :year]}"
    }

Needless to say, that is Extremely Dangerous to enable so you'll have to dig
into the source code to find out how to switch it on.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `amnesix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:amnesix, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/amnesix](https://hexdocs.pm/amnesix).
