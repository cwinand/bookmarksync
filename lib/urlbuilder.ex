defmodule Bookmarksync.URLBuilder do
  @moduledoc """
  Builds URLs for Bookmarksync application
  """

  def join_path_fragments( fragments ) do
    Enum.join( fragments, "/" )
  end

  def join_path_with_query( path, query ) do
    Enum.join( [ path, query ], "?" )
  end

  ##
  ## Pocket URL Fragments
  ##
  @pocket_base "https://getpocket.com"
  @pocket_api_version "v3"
  @pocket_api_get "get"
  @pocket_request_token "oauth/request"
  @pocket_access_token "oauth/authorize"
  @pocket_user_auth "auth/authorize"

  ##
  ## Pocket Authentication URLs
  ##
  def pocket_request_token_url do
    join_path_fragments [ @pocket_base, @pocket_api_version, @pocket_request_token ]
  end

  def pocket_access_token_url do
    join_path_fragments [ @pocket_base, @pocket_api_version, @pocket_access_token ]
  end

  def pocket_user_auth_url( request_token, redirect_uri ) do
    params = %{
      "request_token" => URI.encode_www_form( request_token ),
      "redirect_uri" => URI.encode_www_form( redirect_uri )
    }

    join_path_fragments( [ @pocket_base, @pocket_user_auth ] )
    |> join_path_with_query( URI.encode_query( params ) ) 
  end

  ##
  ## Pocket API URLs
  ##
  def pocket_retrieve_url do
    join_path_fragments [ @pocket_base, @pocket_api_version, @pocket_api_get ]
  end

  ##
  ## Pinboard URL fragments
  ##
  @pinboard_base "https://api.pinboard.in"
  @pinboard_api_version "v1"
  @pinboard_api_posts "posts"
  @pinboard_api_tags "tags"
  @pinboard_api_last_update "update"
  @pinboard_api_get "get"
  @pinboard_api_all "all"
  @pinboard_api_add "add"

  ##
  ## Pinboard API URLs
  ##
  def pinboard_last_update_url do
    join_path_fragments [ @pinboard_base, @pinboard_api_version, @pinboard_api_posts, @pinboard_api_last_update ]
  end

  def pinboard_retrieve_url do
    join_path_fragments [ @pinboard_base, @pinboard_api_version, @pinboard_api_posts, @pinboard_api_get ]
  end

  def pinboard_retrieve_all_url do
    join_path_fragments [ @pinboard_base, @pinboard_api_version, @pinboard_api_posts, @pinboard_api_all ]
  end

  def pinboard_add_url do
    join_path_fragments [ @pinboard_base, @pinboard_api_version, @pinboard_api_posts, @pinboard_api_add ]
  end

  def pinboard_tags_url do
    join_path_fragments [ @pinboard_base, @pinboard_api_version, @pinboard_api_tags, @pinboard_api_get ]
  end
end
