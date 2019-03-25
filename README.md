# Slash

[![CircleCI](https://circleci.com/gh/vanetix/slash.svg?style=svg)](https://circleci.com/gh/vanetix/slash)
[![Documentation](http://inch-ci.org/github/vanetix/slash.svg)](http://inch-ci.org/github/vanetix/slash)

> A simple Slack slash command builder that integrates with Plug.

## Documentation

Documentation can be found at [https://hexdocs.pm/slash](https://hexdocs.pm/slash).

If you're not sure what a Slack slash command is, see the [Slack documentation](https://api.slack.com/slash-commands).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `slash` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:slash, "~> 2.0.0"}]
end
```

## Usage

<!-- moduledoc -->

Provides a primary macro `command/2` to enable building a Plug that can route inbound requests from Slack with a familiar interface (functions).

Since `Slash.Builder` is just a builder for a [Plug](https://hexdocs.pm/plug/readme.html), it can be integrated into either a `Plug.Router` ***or*** a [Phoenix](https://phoenixframework.org/) application.

### Example Usage

```elixir
defmodule SlackBot.SlackRouter do
  use Slash.Builder

  @help """
  Greets a user

  Example: `/hello bob`
  """
  command fn %Command{args: [name | []]} ->
    "Greetings #{name}!"
  end
end

defmodule SlackBot.Router do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Jason
  plug :dispatch

  forward "/slack", to: SlackBot.SlackRouter
end
```

<!-- moduledoc -->

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
