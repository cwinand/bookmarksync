defmodule Bookmarksync.Pocket.Authenticate do
  @moduledoc """
  Authentication flow for Pocket API
  See: https://getpocket.com/developer/docs/authentication
  """

  @post_headers [ "Content-Type": "application/json; charset=UTF8", "X-Accept": "application/json" ]

  @doc """
  Performs the first step in the authentication flow, using the application's consumer key to generate
  a 'request_token'.
  """
  def get_request_token do
    post_body = %{
      "consumer_key" => Bookmarksync.Storage.get( [ "pocket", "consumer_key" ] ),
      "redirect_uri" => Bookmarksync.Storage.get( [ "pocket", "redirect_uri" ] )
    }

    Bookmarksync.URLBuilder.pocket_request_token_url()
    |> HTTPotion.post( [ body: Poison.encode!( post_body ), headers: @post_headers ] )
    |> handle_auth_response( :request_token )
  end

  @doc """
  Performs the second step of the authentication flow, converting the 'request_token' to an 'access_token'
  """
  def get_access_token( code ) do
    post_body = %{
      "consumer_key" => Bookmarksync.Storage.get( [ "pocket", "consumer_key" ] ),
      "code" => code
    }

    { status, response } = Bookmarksync.URLBuilder.pocket_access_token_url()
    |> HTTPotion.post( [ body: Poison.encode!( post_body ), headers: @post_headers ] )
    |> handle_auth_response( :access_token )

    case status do
      :ok -> response
      :error -> 
        Process.sleep( 10000 )
        get_access_token( code )
    end
  end

  @doc """
  Makes a get request for the authorization URL, which approves the access token.
  """
  def authorize( request_token ) do
    Bookmarksync.URLBuilder.pocket_user_auth_url( request_token, Bookmarksync.Storage.get( [ "pocket", "redirect_uri" ] ) )
    |> HTTPotion.get
  end

  @doc """
  Kicks off the authentication flow, and prompts user to approve the application in a browser. Authentication
  must be user-approved before the 'access_token' will be created.
  """
  def authenticate do
    unless is_authenticated() do
      { :ok, request_token } = get_request_token()

      authorize( request_token )

      task = Task.async( fn ->
        get_access_token( request_token )
      end )

      Task.await( task, 20000 )
    end
  end

  @doc """
  Checks if access token exists in store and then pings Pocket API with that token
  """
  def is_authenticated do
    case Bookmarksync.Storage.get( [ "pocket", "access_token" ] ) do
      nil -> false
      _ -> 
        case Bookmarksync.Pocket.ping() do
          { :ok } -> true
          { :error } -> false
        end
    end
  end

  @doc """
  Routes the response to another handler function based on HTTP status and token type
  """
  def handle_auth_response( response, token_type ) do
    unless Map.get( response, :status_code ) == 200 do
      handle_auth_error( response )
    else
      handle_auth_success( response, token_type )
    end
  end

  @doc """
  Handles a successful HTTP response for a token. Writes the 'access_token' to a file for future use.
  """
  def handle_auth_success( response, token_type ) do
    response_body = Map.get( response, :body ) |> Poison.decode!()
    case token_type do
      :request_token -> 
        { :ok, Map.get( response_body, "code" ) }
      :access_token -> 
        Bookmarksync.Storage.set( [ "pocket", "access_token" ], Map.get( response_body, "access_token" ) )
        { :ok, response_body }
    end
  end

  @doc """
  Handles an unsuccessful HTTP response for a token
  """
  def handle_auth_error( response ) do
    status = Map.get( response, :status_code )
    errors = Map.get( response, :headers )
             |> Map.get( :hdrs )
             |> Map.take( [ "x-error-code", "x-error" ] )

    List.insert_at( errors, 0, status )

    { :error, errors }
  end
end
