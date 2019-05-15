defmodule Slash.Utils do
  @moduledoc """
  Utility functions for usage in `Slash.Builder` plugs.
  """

  alias Plug.Conn

  @doc """
  Sends a json response to the `conn`.
  """
  @spec send_json(Conn.t(), map(), number()) :: Conn.t()
  def send_json(conn, response, status \\ 200)

  def send_json(conn, response, status) when is_binary(response) do
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(status, response)
  end

  def send_json(conn, response, status),
    do: send_json(conn, Jason.encode!(response), status)

  @doc """
  Handle a response from a command block.
  """
  @spec build_response_payload(Slash.Builder.command_response()) :: map()
  def build_response_payload(response) when is_binary(response), do: %{text: response}
  def build_response_payload(response) when is_map(response), do: response
  def build_response_payload(:async), do: ""

  def build_response_payload(response) do
    raise ArgumentError, """
    Expected command to return map(), binary(), or :async. Got #{inspect(response)}.
    """
  end
end
