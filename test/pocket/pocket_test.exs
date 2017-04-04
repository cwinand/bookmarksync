defmodule Bookmarksync.PocketTest do
  use ExUnit.Case, async: true

  import Bookmarksync.Pocket

  setup do
    [ data: %{
      "status" => 1,
      "list" => %{
        "12345" => %{
          "excerpt" => "",
          "favorite" => "0",
          "given_title" => "Example",
          "given_url" => "http://example.com",
          "has_image" => "0",
          "has_video" => "0",
          "is_article" => "1",
          "is_index" => "0",
          "item_id" => "12345",
          "resolved_id" => "12345",
          "resolved_title" => "Example",
          "resolved_url" => "http://example.com",
          "sort_id" => 0,
          "status" => "0",
          "time_added" => "123456789",
          "time_favorited" => "123456789",
          "time_read" => "123456789",
          "time_updated" => "123456789",
          "word_count" => "100",
          "tags" => %{
            "tag1" => %{"item_id" => "100", "tag" => "tag1"},
            "tag2" => %{"item_id" => "101", "tag" => "tag2"},
            "tag3" => %{"item_id" => "102", "tag" => "tag3"}
          },
        }
      }
    },
    existing_url: [ "http://example.com" ]
  ]
  end

  test "filters Pocket API data down to list of required bookmark data", context do
    processed = process_api_response( context[ :data ] )

    assert is_list processed
    assert is_map List.first( processed )
    assert Map.has_key?( List.first( processed ), "resolved_url" )
    assert Map.has_key?( List.first( processed ), "resolved_title" )
    assert Map.has_key?( List.first( processed ), "time_added" )
    assert Map.has_key?( List.first( processed ), "tags" )
    assert is_map Map.get( List.first( processed ), "tags" )
  end

  test "flattens Pocket bookmark tags to format acceptable to Pinboard API", context do
    flattened = process_api_response( context[ :data ] )
                |> flatten_tags()

    assert is_list flattened
    assert List.first( flattened ) |> Map.get( "tags" ) |> is_list
    assert List.first( flattened ) |> Map.get( "tags" ) |> List.first |> is_bitstring
  end

  test "converts each bookmark in a list to format acceptable to Pinboard API", context do
    formatted = process_api_response( context[ :data ] )
                |> flatten_tags()
                |> format_bookmarks()

    assert is_list formatted
    assert List.first( formatted ) |> is_map
    assert List.first( formatted ) |> Map.has_key?( "url" )
    assert List.first( formatted ) |> Map.has_key?( "description" )
    assert List.first( formatted ) |> Map.has_key?( "tags" )
    assert List.first( formatted ) |> Map.has_key?( "dt" )
  end

  test "removes bookmarks from a list if that bookmark's URL exists in a list", context do
    deduped = process_api_response( context[ :data ] ) 
              |> flatten_tags()
              |> format_bookmarks()
              |> remove_duplicate_bookmarks( context[ :existing_url ] )

    assert is_list deduped
    assert Enum.count( deduped ) == 0
  end

end
