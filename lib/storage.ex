defmodule Bookmarksync.Storage do
  @moduledoc """
  Simple JSON storage layer for keys, access tokens, etc.
  """

  @config "data/config.json"

  def open( file ) do
    file
    |> File.read!
    |> Poison.decode!
  end

  def save( data, file ) do
    encoded = Poison.encode!( data )
    File.write!( file, encoded )
  end

  def get( type, identifiers ) do
    case type do
      :config ->
        get_config( identifiers )
      :cache ->
        name = List.first( identifiers )
        timestamp =
          List.last( identifiers )
          |> Integer.to_string

        get_cache( name, timestamp )
    end
  end

  def get_config( keys ) do
    open( @config )
    |> get_in( keys )
  end

  def get_cache( name, timestamp ) do
    open "data/#{ name }/#{ timestamp }.json"
  end

  def set( data, type, identifiers ) do
    case type do
      :config ->
        set_config( data, identifiers )
      :cache ->
        name = List.first( identifiers )
        timestamp =
          List.last( identifiers )
          |> Integer.to_string

        set_cache( data, name, timestamp )
    end
  end

  def set_config( value, keys ) do
    open( @config )
    |> put_in( keys, value )
    |> save( @config )
  end

  def set_cache( data, name, timestamp ) do
    file = "data/#{ name }/#{ timestamp }.json"
    save( data, file )
  end
end
