defmodule ShaderGenerator.MixProject do
  use Mix.Project

  def project do
    [
      app: :shader_generator,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ShaderGenerator.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.4.0"},
      {:dotenv_parser, "~> 2.0"},
      # Add CORS support for frontend integration
      {:cors_plug, "~> 3.0"}
    ]
  end
end
