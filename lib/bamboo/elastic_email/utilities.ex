defmodule Bamboo.ElasticEmail.Utilities do
  @moduledoc """
  Utilities for working with the Elastic Email API.

  The decode_query/{1,2} and encode_query/{1,2} functions are based heavily
  on Plug.Conn.Query, but the Elastic Email API accepts repeated values for
  list values instead of requiring `[]` be appended to the key name. Nested
  key names are not supported.
  """

  @doc """
  Decode an Elastic Email API query string. Because the decoded query is
  returned as a map, a list is always returned.

      iex> decode_query("foo=bar")["foo"]
      ["bar"]

  If a value is given more than once, a list is returned:

      iex> decode_query("foo=bar&foo=baz")["foo"]
      ["bar", "baz"]

  Decoding an empty string returns an empty map.

      iex> decode_query("")
      %{}
  """
  def decode_query(query, initial \\ %{})

  def decode_query("", initial), do: initial

  def decode_query(query, initial) do
    parts = :binary.split(query, "&", [:global])

    Enum.reduce(Enum.reverse(parts), initial, &decode_www_pair(&1, &2))
  end

  @doc """
  Encodes an Elastic Email API query string. Maps can be encoded:

      iex> encode_query(%{foo: "bar", baz: "bat"})
      "baz=bat&foo=bar"

  Encoding keyword lists preserves the order of the fields:

      iex> encode_query([foo: "bar", baz: "bat"])
      "foo=bar&baz=bat"

  When encoding keyword lists with duplicate keys, the keys are repeated:

      iex> encode_query([foo: "bar", foo: "bat"])
      "foo=bar&foo=bat"

  Encoding maps or keys with simple lists will have the same result as
  repeated keys in a keyword list:

      iex> encode_query(%{foo: ["bar", "bat"]})
      "foo=bar&foo=bat"

  Encoding a list of maps works the same way:

      iex> encode_query([%{foo: "bar"}, %{foo: "bat"}])
      "foo=bar&foo=bat"

  Nested maps and keyword lists are not supported and raise exceptions:

      iex> encode_query(%{foo: %{bar: "baz"}})
      ** (ArgumentError) cannot encode nested structures for foo

      iex> encode_query(%{foo: [bar: "baz"]})
      ** (ArgumentError) cannot encode nested structures for foo

  Structs work as well as maps:

      iex> encode_query(%Point{x: 1, y: 1})
      "x=1&y=1"

  Other structures raise an exception:

      iex> encode_query(3)
      ** (ArgumentError) can only encode maps, keyword lists, or lists of maps, got: 3
  """
  def encode_query(kv, encoder \\ &to_string/1) do
    kv
    |> encode_pair(encoder)
    |> IO.iodata_to_binary()
    |> String.trim_leading("&")
    |> String.replace("&&", "&", global: true)
  end

  defp decode_www_pair(binary, acc) do
    current =
      case :binary.split(binary, "=") do
        [key, value] ->
          {decode_www_form(key), decode_www_form(value)}

        [key] ->
          {decode_www_form(key), nil}
      end

    decode_pair(current, acc)
  end

  defp decode_www_form(value) do
    URI.decode_www_form(value)
  rescue
    ArgumentError ->
      # credo:disable-for-lines:1 Credo.Check.Warning.RaiseInsideRescue
      raise Plug.Conn.InvalidQueryError,
        message: "invalid www-form encoding on query-string, got #{value}"
  end

  # Decodes the given tuple and stores it in the accumulator. It parses the key
  # and stores the value into the current accumulator. Parameter lists are
  # added to the accumulator in reverse order, so be sure # to pass the
  # parameters in reverse order.
  defp decode_pair({key, value}, acc), do: assign_map(acc, key, value)

  defp assign_map(acc, key, value) do
    case acc do
      %{^key => values} -> Map.put(acc, key, [value | values])
      %{} -> Map.put(acc, key, [value])
    end
  end

  # covers structs
  defp encode_pair(%{__struct__: struct} = map, encoder) when is_atom(struct) do
    encode_pair(Map.from_struct(map), encoder)
  end

  defp encode_pair(%{} = map, encoder), do: encode_kv(map, encoder)

  defp encode_pair([], _encoder), do: []

  defp encode_pair([head | _] = list, encoder) when is_list(list) and is_tuple(head) do
    encode_kv(list, encoder)
  end

  defp encode_pair([head | _] = list, encoder) when is_list(list) and is_map(head) do
    list
    |> Enum.flat_map(&[?&, encode_pair(&1, encoder)])
    |> prune()
  end

  # covers nil
  defp encode_pair(nil, _encoder), do: []

  defp encode_pair(value, _encoder) do
    raise ArgumentError,
          "can only encode maps, keyword lists, or lists of maps, got: #{inspect(value)}"
  end

  defp encode_kv(kv, encoder) do
    mapper = fn
      {_, value} when value in [%{}, []] ->
        []

      {field, value} when is_map(value) ->
        raise ArgumentError, "cannot encode nested structures for #{field}"

      {field, [head | _] = value} when is_list(value) and (is_tuple(head) or is_map(head)) ->
        raise ArgumentError, "cannot encode nested structures for #{field}"

      {field, value} when is_list(value) ->
        field = encode_key(field)
        [?&, Enum.map(value, &[?&, field, ?= | encode_value(&1, encoder)])]

      {field, value} ->
        [?& | [encode_key(field), ?=, encode_value(value, encoder)]]
    end

    kv
    |> Enum.flat_map(mapper)
    |> prune()
  end

  defp encode_key(item), do: URI.encode_www_form(to_string(item))

  defp encode_value(item, encoder), do: URI.encode_www_form(encoder.(item))

  defp prune([?& | t]), do: t
  defp prune([]), do: []
end
