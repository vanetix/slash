defmodule Slash.Builder do
  @moduledoc ~S"""
  `Slash.Builder` is responsible for building the actual plug that can be used in a
  [Plug](https://hexdocs.pm/plug/readme.html) pipeline.

  The main macro provided when using the module is `command/2`, which allows you to declare
  commands for your Slash plug.

  ## Examples

      defmodule Bot.SlackRouter do
        use Slash.Builder

        before :verify_user

        command :greet, fn %{args: args} ->
          case args do
            [name] ->
              "Hello #{name}!"
            _ ->
              "Please pass name to greet"
          end
        end

        def verify_user(%{user_id: user_id} = command) do
          case Accounts.find_user_by_slack_id(user_id) do
            nil ->
              {:error, "User not authorized"}

            user ->
              {:ok, put_data(command, :user, user)}
          end
        end
      end

  """

  require Logger

  alias Plug.Conn

  alias Slash.{
    Command,
    Signature,
    Utils
  }

  @default_router_opts [
    name: "Slack",
    formatter: Slash.Formatter.Dasherized
  ]

  @typedoc """
  Valid return types from command handler functions. See `Slash.Builder.command/2`
  for more information.
  """
  @type command_response :: binary() | map() | :async

  @typedoc """
  Valid return values for a before handler function. See `Slash.Builder.before/1` for more information.
  """
  @type before_response :: {:ok, Command.t()} | {:error, String.t()}

  @doc false
  defmacro __using__(opts) do
    opts = Keyword.merge(@default_router_opts, opts)

    quote do
      @behaviour Plug

      @before_compile Slash.Builder

      @router_opts unquote(opts)

      Module.register_attribute(__MODULE__, :commands, accumulate: true)
      Module.register_attribute(__MODULE__, :before_functions, accumulate: true)

      import Slash.Command, only: [async: 2, async: 3, put_data: 3]

      import Slash.{
        Builder,
        Utils
      }

      alias Slash.Command

      @doc false
      def init(_opts), do: []

      @doc false
      def call(%Conn{method: "POST", path_info: [], body_params: body} = conn, _opts) do
        with {:ok, command} <- Command.from_params(body),
             true <- verify_request(__MODULE__, conn),
             {:ok, %Command{} = command} <- run_before_functions(command) do
          handle_command(__MODULE__, conn, command)
        else
          {:error, :invalid} ->
            send_json(conn, %{text: "Invalid"}, 400)

          false ->
            send_json(conn, %{text: "Invalid signature"}, 401)

          {:error, message} ->
            send_json(conn, %{text: message}, 200)
        end
      end

      def call(%Conn{} = conn, _opts) do
        send_json(conn, %{error: "Not found"}, 404)
      end
    end
  end

  @doc false
  defmacro __before_compile__(%{module: module}) do
    router_opts = Module.get_attribute(module, :router_opts)
    commands = Module.get_attribute(module, :commands)
    before_functions = Module.get_attribute(module, :before_functions)

    commands_ast = compile_commands(commands, router_opts)
    before_functions_ast = compile_before_functions(module, before_functions)

    quote location: :keep do
      unquote(commands_ast)
      unquote(before_functions_ast)
    end
  end

  @doc """
  Defines a command for the Slack router, the first argument is always a `Slash.Command`
  struct.

  The `name` argument should be the command name you would like to define, this should be an
  internal name, for example `greet_user`. This will then ran through
  `SlackCommand.Formatter.Dasherized` by default, creating the Slack command `greet-user`.

  The `func` argument will be your function which is invoked on command route match, ***this
  function will always receive the `%Slash.Command{}` struct as an argument***.

  TODO: This needs to verify the arity of `func`.
  """
  @spec command(atom(), (Command.t() -> command_response())) :: Macro.t()
  defmacro command(name, func) when is_atom(name) do
    func = Macro.escape(func)

    quote bind_quoted: [name: name, func: func] do
      help_text = Module.get_attribute(__MODULE__, :help)

      Module.delete_attribute(__MODULE__, :help)

      @commands {name, func, help_text}
    end
  end

  @doc """
  Defines a function to be executed before the command is routed to the appropriate handler
  function.

  The `function_name` should be a reference to the name of the function on the current module.
  Values returned from a before function should match the `t:before_response/0` type.
  """
  @spec before(atom()) :: Macro.t()
  defmacro before(function_name) when is_atom(function_name) do
    quote do
      @before_functions unquote(function_name)
    end
  end

  # Compiles all before commands using a recursive case statement.
  defp compile_before_functions(module, functions) do
    result = quote do: {:ok, command}

    before_chain =
      functions
      |> Enum.map(fn function_name ->
        unless Module.defines?(module, {function_name, 1}) do
          raise ArgumentError,
                "Expected #{module} to define #{function_name}(%Command{})."
        end

        quote do: unquote(function_name)
      end)
      |> Enum.reduce(result, fn function, acc ->
        quote do
          case unquote(function)(command) do
            {:ok, command} ->
              unquote(acc)

            {:error, message} ->
              {:error, message}

            result ->
              raise ArgumentError, """
              Expected before handler #{unquote(function)} to return `{:ok, %Command{}}` or `{:error, "message"}`.

              Got #{inspect(result)}.
              """
          end
        end
      end)

    quote do
      def run_before_functions(command) do
        unquote(before_chain)
      end
    end
  end

  # Commands definitions are generated using pattern matching.
  #
  # For example:
  #   def match_command("do-some-work", %Command{})
  #   def match_command("do-additional-work", %Command{})
  #   def match_command(_, %Command{})
  #
  defp compile_commands(commands, opts) do
    formatter = opts[:formatter]
    help_ast = compile_help(commands, opts)

    ast =
      for {name, func, _help} <- commands do
        name
        |> to_string()
        |> formatter.to_command_name()
        |> compile_command(func)
      end

    quote do
      unquote(ast)
      unquote(help_ast)
    end
  end

  # Compiles the help response using the defined command ast.
  defp compile_help(commands, opts) do
    name = opts[:name]
    formatter = opts[:formatter]

    help_text =
      commands
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {name, _func, help} ->
        help = help || "No help text provided."

        humanized_name =
          name
          |> to_string()
          |> formatter.to_command_name()

        %{
          title: humanized_name,
          text: "```#{help}```",
          mrkdwn_in: ["text"],
          color: "#00d1b2"
        }
      end)
      |> Macro.escape()

    quote do
      def match_command(_help, _command) do
        %{
          text: unquote(name) <> " supports the following commands:",
          attachments: unquote(help_text)
        }
      end
    end
  end

  # Compiles an AST for a specific command
  defp compile_command(name, func) do
    if name == "help" do
      IO.puts("Warning: defining a `help` command will override the default help generation.")
    end

    quote do
      def match_command(unquote(name), command), do: unquote(func).(command)
    end
  end

  defp try_handle(module, %{command: cmd} = command) do
    try do
      module.match_command(cmd, command)
    rescue
      error ->
        message = Exception.message(error)

        Logger.error("Error while processing command '#{cmd}': #{message}.")

        "Failed to execute the command."
    end
  end

  @doc """
  Handle a command block return value.
  """
  @spec handle_command(module(), Conn.t(), Command.t()) :: Conn.t()
  def handle_command(module, %Conn{} = conn, %Command{} = command) do
    response =
      module
      |> try_handle(command)
      |> Utils.build_response_payload()

    Utils.send_json(conn, response, 200)
  end

  @doc """
  Verify the request according to the Slack documentation.

  See the [Slack documentation](https://api.slack.com/docs/verifying-requests-from-slack) for
  additional details.
  """
  @spec verify_request(module(), Conn.t()) :: boolean()
  def verify_request(module, %Conn{private: %{slash_raw_body: raw_body}} = conn) do
    with [signature | _] <- Conn.get_req_header(conn, "x-slack-signature"),
         [timestamp | _] <- Conn.get_req_header(conn, "x-slack-request-timestamp"),
         true <- valid_timestamp?(timestamp) do
      :slash
      |> Application.get_env(module, [])
      |> Keyword.fetch!(:signing_key)
      |> Signature.generate(timestamp, raw_body)
      |> Signature.verify(signature)
    else
      _ ->
        false
    end
  end

  def verify_request(_, _) do
    raise RuntimeError, """
    Please ensure that `Slash.BodyReader is used when configuring the Plug.Parsers plug.

    plug Plug.Parsers,
      parsers: [:urlencoded, ...],
      body_reader: {Slash.BodyReader, :read_body, []}
    """
  end

  # Verifies that the request timestamp isn't greater than a minute
  defp valid_timestamp?(timestamp) do
    current_timestamp =
      DateTime.utc_now()
      |> DateTime.to_unix()

    case Integer.parse(timestamp) do
      {timestamp, ""} ->
        current_timestamp - timestamp < 60

      _ ->
        false
    end
  end
end
