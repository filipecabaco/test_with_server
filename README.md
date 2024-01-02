# TestWithServer


[![Hex version badge](https://img.shields.io/hexpm/v/test_with_server.svg)](https://hex.pm/packages/test_with_server)
[![License badge](https://img.shields.io/hexpm/l/repo_example.svg)](https://github.com/filipecabaco/test_with_server/blob/master/LICENSE.md)
[![Elixir CI](https://github.com/filipecabaco/test_with_server/actions/workflows/elixir.yaml/badge.svg)](https://github.com/filipecabaco/test_with_server/actions/workflows/elixir.yaml)

Simple way to start up a server during tests with a given number of handlers

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `test_with_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:test_with_server, "~> 0.1.0", only: :test}
  ]
end
```

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


```elixir
import TestWithServer
setup do
  %{element: element}
end
test_with_server "", [quote(do: get("hello", fn conn -> "world" end))] do

end
```