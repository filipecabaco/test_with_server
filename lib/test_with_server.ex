defmodule TestWithServer do
  use ExUnit.Case

  defmacro test_with_server(test_name, {:%{}, _, _} = context, handlers, opts, test_block) do
    quote do
      import Francis

      test unquote(test_name), unquote(context) do
        server = TestWithServer.start_server(self(), unquote(handlers))
        start_supervised!({Bandit, [plug: server] ++ unquote(opts)})
        unquote(test_block)
      end
    end
  end

  defmacro test_with_server(test_name, {:%{}, _, _} = context, handlers, test_block) do
    quote do
      import Francis

      test unquote(test_name), unquote(context) do
        server = TestWithServer.start_server(self(), unquote(handlers))
        start_supervised!({Bandit, [plug: server]})
        unquote(test_block)
      end
    end
  end

  defmacro test_with_server(test_name, handlers, opts, test_block) do
    quote do
      import Francis

      test unquote(test_name) do
        server = TestWithServer.start_server(self(), unquote(handlers))
        start_supervised!({Bandit, [plug: server] ++ unquote(opts)})
        unquote(test_block)
      end
    end
  end

  defmacro test_with_server(test_name, handlers, test_block) do
    quote do
      import Francis

      test unquote(test_name) do
        server = TestWithServer.start_server(self(), unquote(handlers))
        start_supervised!({Bandit, plug: server})
        unquote(test_block)
      end
    end
  end

  def start_server(pid, handlers) do
    ast =
      quote location: :keep do
        use Francis
        unquote_splicing(handlers)

        def send_to_test(message), do: send(unquote(pid), message)
      end

    name = String.to_atom("TestWithServer#{6 |> :crypto.strong_rand_bytes() |> Base.encode16()}")

    {_, module, _, _} = Module.create(name, ast, Macro.Env.location(__ENV__))
    module
  end
end
