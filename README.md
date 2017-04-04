# Bookmarksync

A small Elixir project to sync bookmarks between [Pocket](https://getpocket.com) and [Pinboard](https://pinboard.in).

You must have a developer token on Pocket to authenticate, which can be made at https://getpocket.com/developer/apps/new.

## Installation

Clone the repo, then install the dependencies:
```elixir
$ mix deps.get
```

## Usage

### Setup

Create a new directory `data`, and create two more directories there called `pinboard` and `pocket`.

Create a `config.json` within data, with the following structure:
```json
{
  "pinboard": {
    "token": YOUR_PINBOARD_API_TOKEN
  },
  "pocket": {
    "consumer_key": YOUR_POCKET_CONSUMER_KEY,
    "redirect_uri": YOUR_POCKET_APP_REDIRECT
  }
}
```

### Authentication

Run `Bookmarksync.Pocket.authenticate` in iex to run through the oauth flow & save an API token to the config file. From there, you should be able to perform authenticated requests to both services.

Each API wrapper module has a function called `ping/0` to make a small status request to the service.

### Syncing

Take a look at the various functions within each wrapper, each are fairly well documented. To just run a sync of bookmarks, there is a function `Bookmarksync.start_sync/1` which defaults to syncing Pocket's favorited items over to Pinboard. You can pass a map of what you want from Pocket to this function by following the API's [retrieve](https://getpocket.com/developer/docs/v3/retrieve) parameters.
