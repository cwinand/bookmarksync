defmodule Bookmarksync.StorageTest do
  use ExUnit.Case

  import Bookmarksync.Storage

  setup do
    File.write!( "data/data_test.json", "{}" )
  end

  test "opens the storage file as a map" do
    assert is_map open()
  end

  test "saves a map as encoded JSON" do
    assert save %{ "key" => "value" } == :ok
  end

  test "sets a value on a non-nested key" do
    assert set( "key", "value" ) == :ok
  end

  test "sets a value on a nested key" do
    set( "key", %{} )
    assert set( [ "key", "child_key" ], "value" ) == :ok
  end

end
