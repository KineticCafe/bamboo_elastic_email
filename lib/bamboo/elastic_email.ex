defmodule Bamboo.ElasticEmail do
  @moduledoc """
  Helper functions for manipulating Bamboo.Email to enable Elastic Email
  functionality.
  """

  alias Bamboo.Email

  @doc """
  Add attachment identifiers to the email.

  > Names or IDs of attachments previously uploaded to your account (via the
  > File/Upload request) that should be sent with this e-mail.
  """
  @spec attachments(Email.t(), [binary(), ...] | binary()) :: Email.t()
  def attachments(%Email{} = email, attachments) do
    put_elastic_send_option(email, :attachments, List.wrap(attachments))
  end

  @doc """
  Sets the channel for the email.

  > An ID field (max 191 chars) that can be used for reporting [will default
  > to HTTP API or SMTP API]
  """
  @spec channel(Email.t(), binary()) :: Email.t()
  def channel(%Email{} = email, channel) do
    put_elastic_send_option(email, :channel, String.slice(channel, 0..190))
  end

  @doc """
  Sets the character set for the email or one of the MIME parts. Overrides the
  global default of "utf-8".

  > Text value of charset encoding for example: iso-8859-1, windows-1251,
  > utf-8, us-ascii, windows-1250 and more…

  The `part` parameter is interpreted as:

  - `:amp`: sets the `charsetBodyAmp` option (the AMP body MIME part)
  - `:html`: sets the `charsetBodyHtml` option (the HTML body MIME part)
  - `:text`: sets the `charsetBodyText` option (the text body MIME part)

  Any other value sets the global `charset` option.
  """
  @spec charset(Email.t(), part :: nil | :amp | :html | :text, binary()) :: Email.t()
  def charset(%Email{} = email, part \\ nil, charset) do
    put_elastic_send_option(
      email,
      case part do
        :amp -> :charset_body_amp
        :html -> :charset_body_html
        :text -> :charset_body_text
        _ -> :charset
      end,
      charset
    )
  end

  @doc """
  Sets the data source of the email.

  > Name or ID of the previously uploaded file (via the File/Upload request)
  > which should be a CSV list of Recipients.
  """
  @spec data_source(Email.t(), binary()) :: Email.t()
  def data_source(%Email{} = email, name) do
    put_elastic_send_option(email, :data_source, name)
  end

  @doc """
  Sets the email encoding type. The default encoding is `:base64`, which is
  the recommended value. Either `:base64` or `:quoted_printable` is
  recommended if you are validating your domain(s) with DKIM.

  Supported encoding types are:
  - `:none`: no encoding
  - `:raw_7bit`: Raw 7bit. Must be plain ASCII.
  - `:raw_8bit`: Raw 8bit.
  - `:quoted_printable`:  Quoted printable format.
  - `:base64`: Base64
  - `:uue`: UU
  """
  @spec encoding_type(Email.t(), atom) :: Email.t()
  def encoding_type(%Email{} = email, encoding) do
    put_elastic_send_option(
      email,
      :encoding_type,
      case encoding do
        :none -> 0
        :raw_7bit -> 1
        :raw_8bit -> 2
        :quoted_printable -> 3
        :uue -> 5
        _ -> 4
      end
    )
  end

  @doc "The name or names of a contact list you would like to send to."
  @spec lists(Email.t(), [binary(), ...] | binary()) :: Email.t()
  def lists(%Email{} = email, lists) do
    put_elastic_send_option(email, :lists, Enum.join(List.wrap(lists), ";"))
  end

  @doc """
  Sets merge parameters. The params must be a list of maps or keyword lists
  (or other 2-tuple lists).

  > Repeated list of string keys and string values
  > Request parameters prefixed by merge_ like merge_firstname,
  > merge_lastname. If sending to a template you can send merge_ fields to
  > merge data with the template. Template fields are entered with
  > {firstname}, {lastname} etc.
  """
  @spec merge(Email.t(), map() | keyword() | [map() | keyword(), ...]) :: Email.t()
  def merge(%Email{} = email, params) do
    put_elastic_send_option(email, :merge, Enum.flat_map(List.wrap(params), &to_merge_params/1))
  end

  @doc """
  The file name of a previously uploaded attachment which is a CSV list of
  Recipients.
  """
  @spec merge_source_filename(Email.t(), binary()) :: Email.t()
  def merge_source_filename(%Email{} = email, filename) do
    put_elastic_send_option(email, :merge_source_filename, filename)
  end

  @doc "Name of the custom IP Pool to be used in the sending process."
  @spec pool_name(Email.t(), binary()) :: Email.t()
  def pool_name(%Email{} = email, name) do
    put_elastic_send_option(email, :pool_name, name)
  end

  @doc "Optional header returned in notifications."
  @spec post_back(Email.t(), binary()) :: Email.t()
  def post_back(%Email{} = email, post_back) do
    put_elastic_send_option(email, :post_back, post_back)
  end

  @doc """
  The name or names of the Contact segment(s) you wish to send. Use :all
  for all active contacts.
  """
  @spec segments(Email.t(), :all | binary() | [binary() | :all, ...]) :: Email.t()
  def segments(%Email{} = email, segments) do
    segments =
      segments
      |> List.wrap()
      |> Enum.map(&if(match?(:all, &1), do: "0", else: &1))
      |> Enum.uniq()
      |> Enum.join(";")

    put_elastic_send_option(email, :segments, segments)
  end

  @doc "The ID of an email template you have created in your account."
  @spec template(Email.t(), binary()) :: Email.t()
  def template(%Email{} = email, template) do
    put_elastic_send_option(email, :template, template)
  end

  @doc """
  The number of minutes in the future this email should be sent up to a
  maximum of 1 year (524,160 minutes).
  """
  @spec time_off_set_minutes(Email.t(), 1..524_160) :: Email.t()
  def time_off_set_minutes(%Email{} = email, minutes) when is_integer(minutes) do
    put_elastic_send_option(
      email,
      :time_off_set_minutes,
      cond do
        minutes < 1 -> 1
        minutes > 524_160 -> 524_160
        true -> minutes
      end
    )
  end

  @doc "Indicates whether clicks should be tracked on this email."
  @spec track_clicks(Email.t(), boolean) :: Email.t()
  def track_clicks(%Email{} = email, track_clicks) do
    put_elastic_send_option(email, :track_clicks, track_clicks)
  end

  @doc "Indicates whether opens should be tracked on this email."
  @spec track_opens(Email.t(), boolean) :: Email.t()
  def track_opens(%Email{} = email, track_opens) do
    put_elastic_send_option(email, :track_opens, track_opens)
  end

  @doc "Set UTM Marketing Parameters for campaign links."
  @spec utm_parameters(
          Email.t(),
          %{optional(:campaign | :content | :medium | :source) => binary()} | keyword
        ) :: Email.t()
  def utm_parameters(%Email{} = email, params) do
    merge_elastic_send_options(email, Map.new(params, &to_utm_parameter/1))
  end

  defp put_elastic_send_option(%{private: private} = email, key, value) do
    send_options =
      private
      |> Map.get(:elastic_send_options, %{})
      |> Map.put(key, value)

    %{email | private: Map.put(private, :elastic_send_options, send_options)}
  end

  defp merge_elastic_send_options(%{private: private} = email, %{} = options) do
    send_options =
      private
      |> Map.get(:elastic_send_options, %{})
      |> Map.merge(options)

    %{email | private: Map.put(private, :elastic_send_options, send_options)}
  end

  defp to_merge_params({k, v}), do: [{"merge_#{k}", v}]

  defp to_merge_params(params) when is_list(params) or is_map(params),
    do: Enum.map(params, &to_merge_params/1)

  defp to_utm_parameter({:campaign, value}), do: {:utm_campaign, value}
  defp to_utm_parameter({:content, value}), do: {:utm_content, value}
  defp to_utm_parameter({:medium, value}), do: {:utm_medium, value}
  defp to_utm_parameter({:source, value}), do: {:utm_source, value}
end
