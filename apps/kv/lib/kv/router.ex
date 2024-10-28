defmodule KV.Router do
  require Logger

  @doc """
  Dispatch the given `mod`, `fun`, `args` request
  to the appropriate node based on the `bucket`.
  """
  def route(bucket, mod, fun, args) do
    # Get the first byte of the binary
    first = :binary.first(bucket)

    # Try to find an entry in the table() or raise
    entry =
      Enum.find(table(), fn {enum, _node} ->
        first in enum
      end) || no_entry_error(bucket)

    # If the entry node is the current node, execute locally
    # else, create a supervised task to be execute on the other node
    Logger.info("Routing to entry: #{inspect(entry)}")

    if elem(entry, 1) == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect(bucket)} in table #{inspect(table())}"
  end

  @doc """
  The routing table.
  """
  def table do
    # If the first letter of the bucket is...
    # [{?a..?m, :foo@MacBookPro}, {?n..?z, :bar@MacBookPro}]
    # Or from the env var from kv/mix.exs
    Application.fetch_env!(:kv, :routing_table)
  end
end
