defmodule Kv.BucketTest do
  # Async makes the test faster, but don't use it if
  # you're using global values or file system
  use ExUnit.Case, async: true

  # setup is a function callback called before each test
  # start_supervised! -> ExUnit kill the process before each test
  # ExUnit will merge the map %{bucket: bucket} with the test map
  setup do
    # {:ok, bucket} = KV.Bucket.start_link([])
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  # The test macro's context is a map itself,
  # we can pattern match to retreive the bucket
  test "stores values by key", context do
    %{bucket: bucket} = context
    assert KV.Bucket.get(bucket, "milk") == nil
    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "pop values from the bucket", %{bucket: bucket} do
    KV.Bucket.put(bucket, "key_1", :one)
    KV.Bucket.put(bucket, "key_2", :two)
    assert KV.Bucket.delete(bucket, "key_0") == nil
    assert KV.Bucket.delete(bucket, "key_1") == :one
    assert KV.Bucket.delete(bucket, "key_1") == nil
    assert KV.Bucket.delete(bucket, "key_2") == :two
    assert KV.Bucket.delete(bucket, "key_2") == nil
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
