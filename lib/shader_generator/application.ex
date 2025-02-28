defmodule ShaderGenerator.Application do
  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4000")

    children = [
      {Plug.Cowboy, scheme: :http, plug: ShaderGenerator.Router, options: [port: port]}
    ]

    Logger.info("Starting ShaderGenerator on port #{port}")

    opts = [strategy: :one_for_one, name: ShaderGenerator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
