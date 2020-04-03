defmodule FakeElasticEmail do
  @moduledoc false

  use Plug.Router

  alias Plug.Adapters.Cowboy

  plug Plug.Parsers,
    parsers: [UrlencodedParser, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug :match
  plug :dispatch

  def start_server(parent) do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
    Agent.update(__MODULE__, &Map.put(&1, :parent, parent))
    port = get_free_port()

    Application.put_env(:bamboo, :elastic_email_base_uri, "http://localhost:#{port}")
    Cowboy.http(__MODULE__, [], port: port, ref: __MODULE__)
  end

  def get_free_port do
    {:ok, socket} = :ranch_tcp.listen(port: 0)
    {:ok, port} = :inet.port(socket)
    :erlang.port_close(socket)
    port
  end

  def shutdown do
    Cowboy.shutdown(__MODULE__)
  end

  post "/email/send" do
    case conn.params["from"] do
      ["INVALID_EMAIL"] ->
        conn
        |> send_resp(500, "Error!!")
        |> send_to_parent

      _ ->
        conn
        |> send_resp(200, "SENT")
        |> send_to_parent
    end
  end

  defp send_to_parent(conn) do
    parent = Agent.get(__MODULE__, &Map.get(&1, :parent))
    send(parent, {:fake_elastic_email, conn})
    conn
  end
end
