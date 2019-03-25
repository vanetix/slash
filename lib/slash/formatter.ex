defmodule Slash.Formatter do
  @moduledoc """
  Handles formatting a command from internal name to external name.

  See `Slash.Formatter.Dasherized` for the default implementation.
  """

  @doc """
  Converts and internal representation of a command to a command that can be used in Slack.
  """
  @callback to_command_name(String.t()) :: String.t()
end
