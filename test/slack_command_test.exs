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
end
