defmodule SlackCommand.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :slack_command,
      version: @version,
      elixir: "~> 1.4",
      name: "slack_command",
      description: "Plug builder for the routing of Slack slash commands",
      package: package(),
      deps: deps(),
      docs: [
        main: "readme",
        source_url: "https://github.com/vanetix/slack_command",
        extras: [
          "README.md",
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
      {:ex_doc, "~> 0.18.0", only: [:dev, :test]},
      {:inch_ex, "~> 2.0", only: [:test]}
    ]
  end

  defp package do
    [
      maintainers: ["Matthew McFarland"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/vanetix/slack_command"}
    ]
  end
end
