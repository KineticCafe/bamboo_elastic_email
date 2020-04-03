defmodule Bamboo.ElasticEmailAdapterTest do
  @moduledoc false

  use ExUnit.Case

  alias Bamboo.{
    ElasticEmail,
    ElasticEmailAdapter,
    Email,
    Mailer
  }

  alias Plug.Conn

  @config %{adapter: ElasticEmailAdapter, api_key: "123_abc"}
  @config_with_bad_key %{adapter: ElasticEmailAdapter, api_key: nil}

  test "raises if the api key is nil" do
    assert_raise ArgumentError, ~r/no API key set/, fn ->
      [from: "foo@bar.com"]
      |> new_email()
      |> ElasticEmailAdapter.deliver(@config_with_bad_key)
    end

    assert_raise ArgumentError, ~r/no API key set/, fn ->
      ElasticEmailAdapter.handle_config(%{})
    end
  end

  describe "when sending emails" do
    setup do
      FakeElasticEmail.start_server(self())

      on_exit fn ->
        FakeElasticEmail.shutdown()
      end

      :ok
    end

    test "deliver/2 sends the to the right url" do
      new_email() |> ElasticEmailAdapter.deliver(@config)

      assert_receive {:fake_elastic_email, %{request_path: request_path}}

      assert request_path == "/email/send"
    end

    test "deliver/2 sends from, html and text body, subject, reply_to, and headers" do
      email =
        [
          from: {"From", "from@foo.com"},
          subject: "My Subject",
          text_body: "TEXT BODY",
          html_body: "HTML BODY"
        ]
        |> new_email()
        |> Email.put_header("Reply-To", "reply@foo.com")

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params} = conn}

      assert Conn.get_req_header(conn, "content-type") == ["application/x-www-form-urlencoded"]

      assert params["apikey"] == [@config[:api_key]]

      assert {params["fromName"], params["from"]} ==
               {[elem(email.from, 0)], [elem(email.from, 1)]}

      assert params["subject"] == [email.subject]
      assert params["bodyText"] == [email.text_body]
      assert params["bodyHtml"] == [email.html_body]
      assert params["replyTo"] == ["reply@foo.com"]

      assert not Enum.any?(Map.keys(params), &String.starts_with?(&1, "header_"))
    end

    test "deliver/2 correctly formats recipients" do
      email =
        new_email(
          to: [{"To", "to@bar.com"}, {"To2", "to2@bar.com"}],
          cc: [{"CC", "cc@bar.com"}],
          bcc: [{"BCC", "bcc@bar.com"}]
        )

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert ["To <to@bar.com>;To2 <to2@bar.com>"] == params["msgTo"]
      assert ["CC <cc@bar.com>"] == params["msgCc"]
      assert ["BCC <bcc@bar.com>"] == params["msgBcc"]
    end

    test "deliver/2 adds extra params to the message " do
      ElasticEmailAdapter.deliver(new_email(), @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert params["isTransactional"] == ["true"]
    end

    test "raises if the response is not a success" do
      email = new_email(from: "INVALID_EMAIL")

      assert_raise Bamboo.ElasticEmailAdapter.ApiError, fn ->
        email |> ElasticEmailAdapter.deliver(@config)
      end
    end

    test "removes api key from error output" do
      email = new_email(from: "INVALID_EMAIL")

      assert_raise Bamboo.ElasticEmailAdapter.ApiError, ~r/"apikey" => "\[FILTERED\]"/, fn ->
        ElasticEmailAdapter.deliver(email, @config)
      end
    end

    test "deliver/2 adds custom elastic fields using from email to the message" do
      email =
        Email.put_private(new_email(), :elastic_send_options, %{
          post_back: "12345",
          pool_name: "test"
        })

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert params["postBack"] == ["12345"]
      assert params["poolName"] == ["test"]
    end

    test "deliver/2 handles the merge custom elastic field correctly" do
      email = ElasticEmail.merge(new_email(), first_name: ["Chris", "George"])

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert params["merge_first_name"] == ["Chris", "George"]
    end

    test "deliver/2 skips unknown custom elastic fields from email to the message" do
      email =
        Email.put_private(new_email(), :elastic_send_options, %{
          pool_name: "test",
          unknown: "unknown"
        })

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert params["poolName"] == ["test"]
      refute params["unknown"]
    end

    test "deliver/2 handles charset settings correctly" do
      [nil, :amp, :html, :text]
      |> Enum.each(fn type ->
        new_email()
        |> ElasticEmail.charset(type, "iso-8859-1")
        |> ElasticEmailAdapter.deliver(@config)

        assert_receive {:fake_elastic_email, %{params: params}}

        type =
          case type do
            nil -> "charset"
            :amp -> "charsetBodyAmp"
            :html -> "charsetBodyHtml"
            :text -> "charsetBodyText"
          end

        assert params[type] == ["iso-8859-1"]
      end)
    end

    test "deliver/2 rejects custom elastic fields with nil value" do
      email =
        Email.put_private(new_email(), :elastic_send_options, %{
          post_back: "12345",
          pool_name: nil
        })

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert params["postBack"] == ["12345"]
      refute params["poolName"]
    end

    test "deliver/2 adds custom elastic fields using deprecated :elastic_custom_vars" do
      email =
        Email.put_private(new_email(), :elastic_custom_vars, %{
          post_back: "12345",
          pool_name: "test"
        })

      ElasticEmailAdapter.deliver(email, @config)

      assert_receive {:fake_elastic_email, %{params: params}}

      assert params["postBack"] == ["12345"]
      assert params["poolName"] == ["test"]
    end

    defp new_email(attrs \\ []) do
      [from: "foo@bar.com", to: []]
      |> Keyword.merge(attrs)
      |> Email.new_email()
      |> Mailer.normalize_addresses()
    end
  end
end
