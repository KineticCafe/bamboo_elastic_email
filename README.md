# Bamboo.ElasticEmailAdapter

[![Build Status][build_status_svg]][build status]

An [Elastic Email][] adapter for the [Bamboo][] email app for Elixir.

## Installation

1.  Add `bamboo` and `bamboo_elastic_email` to your `mix.exs`:

    ```elixir
    def deps do
      [
        {:bamboo, "~> 1.0"},
        {:bamboo_elastic_email, "~> 1.0"}
        # OR: {:bamboo_elastic_email, github: "KineticCafe/bamboo_elastic_email"}
      ]
    end
    ```

2.  Add your Elastic Email API key to your config:

    ```elixir
    # In your config/config.exs file
    config :my_app, MyApp.Mailer,
      adapter: Bamboo.ElasticEmailAdapter
      api_key: "my-api-key"
    ```

3.  Follow the Bamboo [Getting Started Guide][getting_started].

4.  To use [Elastic Email's API parameters][email_send] that are not automatically
      handled by this plug-in natively, you can place a value in the `Email#private`
      parameter:

    ```elixir
    Email.put_private(email, :elastic_send_options, %{post_back: "your-post-back-value", pool_name: "your-pool-name"})
    ```

    Supported parameters are:
      * :attachments
      * :channel
      * :charset_body_html
      * :charset_body_text
      * :data_source
      * :encoding_type
      * :lists
      * :merge
      * :merge_source_filename
      * :pool_name
      * :post_back
      * :segments
      * :template
      * :time_off_set_minutes
      * :track_clicks
      * :track_opens

### A note on Bamboo compatibility

The examples here use the recently release Bamboo 1.0 as an example, but
`bamboo_elastic_email` is compatible with Bamboo 0.8 or Bamboo 1.0.

## Community and Contributing

We welcome your contributions, as described in [Contributing.md][]. Like all
Kinetic Cafe [open source projects][], is under the Kinetic Cafe Open Source
[Code of Conduct][kccoc].

[build status svg]: https://travis-ci.org/KineticCafe/bamboo_elastic_email.svg?branch=master
[build status]: https://travis-ci.org/KineticCafe/bamboo_elastic_email
[Elastic Email]: https://elasticemail.com/
[Bamboo]: https://github.com/thoughtbot/bamboo
[Hex.pm]: https://hex.pm
[getting_started]: https://github.com/thoughtbot/bamboo#getting-started
[Contributing.md]: Contributing.md
[open source projects]: https://github.com/KineticCafe
[kccoc]: https://github.com/KineticCafe/code-of-conduct
[email_send]: https://api.elasticemail.com/public/help#Email_Send
