defmodule TestWithServer do
  @moduledoc """
  A macro to start a server for a test and send messages to the test process.

  ## Usage

  Import `TestWithServer` and use the function `test_with_server` to run a server on port 5000 by default:
  ```elixir
  import TestWithServer

  test_with_server "hello world get request",
                 [quote(do: get("hello", fn conn -> "world" end))] do
  assert Req.get!("http://localhost:5000/hello").body == "ok"
  end
  ```

  You could set multiple handlers:
  ```elixir
  import TestWithServer

  test_with_server "hello world get and post request",
                 [
                   quote(do: get("hello", fn conn -> "world" end)),
                   quote(
                     do:
                       post("hello", fn conn ->
                         {:ok, body, _} = read_body(conn)
                         body
                       end)
                   )
                 ] do
  assert Req.get!("http://localhost:5000/hello").body == "ok"
  assert Req.post!("http://localhost:5000/hello", body: "test").body == "test"
  end
  ```
  You are also able to use test context in the handlers and in your test.

  We set a module attribute `@context` for your handlers to use said context:

  ```elixir
  import TestWithServer

  setup do
  %{element: Enum.random(1000..4000)}
  end

  test_with_server "using context", %{element: element}, [
  quote(do: get("hello", fn _conn -> Integer.to_string(@context.element) end))
  ] do
  assert Req.get!("http://localhost:5000/hello").body == Integer.to_string(element)
  end
  ```

  You can also set your bandit server opts and you can also use context to set options:
  ```elixir
  import TestWithServer

  setup do
  %{port: Enum.random(4000..5000)}
  end

  test_with_server "using context",
                  %{port: port},
                  [
                    quote(do: get("hello", fn _conn -> "ok" end))
                  ],
                  port: port do
    assert Req.get!("http://localhost:\#{port}/hello").body == "ok"
  end
  ```

  """
  use ExUnit.Case

  @doc """
  Starts a server for the given handlers and sends messages to the test process.

  The arguments are:
  * `test_name` - the name of the test
  * `context` - the test context to be used in the test, handlers and server options (defaults to `%{}`)
  * `handlers` - a list of handlers to be passed to `francis`
  * `opts` - a keyword list of options to be passed to `Bandit` (defaults to `[]`)
  * `test_block` - the actual test block to be ran after the server is started
  """

  defmacro test_with_server(test_name, {:%{}, _, _} = context, handlers, opts, test_block) do
    quote do
      import Francis

      test unquote(test_name), unquote(context) do
        server = TestWithServer.start_server(self(), unquote(handlers), unquote(context))
        start_supervised!({Bandit, [plug: server] ++ unquote(Keyword.merge([port: 5000], opts))})
        unquote(test_block)
      end
    end
  end

  @doc """
  See `test_with_server/5` for more information.
  """
  defmacro test_with_server(test_name, {:%{}, _, _} = context, handlers, test_block) do
    quote do
      import Francis

      test unquote(test_name), unquote(context) do
        server = TestWithServer.start_server(self(), unquote(handlers), unquote(context))
        start_supervised!({Bandit, [plug: server, port: 5000]})
        unquote(test_block)
      end
    end
  end

  defmacro test_with_server(test_name, handlers, opts, test_block) do
    quote do
      import Francis

      test unquote(test_name) do
        server = TestWithServer.start_server(self(), unquote(handlers))
        start_supervised!({Bandit, [plug: server] ++ unquote(Keyword.merge([port: 5000], opts))})
        unquote(test_block)
      end
    end
  end

  @doc """
  See `test_with_server/5` for more information.
  """
  defmacro test_with_server(test_name, handlers, test_block) do
    quote do
      import Francis

      test unquote(test_name) do
        server = TestWithServer.start_server(self(), unquote(handlers))
        start_supervised!({Bandit, plug: server, port: 5000})
        unquote(test_block)
      end
    end
  end

  def start_server(pid, handlers, context \\ %{}) do
    ast =
      quote location: :keep do
        # Module.register_attribute(__MODULE__, :test_context, accumulate: false, persist: true)
        Module.put_attribute(__MODULE__, :context, unquote(Macro.escape(context)))
        use Francis

        unquote_splicing(handlers)

        def send_to_test(message), do: send(unquote(pid), message)
      end

    name = String.to_atom("TestWithServer#{6 |> :crypto.strong_rand_bytes() |> Base.encode16()}")

    {_, module, _, _} = Module.create(name, ast, Macro.Env.location(__ENV__))
    module
  end
end
