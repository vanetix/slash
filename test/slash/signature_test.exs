defmodule Slash.SignatureTest do
  use ExUnit.Case

  import Slash.Signature

  describe "generate/3" do
    test "should generate signature" do
      timestamp =
        1_555_000_000
        |> to_string()

      assert signature = generate("foo", timestamp, "body")

      assert signature ==
               "8bfff1e77496dbc2ec9835c5b455e7705dffa32ff3bc69f13b82c297d39aea47"
    end
  end

  describe "verify/2" do
    test "should return true if arguments are equal" do
      assert verify("foo", "foo")
    end

    test "should return false if arguments are not equal" do
      refute verify("foo", "fooo")
    end
  end
end
