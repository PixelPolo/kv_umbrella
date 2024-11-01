defmodule KV do
  @moduledoc """
  Main application module for the `KV` application.

  This module is responsible for starting the `KV.Supervisor`, which in turn
  manages the supervision of the registry and bucket processes within the application.
  By leveraging supervisors, the `KV` application ensures that critical components
  are restarted in case of unexpected failures, enhancing resilience.

  ## Supervision Tree

  When the application starts, it initiates the `KV.Supervisor`,
  which supervises:

  - `KV.Registry`: A GenServer process responsible for managing registered buckets.
  - `KV.BucketSupervisor`: A DynamicSupervisor managing individual bucket agents.
  - `KV.RouterTasks`: A Task.Supervisor to handle distributed tasks, allowing for
    potential task delegation across nodes.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Starts the main supervisor for the application with a named process for easier debugging
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
