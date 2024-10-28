defmodule KV.Registry do
  @moduledoc """
  `KV.Registry` is a `GenServer` that manages and monitors `Agent` processes as buckets.

  It creates new buckets on demand, keeps track of them, and monitors their status.
  To improve the registry and allow for concurrent reads, we can use an ETS table.
  An ETS table will leverage a caching mechanism to directly read data in the `lookup` method.
  With this approach, the `GenServer` will not call its callback to perform a read from its map (state).
  Using ETS will not prevent race conditions... Be cautious! https://hexdocs.pm/elixir/erlang-term-storage.html
  """

  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Server Callbacks

  # Create a new GenServer with a state as a new map
  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  # Calls are synchronous and the server must respond
  # Return `{:reply, reply, new_state to continue the loop}`
  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  # Cast are asynchronous
  # Check if a process with a bucket already exists; if not, create one
  # start_link creates a bidirectional link (if one crashes, the other does too)
  # monitor is unidirectional (if the bucket crashes, the GenServer is notified but not affected)
  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      # Starts a KV.Bucket process directly, bypassing the supervisor.
      # {:ok, bucket} = KV.Bucket.start_link([])
      # Dynamically adds a child specification to supervisor and starts that child.
      {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
      ref = Process.monitor(bucket)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, bucket)
      {:noreply, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
