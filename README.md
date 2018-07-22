# Bamboo.ElasticEmailAdapter

[![Build Status][build_status_svg]][build status]

An [Elastic Email][] adapter for the [Bamboo][] email app for Elixir.

## Installation

1.  Add `bamboo_elastic_email` to your `mix.exs`:

    ```elixir
    def deps do
      [
        {:bamboo, "~> 0.8"},
        {:bamboo_elastic_email, "~> 0.1"}
        # OR: {:bamboo_elastic_email, github: "KineticCafe/bamboo_elastic_email"}
      ]
    end
    ```

2.  If using Elixir before 1.4, or if you are managing all applications
    yourself, ensure that `bamboo` is started before your application:

    ```elixir
    def application do
      [applications: [:bamboo]]
    end
    ```

3.  Add your Elastic Email API key to your config:

    ```elixir
    # In your config/config.exs file
    config :my_app, MyApp.Mailer,
      adapter: Bamboo.ElasticEmailAdapter
      api_key: "my-api-key"
    ```

4.  Follow the Bamboo [Getting Started Guide][getting_started].

5.  To use ElasticEmail's [postBack][] functionality you can place a value in
    the `Email#private` parameter:

    ```elixir
    Email.put_private(email, :elastic_custom_vars, %{post_back: "your-post-back-value"})
    ```

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
[postBack]: https://api.elasticemail.com/public/help#Email_Send
