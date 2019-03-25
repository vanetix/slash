defmodule Slash.Test do
  @moduledoc """
  Use this module for testing your plugs built with `Slash.Builder`.

  ```
    use Slash.Test, signing_key: "foo"
  ```
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
  Builds a `%Conn{}` body for a specific Slack command payload.

  ***If a `:signer_key` has not been configured for the test module, a key will be generated and
  put into the application environment.***

  NOTE: This is a little awkward right now due to having to send the mock module as an argument.
  """
  @spec send_command(Conn.t(), module :: atom(), command :: String.t()) :: Conn.t()
  def send_command(%Conn{} = conn, module, command) do
    params = build_params(command)

    timestamp =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> to_string()

    signature =
      module
      |> maybe_put_signer_key()
      |> Signature.generate(timestamp, Jason.encode!(params))

    conn
    |> Map.put(:body_params, params)
    |> Conn.put_req_header("x-slack-signature", signature)
    |> Conn.put_req_header("x-slack-request-timestamp", timestamp)
  end

  @doc false
  defp generate_signing_key() do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp maybe_put_signer_key(module) do
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

  defp build_params(text) do
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
  end
end
