defmodule Bookmarksync do
  @moduledoc """
  Documentation for Bookmarksync.
  """

  alias Bookmarksync.Pocket
  alias Bookmarksync.Pinboard

  def start_sync( get_from_pocket \\ %{ "favorites" => 1 } ) do
    existing_bookmarks = Pinboard.get_all_links()

    Pocket.get( get_from_pocket )
    |> Pocket.process_all( existing_bookmarks )
    |> Enum.each( fn bookmark ->
      Pinboard.add( bookmark )
      IO.puts "ADDED: #{ Map.get( bookmark, "description" ) }"
      # Don't hit Pinboard's rate limit!
      Process.sleep( 3000 )
    end )
  end
end
