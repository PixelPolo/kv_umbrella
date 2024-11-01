defmodule KV.Bucket do
  @moduledoc """
  `KV.Bucket` is a module to start buckets as `Agents` that acts as a simple key-value store.

  An Agent is a simple abstraction that allows
  to manage state in a separate process.
  This bucket will use a map (`%{}`) to store its state.
  https://hexdocs.pm/elixir/Agent.html
  """

  #  If the Agent crash, it should not be restarted (temporary)
  use Agent, restart: :temporary

  @doc """
  Starts a new bucket (a process as an Agent with an empty map as a state)
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`
  """
  def get(bucket, key) do
    # Agent.get(bucket, fn state -> Map.get(state, key) end)
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key`in the `bucket`.
  """
  def put(bucket, key, value) do
    # Agent.update(bucket, fn state -> Map.put(state, key, value) end)
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Deletes `key`from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(bucket, key) do
    # Agent.get_and_update(bucket, fn state -> Map.pop(state, key) end)
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end
