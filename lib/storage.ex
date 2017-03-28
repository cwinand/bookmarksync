defmodule Bookmarksync.Storage do
  @moduledoc """
  Simple JSON storage layer for keys, access tokens, etc.
  """

  @store "data/data.json"
  @store_test "data/data_test.json"

  def open do
    case Mix.env() do
      :dev -> File.read!( @store ) |> Poison.decode!
      :test -> File.read!( @store_test ) |> Poison.decode!
    end
  end

  def save( data ) do
    encoded = Poison.encode!( data )
    case Mix.env() do
      :dev -> File.write!( @store, encoded )
      :test -> File.write!( @store_test, encoded )
    end
  end

  def get( keys ) when is_list keys do
    open()
    |> get_in( keys )
  end

  def get( key ) do
    open()
    |> Map.get( key )
  end

  def set( keys, value ) when is_list keys do
    open()
    |> put_in( keys, value )
    |> save()
  end

  def set( key, value ) do
    open()
    |> Map.update( key, value, fn _ -> value end )
    |> save()
  end
end
