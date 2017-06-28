defmodule SlackCommand do
  def child_spec(router) do
    port = Application.get_env(:slack_command, :port)

    Plug.Adapters.Cowboy.child_spec(:http, router, [], [port: port])
  end
end
