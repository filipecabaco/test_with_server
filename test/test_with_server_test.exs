defmodule TestWithServerTest do
  use ExUnit.Case, async: true
  import TestWithServer

  test_with_server "send_to_test function sends a message to the test process",
                   [
                     quote(
                       do:
                         get(":id", fn %{path_params: %{"id" => id}} ->
                           send_to_test({:ok, id})
                           "ok"
                         end)
                     )
                   ] do
    id = Enum.random(1..100) |> Integer.to_string()
    assert Req.get!("http://localhost:5000/#{id}").body == "ok"
    assert_receive {:ok, ^id}
  end

  test_with_server "test_with_server/3 starts a server for the given handler",
                   [
                     quote(do: get("hello", fn _conn -> "world" end))
                   ] do
    assert Req.get!("http://localhost:5000/hello").body == "world"
  end

  describe "with setup context" do
    setup do
      %{port: Enum.random(4000..5000)}
    end

    test_with_server "contains usable context in test block", %{port: port}, [
      quote(do: get("hello", fn _conn -> "world" end))
    ] do
      assert Req.get!("http://localhost:5000/hello").body == "world"
      assert port
    end

    test_with_server "contains usable context in test block and server options that understand context",
                     %{port: port},
                     [
                       quote(do: get("hello", fn _conn -> "world" end))
                     ],
                     port: port do
      assert Req.get!("http://localhost:#{port}/hello").body == "world"
      assert port
    end

    test_with_server "handler can access test", %{port: port}, [
      quote(do: get("hello", fn _conn -> @context.port |> Integer.to_string() end))
    ] do
      assert Req.get!("http://localhost:5000/hello").body == port |> Integer.to_string()
    end
  end
end
