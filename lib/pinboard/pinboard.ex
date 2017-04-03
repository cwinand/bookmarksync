defmodule Bookmarksync.Pinboard do

  @doc """
  Builds default query for requests to Pinboard API.
  """
  def default_query do
    %{
      "auth_token" => Bookmarksync.Storage.get( :config, [ "pinboard", "token" ] ),
      "format" => "json"
    }
  end


  @doc """
  Stripped down request to Pinboard API to check that we are authenticated and the service is up.
  """
  def ping do
    query = URI.encode_query( default_query() )
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
    query = URI.encode_query( default_query() )
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

    if ( Bookmarksync.Storage.stale_cache?( "pinboard", last ) ) do
      query = URI.encode_query( default_query() )

      Bookmarksync.URLBuilder.pinboard_retrieve_all_url()
      |> Bookmarksync.URLBuilder.join_path_with_query( query )
      |> HTTPotion.get
      |> Map.get( :body )
      |> Poison.decode!
      |> Bookmarksync.Storage.set( :cache, [ "pinboard", last ] )
    else
      latest = Bookmarksync.Storage.latest_cache( "pinboard" )
      Bookmarksync.Storage.get( :cache, [ "pinboard", latest ] )
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
    query = URI.encode_query( default_query() )

    Bookmarksync.URLBuilder.pinboard_tags_url()
    |> Bookmarksync.URLBuilder.join_path_with_query( query )
    |> HTTPotion.get
    |> Map.get( :body )
    |> Poison.decode!
  end

  @doc """
  Flushes the cache and adds back a single item with all current bookmarks.
  """
  def reset_cache do
    Bookmarksync.Storage.flush_cache( "pinboard" )
    get_all()
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
    query =
      default_query()
      |> Map.merge( bookmark )
      |> URI.encode_query()

    Bookmarksync.URLBuilder.pinboard_add_url()
    |> Bookmarksync.URLBuilder.join_path_with_query( query )
    |> HTTPotion.get
    |> Map.get( :body )
    |> Poison.decode!
  end
end