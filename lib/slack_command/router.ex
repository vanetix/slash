defmodule SlackCommand.Router do
  alias SlackCommand.Response

  defmacro __using__(_) do
    quote do
      use Plug.Router

      import SlackCommand.Router

      plug Plug.Logger
      plug Plug.Parsers,
        parsers: [:json, :urlencoded],
        json_decoder: Poison
      plug :match
      plug :dispatch

      post "/" do
        %{body_params: params} = var!(conn)

        {status, resp} =
          if Map.has_key?(params, "text") do
            process_command(params)
          else
            {422, %{error: "No text specified"}}
          end

        var!(conn)
        |> put_resp_content_type("application/json")
        |> send_resp(status, Poison.encode!(resp))
      end

      match _ do
        var!(conn)
        |> put_resp_content_type("application/json")
        |> send_resp(404, Poison.encode!(%{error: "Not found"}))
      end

      def process_command(params) do
        text =
          params["text"]
          |> String.trim()

        case match_command(text, params) do
          {:ok, %Response{} = response} -> {200, response}
          {:error, %Response{} = response} -> {500, response}
          {:ok, message} -> {200, Response.build(message)}
          {:error, error} -> {500, Response.build(text) |> Response.set_ephemeral()}
        end
      end
    end
  end

  defmacro command(text, do: block) do
    quote do
      @spec match_command(String.t, map()) :: SlackCommand.Response.t
      def match_command(unquote(text), var!(params)), do: unquote(block)
    end
  end
end
