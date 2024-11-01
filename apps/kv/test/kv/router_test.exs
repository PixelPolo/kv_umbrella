### TO RUN THIS TEST ###
# Start a distributed session !!!
# 1. Start the app in a terminal from apps/kv
#   iex --sname bar -S mix
# 2. Start the app in another terminal from apps/kv
#   iex --sname foo -S mix
# 3. Start the test from the root of the umbrella app
#   elixir --sname test_node -S mix test --only distributed
# Don't forget to modify :foo@computer-name... below

defmodule KV.RouterTest do
  use ExUnit.Case

  # Modify the env var before the test and reset it on exit
  setup_all do
    current = Application.get_env(:kv, :routing_table)

    Application.put_env(:kv, :routing_table, [
      {?a..?m, :foo@MacBookPro},
      {?n..?z, :bar@MacBookPro}
    ])

    on_exit(fn -> Application.put_env(:kv, :routing_table, current) end)
  end

  @tag :distributed
  test "route requests across nodes" do
    assert KV.Router.route("hello", Kernel, :node, []) ==
             :foo@MacBookPro

    assert KV.Router.route("world", Kernel, :node, []) ==
             :bar@MacBookPro
  end

  test "raises on unknown entries" do
    assert_raise RuntimeError, ~r/could not find entry/, fn ->
      KV.Router.route(<<0>>, Kernel, :node, [])
    end
  end
end
