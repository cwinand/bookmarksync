defmodule Bookmarksync.URLBuilderTest do
  use ExUnit.Case, async: true

  import Bookmarksync.URLBuilder

  test "joins array of strings with a forward slash" do
    assert join_path_fragments( [ "one", "two", "three" ] ) == "one/two/three"
  end

  test "joins two strings with a question mark" do
    assert join_path_with_query( "one", "two" ) == "one?two"
  end

  test "builds the URL to get a request_token from Pocket API" do
    assert pocket_request_token_url() == "https://getpocket.com/v3/oauth/request"
  end

  test "builds the URL to get an access_token from Pocket API" do
    assert pocket_access_token_url() == "https://getpocket.com/v3/oauth/authorize"
  end

  test "builds the URL to approve access for Pocket API" do
    test_token = "1234-5678"
    test_redirect = "https://github.com"
    success_case = "https://getpocket.com/auth/authorize?redirect_uri=https%253A%252F%252Fgithub.com&request_token=1234-5678"
    assert pocket_user_auth_url( test_token, test_redirect ) == success_case
  end

  test "builds the URL to the Retrieve endpoint of the Pocket API" do
    assert pocket_retrieve_url() == "https://getpocket.com/v3/get"
  end

  test "builds the URL to the posts/get Pinboard API endpoint" do
    assert pinboard_retrieve_url() == "https://api.pinboard.in/v1/posts/get"
  end

  test "builds the URL to the posts/all Pinboard API endpoint" do
    assert pinboard_retrieve_all_url() == "https://api.pinboard.in/v1/posts/all"
  end

end
