defmodule Bamboo.ElasticEmailTest do
  @moduledoc false

  use ExUnit.Case

  import Bamboo.ElasticEmail

  test "attachments/2 works with a single binary" do
    new_email()
    |> attachments("one")
    |> assert_elastic_send_option(:attachments, ["one"])
  end

  test "attachments/2 works with a list of binaries" do
    new_email()
    |> attachments(["one", "two"])
    |> assert_elastic_send_option(:attachments, ["one", "two"])
  end

  test "channel/2 limits the channel ID to 191 characters" do
    email = channel(new_email(), String.duplicate("a", 192))
    assert_elastic_send_option(email, :channel, String.duplicate("a", 191))
  end

  test "charset/2 sets the global charset" do
    new_email()
    |> charset("iso-8859-1")
    |> assert_elastic_send_option(:charset, "iso-8859-1")
  end

  test "charset/3 sets the appropriate part charset" do
    new_email()
    |> charset(:amp, "iso-8859-1")
    |> assert_elastic_send_option(:charset_body_amp, "iso-8859-1")

    new_email()
    |> charset(:html, "iso-8859-1")
    |> assert_elastic_send_option(:charset_body_html, "iso-8859-1")

    new_email()
    |> charset(:text, "iso-8859-1")
    |> assert_elastic_send_option(:charset_body_text, "iso-8859-1")
  end

  test "data_source/2 works correctly" do
    new_email()
    |> data_source("data_source")
    |> assert_elastic_send_option(:data_source, "data_source")
  end

  test "encoding_type/2 works correctly" do
    ~w(none raw_7bit raw_8bit quoted_printable base64 uue)a
    |> Enum.with_index()
    |> Enum.each(fn {type, index} ->
      new_email()
      |> encoding_type(type)
      |> assert_elastic_send_option(:encoding_type, index)
    end)
  end

  test "lists/2 works with a single binary correctly" do
    new_email()
    |> lists("foo")
    |> assert_elastic_send_option(:lists, "foo")
  end

  test "lists/2 works with a list of binaries correctly" do
    new_email()
    |> lists(~w(foo bar))
    |> assert_elastic_send_option(:lists, "foo;bar")
  end

  test "merge_source_filename/2 works correctly" do
    new_email()
    |> merge_source_filename("foo")
    |> assert_elastic_send_option(:merge_source_filename, "foo")
  end

  test "pool_name/2 works correctly" do
    new_email()
    |> pool_name("foo")
    |> assert_elastic_send_option(:pool_name, "foo")
  end

  test "post_back/2 works correctly" do
    new_email()
    |> post_back("foo")
    |> assert_elastic_send_option(:post_back, "foo")
  end

  test "segments/2 works with :all" do
    new_email()
    |> segments(:all)
    |> assert_elastic_send_option(:segments, "0")
  end

  test "segments/2 works with a single binary" do
    new_email()
    |> segments("foo")
    |> assert_elastic_send_option(:segments, "foo")
  end

  test "segments/2 works with a mixed list of :all or binary" do
    new_email()
    |> segments([:all, "foo", "foo", :all])
    |> assert_elastic_send_option(:segments, "0;foo")
  end

  test "template/2 works correctly" do
    new_email()
    |> template("foo")
    |> assert_elastic_send_option(:template, "foo")
  end

  test "time_off_set_minutes/2 ensures that values are in the range 1..524_160" do
    Enum.each(%{0 => 1, 20 => 20, 524_161 => 524_160}, fn {input, output} ->
      new_email()
      |> time_off_set_minutes(input)
      |> assert_elastic_send_option(:time_off_set_minutes, output)
    end)
  end

  test "track_clicks/2 works correctly" do
    new_email()
    |> track_clicks(true)
    |> assert_elastic_send_option(:track_clicks, true)
  end

  test "track_opens/2 works correctly" do
    new_email()
    |> track_opens(false)
    |> assert_elastic_send_option(:track_opens, false)
  end

  test "utm_parameters/2 works correctly" do
    Enum.each(~w(campaign content medium source)a, fn param ->
      new_email()
      |> utm_parameters(%{param => "foo"})
      # credo:disable-for-lines:1 Credo.Check.Warning.UnsafeToAtom
      |> assert_elastic_send_option(:"utm_#{param}", "foo")
    end)
  end

  defp assert_elastic_send_option(%{private: private}, key, value) do
    assert Map.has_key?(private, :elastic_send_options)
    assert Map.has_key?(private.elastic_send_options, key)
    assert get_in(private, [:elastic_send_options, key]) == value
  end

  defp new_email(attrs \\ []) do
    [from: "foo@bar.com", to: []]
    |> Keyword.merge(attrs)
    |> Bamboo.Email.new_email()
    |> Bamboo.Mailer.normalize_addresses()
  end
end
