# Slash

[![CircleCI](https://circleci.com/gh/vanetix/slash.svg?style=svg)](https://circleci.com/gh/vanetix/slash)
[![Documentation](http://inch-ci.org/github/vanetix/slash.svg)](http://inch-ci.org/github/vanetix/slash)

> A simple Slack slash command builder for Plug.

## Documentation

Documentation can be found at [https://hexdocs.pm/slash](https://hexdocs.pm/slash).

If you're not sure what a Slack slash command is, see the [Slack documentation](https://api.slack.com/slash-commands).

## Installation

Add `slash` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:slash, "~> 2.0.0"}]
end
```

## Usage

Provides a primary macro `command/2` to enable building a Plug that can route inbound requests from Slack with a familiar interface (functions).

Since `Slash.Builder` is just a builder for a [Plug](https://hexdocs.pm/plug/readme.html), it can be integrated into either a `Plug.Router` ***or*** a [Phoenix](https://phoenixframework.org/) application.

### Usage with Plug Router

##### 1. Define your Slack Router plug using `Slash.Builder`.

```elixir
defmodule Bot.SlackRouter do
  use Slash.Builder

  command :async_greet, fn command ->
    async(command, fn ->
      Process.sleep(5_000)

      "Async response!"
    end)
  end

  command :greet, fn %{args: args} ->
    case args do
      [name] ->
        "Greetings #{name}!"

      _ ->
        "Please pass a name to greet!"
    end
  end
end
```

##### 2. Define your Plug Router

```elixir
defmodule Bot.Router do
  use Plug.Router

  # NOTE: The custom body_reader option here is critical.
  plug Plug.Parsers,
    parsers: [:urlencoded],
    body_reader: {Slash.BodyReader, :read_body, []}

  plug :match
  plug :dispatch

  forward "/slack", to: Bot.SlackRouter

  match _ do
    send_resp(conn, 404, "")
  end
end

```

### Usage with Phoenix

##### 1. Define your Slash Router plug using `Slash.Builder` like above.

##### 2. Add a new scope *or* use an existing scope in your `Phoenix.Router`

```elixir
scope "/" do
  pipe_through [:api]

  forward "/slack", ShieldSlack.Router
end
```

##### 3. Override the body reader in your `Phoenix.Endpoint`

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  body_reader: {Slash.BodyReader, :read_body, []}
```

## Configuration

Assuming you've setup the above `Bot.SlackRouter` module in your mix project. To configure the Slack signature key, configure your builder module using the following:

```elixir
config :slash, Bot.SlackRouter,
  signing_key: "secret key from slack"
```

## Slack Help Generation

Another feature of this library is the ability to automatically generate help documentation and the `help` command itself. To generate per-command help text, simply decorate your command functions with a `@help` module parameter.

Here is an example:

```elixir
  @help """
  Generates a sweet gif

  Example: '/gif make'
  """
  command :make, fn _command  do
    # some code
  end
```

## Testing

See the `Slash.Test` module for more information in testing `Slash.Builder` plugs.

## License (MIT)

Copyright (c) 2017-2019 Matt McFarland

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
