defmodule Bookmarksync.Pinboard do

  @doc """
  Stripped down request to Pinboard API to check that we are authenticated and the service is up.
  """
  def ping do
    auth = Bookmarksync.Storage.get( [ "pinboard", "token" ] )
    query = URI.encode_query( %{
      "auth_token" => auth,
      "format" => "json"
    } )

    status = Bookmarksync.URLBuilder.pinboard_last_update_url()
             |> Bookmarksync.URLBuilder.join_path_with_query( query )
             |> HTTPotion.get
             |> Map.get( :status_code )

    case status do
      200 -> :ok
      _   -> :error
    end
  end

  @doc """
  Gets the timestamp of the last time a bookmark was added. We need this data to check our cache
  so we avoid Pinboard's rate limit on the /posts/all endpoint.
  """
  def last_update do
    auth = Bookmarksync.Storage.get( [ "pinboard", "token" ] )
    query = URI.encode_query( %{
      "auth_token" => auth,
      "format" => "json"
    } )

    { status, response, _ } = Bookmarksync.URLBuilder.pinboard_last_update_url()
                              |> Bookmarksync.URLBuilder.join_path_with_query( query )
                              |> HTTPotion.get
                              |> Map.get( :body )
                              |> Poison.decode!
                              |> Map.get( "update_time" )
                              |> DateTime.from_iso8601
    case status do
      :ok -> DateTime.to_unix( response )
      :error -> response
    end
  end

  @doc """
  Get all current bookmarks. Checks a simple JSON cache first due to Pinboard rate limit.
  """
  def get_all do
    last = last_update()
    last_cache = "data/pinboard/#{ last }.json"
    if File.exists?( last_cache ) do
      File.read!( last_cache )
      |> Poison.decode!

    else
      auth = Bookmarksync.Storage.get( [ "pinboard", "token" ] )
      query = URI.encode_query( %{
        "auth_token" => auth,
        "format" => "json",
      } )

      Bookmarksync.URLBuilder.pinboard_retrieve_all_url()
      |> Bookmarksync.URLBuilder.join_path_with_query( query )
      |> HTTPotion.get
      |> Map.get( :body )
      |> update_cache( last )
      |> Poison.decode!
    end
  end

  @doc """
  Helper function to get just the URLs of all current bookmarks. This is generally used to filter
  a new list of bookmarks that need added.
  """
  def get_all_links do
    get_all()
    |> Enum.map( &( Map.get( &1, "href" ) ) )
  end

  @doc """
  Get all current tags on Pinboard. No cache used since rate limit is low for this endpoint.
  """
  def get_tags do
    auth = Bookmarksync.Storage.get( [ "pinboard", "token" ] )
    query = URI.encode_query( %{
      "auth_token" => auth,
      "format" => "json"
    } )

    Bookmarksync.URLBuilder.pinboard_tags_url()
    |> Bookmarksync.URLBuilder.join_path_with_query( query )
    |> HTTPotion.get
    |> Map.get( :body )
    |> Poison.decode!
  end

  @doc """
  Simple check to see if the current cache is out of date.
  """
  def stale_cache? do
    last = last_update()
    cache = get_latest_cache() 
            |> String.split( "." )
            |> List.first
            |> String.to_integer

    last > cache
  end

  @doc """
  Gets the filename of the most recent cached JSON.
  """
  def get_latest_cache do
    File.ls!( "data/pinboard" )
    |> Enum.sort
    |> List.last
  end

  @doc """
  Writes a new JSON blob of bookmarks to a file named by the last_update timestamp.
  """
  def update_cache( data, timestamp ) do
    File.write( "data/pinboard/#{ timestamp }.json", data )
    data
  end

  @doc """
  Flushes the cache and adds back a single item with all current bookmarks.
  """
  def reset_cache do
    File.ls!( "data/pinboard" )
    |> Enum.each( fn( file ) -> File.rm( "data/pinboard/" <> file ) end )

    last = last_update()

    auth = Bookmarksync.Storage.get( [ "pinboard", "token" ] )
    query = URI.encode_query( %{
      "auth_token" => auth,
      "format" => "json"
    } )

    Bookmarksync.URLBuilder.pinboard_retrieve_all_url()
    |> Bookmarksync.URLBuilder.join_path_with_query( query )
    |> HTTPotion.get
    |> Map.get( :body )
    |> update_cache( last )
    |> Poison.decode!
  end

  @doc """
  Converts items from the Pocket API format to the Pinboard API format.
  """
  def format_for_adding( data ) do
    %{
      "url" => Map.get( data, "resolved_url" ),
      "description" => Map.get( data, "resolved_title" ),
      "dt" => Map.get( data, "time_added" ) |> String.to_integer |> DateTime.from_unix! |> DateTime.to_iso8601,
      "tags" => Map.get( data, "tags" ) |> List.insert_at( -1, "from:pocket" ) |> Enum.join( "," )
    }
  end

  def add( bookmark ) do
    auth = Bookmarksync.Storage.get( [ "pinboard", "token" ] )
    query = %{ "auth_token" => auth, "format" => "json" }
    |> Map.merge( bookmark ) 
    |> URI.encode_query()

    Bookmarksync.URLBuilder.pinboard_add_url()
    |> Bookmarksync.URLBuilder.join_path_with_query( query )
    |> HTTPotion.get
    |> Map.get( :body )
    |> Poison.decode!
  end
end