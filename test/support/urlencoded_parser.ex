defmodule UrlencodedParser do
  @moduledoc false

  @behaviour Plug.Parsers

  alias Bamboo.ElasticEmail.Utilities

  alias Plug.{
    Conn.Utils,
    Parsers.BadEncodingError
  }

  def init(opts) do
    opts = Keyword.put_new(opts, :length, 1_000_000)
    Keyword.pop(opts, :body_reader, {Plug.Conn, :read_body, []})
  end

  def parse(conn, "application", "x-www-form-urlencoded", _headers, {{mod, fun, args}, opts}) do
    case apply(mod, fun, [conn, opts | args]) do
      {:ok, body, conn} ->
        Utils.validate_utf8!(body, BadEncodingError, "urlencoded body")
        {:ok, Utilities.decode_query(body), conn}

      {:more, _data, conn} ->
        {:error, :too_large, conn}

      {:error, :timeout} ->
        raise Plug.TimeoutError

      {:error, _} ->
        raise Plug.BadRequestError
    end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
