defmodule Bookmarksync.Pocket do

  @post_headers [ "Content-Type": "application/json; charset=UTF8", "X-Accept": "application/json" ]

  @doc """
  Stripped down request to Pocket API to check if we are authenticated and the service is available.
  """
  def ping do
    auth = Bookmarksync.Storage.get( :config, [ "pocket" ] )
    post_body = %{
      "consumer_key" => Map.get( auth, "consumer_key" ),
      "access_token" => Map.get( auth, "access_token" ),
      "count" => 1,
      "detailType" => "simple"
    }

    status = Bookmarksync.URLBuilder.pocket_retrieve_url()
             |> HTTPotion.post( [ body: Poison.encode!( post_body ), headers: @post_headers ] )
             |> Map.get( :status_code )

    case status do
      200 -> { :ok }
      _   -> { :error }
    end
  end
  
  @doc """
  General purpose fetching of Pocket bookmarks.
  Defaults to fetching all unread items.
  """
  def get( options \\ %{} ) do
    auth = Bookmarksync.Storage.get( :config, [ "pocket" ] )
    defaults = %{
      "consumer_key" => Map.get( auth, "consumer_key" ),
      "access_token" => Map.get( auth, "access_token" ),
      "detailType" => "complete",
    }

    post_body = Map.merge( defaults, options )

    Bookmarksync.URLBuilder.pocket_retrieve_url()
    |> HTTPotion.post( [ body: Poison.encode!( post_body ), headers: @post_headers ] )
    |> Map.get( :body )
    |> Poison.decode!
  end

  @doc """
  Retrieves favorited bookmarks from Pocket API.
  """
  def get_favorites do
    %{ "favorite" => 1 }
    |> get()
  end

  @doc """
  Parses the full response body from the API request to get what we need from a bookmark.
  """
  def process_api_response( response ) do
    keys_for_pinboard = [ "resolved_url", "resolved_title", "time_added", "tags" ]

    response
    |> Map.get( "list" )
    |> Map.values
    |> Enum.map( &( Map.take( &1, keys_for_pinboard ) ) )
  end

  @doc """
  Tags are returned from the API as a JSON object with the tag names as keys and a map as the value
  of that key. This function maps over the entire data Map and flattens the tag map into an array of the tag names.
  """
  def flatten_tags( data ) do
    Enum.map( data, fn( item ) ->
      Map.update( item, "tags", [], fn( tag_map ) ->
        Map.keys( tag_map )
      end )
    end)
  end

  @doc """
  Converts each Pocket-format bookmark from a list into the format to add to Pinboard.
  """
  def format_bookmarks( bookmarks ) do
    Enum.map( bookmarks, &( Bookmarksync.Pinboard.format_for_adding( &1 ) ) )
  end

  @doc """
  Removes bookmarks from a list if that URL is already in the current bookmark list.
  """
  def remove_duplicate_bookmarks( bookmarks_to_add, current ) do
    Enum.filter( bookmarks_to_add, fn( bookmark ) ->
      Enum.find( current, fn( link_from_current ) ->
        link_from_current == Map.get( bookmark, "url" )
      end ) == nil end )
  end

  def process_all( data ) do
    data
    |> process_api_response()
    |> flatten_tags()
    |> format_bookmarks()
    |> remove_duplicate_bookmarks( Bookmarksync.Pinboard.get_all_links )
  end
end

