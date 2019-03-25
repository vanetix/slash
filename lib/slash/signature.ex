defmodule Slash.Signature do
  @moduledoc """
  All Slack signature generation and verification happens in this module.
  """

  @version "v0"

  @doc """
  Generate a signature given the `key`, `timestamp`, and `body`.

  For more information on this computation see the
  [Slack documentation](https://api.slack.com/docs/verifying-requests-from-slack).
  """
  @spec generate(String.t(), String.t(), String.t()) :: binary()
  def generate(secret, timestamp, body) do
    data = @version <> ":" <> timestamp <> ":" <> body

    :sha256
    |> :crypto.hmac(secret, data)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verify two computed signatures, returning `true` if the signatures match.
  """
  @spec verify(binary(), binary()) :: boolean()
  def verify(signature, signature), do: true
  def verify(_, _), do: false
end
