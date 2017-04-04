defmodule Bookmarksync.StorageTest do
  use ExUnit.Case, async: true

  import Bookmarksync.Storage

  @config Application.get_env( :bookmarksync, :key_file )

  setup do
    # Testing File IO is hard. We need to wipe and recreate the files each test so we aren't
    # having race conditions when a test expects a file to exist when it doesn't, or vice versa.

    cache = "data/test"

    File.write!( @config, "{}" )
    File.mkdir!( cache )

    on_exit fn ->
      File.rm_rf!( @config )
      File.rm_rf!( cache )
    end
  end

  test "opens a json file as a map" do
    assert is_map open( @config )
  end

  test "saves a map as encoded JSON" do
    assert save( %{}, @config ) == :ok
  end

  test "gets and sets key-value pairs in the config file" do
    assert set_config( %{}, [ "key" ] ) == :ok
    assert is_map get_config( [ "key" ] )

    assert set_config( "value", [ "key", "nested_key" ] ) == :ok
    assert get_config( [ "key", "nested_key" ] ) == "value"

    assert set( "value", :config, [ "key2" ] ) == :ok
    assert get( :config, [ "key2" ] ) == "value"
  end

  test "sets a JSON cache file named with a timestamp" do
    data = %{ "key" => "value" }
    assert set_cache( data, "test", "12345" ) == data
    assert set( data, :cache, [ "test", 12345 ] ) == data
  end

  test "opens a cache file as a map" do
    File.write( "data/test/12345.json", "{}" )
    assert is_map get_cache( "test", "12345" )
    assert is_map get( :cache, [ "test", 12345 ] )
  end

  test "gets the timestamp of the most recent cache file" do
    File.write( "data/test/12345.json", "{}" )
    assert latest_cache( "test" ) == 12345
  end

  test "check if the current cache is out of date" do
    File.write( "data/test/12345.json", "{}" )
    assert stale_cache?( "test", 12346 )
    refute stale_cache?( "test", 12344 )
  end

  test "clears the current cache" do
    file ="data/test/12345.json"

    File.write( file, "{}" )
    assert File.exists?( file )

    flush_cache( "test" )
    refute File.exists?( file )
  end
end
