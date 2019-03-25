defmodule Slash.Command do
  @moduledoc """
  `Slash.Command` stores all command data received from Slack when invoking a command.

  The primary user facing functionality provided by this module is `async/2`.
  """

  require Logger

  alias __MODULE__
  alias Slash.Utils

  @http Application.get_env(:slash, :http_module, HTTPoison)

  @param_keys ~w(
    channel_id
    channel_name
    command
    enterprise_id
    enterprise_name
    response_url
    team_domain
    team_id
    text
    trigger_id
    user_id
    user_name
  )

  @type t :: %__MODULE__{
          args: [String.t()],
          channel_id: String.t(),
          channel_name: String.t(),
          command: String.t(),
          data: map(),
          enterprise_id: String.t(),
          enterprise_name: String.t(),
          response_url: String.t(),
          team_domain: String.t(),
          team_id: String.t(),
          text: String.t(),
          trigger_id: String.t(),
          user_id: String.t(),
          user_name: String.t()
        }

  defstruct args: [],
            channel_id: nil,
            channel_name: nil,
            command: nil,
            data: %{},
            enterprise_id: "",
            enterprise_name: "",
            response_url: nil,
            team_domain: nil,
            team_id: nil,
            trigger_id: nil,
            text: nil,
            user_id: nil,
            user_name: nil

  @doc """
  Takes keys from the Slack payload and builds the `Command` struct.
  """
  @spec from_params(map()) :: {:ok, t()} | {:error, String.t()}
  def from_params(body) do
    params =
      for {k, v} <- body, k in @param_keys do
        {String.to_atom(k), v}
      end

    command =
      __MODULE__
      |> struct(params)
      |> parse()

    if valid?(command) do
      {:ok, command}
    else
      {:error, :invalid}
    end
  end

  @doc """
  Returns `true` or `false` depending on if this command is populated with all required fields.

  A command struct is considered invalid if any field is nil at this point.
  """
  @spec valid?(t()) :: boolean()
  def valid?(%Command{} = command) do
    command
    |> Map.to_list()
    |> Enum.all?(&(elem(&1, 1) != nil))
  end

  @doc """
  Puts a value into the `%Command{}` under the key, `key`.
  """
  @spec put_data(t(), atom(), term()) :: t()
  def put_data(%Command{data: data} = command, key, value) do
    %{command | data: Map.put(data, key, value)}
  end

  @doc """
  Responses to the `%Command{}` with `message`.

  *Note, this is for internal usage with async commands. Please see `Slash.Builder` for
  valid return types from command functions.*
  """
  @spec send_response(t(), String.t()) :: :ok | :error
  def send_response(%Command{response_url: url}, message) when is_binary(message) do
    case @http.post(url, message, [{"content-type", "application/json"}]) do
      {:ok, %{status_code: code}} when code in [200, 201] ->
        :ok

      _ ->
        :error
    end
  end

  @doc """
  Starts an async task under the `Slash.Supervisor` so the command can automatically be
  responded to upon completion.

  **If you intend to use async commands, you MUST have `Slash.Supervisor` started.**

  ### Options

  The following are valid options when calling `async/3`.

  - :timeout - specific the `Task.async/2` timeout option to be used.

  ### Example usage

  ```elixir
  command :async_reply, fn command ->
    async command, fn ->
      Process.sleep(5_000)

      "Hello!"
    end
  end
  ```
  """
  @spec async(t(), (() -> Slash.Builder.command_response()), keyword()) :: :async
  def async(command, func, opts \\ [])

  def async(%Command{} = command, func, opts) when is_function(func, 0) do
    Task.Supervisor.start_child(Slash.TaskSupervisor, fn ->
      task = Task.Supervisor.async_nolink(Slash.TaskSupervisor, func)

      case Task.yield(task, opts[:timeout] || :infinity) do
        {:ok, response} ->
          message =
            response
            |> Utils.build_response_payload()
            |> Jason.encode!()

          send_response(command, message)

        {:exit, _} ->
          Logger.error("Failed to send response for async command - #{command.command}.")
      end
    end)

    :async
  end

  def async(_, _, _) do
    raise ArgumentError, """
    Expected `func` to have an arity of 0 in the call to `async_response/2`.
    """
  end

  # Parses the command text into a list of arguments, turning the first
  # into the main command being ran.
  defp parse(%{text: text} = command) do
    text = text || ""

    args =
      text
      |> String.split(" ")
      |> Enum.map(&String.trim/1)

    case args do
      [name | args] ->
        %{command | command: name, args: args}

      [] ->
        %{command | command: ""}
    end
  end
end
