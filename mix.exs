defmodule Bamboo.ElasticEmailAdapter.Mixfile do
  use Mix.Project

  @project_url "https://github.com/KineticCafe/bamboo_elastic_email"
  @version "1.0.0"

  def project do
    [
      app: :bamboo_elastic_email,
      version: @version,
      elixir: "~> 1.3",
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
      {:bamboo, ">= 0.8.0 or < 2.0.0"},
      {:plug, "~> 1.0"},
      {:hackney, "~> 1.6"},
      poison_dep(Version.compare(System.version(), "1.6.0-rc1")),
      {:cowboy, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end

  defp poison_dep(:lt), do: {:poison, ">= 1.5.0 or < 4.0.0"}
  defp poison_dep(_), do: {:poison, "~> 4.0"}
end
