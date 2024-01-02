# TestWithServer


[![Hex version badge](https://img.shields.io/hexpm/v/test_with_server.svg)](https://hex.pm/packages/test_with_server)
[![License badge](https://img.shields.io/hexpm/l/repo_example.svg)](https://github.com/filipecabaco/test_with_server/blob/master/LICENSE.md)
[![Elixir CI](https://github.com/filipecabaco/test_with_server/actions/workflows/elixir.yaml/badge.svg)](https://github.com/filipecabaco/test_with_server/actions/workflows/elixir.yaml)

Simple way to start up a server during tests with a given number of handlers

## Installation

The package can be installed by adding `test_with_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:test_with_server, "~> 0.0.1", only: :test}
  ]
end
```
## How it works

Uses ![francis](https://hex.pm/packages/francis) under the hood to create a module with the given handlers (routes) which then uses `start_supervised!` from ExUnit to start a Bandit server under port 5000 to avoid collisions with usual default ports.

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
  assert Req.get!("http://localhost:#{port}/hello").body == "ok"
end
```