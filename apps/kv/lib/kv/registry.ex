defmodule KV.Registry do
  @moduledoc """
  `KV.Registry` is a module to start a `GenServer` that
  manages and monitors `Agent` processes as buckets.

  It creates new buckets on demand, keeps track of them, and monitors their status.

  To improve the registry and allow for concurrent reads, we can use an ETS table.
  An ETS table will leverage a caching mechanism to directly read data in the `lookup` method.
  With this approach, the `GenServer` will not call its callback to perform a read from its map (state).
  Using ETS will not prevent race conditions... Be cautious! https://hexdocs.pm/elixir/erlang-term-storage.html
  """

  use GenServer

  ################
  ## Client API ##
  ################

  @doc """
  Starts the registry process.
  """
  def start_link(opts) do
    # Options are passed from the supervisor.ex as {KV.Registry, name: KV.Registry}
    # By convention, the module name is the same as the name of the registry
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

  ######################
  ## Server Callbacks ##
  ######################

  # Initialize a GenServer with a state of two maps:
  # - `names` tracks bucket Agent names.
  # - `refs` tracks Agent references as PIDs.
  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  # CALL is synchronous, requiring a server response.
  # The client blocks until it receives the response.
  # Return {:reply, reply, new_state} to continue processing.
  # The reply is the result of the fetch method, i.e. if the bucket Agent exists
  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  # handle_cast is asynchronous, instantly returns `:ok`, and executes in the background.
  # - `:noreply` allows the server to continue without sending a response.
  # This function checks if a bucket Agent already exists; if not, it creates one.
  # A bucket Agent could be created directly with {:ok, bucket} = KV.Bucket.start_link([]),
  # establishing a bidirectional link (if one process crashes, the other follows).
  # Instead, we use a DynamicSupervisor and monitor the process to get its reference.
  # - `monitor` is unidirectional: if the bucket crashes, the GenServer is notified without crashing.
  # Process.monitor(pid) returns a unique reference that allows us to match upcoming messages (like :DOWN) to that monitoring reference.
  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
      ref = Process.monitor(bucket)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, bucket)
      IO.inspect(refs)
      IO.inspect(names)
      {:noreply, {names, refs}}
    end
  end

  # Monitoring allows us to handle bucket failures dynamically, removing the bucket's references from the `names` and `refs` states,
  # thereby preserving system stability without interrupting the GenServer.
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
