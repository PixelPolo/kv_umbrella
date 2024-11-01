defmodule KV.Supervisor do
  @moduledoc """
  A Supervisor is a process that supervises other processes and restarts them whenever they crash.

  `KV.Supervisor` is a module to start a `Supervisor` that ensures `KV.Registry` is always running
  """

  # EXAMPLES :
  # {:ok, sup} = KV.Supervisor.start_link([]) to tell the supervisor to create children
  # [{_, registry, _, _}] = Supervisor.which_children(sup) to fetch the PID name of the child

  # STRATEGIES :
  # :one_for_all strategy: if one child process crashes, the supervisor will terminate and restart all child processes.
  # :one_for_one strategy: if a child process crashes, only that specific child will be restarted.

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  #   KV.Supervisor (strategy :one_for_all)
  # │
  # ├── KV.Registry (GenServer)
  # │
  # └── KV.BucketSupervisor (DynamicSupervisor, strategy :one_for_one)
  #     ├── Bucket 1 (Agent)
  #     ├── Bucket 2 (Agent)
  #     └── Bucket N (Agent)

  @impl true
  def init(:ok) do
    children = [
      # 1st child : Bucket supervisor
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      # 2nd child : Registry, create supervised bucket by KV.BucketSupervisor
      {KV.Registry, name: KV.Registry},
      # 3rd child : Task supervisor to create a distributed system
      {Task.Supervisor, name: KV.RouterTasks}
    ]

    # Init callback to start_link all children
    Supervisor.init(children, strategy: :one_for_all)
  end
end
