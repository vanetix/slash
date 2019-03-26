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

  describe "build_response_payload/1" do
    test "should build binary payload" do
      assert %{text: "message"} = build_response_payload("message")
    end

    test "should build map payload" do
      assert %{key: :value} = build_response_payload(%{key: :value})
    end

    test "should build async payload" do
      assert "" = build_response_payload(:async)
    end

    test "should raise for other types" do
      assert_raise ArgumentError, fn ->
        build_response_payload(:ok)
      end
    end
  end
end
