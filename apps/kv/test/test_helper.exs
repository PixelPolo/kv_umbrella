# Exclude distributed test if the node isn't alive
exclude = if Node.alive?(), do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
