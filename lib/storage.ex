defmodule Bookmarksync.Storage do
  @moduledoc """
  Simple JSON storage layer for keys, access tokens, etc.
  """

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
    Application.get_env( :bookmarksync, :key_file )
    |> open()
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
    config = Application.get_env( :bookmarksync, :key_file )

    config
    |> open()
    |> put_in( keys, value )
    |> save( config )
  end

  def set_cache( data, name, timestamp ) do
    file = "data/#{ name }/#{ timestamp }.json"
    case save( data, file ) do
      :ok -> data
    end
  end

  @doc """
  Gets the filename of the most recent cached JSON.
  """
  def latest_cache( name ) do
    files = File.ls!( "data/#{ name }" )
    unless Enum.empty?( files ) do
      Enum.sort( files )
      |> List.last
      |> String.split( "." )
      |> List.first
      |> String.to_integer
    end
  end

  @doc """
  Simple check to see if the current cache is out of date.
  """
  def stale_cache?( name, latest ) do
    cache = latest_cache( name ) 
    if cache == nil do
      true
    else
      latest > cache
    end
  end

  def flush_cache( name ) do
    cache = "data/#{ name }"

    if File.dir?( cache ) do
      File.rm_rf( cache )
      File.mkdir( cache )
    end
  end
end
