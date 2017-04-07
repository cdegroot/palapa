use Mix.Config

config :amnesix,
  brokers: [localhost: 9092],
  journal_topic: "scheduler_journal",
  work_topic: "scheduler",
  partitions: 64

import_config "#{Mix.env}.exs"
