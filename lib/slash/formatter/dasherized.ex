defmodule Slash.Formatter.Dasherized do
  @moduledoc """
  Implementation of `Slash.Formatter` that uses snake_cased and dasherized commands.

  Internal command names such as `"cat_me"` will be transformed into `"cat-me"`.
  """

  @behaviour Slash.Formatter

  @impl Slash.Formatter
  def to_command_name(string) when is_binary(string) do
    String.replace(string, ~r/_+/, "-")
  end
end
