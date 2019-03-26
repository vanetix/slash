defmodule Slash.BodyReader do
  @moduledoc """
  Custom [Plug.Parsers](https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader) body
  reader to support the custom `Slash.Signature` verification process.

  ***This must be configured for your application when using Slash!***

  ## Example

    plug Plug.Parsers,
      parsers: [:urlencoded],
      body_reader: {Slash.BodyReader, :read_body, []}
  """

  alias Plug.Conn

  @doc """
  Custom `Plug.Conn.read_body/2` implementation to put the raw request body into a private `conn`
  field for usage during the signature verification process.
  """
  @spec read_body(Conn.t(), keyword()) :: {:ok, binary(), Conn.t()}
  def read_body(%Conn{} = conn, opts) do
    {:ok, body, conn} = Conn.read_body(conn, opts)

    {:ok, body, Conn.put_private(conn, :slash_raw_body, body)}
  end
end
