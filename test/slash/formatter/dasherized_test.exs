defmodule Slash.Formatter.DasherizedTest do
  use ExUnit.Case

  alias Slash.Formatter.Dasherized

  describe "to_command_name/1" do
    test "should properly format underscores to dashes" do
      assert "command" = Dasherized.to_command_name("command")
      assert "short-command" = Dasherized.to_command_name("short-command")
      assert "super-long-command-name" = Dasherized.to_command_name("super_long_command_name")
    end
  end
end
