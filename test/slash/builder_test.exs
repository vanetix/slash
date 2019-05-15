defmodule Slash.BuilderTest do
  use ExUnit.Case
  use Plug.Test
  use Slash.Test

  defmodule BeforeErrorMock do
    use Slash.Builder

    before :error
    before :next_error

    def error(_command) do
      {:error, "Error, not sure what happened here"}
    end

    def next_error(_command) do
      throw(:not_implemented)
    end
  end

  defmodule BeforeDataMock do
    use Slash.Builder

    before :data

    def data(%Command{} = command) do
      {:ok, put_data(command, :data, :data)}
    end

    command :tell, fn %Command{data: %{data: :data}} ->
      "Looks good!"
    end
  end

  defmodule BeforeGuardMock do
    use Slash.Builder

    before :error when command not in [:greet, :tell]
    before :data when command in [:greet]

    def error(_command) do
      {:error, "Something went wrong"}
    end

    def data(%Command{} = command) do
      {:ok, put_data(command, :data, :data)}
    end

    command :tell, fn _ ->
      "Success"
    end

    command :greet, fn %Command{data: %{data: :data}} ->
      "Hello"
    end
  end

  defmodule MapResponseMock do
    use Slash.Builder

    command :greet, fn _ ->
      %{
        text: "Hello world!",
        attachments: [%{title: "Greetings!"}]
      }
    end

    command :hello, fn %Command{args: args} ->
      [name | _] = args

      %{
        text: "Hello #{name}!"
      }
    end
  end

  defmodule LongCommandMock do
    use Slash.Builder

    command :really_long_command_name, fn _ ->
      "Success!"
    end
  end

  defmodule AsyncTaskMock do
    use Slash.Builder

    command :async_task, fn command ->
      pid = self()

      async(command, fn -> send(pid, :ok) end)
    end
  end

  defmodule InvalidResultMock do
    use Slash.Builder

    before :error

    def error(_command) do
      {:ok, :nope}
    end
  end

  defmodule DefaultCommandMock do
    use Slash.Builder

    before :error when command in [:print]

    def error(_) do
      throw(:not_implemented)
    end

    command fn %{text: text} ->
      text
    end
  end

  setup _ do
    {:ok, conn: conn(:post, "/", %{})}
  end

  describe "router with error in before command" do
    test "should return error message", %{conn: conn} do
      conn =
        conn
        |> send_command(BeforeErrorMock, "help")
        |> BeforeErrorMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert body =~ ~r/error, not sure what happened here/i
    end
  end

  describe "router with before data" do
    test "should put data into the command struct", %{conn: conn} do
      conn =
        conn
        |> send_command(BeforeDataMock, "tell")
        |> BeforeDataMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert body =~ ~r/looks good!/i
    end

    test "should return help when command not found", %{conn: conn} do
      conn =
        conn
        |> send_command(BeforeDataMock, "not_sure")
        |> BeforeDataMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert body =~ ~r/slack supports the following commands/i
    end
  end

  describe "router with before guard clauses" do
    test "should put data into command struct when calling tell", %{conn: conn} do
      conn =
        conn
        |> send_command(BeforeGuardMock, "tell")
        |> BeforeGuardMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert body =~ ~r/Success/
    end

    test "should return error when calling greet", %{conn: conn} do
      conn =
        conn
        |> send_command(BeforeGuardMock, "greet")
        |> BeforeGuardMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert body =~ ~r/Hello/
    end
  end

  describe "router with map response data" do
    test "should encode response as json", %{conn: conn} do
      conn =
        conn
        |> send_command(MapResponseMock, "greet")
        |> MapResponseMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert %{"text" => "Hello world!", "attachments" => [_ | []]} = Jason.decode!(body)
    end

    test "should encode command with argument as json", %{conn: conn} do
      conn =
        conn
        |> send_command(MapResponseMock, "hello bob")
        |> MapResponseMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert %{"text" => "Hello bob!"} = Jason.decode!(body)
    end
  end

  describe "router with long command name" do
    test "should run dasherized command", %{conn: conn} do
      conn =
        conn
        |> send_command(LongCommandMock, "really-long-command-name")
        |> LongCommandMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert %{"text" => "Success!"} = Jason.decode!(body)
    end
  end

  describe "router with async task" do
    setup _ do
      {:ok, _} = Slash.Supervisor.start_link(:ok)

      :ok
    end

    test "should send 200 response", %{conn: conn} do
      conn =
        conn
        |> send_command(AsyncTaskMock, "async-task")
        |> AsyncTaskMock.call([])

      assert %Plug.Conn{status: 200} = conn
      assert_receive :ok
    end
  end

  describe "router with invalid before handler result" do
    test "should raise an argument error", %{conn: conn} do
      assert_raise ArgumentError, fn ->
        conn
        |> send_command(InvalidResultMock, "noop")
        |> InvalidResultMock.call([])
      end
    end
  end

  describe "router with default command block" do
    test "should route all commands to default command", %{conn: conn} do
      conn =
        conn
        |> send_command(DefaultCommandMock, "command")
        |> DefaultCommandMock.call([])

      assert %Plug.Conn{resp_body: body} = conn
      assert %{"text" => "command"} = Jason.decode!(body)
    end
  end
end
