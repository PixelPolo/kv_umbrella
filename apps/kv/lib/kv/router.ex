defmodule KV.Router do
  @moduledoc """
  The `KV.Router` module handles the routing of requests to the appropriate node
  based on the given bucket name. This allows for distributed processing by directing
  calls to specific nodes based on the bucket identifier.
  """
  require Logger

  @doc """
  Dispatches a request to the appropriate node based on the `bucket` name.

  - `bucket`: The bucket name used to determine the target node.
  - `mod`, `fun`, `args`: Specifies the module, function, and arguments to execute.

  If the target node is the current node, the function is executed locally.
  Otherwise, a supervised task is created to handle the request on the remote node.
  """
  def route(bucket, mod, fun, args) do
    # Get the first byte of the binary
    first = :binary.first(bucket)

    # Try to find an entry in the table() or raise
    entry =
      Enum.find(table(), fn {enum, _node} ->
        first in enum
      end) || no_entry_error(bucket)

    # Logger to see what happen
    Logger.info("Routing to entry: #{inspect(entry)}")

    # If the entry node is the current node, execute locally
    # else, create a supervised task to be execute on the other node
    if elem(entry, 1) == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  # Simple raise
  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect(bucket)} in table #{inspect(table())}"
  end

  @doc """
  The routing table.
  """
  def table do
    # First letter of the bucket is used to compare with ASCII codes ?a...
    # [{?a..?m, :foo@MacBookPro}, {?n..?z, :bar@MacBookPro}]
    # Get the table from the environment variable :routing_rable
    Application.fetch_env!(:kv, :routing_table)
  end
end
