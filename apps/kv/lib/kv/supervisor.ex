defmodule KV.Supervisor do
  @moduledoc """
  A Supervisor is a process that supervises other processes and restarts them whenever they crash.
  `KV.Supervisor` is a `Supervisor` that ensures `KV.Registry` is always running and restarts it if it crashes.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # The supervision strategy defines what happens when one of the children crashes.
  # :one_for_one means that if a child dies, it will be the only one restarted.

  # {:ok, sup} = KV.Supervisor.start_link([]) to tell the supervisor to create children
  # [{_, registry, _, _}] = Supervisor.which_children(sup) to fetch the PID name of the child

  # The name `KV.Registry` is an option given to KV.Registry.start_link/1 in registry.ex
  # KV.Supervisor.start_link([])
  # KV.Registry.create(KV.Registry, "shopping") not using a PID fetched from supervisor

  # The DynamicSupervisor does not expect a list of children during initialization,
  # instead each child is started manually via DynamicSupervisor.start_child/2
  # {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)

  # :one_for_all strategy: the supervisor will kill and restart
  # all of its children processes whenever any one of them dies

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

    Supervisor.init(children, strategy: :one_for_all)
  end
end
