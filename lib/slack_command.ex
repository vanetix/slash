defmodule SlackCommand do
  def child_spec(router) do
    port = Application.get_env(SlackCommand, :port, 8080)

    Plug.Adapters.Cowboy.child_spec(:http, router, [], [port: port])
  end
end
