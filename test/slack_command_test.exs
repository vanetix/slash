defmodule SlackCommand.RouterTest do
  use ExUnit.Case

  defmodule MockRouter do
    use SlackCommand.Router

    defcommand ping(_) do
      "pong"
    end

    defcommand hello(_, name) do
      "hello #{name}!"
    end
  end

  describe "MockRouter" do
    test "should define do_command/3" do
      assert function_exported?(MockRouter, :do_command, 3)
    end
  end

  describe "SlackCommand.Router" do
    test "compile/1 should generate default function definitions" do
      generated = "SlackTest"
                  |> SlackCommand.Router.compile([])
                  |> Macro.to_string()

      assert generated == String.trim ~S"""
      (
        def(do_command(command, conn, _args \\ []))
        []
        def(do_command(_help, _conn, _args)) do
          {:ok, %Message{text: "SlackTest" <> " supports the following commands:", attachments: []}}
        end
      )
      """
    end
  end
end
