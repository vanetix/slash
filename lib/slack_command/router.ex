defmodule SlackCommand.Router do
  @moduledoc """
  Utility module for defining a new plug router for handling Slack slash commands.
  """

  alias Plug.Conn
  alias SlackCommand.Message

  defmacro __using__(opts) do
    name = Keyword.get(opts, :router_name, "Slack")

    quote do
      @behaviour Plug
      @behaviour SlackCommand.Router

      @before_compile SlackCommand.Router

      import SlackCommand.Router

      Module.put_attribute(__MODULE__, :router_name, unquote(name))
      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      defdelegate authenticated?(token), to: SlackCommand.Router

      def init(opts \\ []), do: opts

      def call(%Conn{} = conn, opts) do
        SlackCommand.Router.handle(__MODULE__, conn)
      end

      defoverridable authenticated?: 1
    end
  end

  @doc false
  defmacro __before_compile__(%{module: module}) do
    name = Module.get_attribute(module, :router_name)
    commands = Module.get_attribute(module, :commands)

    compile(name, commands)
  end

  @doc """
  Process the command given from slack.
  """
  @callback do_command(String.t(), Conn.t(), list(String.t())) ::
              Message.t() | {:ok, Message.t()} | {:ok, String.t() | {:error, String.t()}}

  @doc """
  Authenticates the connection, the default implementation just verifies that the received
  token in the payload matches the configured value.
  """
  @callback authenticated?(String.t()) :: boolean()

  @doc """
  Defines a Slack command by decomposing the function head. The first argument
  is the `%Plug.Conn{}` struct and is **always** required.

  #### For example:

  ```elixir
  defcommand ping(_) do
    "pong"
  end
  ```

  Which will then translate to then slash command in Slack `/bot ping`.
  """
  defmacro defcommand(head_ast, do: block) do
    {name, args} = Macro.decompose_call(head_ast)
    block = Macro.escape(block)
    args = Macro.escape(args)

    quote bind_quoted: [name: name, args: args, block: block] do
      help_text = Module.get_attribute(__MODULE__, :help)

      Module.delete_attribute(__MODULE__, :help)

      Module.put_attribute(
        __MODULE__,
        :commands,
        {name, args, help_text, block}
      )
    end
  end

  @doc false
  def compile(name, commands) do
    ast =
      for {name, arguments, _help, block} <- commands do
        compile_command(name, arguments, block)
      end

    help_ast = compile_help(name, commands)

    quote do
      def do_command(command, conn, _args \\ [])
      unquote(ast)
      unquote(help_ast)
    end
  end

  defp compile_help(name, commands) do
    help_text =
      commands
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {name, _arguments, help, _block} ->
        humanized_name =
          name
          |> to_string()
          |> dasherize()

        %{
          title: humanized_name,
          text: "```#{help}```",
          mrkdwn_in: ["text"],
          color: "#00d1b2"
        }
      end)
      |> Macro.escape()

    quote do
      def do_command(_help, _conn, _args) do
        {:ok,
         %Message{
           text: unquote(name) <> " supports the following commands:",
           attachments: unquote(help_text)
         }}
      end
    end
  end

  # Compiles an AST for a specific command
  defp compile_command(name, arguments, block) do
    arity = length(arguments)

    quote location: :keep do
      def do_command(unquote(name), conn, args) when length(args) == unquote(arity - 1) do
        unquote(arguments) = [conn | args]
        unquote(block)
      end
    end
  end

  @doc """
  Handle the `%Plug.Conn{}` with `router`, which is
  expected to be a module that has called `use SlackCommand.Router`

  Matches on the root route when `path_info == []`
  """
  @spec handle(SlackCommand.Router, Conn.t()) :: Conn.t()
  def handle(router, %Conn{method: "POST", path_info: []} = conn) do
    params = Map.get(conn, :body_params, %{})

    if router.authenticated?(params["token"]) do
      {command, args} = normalize_arguments(params["text"])

      case try_handle(router, command, conn, args) do
        %Message{} = message ->
          body = Map.take(message, [:text, :attachments])

          send_json(conn, body)

        {:ok, %Message{} = message} ->
          body = Map.take(message, [:text, :attachments])

          send_json(conn, body)

        {:ok, message} ->
          send_json(conn, %{text: message})

        {:error, reason} ->
          body = "An error occurred! `#{reason}`"

          send_json(conn, %{text: body})
      end
    else
      send_json(conn, %{text: "Unauthorized"}, 401)
    end
  end

  def handle(_router, %Conn{} = conn) do
    send_json(conn, %{text: "Not found"}, 404)
  end

  defp normalize_arguments(""), do: {"help", []}

  defp normalize_arguments(text) when is_binary(text) do
    [command | rest] =
      text
      |> String.split()
      |> Enum.map(&String.trim/1)

    command =
      command
      |> undasherize()
      |> String.to_atom()

    {command, rest}
  end

  defp send_json(conn, response, status \\ 200) do
    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(status, Jason.encode!(response))
  end

  defp try_handle(router_module, command, conn, args) do
    try do
      router_module.do_command(command, conn, args)
    rescue
      _ in Ecto.NoResultsError ->
        {:ok, %Message{text: "Yikes, there was a database lookup error."}}

      _ ->
        {:ok, %Message{text: "Failed to execute the command."}}
    end
  end

  def authenticated?(token) do
    verify_token =
      :slack_command
      |> Application.get_all_env()
      |> Keyword.fetch!(:verify_token)

    token == verify_token
  end

  defp dasherize(string) when is_binary(string) do
    String.replace(string, ~r/_+/, "-")
  end

  defp undasherize(string) when is_binary(string) do
    String.replace(string, ~r/-+/, "_")
  end
end
