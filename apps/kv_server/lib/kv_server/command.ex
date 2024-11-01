defmodule KVServer.Command do
  require Config
  require Logger

  ###########
  ## Parse ##
  ###########

  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

      iex> KVServer.Command.parse "CREATE shopping\r\n"
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse "CREATE   shopping  \r\n"
      {:ok, {:create, "shopping"}}

      iex> KVServer.Command.parse "PUT shopping milk 1\r\n"
      {:ok, {:put, "shopping", "milk", "1"}}

      iex> KVServer.Command.parse "GET shopping milk\r\n"
      {:ok, {:get, "shopping", "milk"}}

      iex> KVServer.Command.parse "DELETE shopping eggs\r\n"
      {:ok, {:delete, "shopping", "eggs"}}

  Unknown commands or commands with the wrong number of
  arguments return an error:

      iex> KVServer.Command.parse "UNKNOWN shopping eggs\r\n"
      {:error, :unknown_command}

      iex> KVServer.Command.parse "GET shopping\r\n"
      {:error, :unknown_command}
  """
  def parse(line) do
    # String.split for whitespace-insensitive
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  #########
  ## Run ##
  #########

  # Function without a body for documentation

  @doc """
  Runs the given command.
  """
  def run(command)

  def run({:create, bucket}) do
    if Application.get_env(:kv, :env) == :prod do
      # Run in a distributed system
      case KV.Router.route(bucket, KV.Registry, :create, [KV.Registry, bucket]) do
        pid when is_pid(pid) -> {:ok, "OK\r\n"}
        :ok -> {:ok, "Bucket created successfully.\r\n"}
        _ -> {:error, "FAILED TO CREATE BUCKET"}
      end
    else
      Logger.info("No distributed system")
      # Run normally
      KV.Registry.create(KV.Registry, bucket)
      {:ok, "OK\r\n"}
    end
  end

  def run({:get, bucket, key}) do
    lookup(bucket, fn pid ->
      value = KV.Bucket.get(pid, key)
      {:ok, "#{value}\r\nOK\r\n"}
    end)
  end

  def run({:put, bucket, key, value}) do
    lookup(bucket, fn pid ->
      KV.Bucket.put(pid, key, value)
      {:ok, "OK\r\n"}
    end)
  end

  def run({:delete, bucket, key}) do
    lookup(bucket, fn pid ->
      KV.Bucket.delete(pid, key)
      {:ok, "OK\r\n"}
    end)
  end

  # Helper to find the bucket
  defp lookup(bucket, callback) do
    if Application.get_env(:kv, :env) == :prod do
      # Distributed system
      case KV.Router.route(bucket, KV.Registry, :lookup, [KV.Registry, bucket]) do
        {:ok, pid} -> callback.(pid)
        :error -> {:error, :not_found}
      end
    else
      # Normally
      Logger.info("No distributed system")

      case KV.Registry.lookup(KV.Registry, bucket) do
        {:ok, pid} -> callback.(pid)
        :error -> {:error, :not_found}
      end
    end
  end
end
