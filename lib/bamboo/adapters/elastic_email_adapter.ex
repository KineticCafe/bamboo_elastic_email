defmodule Bamboo.ElasticEmailAdapter do
  @moduledoc """
  Sends email using ElasticEmail's JSON API.

  Use this adapter to send emails through ElasticEmail's API. Requires that an
  API key is set in the config.

  This version is extracted from a hastily-constructed adapter for a Kinetic
  Commerce project. It makes several assumptions that will be broken in a
  future release:

  * It always puts a `charset` of `utf-8`.
  * It cannot send emails from Elastic Email templates.
  * All emails are currently sent as transactional.
  * It always passes `ssl_options: [versions: [:"tlsv1.2"]]` to Hackney.

  ## Example config

      # In config/config.exs, or config/prod.exs, etc.
      config :my_app, MyApp.Mailer,
        adapter: Bamboo.ElasticEmailAdapter,
        api_key: "my_api_key"

      # Define a Mailer. Maybe in lib/my_app/mailer.ex
      defmodule MyApp.Mailer do
        use Bamboo.Mailer, otp_app: :my_app
      end
  """

  @behaviour Bamboo.Adapter

  @base_uri "https://api.elasticemail.com/v2"
  @send_message_path "/email/send"
  @hackney_opts [:with_body, ssl_options: [versions: [:"tlsv1.2"]]]

  alias Bamboo.Email
  alias Plug.Conn.Query

  def supports_attachments, do: true

  defmodule ApiError do
    @moduledoc false

    defexception [:message]

    @spec exception(%{message: String.t()} | %{params: any, response: any}) :: Exception.t()
    def exception(%{message: message}), do: %ApiError{message: message}

    def exception(%{params: params, response: response}) do
      filtered_params =
        params
        |> Query.decode()
        |> Map.put("apikey", "[FILTERED]")

      message = """
      There was a problem sending the email through the ElasticEmail API.

      Here is the response:

      #{inspect(response, limit: :infinity)}

      Here are the params we sent:

      #{inspect(filtered_params, limit: :infinity)}
      """

      %ApiError{message: message}
    end
  end

  @doc false
  @impl Bamboo.Adapter
  @spec deliver(%Bamboo.Email{}, map) :: any
  def deliver(email, config) do
    api_key = get_key(config)

    body =
      email
      |> to_elastic_body(api_key)
      |> Query.encode()

    case request!(@send_message_path, body, api_key) do
      {:ok, status, _headers, response} when status > 299 ->
        raise(ApiError, %{params: body, response: response})

      {:ok, status, headers, response} ->
        # Note: this may *not* be correct because ElasticEmail uses an
        # in-response status code, too. We will extend this a bit later.
        %{status_code: status, headers: headers, body: response}

      {:error, reason} ->
        raise(ApiError, %{message: inspect(reason)})

      response ->
        response
    end
  end

  @doc false
  @impl Bamboo.Adapter
  @spec handle_config(map) :: map | no_return
  def handle_config(config) do
    if Map.get(config, :api_key) in [nil, ""] do
      raise_api_key_error(config)
    else
      config
    end
  end

  @spec get_key(map) :: String.t() | no_return
  defp get_key(config) do
    case Map.get(config, :api_key) do
      nil -> raise_api_key_error(config)
      {:system, var} -> System.get_env(var) || raise_api_key_error(config)
      key -> key
    end
  end

  @spec raise_api_key_error(keyword) :: no_return
  defp raise_api_key_error(config) do
    raise ArgumentError, """
    There was no API key set for the ElasticEmail adapter.

    * Here are the config options that were passed in:

    #{inspect(config)}
    """
  end

  defp headers(_api_key) do
    [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]
  end

  defp to_elastic_body(%Email{} = email, api_key) do
    email
    |> Map.from_struct()
    |> put_from()
    |> put_to()
    |> put_cc()
    |> put_bcc()
    |> put_html_body()
    |> put_text_body()
    |> put_charset()
    |> put_headers(email)
    |> put_api_key(api_key)
    |> put_elastic_send_options()
    |> put_transactional()
    |> transform_fields()
    |> filter_fields()
  end

  defp put_from(%{from: {nil, email}} = map), do: Map.put(map, "from", email)
  defp put_from(%{from: {"", email}} = map), do: Map.put(map, "from", email)

  defp put_from(%{from: {name, email}} = map) do
    map
    |> Map.put("fromName", name)
    |> Map.put("from", email)
  end

  defp put_from(%{from: email} = map), do: Map.put(map, "from", email)
  defp put_from(map), do: map

  defp put_to(%{to: email} = map), do: Map.put(map, "msgTo", combine_name_and_email(email))
  defp put_to(map), do: map

  defp put_cc(%{cc: email} = map), do: Map.put(map, "msgCc", combine_name_and_email(email))
  defp put_cc(map), do: map

  defp put_bcc(%{bcc: email} = map), do: Map.put(map, "msgBcc", combine_name_and_email(email))
  defp put_bcc(map), do: map

  defp put_reply_to(map, {nil, email}), do: Map.put(map, "replyTo", email)
  defp put_reply_to(map, {"", email}), do: Map.put(map, "replyTo", email)

  defp put_reply_to(map, {name, email}) do
    map
    |> Map.put("replyToName", name)
    |> Map.put("replyTo", email)
  end

  defp put_reply_to(map, nil), do: map
  defp put_reply_to(map, ""), do: map
  defp put_reply_to(map, email), do: Map.put(map, "replyTo", email)

  defp put_api_key(body, api_key), do: Map.put(body, "apikey", api_key)

  defp put_html_body(%{html_body: html_body} = map), do: Map.put(map, "bodyHtml", html_body)
  defp put_html_body(map), do: map

  defp put_text_body(%{text_body: text_body} = map), do: Map.put(map, "bodyText", text_body)
  defp put_text_body(map), do: map

  defp put_charset(map), do: Map.put(map, "charset", "utf-8")

  defp put_transactional(map), do: Map.put(map, "isTransactional", true)

  defp put_elastic_send_options(%{private: %{elastic_custom_vars: options} = private} = email) do
    private =
      private
      |> Map.delete(:elastic_custom_vars)
      |> Map.put(:elastic_send_options, options)

    put_elastic_send_options(%{email | private: private})
  end

  defp put_elastic_send_options(%{private: %{elastic_send_options: options}} = email) do
    options
    |> Enum.map(&send_option/1)
    |> Enum.reject(&(is_nil(&1) || match?({_, nil}, &1)))
    |> Enum.into(email)
  end

  defp put_elastic_send_options(email), do: email

  defp send_option({:attachments, attachments}), do: {"attachments", attachments}
  defp send_option({:channel, channel}), do: {"channel", channel}
  defp send_option({:data_source, data_source}), do: {"dataSource", data_source}
  defp send_option({:encoding_type, encoding_type}), do: {"encodingType", encoding_type}
  defp send_option({:lists, lists}), do: {"lists", lists}
  defp send_option({:merge, merge}), do: {"merge", merge}
  defp send_option({:pool_name, pool_name}), do: {"poolName", pool_name}
  defp send_option({:post_back, post_back}), do: {"postBack", post_back}
  defp send_option({:segments, segments}), do: {"segments", segments}
  defp send_option({:template, template}), do: {"template", template}
  defp send_option({:track_clicks, track_clicks}), do: {"trackClicks", track_clicks}
  defp send_option({:track_opens, track_opens}), do: {"trackOpens", track_opens}

  defp send_option({:charset_body_html, charset_body_html}),
    do: {"charsetBodyHtml", charset_body_html}

  defp send_option({:charset_body_text, charset_body_text}),
    do: {"charsetBodyText", charset_body_text}

  defp send_option({:merge_source_filename, merge_source_filename}),
    do: {"mergeSourceFilename", merge_source_filename}

  defp send_option({:time_off_set_minutes, time_off_set_minutes}),
    do: {"timeOffSetMinutes", time_off_set_minutes}

  defp send_option(_), do: nil

  defp put_headers(body, %Email{headers: headers}) do
    Enum.reduce(headers, body, fn {key, value}, acc ->
      case String.downcase(key) do
        "reply-to" -> put_reply_to(acc, value)
        key -> Map.put(acc, "headers_#{key}", "#{key}: #{value}")
      end
    end)
  end

  defp combine_name_and_email(list) when is_list(list) do
    list
    |> Enum.map(&combine_name_and_email/1)
    |> Enum.join(";")
  end

  defp combine_name_and_email({nil, email}), do: email
  defp combine_name_and_email({"", email}), do: email
  defp combine_name_and_email({name, email}), do: "#{name} <#{email}>"

  @message_fields ~w(subject)a

  defp transform_fields(map) do
    Enum.reduce(@message_fields, map, &transform_field/2)
  end

  defp transform_field(field, map) when is_atom(field) do
    Map.put(map, Atom.to_string(field), Map.get(map, field))
  end

  defp transform_field(_field, map), do: map

  defp filter_fields(map) do
    Enum.reject(map, &(is_atom(elem(&1, 0)) or elem(&1, 1) in [nil, "", []]))
  end

  defp base_uri do
    Application.get_env(:bamboo, :elastic_email_base_uri) || @base_uri
  end

  defp request!(path, body, api_key) do
    uri = base_uri() <> path
    :hackney.post(uri, headers(api_key), body, @hackney_opts)
  end
end
