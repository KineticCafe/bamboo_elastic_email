defmodule Bamboo.ElasticEmail.UtilitiesTest do
  @moduledoc false

  use ExUnit.Case

  defmodule Point do
    @moduledoc false

    defstruct x: 0, y: 0
  end

  doctest Bamboo.ElasticEmail.Utilities, import: true
end
