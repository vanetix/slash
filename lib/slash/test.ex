defmodule Slash.Test do
  @moduledoc """
  Use this module for testing your plugs built with `Slash.Builder`.

  ## Examples

      defmodule Bot.SlackRouterTest do
        use ExUnit.Case
        use Plug.Test
        use Slash.Test

        alias Bot.SlackRouter

        test "should encode response as json", %{conn: conn} do
          conn =
            :post
            |> conn("/", %{})
            |> send_command(SlackRouter, "greet")
            |> SlackRouter.call([])

          assert %Plug.Conn{resp_body: body} = conn
          assert %{"text" => "Hello world!"} = Jason.decode!(body)
        end

        test "should authenticate user" do
          user_id = "slack user id"

          conn =
            :post
            |> conn("/", %{})
            |> send_command(SlackRouter, "login", %{"user_id" => user_id})
            |> SlackRouter.call([])

          assert %Plug.Conn{resp_body: body} = conn
          assert %{"text" => "You're authenticated!"} = Jason.decode!(body)
        end
      end

  """

  alias Plug.Conn
  alias Slash.Signature

  @doc false
  defmacro __using__(_) do
    quote do
      import Slash.Test
    end
  end

  @doc """
  Builds a `%Conn{}` body for a specific Slack command payload. The optional `overrides` map
  can be passed which will be merged with default params.

  ***If a `:signing_key` has not been configured for the test module, a key will be generated and
  put into the application environment.***

  NOTE: This is a little awkward right now due to having to send the mock module as an argument.
  """
  @spec send_command(
          Conn.t(),
          module :: atom(),
          command :: String.t(),
          overrides :: %{optional(String.t()) => term()}
        ) :: Conn.t()
  def send_command(%Conn{} = conn, module, command, overrides \\ %{}) do
    params = build_params(command, overrides)
    encoded_params = URI.encode_query(params)

    timestamp =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> to_string()

    signature =
      module
      |> maybe_put_signing_key()
      |> Signature.generate(timestamp, encoded_params)

    conn
    |> Map.put(:body_params, params)
    |> Conn.put_private(:slash_raw_body, encoded_params)
    |> Conn.put_req_header("x-slack-signature", signature)
    |> Conn.put_req_header("x-slack-request-timestamp", timestamp)
  end

  @doc false
  defp generate_signing_key() do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp maybe_put_signing_key(module) do
    :slash
    |> Application.get_env(module, [])
    |> Keyword.get(:signing_key)
    |> case do
      nil ->
        signing_key = generate_signing_key()

        Application.put_env(:slash, module, signing_key: signing_key)

        signing_key

      key ->
        key
    end
  end

  defp build_params(text, overrides) do
    %{
      "text" => text,
      "channel_id" => "channel_id",
      "channel_name" => "channel_name",
      "enterprise_id" => "enterprise_id",
      "enterprise_name" => "enterprise_name",
      "response_url" => "response_url",
      "team_domain" => "team_domain",
      "team_id" => "team_id",
      "trigger_id" => "trigger_id",
      "user_id" => "user_id",
      "user_name" => "user_name"
    }
    |> Map.merge(overrides)
  end
end
