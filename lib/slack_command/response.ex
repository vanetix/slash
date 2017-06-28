defmodule SlackCommand.Response do
  alias SlackCommand.Response

  @moduledoc """
    Defines a response type for slack.
  """

  @type response_type :: String.t
  @type text :: String.t
  @type color :: String.t
  @type attachment :: %{color: color, title: String.t,
    text: String.t, pretext: String.t}
  @type attachments :: [attachment]

  @type t :: %__MODULE__{
             response_type: response_type,
             text: text,
             color: color,
             attachments: attachments}

  defstruct response_type: "in_channel",
            text: nil,
            color: nil,
            attachments: []

  @spec add_attachment(t, attachment) :: t
  def add_attachment(%Response{attachments: list} = response, attachment) do
    %{response | attachments: list ++ attachment}
  end

  @spec set_color(t, color) :: t
  def set_color(response, color), do: %{response | color: color}

  @spec set_ephemeral(t) :: t
  def set_ephemeral(response), do: %{response | response_type: "ephemeral"}

  def build(attrs \\ %{})

  @spec build(String.t) :: t
  def build(text) when is_binary(text), do: build(text: text)

  @spec build(map()) :: t
  def build(attrs), do: struct(Response, attrs)
end

