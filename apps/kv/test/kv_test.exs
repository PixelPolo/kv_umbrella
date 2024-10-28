defmodule KVTest do
  # Inject the test API for macros
  use ExUnit.Case
  # Macro to indicate KV module contains doctests
  doctest KV
end
