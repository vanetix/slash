defmodule SlackCommand.Message do
  @moduledoc """
  Struct for representing a single slack message.
  """

  alias SlackCommand.Message

  @type t :: %__MODULE__{
          text: String.t(),
          channel: String.t(),
          attachments: [map()]
        }

  @derive {Jason.Encoder, only: [:text, :attachments]}
  defstruct channel: "", text: "", attachments: [], as_user: true

  @spec new(map()) :: t
  def new(attrs \\ %{}) when is_map(attrs) or is_list(attrs) do
    struct(__MODULE__, attrs)
  end

  @spec to(t, String.t()) :: t
  def to(%Message{} = message, channel) when is_binary(channel) do
    %{message | channel: channel}
  end
end
