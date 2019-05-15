defmodule Slash.Mixfile do
  use Mix.Project

  @version "2.0.4"

  def project do
    [
      app: :slash,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "slash",
      description: "Plug builder for the routing of Slack slash commands",
      package: package(),
      deps: deps(),
      docs: [
        main: "readme",
        source_url: "https://github.com/vanetix/slash",
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.7"},
      {:jason, "~> 1.1"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19.3", only: [:dev, :test]},
      {:httpoison, "~> 1.5"},
      {:inch_ex, "~> 2.0", only: [:test]},
      {:mox, "~> 0.5.0", only: [:test]}
    ]
  end

  defp package do
    [
      maintainers: ["Matthew McFarland"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/vanetix/slash"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
