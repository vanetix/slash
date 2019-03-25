defmodule Slash.UtilsTest do
  use ExUnit.Case
  use Plug.Test

  import Slash.Utils

  alias Plug.Conn

  describe "send_json/2" do
    test "should send json response" do
      data = %{text: "text"}
      conn = conn(:get, "/")

      assert %Conn{} = conn = send_json(conn, data)
      assert conn.resp_body == Jason.encode!(data)

      assert ["application/json" <> _ | []] = Conn.get_resp_header(conn, "content-type")
    end
  end
end
