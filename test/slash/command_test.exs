defmodule Slash.CommandTest do
  use ExUnit.Case

  import Mox
  import Slash.Command

  alias Slash.Command

  defp mock_params() do
    %{
      "text" => "text",
      "channel_id" => "channel_id",
      "channel_name" => "channel_name",
      "enterprise_id" => "enterprise_id",
      "enterprise_name" => "enterprise_name",
      "response_url" => "response_url",
      "team_domain" => "team_domain",
      "team_id" => "team_id",
      "trigger_id" => "trigger_id",
      "user_id" => "user_id",
      "user_name" => "user_name"
    }
  end

  describe "put_data/3" do
    test "should put data into %Command{}" do
      data = :data

      assert %Command{data: %{key: ^data}} = put_data(%Command{}, :key, data)
    end

    test "should overwrite any existing data" do
      data = :new_data

      assert %Command{data: %{key: ^data}} =
               put_data(%Command{data: %{key: :old_data}}, :key, data)
    end
  end

  describe "from_params/1" do
    test "should return ok result tuple when valid params passed" do
      params = mock_params()

      assert {:ok, %Command{} = command} = Command.from_params(params)

      for {k, v} <- params do
        assert v == Map.get(command, String.to_atom(k))
      end
    end

    test "should properly parse text command with arguments" do
      params =
        mock_params()
        |> Map.put("text", "do-some-work arg1 arg2")

      assert {:ok, %Command{command: "do-some-work", args: ["arg1", "arg2"]}} =
               Command.from_params(params)
    end

    test "should properly empty text command" do
      params =
        mock_params()
        |> Map.put("text", "")

      assert {:ok, %Command{command: "", args: []}} = Command.from_params(params)
    end

    test "should filter invalid command fields" do
      params =
        mock_params()
        |> Map.put("filter_me", "value")

      assert {:ok, %Command{} = command} = Command.from_params(params)
      refute Map.has_key?(command, :filter_me)
    end

    test "should return error result tuple when invalid params passed" do
      params =
        mock_params()
        |> Map.delete("text")

      assert {:error, :invalid} = Command.from_params(params)
    end
  end

  describe "valid?/1" do
    test "should return false with empty %Command{}" do
      refute Command.valid?(%Command{})
    end

    test "should return false with nil %Command{} fields" do
      command =
        mock_params()
        |> Command.from_params()
        |> elem(1)
        |> Map.put(:text, nil)

      refute Command.valid?(command)
    end

    test "should return true when all fields are not empty" do
      command =
        mock_params()
        |> Command.from_params()
        |> elem(1)

      assert Command.valid?(command)
    end
  end

  describe "send_response/2" do
    setup :verify_on_exit!

    test "should send post request to request_url" do
      command = %Command{response_url: "test_url"}

      Mox.expect(HTTPoisonMock, :post, fn "test_url",
                                          "message",
                                          [{"content-type", "application/json"}] ->
        {:ok, %{status_code: 201}}
      end)

      assert :ok = Command.send_response(command, "message")
    end
  end
end
