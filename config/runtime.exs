import Config

config :logger, :console,
  level: :info,
  format: "$date $time [$level] $message\n"

config :kv, :routing_table, [{?a..?z, node()}]

if config_env() == :prod do
  config :kv, :routing_table, [
    {?a..?m, :foo@MacBookPro},
    {?n..?z, :bar@MacBookPro}
  ]
end

# config :kv, :routing_table, [
#   {?a..?m, :foo@MacBookPro},
#   {?n..?z, :bar@MacBookPro}
# ]

# To change the iex prompt
# config :iex, default_prompt: ">>>"
