# KvUmbrella

Tutorial from : https://hexdocs.pm/elixir/introduction-to-mix.html

## Run without Distributed System

```sh
$ iex -S mix
```

This command starts the application in a single-node mode (non-distributed). Useful for testing or development without needing multiple nodes.

To connect to the TCP server (listening on port 4040), open another terminal and run:

```sh
$ telnet 127.0.0.1 4040
```

## Commands

```
CREATE shopping
OK

PUT shopping milk 1
OK

PUT shopping eggs 3
OK

GET shopping milk
1
OK

DELETE shopping eggs
OK
```

## Run a Distributed System

### WARNING : 

If your computer is not named "MacBookPro," update the name in `runtime.exs` and in the test file `router_test.exs`.

---
### Build

To run the distributed system, use Elixir releases to build and start each node in production mode.

```sh
$ MIX_ENV=prod mix release foo
$ MIX_ENV=prod mix release bar
```

This creates standalone releases for `foo` and `bar`, allowing them to run as independent nodes in a distributed setup.

### Node foo

Next, open separate terminals to start each node:

```sh
$ _build/prod/rel/foo/bin/foo start_iex
```

### Node bar

And in another terminal:

```sh
$ _build/prod/rel/bar/bin/bar start_iex
```

### Connect foo to bar

Then, you can connect `foo` to `bar` with the following command (you may need to restart `bar` if the connection fails):

```sh
$ Node.connect(:bar@MacBookPro)
```

### Client with TCP connection

To connect to the TCP server (listening on port 4040), open a third terminal and run:

```sh
$ telnet 127.0.0.1 4040
```

## Distributed System Architecture:

### Node :foo@MacBookPro (Central server and KV application instance)
Acts as both the main server and a KV application instance, managing routing and bucket processes.

- **:foo@MacBookPro**
  - **KVServer** (Central server to receive and route client requests)
  - **Router (KV.Router)**
    - **Routing Table**:
      - `{?a..?m, :foo@MacBookPro}`
      - `{?n..?z, :bar@MacBookPro}`
    - **Routing Paths**
      - Routes to `:foo@MacBookPro` for keys starting with "a" to "m"
      - Routes to `:bar@MacBookPro` for keys starting with "n" to "z`
  - **KV.Supervisor** (strategy: `:one_for_all`)
    - **KV.Registry** (GenServer) - Manages bucket registration
    - **KV.BucketSupervisor** (DynamicSupervisor, strategy: `:one_for_one`)
      - **Bucket 1** (Agent)
      - **Bucket 2** (Agent)
      - **Bucket N** (Agent)

---

#### Node :bar@MacBookPro (Secondary KV application instance)
Manages its own processes and buckets independently based on routing rules.
- **:bar@MacBookPro**
  - **KV.Supervisor** (strategy: `:one_for_all`)
    - **KV.Registry** (GenServer) - Manages bucket registration
    - **KV.BucketSupervisor** (DynamicSupervisor, strategy: `:one_for_one`)
      - **Bucket 1** (Agent)
      - **Bucket 2** (Agent)
      - **Bucket N** (Agent)

---

#### Node :bar@MacBookPro (KV application instance)
Same structure as `:foo@MacBookPro`, but with its own buckets.

- **:bar@MacBookPro**
  - **KV.Supervisor** (strategy: `:one_for_all`)
    - **KV.Registry** (GenServer)
    - **KV.BucketSupervisor** (DynamicSupervisor, strategy: `:one_for_one`)
      - **Bucket 1** (Agent)
      - **Bucket 2** (Agent)
      - **Bucket N** (Agent)

