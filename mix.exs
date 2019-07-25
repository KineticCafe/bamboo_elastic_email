defmodule Bamboo.ElasticEmailAdapter.Mixfile do
  use Mix.Project

  @project_url "https://github.com/KineticCafe/bamboo_elastic_email"
  @version "1.1.1"

  def project do
    [
      app: :bamboo_elastic_email,
      version: @version,
      elixir: "~> 1.4",
      source_url: @project_url,
      homepage_url: @project_url,
      name: "Bamboo Elastic Email Adapter",
      description: "A Bamboo adapter for the Elastic Email email service",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      dialyzer: [
        plt_apps: [:dialyzer, :elixir, :kernel, :mix, :stdlib],
        ignore_warnings: ".dialyzer_ignore",
        flags: [:unmatched_returns, :error_handling, :underspecs]
      ],
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger, :bamboo]]
  end

  defp package do
    [
      maintainers: ["Austin Ziegler", "Kinetic Commerce"],
      licenses: ["MIT"],
      links: %{
        "Github" => @project_url,
        "Elastic Email" => "https://elasticemail.com"
      }
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/bamboo_elastic_email",
      main: "Bamboo.ElasticEmailAdapter",
      source_url: @project_url,
      extras: ["README.md", "Changelog.md", "Contributing.md", "Licence.md"]
    ]
  end

  defp deps do
    [
      {:bamboo, ">= 0.8.0 and < 2.0.0"},
      {:plug, "~> 1.0"},
      {:hackney, "~> 1.6"},
      poison_dep(Version.compare(System.version(), "1.6.0-rc1")),
      {:cowboy, "~> 1.0", only: [:dev, :test]},
      {:plug_cowboy, "~> 1.0 or ~> 2.0", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      ex_doc_dep(Version.compare(System.version(), "1.7.0"))
    ]
  end

  defp poison_dep(:lt), do: {:poison, ">= 1.5.0 and < 4.0.0", optional: true}
  defp poison_dep(_), do: {:poison, "~> 2.0 or ~3.0 or ~> 4.0", optional: true}

  defp ex_doc_dep(:lt), do: {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
  defp ex_doc_dep(_), do: {:ex_doc, "~> 0.19", only: :dev, runtime: false}
end
